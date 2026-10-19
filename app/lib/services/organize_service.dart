import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/change_log.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import '../data/repositories/record_repository.dart';
import 'key_store.dart';
import 'model_client.dart';
import 'organize_prompt.dart';
import 'organize_result.dart';

/// 模型调用入口，测试时替换为假实现。
typedef OrganizeModelCall = Future<ModelResponse> Function({
  required ModelConfig config,
  required String apiKey,
  String? system,
  required String userText,
  required int maxTokens,
});

/// 整理管线（D-05、schema §3.1/§3.1a，plan-v0.2 V2-M2）。
///
/// 单一写入队列：触发（记好了 / 无输入预整理 / 每日回顾 / 用户重整理）只
/// 负责建批次排队，[_pump] 串行执行，不并行处理同一输入。每一项在一个
/// 事务里按 D-05 提交：输入快照校验 → 目标版本校验 → 受保护字段转修正
/// 建议 → 记录、来源、项状态与消息状态同事务落盘。
///
/// stale 重排的次数上限（2 次转 needs_manual）按消息在内存里计数，进程
/// 重启后从头计——上限只是防死循环，不是精确账本；目标记录的重排次数
/// 持久在 organize_run_items.retry_count 上并跨批次继承。
class OrganizeService {
  OrganizeService({
    required AppDatabase db,
    required MessageRepository messages,
    required RecordRepository records,
    required OrganizeRepository runs,
    required ModelConfigRepository modelConfigs,
    required KeyStore keyStore,
    OrganizeModelCall? modelCall,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _messages = messages,
        _records = records,
        _runs = runs,
        _modelConfigs = modelConfigs,
        _keyStore = keyStore,
        _modelCall = modelCall ?? _defaultModelCall;

  final AppDatabase _db;
  final MessageRepository _messages;
  final RecordRepository _records;
  final OrganizeRepository _runs;
  final ModelConfigRepository _modelConfigs;
  final KeyStore _keyStore;
  final OrganizeModelCall _modelCall;
  final IdGenerator ids;

  static Future<ModelResponse> _defaultModelCall({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    required int maxTokens,
  }) =>
      ModelClient().complete(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens);

  Future<void>? _pumpFuture;
  Timer? _idleTimer;

  /// 模型调用失败后的自动重试计时；成功一次即清零退避。
  Timer? _retryTimer;
  int _retryAttempt = 0;
  static const _retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 30),
  ];

  /// 每条消息因 stale 重排的次数（内存计数，见类注释）。
  final _staleCounts = <String, int>{};

  /// 建一个整理批次并启动队列。没有待整理消息或没有默认模型时返回 null
  /// （A-10：没有模型时一切照常，消息保持"待整理"）。
  Future<OrganizeRun?> enqueue(OrganizeTrigger trigger) async {
    if (await _modelConfigs.defaultConfig() == null) return null;
    final pending = await _messages.pendingOrganize();
    // 有文字的消息都参与；纯图片消息也带上（模型把它们关联到相邻记录，
    // 照片本身的识别等图片输入能力）。
    final input = <Message>[];
    for (final m in pending.where((m) => !_isManual(m))) {
      if (m.body != null || await _hasAttachments(m.id)) input.add(m);
    }
    if (input.isEmpty || input.every((m) => m.body == null)) return null;

    final snapshot = await _buildSnapshot(input);
    final run = await _runs.createRun(
      trigger: trigger,
      inputSnapshotJson: jsonEncode(snapshot),
    );
    unawaited(pump());
    return run;
  }

  bool _isManual(Message m) => m.organizeState == OrganizeState.needsManual;

