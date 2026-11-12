import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/change_log.dart';
import '../data/condition_entry.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import '../data/workout_names.dart';
import 'app_log.dart';
import 'health_service.dart' show DeviceDayData;
import 'key_store.dart';
import 'model_client.dart';
import 'organize_service.dart' show OrganizeModelCall;

/// 周报提示词（D-20：只做描述与关联，不下医疗诊断；R-35：含下周建议）。
/// 改动本提示词时同步更新 docs/prompts.md。
const weeklyReviewSystemPrompt = '''
你是健康记录的周报分析师。根据输入的一周记录写一份简短周报（Markdown），
只输出一个 JSON 对象，不要输出其他文字：
{"content_md": "周报正文", "citations": [{"claim_id": "C1", "record_revision_ids": ["..."]}]}

要求：
- 正文分节：饮食、睡眠、运动、心情与不适、值得注意的变化、下周建议；
- 每条事实陈述末尾标注 [C1] [C2] 这样的引用号，citations 里给出该陈述
  依据的 record_revision_ids（用输入里给出的 revision_id，不要编造）；
- 只描述记录里有的事实和趋势，没有数据的方面写"本周没有记录"；
- health_daily（步数、活动能量）和 health_device（每晚睡眠：时长、入睡、
  醒来；体能训练）是苹果健康等设备数据，睡眠、运动两节要据此描述；它们
  没有 revision_id，不要为它们编造引用，写明"设备数据"即可。用户记录与
  设备数据都没有时才写"本周没有记录"；sleep_minutes 为空表示只有在床数据、
  睡眠时长未知，不要把在床时长当成睡眠时长；
- 下周建议：根据本周记录给出下周在饮食、运动、睡眠等方面的具体注意事项，
  同样标注引用。本周有症状、不适或就医相关记录时，围绕它给出针对性的
  留意事项（比如饮食调整、控制运动强度、保证睡眠）；感冒发烧这类短期不适
  只影响近期建议，不要把它写成长期结论。没有特别情况时给一两条简短的
  维持性建议即可，不要凑数；
- 输入里的 long_term_conditions 是用户已确认的长期身体状况档案
  （结石、慢性病、过敏等），下周建议要把它们考虑进去（比如结石注意
  饮食和饮水、过敏避开过敏原）；recent_temporary_conditions 是近期
  临时疾病，只影响近期建议；past_conditions 是用户标记已痊愈或已解除的
  既往病史，只作背景参考（比如曾有结石，可以温和提一句预防复发），
  不要当作现在的疾病给建议。三者都可能为空；
- 不做医疗诊断，不给用药建议；可以温和提示值得留意的模式；
- 用户手动修改过的值以记录为准，不要质疑。
''';

/// 分析结果的生成与读取（schema §6.1，D-14/D-20）。
/// 生成在 Mac 上进行；手机通过同步端点拉取副本。
class AnalysisService {
  AnalysisService({
    required AppDatabase db,
    required ModelConfigRepository modelConfigs,
    required OrganizeRepository organize,
    required KeyStore keyStore,
    required this.deviceId,
    Future<DeviceDayData> Function(String localDate)? deviceData,
    OrganizeModelCall? modelCall,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _deviceData = deviceData,
        _modelConfigs = modelConfigs,
        _organize = organize,
        _keyStore = keyStore,
        _modelCall = modelCall ?? _defaultCall;

  final AppDatabase _db;
  final ModelConfigRepository _modelConfigs;
  final OrganizeRepository _organize;
  final KeyStore _keyStore;
  final String deviceId;
  final OrganizeModelCall _modelCall;

  /// 按天的设备数据（睡眠按夜合并、体能训练），与日视图同一口径（D-11）。
  /// 睡眠和体能训练按条存在 health_samples，不在 health_daily 里。
  final Future<DeviceDayData> Function(String localDate)? _deviceData;
  final IdGenerator ids;

  static Future<ModelResponse> _defaultCall({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    required int maxTokens,
  }) =>
      // 周报一次输出整篇正文和引用，推理模型常超过默认的 60 秒，同提取用 180 秒。
      ModelClient(timeout: const Duration(seconds: 180)).complete(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens);

  /// 生成上周周报。失败抛异常，已有的旧周报保留（product-spec §12）。
  Future<AnalysisArtifact> generateWeeklyReview() async {
    AppLog.I.i('analysis', '开始生成周报');
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      AppLog.I.w('analysis', '生成周报失败：没有默认模型配置');
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));
    String d(DateTime t) =>
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final periodStart = d(start);
    final periodEnd = d(end);

    // 输入：期间的记录（当前版本）与按天健康数据。
    final records = await (_db.select(_db.records)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.localDate.isNotNull() &
              t.localDate.isBiggerOrEqualValue(periodStart) &
              t.localDate.isSmallerOrEqualValue(periodEnd)))
        .get();
    final input = <Map<String, Object?>>[];
    for (final r in records) {
      if (r.currentRevisionId == null) continue;
      final rev = await (_db.select(_db.recordRevisions)
            ..where((t) => t.id.equals(r.currentRevisionId!)))
          .getSingle();
      input.add({
        'revision_id': rev.id,
        'type': enumToDb(r.recordType),
        'date': r.localDate,
        'data': jsonDecode(rev.data),
      });
    }
    final daily = await (_db.select(_db.healthDaily)
          ..where((t) =>
              t.localDate.isBiggerOrEqualValue(periodStart) &
              t.localDate.isSmallerOrEqualValue(periodEnd)))
        .get();

