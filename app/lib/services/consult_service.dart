import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/record_repository.dart';
import 'app_log.dart';
import 'key_store.dart';
import 'model_client.dart';
import 'organize_service.dart' show OrganizeModelCall;
import '../data/record_summary.dart';

/// 主动咨询提示词（D-26：不诊断不开药，需要就医时明确说）。
/// 改动本提示词时同步更新 docs/prompts.md。
const consultSystemPrompt = '''
你是一个个人健康助手。用户带着自己的健康档案摘要向你咨询，输入是一个 JSON：
profile 是基本资料，long_term_conditions 是已确认的长期身体状况，
recent_temporary_conditions 是近期疾病，recent_records 是最近 7 天的记录
（用户勾选了才有），conversation 是本次咨询的对话历史，最后一条是当前问题。

要求：
- 结合个人背景回答，让建议贴合这个人（有结石就考虑结石，有过敏就避开过敏原）；
- 不做医疗诊断，不给具体用药和剂量；情况可能需要就医时，明确建议就医并说明原因；
- 背景信息可能不全：缺什么就说明你的假设，不要编造用户没提供的情况；
- 用中文回答，简洁、分点，不说空泛的养生套话；
- 直接输出回答正文，不要输出 JSON。
''';

/// 主动咨询（V4-M6，D-26）：问题 + 最小上下文发默认模型；咨询是问答
/// 不是录入——不进消息流、不参与整理、不生成记录；历史本地保存可回看。
class ConsultService {
  ConsultService({
    required AppDatabase db,
    required RecordRepository records,
    required ProfileRepository profile,
    required OrganizeRepository organize,
    required ModelConfigRepository modelConfigs,
    required KeyStore keyStore,
    OrganizeModelCall? modelCall,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _records = records,
        _profile = profile,
        _organize = organize,
        _modelConfigs = modelConfigs,
        _keyStore = keyStore,
        _modelCall = modelCall ?? _defaultCall;

  final AppDatabase _db;
  final RecordRepository _records;
  final ProfileRepository _profile;
  final OrganizeRepository _organize;
  final ModelConfigRepository _modelConfigs;
  final KeyStore _keyStore;
  final OrganizeModelCall _modelCall;
  final IdGenerator ids;

  static Future<ModelResponse> _defaultCall({
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

  /// 一个会话的全部消息，按时间升序。
  Future<List<ConsultMessage>> messagesOf(String sessionId) =>
      (_db.select(_db.consultMessages)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// 最近一个会话的 ID（打开页面时接着上次聊）；没有则 null。
  Future<String?> latestSessionId() async {
    final row = await (_db.select(_db.consultMessages)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.sessionId;
  }

  /// 提问。把问题存入会话、组上下文调模型、存回答；返回回答消息。
  /// [includeRecentRecords] 用户勾选才附带最近 7 天记录（默认不带，D-26）。
  Future<ConsultMessage> ask(
    String sessionId,
    String question, {
    bool includeRecentRecords = false,
  }) async {
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }

    // 最小上下文（D-26）：基本资料摘要 + 已核对的状况档案。
    final profile = <String, Object?>{};
    for (final key in ['birth_year_month', 'sex_at_birth', 'height_cm']) {
      final v = await _profile.current(key);
      if (v != null && v.$2 != null) profile[key] = v.$2;
    }

    final longTerm = <Map<String, Object?>>[];
    final temporary = <Map<String, Object?>>[];
    final recent30 = _daysAgo(30);
    for (final rec in await _records.byType(RecordType.condition)) {
      final rev = await _records.currentRevisionOf(rec.id);
      final reviewed =
          FieldMetaMap.decode(rev.fieldMeta)['condition']?.isProtected ?? false;
      if (!reviewed) continue;
      final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
      final entry = {
        'name': data['name'],
        'status': data['status'],
        'first_found': rec.localDate,
        'development_text': data['development_text'],
      };
      if (data['persistence'] == 'long_term') {
        longTerm.add(entry);
      } else if ((rec.localDate ?? '').compareTo(recent30) >= 0 &&
          data['status'] == 'active') {
        temporary.add(entry);
      }
    }

    // 可选：最近 7 天记录摘要。
    List<Map<String, Object?>>? recentRecords;
    if (includeRecentRecords) {
      recentRecords = [];
      for (final rec in await _records.since(_daysAgo(7))) {
        if (rec.currentRevisionId == null) continue;
        final rev = await _records.currentRevisionOf(rec.id);
        final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
        final meta = FieldMetaMap.decode(rev.fieldMeta);
        final String summary;
        switch (rec.recordType) {
          // 医疗类只发已核对的内容（D-04）：未核对的状况、报告要点不算事实。
          case RecordType.condition:
            if (!(meta['condition']?.isProtected ?? false)) continue;
            summary = recordSummary(rec.recordType, data);
          case RecordType.labPanel:
            final s = reviewedMedicalSummary(data, meta);
            if (s == null) continue;
            summary = s;
          default:
            summary = recordSummary(rec.recordType, data);
        }
        recentRecords.add({
          'date': rec.localDate,
          'type': enumToDb(rec.recordType),
          'summary': summary,
        });
      }
    }

    final history = await messagesOf(sessionId);
    final contextNote = [
      '问题',
      if (profile.isNotEmpty) '基本资料',
      '状况档案 ${longTerm.length + temporary.length} 条',
      if (recentRecords != null) '最近 7 天记录 ${recentRecords.length} 条',
      if (history.isNotEmpty) '本会话历史 ${history.length} 条',
    ].join(' + ');

    await _insert(sessionId, 'user', question, contextNote: contextNote);

    final requestAt = ids.nowMs();
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final userText = jsonEncode({
      'profile': profile,
      'long_term_conditions': longTerm,
      'recent_temporary_conditions': temporary,
      'recent_records': ?recentRecords,
      'conversation': [
        for (final m in history.takeLast(20)) {'role': m.role, 'text': m.body},
        {'role': 'user', 'text': question},
      ],
    });
    ModelResponse response;
    try {
      response = await _modelCall(
        config: config,
        apiKey: apiKey,
        system: consultSystemPrompt,
        userText: userText,
        maxTokens: 4096,
      );
    } catch (e) {
      await _organize.recordModelCall(
        modelConfigId: config.id,
        dataBoundary: config.dataBoundary,
        sentMessageIdsJson: '[]',
        sentAttachmentIdsJson: '[]',
        requestAt: requestAt,
        responseAt: ids.nowMs(),
        status: ModelCallStatus.failed,
        caller: ModelCaller.userConsult,
        sentSummary: contextNote,
        requestText: userText,
      );
      rethrow;
    }
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
      caller: ModelCaller.userConsult,
      sentSummary: contextNote,
      requestText: userText,
    );

    final reply = response.text.trim();
    if (reply.isEmpty) {
      throw StateError('模型返回为空，稍后重试');
    }
    AppLog.I.i('consult', '咨询完成：$contextNote');
    return _insert(sessionId, 'assistant', reply, modelCallId: call.id);
  }

  Future<ConsultMessage> _insert(String sessionId, String role, String body,
          {String? contextNote, String? modelCallId}) =>
      _db.into(_db.consultMessages).insertReturning(
            ConsultMessagesCompanion.insert(
              id: ids.newId(),
              sessionId: sessionId,
              role: role,
              body: body,
              contextNote: Value(contextNote),
              modelCallId: Value(modelCallId),
              createdAt: ids.nowMs(),
            ),
          );

  String _daysAgo(int days) {
    final t = DateTime.now().subtract(Duration(days: days));
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