  Future<bool> _hasAttachments(String messageId) async {
    final row = await (_db.select(_db.messageAttachments)
          ..where((t) => t.messageId.equals(messageId) & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// 应用启动 / 配好模型后的补整理（A-10 恢复后可以补整理）。
  Future<void> catchUp() async {
    await enqueue(OrganizeTrigger.idle);
  }

  /// 用户在记录上点"重新整理"（D-05 触发时机 4）：把这条记录的来源消息
  /// 重新排队，再建一个 userReorganize 批次。记录本身经 _updatableRecords
  /// 进入"已有记录"清单，模型带 record_id 更新而不是新建。
  /// 没有默认模型或找不到可重排的来源消息时返回 null。
  Future<OrganizeRun?> reorganizeRecord(String recordId) async {
    final msgIds = <String>{};
    for (final rev in await _records.revisionsOf(recordId)) {
      for (final src in await _records.sourcesOf(rev.id)) {
        if (src.sourceKind == RecordSourceKind.message) msgIds.add(src.sourceId);
      }
    }
    var any = false;
    for (final id in msgIds) {
      final m = await _messages.byId(id);
      if (m == null || m.deletedAt != null) continue;
      await _messages.setOrganizeState(id, OrganizeState.needsReorganize);
      any = true;
    }
    if (!any) return null;
    return enqueue(OrganizeTrigger.userReorganize);
  }

  /// 用户有输入动作时调用：重置"短暂无输入预整理"计时（R-08，只触发
  /// 预整理，不代表结束或确认）。
  void noteUserActivity(Duration idleAfter) {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleAfter, () => enqueue(OrganizeTrigger.idle));
  }

  void dispose() {
    _idleTimer?.cancel();
    _retryTimer?.cancel();
  }

  /// 串行执行队列里的全部批次。UI 可以不等它；测试里 await 它拿最终状态。
  /// 已在执行时返回同一个在途 Future，不并行开第二个循环。
  Future<void> pump() {
    final inFlight = _pumpFuture;
    if (inFlight != null) return inFlight;
    final future = _drain().whenComplete(() => _pumpFuture = null);
    _pumpFuture = future;
    return future;
  }

  Future<void> _drain() async {
    while (true) {
      final run = await _runs.nextQueuedRun();
      if (run == null) break;
      await _execute(run);
    }
  }

  // ---- 快照 ----

  Future<Map<String, Object?>> _buildSnapshot(List<Message> input) async {
    final msgIds = input.map((m) => m.id).toList();
    final attachments = await (_db.select(_db.messageAttachments)
          ..where((t) => t.messageId.isIn(msgIds) & t.deletedAt.isNull()))
        .get();
    final linkedRecords = await _updatableRecords(msgIds);
    return {
      'messages': [
        for (final m in input)
          {
            'id': m.id,
            'revision_no': m.revisionNo,
            'version': m.version,
            'deleted': m.deletedAt != null,
          },
      ],
      'attachments': [
        for (final a in attachments) {'id': a.attachmentId, 'link_id': a.id},
      ],
      'records': [
        for (final (rec, _) in linkedRecords)
          {'id': rec.id, 'version': rec.version},
      ],
    };
  }

  /// 本批允许模型更新的已有记录：这些消息此前整理出过的记录（消息修改后
  /// 重整理，A-24），加上近 7 天的记录（补充说明更新既有记录，A-25、A-09）。
  Future<List<(RecordRow, RecordRevision)>> _updatableRecords(
      List<String> messageIds) async {
    final recordIds = <String>{};
    if (messageIds.isNotEmpty) {
      final sources = await (_db.select(_db.recordSources)
            ..where((t) =>
                t.sourceKind.equalsValue(RecordSourceKind.message) &
                t.sourceId.isIn(messageIds)))
          .get();
      if (sources.isNotEmpty) {
        final revisions = await (_db.select(_db.recordRevisions)
              ..where((t) =>
                  t.id.isIn(sources.map((s) => s.recordRevisionId).toSet())))
            .get();
        recordIds.addAll(revisions.map((r) => r.recordId));
      }
    }
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final cutoffDate =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    recordIds.addAll((await _records.since(cutoffDate)).map((r) => r.id));

    final result = <(RecordRow, RecordRevision)>[];
    for (final id in recordIds) {
      final rec = await _records.byId(id);
      if (rec == null || rec.deletedAt != null) continue;
      result.add((rec, await _records.currentRevisionOf(id)));
    }
    return result;
  }

  // ---- 批次执行 ----

  Future<void> _execute(OrganizeRun run) async {
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      await _runs.updateRunStatus(run.id, OrganizeRunStatus.failed,
          error: '没有可用的模型配置', finishedAt: ids.nowMs());
      return;
    }
    await _runs.updateRunStatus(run.id, OrganizeRunStatus.running,
        startedAt: ids.nowMs());
    await (_db.update(_db.organizeRuns)..where((t) => t.id.equals(run.id)))
        .write(OrganizeRunsCompanion(
      modelConfigId: Value(config.id),
      modelSnapshot: Value(jsonEncode({
        'preset': enumToDb(config.preset),
        'protocol': enumToDb(config.protocol),
        'base_url': config.baseUrl,
        'model': config.model,
        'data_boundary': enumToDb(config.dataBoundary),
      })),
    ));

    final snapshot =
        (jsonDecode(run.inputSnapshot) as Map).cast<String, Object?>();
    final snapMessages = {
      for (final m in (snapshot['messages'] as List).cast<Map>())
        m['id'] as String: m.cast<String, Object?>(),
    };
    final snapRecordVersions = {
      for (final r in (snapshot['records'] as List? ?? const []).cast<Map>())
        r['id'] as String: r['version'] as int,
    };

    // 只用仍与快照一致、且当前仍待整理的消息组 prompt。
    // 关键（2026-09-28 防重复）：多个批次可能针对同一批 pending 消息排队
    // （连点记好了、失败重试、换模型补整理）。organizeState 从 pending→
    // organized 不改 version，光靠快照版本判断会让后一个批次把已整理的
    // 消息再整理一遍，产生重复记录。因此额外排除当前已不再 pending 的消息。
    final usable = <Message>[];
    var anyChanged = false;
    for (final id in snapMessages.keys) {
      final m = await _messages.byId(id);
      if (m == null) continue;
      final stillPending = m.organizeState == OrganizeState.pending ||
          m.organizeState == OrganizeState.needsReorganize;
      if (_matchesSnapshot(m, snapMessages[id]!) && stillPending) {
        usable.add(m);
      } else if (m.deletedAt == null && stillPending) {
        anyChanged = true;
      }
    }
    if (usable.isEmpty) {
      // 没有仍需整理的消息（多为已被前一批整理）：无事可做，记 succeeded。
      await _runs.updateRunStatus(run.id, OrganizeRunStatus.succeeded,
          finishedAt: ids.nowMs());
      if (anyChanged) await enqueue(run.trigger);
      return;
    }

    final msgIds = usable.map((m) => m.id).toList();
    final attachmentCounts = <String, int>{};
    for (final id in msgIds) {
      final links = await (_db.select(_db.messageAttachments)
            ..where((t) => t.messageId.equals(id) & t.deletedAt.isNull()))
          .get();
      if (links.isNotEmpty) attachmentCounts[id] = links.length;
    }
    final existingRecords = (await _updatableRecords(msgIds))
        .where((r) => snapRecordVersions.containsKey(r.$1.id))
        .toList();

    // 调模型并记录调用（D-16）。
    final requestAt = ids.nowMs();
    final userText = buildOrganizeInput(
      messages: usable,
      attachmentCounts: attachmentCounts,
      existingRecords: existingRecords,
    );
    ModelResponse response;
    try {
      final apiKey = config.keychainRef.isEmpty
          ? ''
          : (await _keyStore.read(config.keychainRef) ?? '');
      response = await _modelCall(
        config: config,
        apiKey: apiKey,
        system: organizeSystemPrompt,
        userText: userText,
        maxTokens: 8192,
      );
    } on ModelClientException catch (e) {
      await _runs.recordModelCall(
        organizeRunId: run.id,
        modelConfigId: config.id,
        dataBoundary: config.dataBoundary,
        sentMessageIdsJson: jsonEncode(msgIds),
        sentAttachmentIdsJson: '[]',
        requestAt: requestAt,
        status: ModelCallStatus.failed,
        responseText: e.message,
        caller: ModelCaller.phoneOrganize,
        requestText: userText,
      );
      // 本机/局域网模型不可达：排队等待，绝不改走云端（A-11、D-16）。
      final status =
          e.retriable && config.dataBoundary != DataBoundary.cloud
              ? OrganizeRunStatus.blockedBoundary
              : OrganizeRunStatus.failed;
      await _runs.updateRunStatus(run.id, status,
          error: e.message, finishedAt: ids.nowMs());
      await _noticeModelUnavailable(e, usable.first.sentTz);
      if (e.retriable) _scheduleRetry();
      return;
    }
    _retryTimer?.cancel();
    _retryAttempt = 0;
    await _noticeModelRecovered(usable.first.sentTz);
    await _runs.recordModelCall(
      organizeRunId: run.id,
      modelConfigId: config.id,
      dataBoundary: config.dataBoundary,
      sentMessageIdsJson: jsonEncode(msgIds),
      sentAttachmentIdsJson: '[]',
      requestAt: requestAt,
      responseAt: ids.nowMs(),
      status: ModelCallStatus.succeeded,
      tokensIn: response.tokensIn,
      tokensOut: response.tokensOut,
      responseText: response.text,
      caller: ModelCaller.phoneOrganize,
      requestText: userText,
    );

    final parsed = parseOrganizeResponse(
      response.text,
      validMessageIds: msgIds.toSet(),
      validRecordIds: snapRecordVersions.keys.toSet(),
      fallbackTz: usable.first.sentTz,
    );
    if (parsed == null) {
      await _runs.updateRunStatus(run.id, OrganizeRunStatus.failed,
          error: '模型返回的不是合法 JSON 数组', finishedAt: ids.nowMs());
      return;
    }

    // 逐项提交（D-05）。
    var committed = 0;
    var stale = 0;
    final staleMessageIds = <String>{};
    final messageItemStates = <String, List<OrganizeItemStatus>>{};
    for (final candidate in parsed.candidates) {
      final recordId = candidate.existingRecordId ?? ids.newId();
      final prior = await _priorRetryCount(recordId);
      final item = await _runs.upsertItem(
        organizeRunId: run.id,
        recordId: recordId,
        status: OrganizeItemStatus.pending,
        initialRetryCount: prior,
      );
      final status = await _commitItem(
        run: run,
        item: item,
        candidate: candidate,
        recordId: recordId,
        snapMessages: snapMessages,
        snapRecordVersions: snapRecordVersions,
      );
      for (final msgId in candidate.sourceMessageIds) {
        messageItemStates.putIfAbsent(msgId, () => []).add(status);
      }
      if (status == OrganizeItemStatus.committed ||
          status == OrganizeItemStatus.protectedSuggested) {
        committed++;
        if (candidate.existingRecordId == null) {
          await _noticeIfOtherDate(candidate, recordId, snapMessages);
        }
      } else if (status == OrganizeItemStatus.staleInput ||
          status == OrganizeItemStatus.staleTarget) {
        stale++;
        staleMessageIds.addAll(candidate.sourceMessageIds);
      }
    }

    // 消息状态汇总：所有相关项落定才更新（schema §3.1a）。
    for (final m in usable) {
      final states = messageItemStates[m.id] ?? const [];
      final hasStale = states.any((s) =>
          s == OrganizeItemStatus.staleInput ||
          s == OrganizeItemStatus.staleTarget);
      if (hasStale) continue; // 留给重排批次
      if (states.any((s) => s == OrganizeItemStatus.needsManual)) {
        await _messages.setOrganizeState(m.id, OrganizeState.needsManual);
      } else if (states.isEmpty && m.body == null) {
        // 纯图片消息没被任何记录引用：保持待整理，等图片输入能力。
      } else {
        // 全部提交成功，或这条文字消息没产出记录（闲聊）：都算整理过。
        await _messages.setOrganizeState(m.id, OrganizeState.organized);
      }
    }

    // stale 的输入重排；同一消息两次后转 needs_manual（D-05 第 4 条）。
    var requeue = false;
    for (final msgId in staleMessageIds) {
      final count = (_staleCounts[msgId] ?? 0) + 1;
      _staleCounts[msgId] = count;
      if (count >= 2) {
        await _messages.setOrganizeState(msgId, OrganizeState.needsManual);
      } else {
        requeue = true;
      }
    }

    final errorText = parsed.errors.isEmpty ? null : parsed.errors.join('；');
    final OrganizeRunStatus finalStatus;
    if (parsed.candidates.isEmpty && parsed.errors.isEmpty) {
      finalStatus = OrganizeRunStatus.succeeded;
    } else if (committed == parsed.candidates.length && parsed.errors.isEmpty) {
      finalStatus = OrganizeRunStatus.succeeded;
    } else if (committed > 0 || stale > 0) {
      finalStatus = OrganizeRunStatus.partial;
    } else {
      finalStatus = OrganizeRunStatus.failed;
    }
    await _runs.updateRunStatus(run.id, finalStatus,
        error: errorText, finishedAt: ids.nowMs());

    if (requeue) await enqueue(run.trigger);
  }

  /// 归属日期不是消息发送日时，在对话流里提示"已记到 X月X日"；
  /// 凌晨歧义（date_ambiguous）时提示核对，点开记录即可改（A-23、D-06）。
  Future<void> _noticeIfOtherDate(
    OrganizeCandidate candidate,
    String recordId,
    Map<String, Map<String, Object?>> snapMessages,
  ) async {
    final localDate = candidate.occurred.localDate;
    if (localDate == null) return;
    final firstSource = await _messages.byId(candidate.sourceMessageIds.first);
    if (firstSource == null) return;
    final sent =
        DateTime.fromMillisecondsSinceEpoch(firstSource.sentAt).toLocal();
    final sentDate =
        '${sent.year}-${sent.month.toString().padLeft(2, '0')}-${sent.day.toString().padLeft(2, '0')}';
    final ambiguous = candidate.occurred.dateAmbiguous;
    if (localDate == sentDate && !ambiguous) return;

    final d = DateTime.parse(localDate);
    final text = ambiguous
        ? '已记到 ${d.month}月${d.day}日，对吗？点开可改'
        : '已记到 ${d.month}月${d.day}日';
    await _messages.send(
      clientMsgId: ids.newId(),
      role: MessageRole.app,
      kind: MessageKind.appNotice,
      text: text,
      sentTz: firstSource.sentTz,
      inReplyTo: firstSource.id,
      promptMeta: jsonEncode({'kind': 'date_notice', 'record_id': recordId}),
    );
  }

  /// 退避后自动补整理（网络、超时、5xx、限流这类会自己恢复的失败）。
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay =
        _retryDelays[_retryAttempt.clamp(0, _retryDelays.length - 1)];
    _retryAttempt++;
    _retryTimer = Timer(delay, () => unawaited(catchUp()));
  }