    final device = <Map<String, Object?>>[];
    if (_deviceData != null) {
      String hm(int ms) {
        final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }

      for (var day = start;
          d(day).compareTo(periodEnd) <= 0;
          day = day.add(const Duration(days: 1))) {
        final data = await _deviceData(d(day));
        final sleep = data.sleep;
        if (sleep == null && data.workouts.isEmpty) continue;
        device.add({
          'date': d(day),
          if (sleep != null)
            'sleep': {
              // 只有在床数据时睡眠时长未知，不拿在床时长冒充（D-11）。
              'sleep_minutes': sleep.sleepDurationMin,
              if (sleep.inBedDurationMin != null)
                'in_bed_minutes': sleep.inBedDurationMin,
              if (sleep.sleepOnsetMs != null) 'onset': hm(sleep.sleepOnsetMs!),
              if (sleep.wakeMs != null) 'wake': hm(sleep.wakeMs!),
            },
          if (data.workouts.isNotEmpty)
            'workouts': [
              for (final w in data.workouts)
                {
                  'type': workoutLabel(w.workoutType),
                  'start': hm(w.startUtc),
                  'minutes': ((w.endUtc - w.startUtc) / 60000).round(),
                  if (w.energyKcal != null) 'kcal': w.energyKcal!.round(),
                },
            ],
        });
      }
    }

    // 身体状况（D-25）：长期档案 + 近 30 天的临时疾病；已痊愈的长期
    // 状况单列为既往病史，只作背景（D-41）。只取已核对的（unreviewed
    // 不算事实，D-04）。
    final recent30 = d(end.subtract(const Duration(days: 30)));
    final longTermConditions = <Map<String, Object?>>[];
    final recentTemporary = <Map<String, Object?>>[];
    final pastConditions = <Map<String, Object?>>[];
    final conditionRecs = await (_db.select(_db.records)
          ..where((t) =>
              t.recordType.equalsValue(RecordType.condition) &
              t.deletedAt.isNull()))
        .get();
    // 同一问题各年份的报告各有一条：归成一组按最新那条算（D-32）。
    final reviewedConditions = <ConditionEntry>[];
    for (final rec in conditionRecs) {
      if (rec.currentRevisionId == null) continue;
      final rev = await (_db.select(_db.recordRevisions)
            ..where((t) => t.id.equals(rec.currentRevisionId!)))
          .getSingle();
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      if (!(meta['condition']?.isProtected ?? false)) continue;
      reviewedConditions.add(ConditionEntry(rec, rev,
          (jsonDecode(rev.data) as Map).cast<String, Object?>(), meta));
    }
    for (final group in ConditionEntry.groups(reviewedConditions)) {
      final latest = group.first;
      final entry = {
        'revision_id': latest.rev.id,
        'name': latest.name,
        'status': latest.data['status'],
        'first_found': group.last.date,
        if (group.length > 1) 'latest_report_date': latest.date,
        'development_text': latest.data['development_text'],
        if (group.length > 1)
          'earlier': [
            for (final c in group.skip(1)) '${c.date ?? ''} ${c.name}'.trim(),
          ],
      };
      if (latest.longTerm) {
        (latest.resolved ? pastConditions : longTermConditions).add(entry);
      } else if ((latest.date ?? '').compareTo(recent30) >= 0 &&
          !latest.resolved) {
        recentTemporary.add(entry);
      }
    }

    final requestAt = ids.nowMs();
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final userText = jsonEncode({
      'period': [periodStart, periodEnd],
      'records': input,
      'health_daily': [
        for (final h in daily)
          {
            'date': h.localDate,
            'metric': enumToDb(h.metric),
            'value': h.value,
          },
      ],
      'health_device': device,
      'long_term_conditions': longTermConditions,
      'recent_temporary_conditions': recentTemporary,
      'past_conditions': pastConditions,
    });
    final response = await _modelCall(
      config: config,
      apiKey: apiKey,
      system: weeklyReviewSystemPrompt,
      userText: userText,
      maxTokens: 8192,
    );
    final call = await _organize.recordModelCall(
      modelConfigId: config.id,
      dataBoundary: config.dataBoundary,
      sentMessageIdsJson: '[]',
      sentAttachmentIdsJson: '[]',
      requestAt: requestAt,
      responseAt: ids.nowMs(),
      status: ModelCallStatus.succeeded,
      tokensIn: response.tokensIn,
      tokensOut: response.tokensOut,
      responseText: response.text,
      caller: ModelCaller.macAnalysis,
      requestText: userText,
    );