  /// 模型调用失败时在对话流提示一次：消息已保存，模型可用后自动整理。
  /// 上一条模型状态提示已经是"不可用"时不重复提示（跨重启也成立）。
  Future<void> _noticeModelUnavailable(
      ModelClientException e, String sentTz) async {
    if (await _lastModelNoticeKind() == 'model_unavailable') return;
    final text = e.retriable
        ? '当前模型不可用，消息已保存，模型可用时会自动整理'
        : '当前模型不可用（${e.message}），消息已保存。'
            '请检查模型设置，模型可用时会自动整理';
    await _messages.send(
      clientMsgId: ids.newId(),
      role: MessageRole.app,
      kind: MessageKind.appNotice,
      text: text,
      sentTz: sentTz,
      promptMeta: jsonEncode({'kind': 'model_unavailable'}),
    );
  }

  /// 此前提示过不可用、这次调用成功：告诉用户已恢复并在整理。
  Future<void> _noticeModelRecovered(String sentTz) async {
    if (await _lastModelNoticeKind() != 'model_unavailable') return;
    await _messages.send(
      clientMsgId: ids.newId(),
      role: MessageRole.app,
      kind: MessageKind.appNotice,
      text: '模型已恢复，之前的消息已开始整理',
      sentTz: sentTz,
      promptMeta: jsonEncode({'kind': 'model_recovered'}),
    );
  }

  Future<String?> _lastModelNoticeKind() async {
    final row = await (_db.select(_db.messages)
          ..where((t) =>
              t.kind.equalsValue(MessageKind.appNotice) &
              t.promptMeta.like('%"kind":"model_%'))
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return (jsonDecode(row.promptMeta!) as Map)['kind'] as String?;
  }

  bool _matchesSnapshot(Message m, Map<String, Object?> snap) =>
      m.deletedAt == null &&
      m.revisionNo == snap['revision_no'] &&
      m.version == snap['version'] &&
      snap['deleted'] == false;

  Future<int> _priorRetryCount(String recordId) async {
    final rows = await (_db.select(_db.organizeRunItems)
          ..where((t) => t.recordId.equals(recordId))
          ..orderBy([(t) => OrderingTerm.desc(t.retryCount)])
          ..limit(1))
        .get();
    return rows.isEmpty ? 0 : rows.first.retryCount;
  }

  /// 提交一项（D-05 的四条规则），返回最终状态。
  Future<OrganizeItemStatus> _commitItem({
    required OrganizeRun run,
    required OrganizeRunItem item,
    required OrganizeCandidate candidate,
    required String recordId,
    required Map<String, Map<String, Object?>> snapMessages,
    required Map<String, int> snapRecordVersions,
  }) async {
    return _db.transaction(() async {
      // 1. 输入校验：来源消息与快照一致。
      for (final msgId in candidate.sourceMessageIds) {
        final current = await _messages.byId(msgId);
        if (current == null ||
            !_matchesSnapshot(current, snapMessages[msgId]!)) {
          final updated = await _runs.markItem(
              item.id, OrganizeItemStatus.staleInput);
          if (updated.retryCount >= 2) {
            await _runs.markItem(item.id, OrganizeItemStatus.needsManual);
            return OrganizeItemStatus.needsManual;
          }
          return OrganizeItemStatus.staleInput;
        }
      }

      final isUpdate = candidate.existingRecordId != null;
      var data = Map<String, Object?>.from(candidate.data);

      // 饮食记录带上来源消息的照片（schema §3.5 photo_attachment_ids）。
      if (candidate.recordType == RecordType.meal) {
        final photoIds = await _imageAttachmentIds(candidate.sourceMessageIds);
        if (photoIds.isNotEmpty) data['photo_attachment_ids'] = photoIds;
      }

      final sources = [
        for (final msgId in candidate.sourceMessageIds)
          SourceLink(
            sourceKind: RecordSourceKind.message,
            sourceId: msgId,
            messageRevisionNo:
                snapMessages[msgId]!['revision_no'] as int,
          ),
      ];

      if (!isUpdate) {
        final fieldMeta = _newFieldMeta(data, candidate.inferredFields);
        await _records.create(
          recordId: recordId,
          recordType: candidate.recordType,
          occurred: candidate.occurred,
          occurredEnd: candidate.occurredEnd,
          dataJson: jsonEncode(data),
          fieldMeta: fieldMeta,
          producedBy: ProducedBy.organizeRun(run.id),
          sources: sources,
        );
        await _runs.markItem(item.id, OrganizeItemStatus.committed);
        return OrganizeItemStatus.committed;
      }

      // 2. 目标校验：记录版本与快照一致。
      final rec = await _records.byId(recordId);
      final snapVersion = snapRecordVersions[recordId]!;
      if (rec == null || rec.deletedAt != null || rec.version != snapVersion) {
        final updated =
            await _runs.markItem(item.id, OrganizeItemStatus.staleTarget);
        if (updated.retryCount >= 2) {
          await _runs.markItem(item.id, OrganizeItemStatus.needsManual);
          return OrganizeItemStatus.needsManual;
        }
        return OrganizeItemStatus.staleTarget;
      }

      // 3. 受保护字段不覆盖，新值不同转修正建议（不为此重调模型）。
      final currentRev = await _records.currentRevisionOf(recordId);
      final currentData =
          (jsonDecode(currentRev.data) as Map).cast<String, Object?>();
      final currentMeta = FieldMetaMap.decode(currentRev.fieldMeta);
      final proposed = <String, Object?>{};
      final mergedData = Map<String, Object?>.from(currentData);
      final mergedMeta = Map<String, FieldMeta>.from(currentMeta.fields);
      data.forEach((field, value) {
        final meta = currentMeta[field];
        if (meta != null && meta.isProtected) {
          if (jsonEncode(currentData[field]) != jsonEncode(value)) {
            proposed[field] = value;
          }
          return; // 保留原值与原状态
        }
        mergedData[field] = value;
        mergedMeta[field] = FieldMeta(
          origin: candidate.inferredFields.contains(field)
              ? FieldOrigin.modelInferred
              : FieldOrigin.userStated,
          reviewStatus: ReviewStatus.unreviewed,
        );
      });

      final updatedRec = await _records.addRevision(
        recordId: recordId,
        baseVersion: snapVersion,
        occurred: candidate.occurred,
        occurredEnd: candidate.occurredEnd,
        dataJson: jsonEncode(mergedData),
        fieldMeta: FieldMetaMap(mergedMeta),
        producedBy: ProducedBy.organizeRun(run.id),
        sources: sources,
      );

      if (proposed.isEmpty) {
        await _runs.markItem(item.id, OrganizeItemStatus.committed);
        return OrganizeItemStatus.committed;
      }
      // 修正建议绑定提交后的版本（schema §6.2、§3.1a）。
      final suggestion = await _db
          .into(_db.correctionSuggestions)
          .insertReturning(CorrectionSuggestionsCompanion.insert(
            id: ids.newId(),
            userId: item.userId,
            createdAt: ids.nowMs(),
            createdOnDevice: item.createdOnDevice,
            proposedBy: SuggestionProposedBy.organizeRun,
            organizeRunId: Value(run.id),
            targetRecordId: recordId,
            targetVersion: updatedRec.version,
            proposedData: jsonEncode(proposed),
            reason: '整理批次得出的新值与用户确认过的字段不同',
            status: SuggestionStatus.pending,
          ));
      await _db.logChange(
          deviceId: item.createdOnDevice,
          table: 'correction_suggestions',
          entityId: suggestion.id);
      await _runs.markItem(item.id, OrganizeItemStatus.protectedSuggested,
          correctionSuggestionId: suggestion.id);
      return OrganizeItemStatus.protectedSuggested;
    });
  }

  FieldMetaMap _newFieldMeta(
      Map<String, Object?> data, Set<String> inferredFields) {
    return FieldMetaMap({
      for (final field in data.keys)
        field: FieldMeta(
          origin: inferredFields.contains(field)
              ? FieldOrigin.modelInferred
              : FieldOrigin.userStated,
          reviewStatus: ReviewStatus.unreviewed,
        ),
    });
  }

  Future<List<String>> _imageAttachmentIds(List<String> messageIds) async {
    final links = await (_db.select(_db.messageAttachments)
          ..where((t) => t.messageId.isIn(messageIds) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    if (links.isEmpty) return [];
    final ids = links.map((l) => l.attachmentId).toList();
    final images = await (_db.select(_db.attachments)
          ..where((t) => t.id.isIn(ids) & t.mimeType.like('image/%')))
        .get();
    final imageIds = images.map((a) => a.id).toSet();
    return [
      for (final l in links)
        if (imageIds.contains(l.attachmentId)) l.attachmentId,
    ];
  }
}