    final parsed = _parse(response.text);
    if (parsed == null) {
      AppLog.I.w('analysis',
          '生成周报失败：响应为空，无法解析。原文：${_logSnippet(response.text)}');
      throw StateError('模型返回为空，本次周报未生成（旧周报保留）');
    }
    AppLog.I.i('analysis',
        '周报解析成功，正文 ${parsed.$1.length} 字，引用 ${parsed.$2.length} 条，'
        '输入记录 ${input.length} 条');

    // 生成依据的手机数据截止点：接收游标（D-14）。
    final pull = await (_db.select(_db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull))
          ..limit(1))
        .getSingleOrNull();

    return _db.into(_db.analysisArtifacts).insertReturning(
          AnalysisArtifactsCompanion.insert(
            id: ids.newId(),
            userId: records.isNotEmpty ? records.first.userId : 'unknown',
            createdAt: ids.nowMs(),
            createdOnDevice: deviceId,
            kind: AnalysisKind.weeklyReview,
            periodStart: periodStart,
            periodEnd: periodEnd,
            dataGeneration: pull?.generation ?? '',
            dataCutoffSeq: pull?.ackedContiguousSeq ?? 0,
            dependsOn: jsonEncode({
              'dates': [periodStart, periodEnd],
              'types': ['meal', 'sleep', 'mood', 'symptom', 'exercise', 'note', 'health_daily'],
            }),
            generatedAt: ids.nowMs(),
            generator: jsonEncode({
              'method': 'app',
              'model': config.model,
              'preset': enumToDb(config.preset),
            }),
            modelCallIds: jsonEncode([call.id]),
            contentMd: parsed.$1,
            citations: jsonEncode(parsed.$2),
          ),
        );
  }

  /// 解析周报，三级降级（模型经常不严格返回纯 JSON，尤其中转站/兼容服务）：
  /// 1. 严格 JSON（去 ``` 围栏）；
  /// 2. 从文本里截第一个 { 到最后一个 } 再试；
  /// 3. 仍不行且有实质文本时，把整段返回当作正文（引用留空）——
  ///    正文是周报的核心，引用是加分项，能出内容就不算失败。
  /// 只有响应完全为空才返回 null。
  (String, List<Object?>)? _parse(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final nl = t.indexOf('\n');
      if (nl > 0) t = t.substring(nl + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
      t = t.trim();
    }

    final fromJson = _tryJson(t) ?? _tryJson(_sliceBraces(t));
    if (fromJson != null) return fromJson;

    // 降级：整段文本当正文。去掉可能残留的围栏后若还有内容就用。
    final body = t.trim();
    if (body.isEmpty) return null;
    return (body, const []);
  }

  (String, List<Object?>)? _tryJson(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final json = jsonDecode(s);
      if (json is! Map) return null;
      final content = json['content_md'];
      if (content is! String || content.trim().isEmpty) return null;
      return (content, (json['citations'] as List?) ?? const []);
    } catch (_) {
      return null;
    }
  }

  String? _sliceBraces(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return s.substring(start, end + 1);
  }

  String _logSnippet(String s) {
    final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return one.length > 200 ? '${one.substring(0, 200)}…' : one;
  }

  Future<AnalysisArtifact?> latest(AnalysisKind kind) =>
      (_db.select(_db.analysisArtifacts)
            ..where((t) => t.kind.equalsValue(kind) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// 手机端：保存从 Mac 拉来的分析结果（不入变更日志——不是手机的业务变更）。
  Future<void> saveFetched(Map<String, Object?> row) async {
    final columns = row.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    await _db.customInsert(
      'INSERT OR REPLACE INTO analysis_artifacts (${columns.join(', ')}) '
      'VALUES ($placeholders)',
      variables: [
        for (final c in columns)
          switch (row[c]) {
            null => const Variable(null),
            final int v => Variable.withInt(v),
            final double v => Variable.withReal(v),
            final String v => Variable.withString(v),
            final bool v => Variable.withBool(v),
            _ => throw StateError('不支持的值'),
          },
      ],
    );
  }

  /// 手机端：分析是否已过期（D-14，粗粒度第一版：截止点之后本机有任何
  /// 新变更即视为可能过期；按 depends_on 范围精算留到后续）。
  Future<bool> isStale(AnalysisArtifact artifact) async {
    final generation = await _db.currentGeneration();
    if (artifact.dataGeneration != generation) return true;
    final maxSeq = await _db
        .customSelect(
          'SELECT COALESCE(MAX(change_seq), 0) AS m FROM change_logs '
          'WHERE generation = ?',
          variables: [Variable.withString(generation)],
        )
        .getSingle();
    return (maxSeq.data['m'] as int) > artifact.dataCutoffSeq;
  }
}
