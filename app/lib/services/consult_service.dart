import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/condition_entry.dart';
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
import 'consult_suggestions.dart';
import 'consult_tools.dart';
import 'organize_service.dart' show OrganizeModelCall;
import 'tool_chat.dart';

/// 主动咨询提示词（D-26：不诊断不开药，需要就医时明确说）。
/// 改动本提示词时同步更新 docs/prompts.md。
const consultSystemPrompt = """
你是一个个人健康助手。用户带着自己的健康档案摘要向你咨询，输入是一个 JSON：
today 是今天的日期，profile 是基本资料，long_term_conditions 是已确认的
长期身体状况，recent_temporary_conditions 是近期疾病，past_conditions 是
用户标记已痊愈或已解除的既往病史，conversation 是本次咨询的对话历史，
最后一条是当前问题。

要求：
- 结合个人背景回答，让建议贴合这个人（有结石就考虑结石，有过敏就避开过敏原）；
- 既往病史只作背景（比如问到相关话题时可以提一句预防复发），不要当作现在的疾病；
- 不做医疗诊断，不给具体用药和剂量；情况可能需要就医时，明确建议就医并说明原因；
- 背景信息可能不全：缺什么就说明你的假设，不要编造用户没提供的情况；
- 用中文回答，简洁、分点，不说空泛的养生套话；
- 直接输出回答正文，不要输出 JSON。
""";

/// 允许查阅时追加的工具说明（D-43）。改动时同步更新 docs/prompts.md。
const consultLookupPrompt = """

你可以用工具查用户的数据：日常记录、手机/手表健康数据、检验指标及其历史、
病历和报告里已核对的文字结论。工具只读，查到的都是用户本人的数据。
- 问题和具体数据有关时（最近睡得怎样、某项指标的变化、以前查出过什么），
  先查再答，不要凭空推测；和个人数据无关的常识问题不必查；
- 只查回答需要的范围：日期从近到远，够用就停，不要为了"全面"把能查的都查一遍；
- 检验项目先用 list_lab_items 找到项目名，再查历史；
- 有 read_health_live 工具时，睡眠细节、心率、血氧、血压、体重等手机"健康"
  里的数据用它实时读：先想清楚问的是哪段时间（"昨晚""这次运动"），
  先找到对应的时间段再读指标；没有这个工具时用 get_device_data；
- 查不到数据就直说没有记录（没有记录不等于没有发生），不要编造；
- 回答里用到具体数据时注明日期，让用户知道依据是什么。
""";

/// 带工具的模型调用，测试时替换为假实现。
typedef ToolChatCall = Future<ToolChatResponse> Function({
  required ModelConfig config,
  required String apiKey,
  String? system,
  required List<ToolChatMessage> messages,
  required List<ToolSpec> tools,
  required bool allowTools,
  required int maxTokens,
});

/// 主动咨询（D-26）：问题 + 最小上下文发默认模型；咨询是问答
/// 不是录入——不进消息流、不参与整理、不生成记录；历史本地保存可回看。
///
/// 用户允许查阅时按 agent 方式运行（D-43）：模型可多轮调用只读工具
/// （[ConsultTools]）按需查数据，最多 [maxLookupRounds] 轮后必须作答。
/// 每一轮都写一条调用记录，问题下方列出查了什么。
class ConsultService {
  ConsultService({
    required AppDatabase db,
    required RecordRepository records,
    required ProfileRepository profile,
    required OrganizeRepository organize,
    required ModelConfigRepository modelConfigs,
    required KeyStore keyStore,
    required ConsultTools tools,
    OrganizeModelCall? modelCall,
    ToolChatCall? toolCall,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _records = records,
        _profile = profile,
        _organize = organize,
        _modelConfigs = modelConfigs,
        _keyStore = keyStore,
        _tools = tools,
        _modelCall = modelCall ?? _defaultCall,
        _toolCall = toolCall ?? _defaultToolCall;

  final AppDatabase _db;
  final RecordRepository _records;
  final ProfileRepository _profile;
  final OrganizeRepository _organize;
  final ModelConfigRepository _modelConfigs;
  final KeyStore _keyStore;
  final ConsultTools _tools;
  final OrganizeModelCall _modelCall;
  final ToolChatCall _toolCall;
  final IdGenerator ids;

  /// 查阅轮数上限：到最后一轮禁止再调用工具，逼模型作答。
  static const maxLookupRounds = 6;

  /// "允许模型查阅我的记录"开关的设置键，默认开（D-43）。
  static const allowLookupKey = 'consult_allow_lookup';

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

  static Future<ToolChatResponse> _defaultToolCall({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required List<ToolChatMessage> messages,
    required List<ToolSpec> tools,
    required bool allowTools,
    required int maxTokens,
  }) =>
      ModelClient().chatWithTools(
          config: config,
          apiKey: apiKey,
          system: system,
          messages: messages,
          tools: tools,
          allowTools: allowTools,
          maxTokens: maxTokens);

  /// 输入框下的示例问题，按本机已有的数据生成（D-45）。
  Future<List<SuggestionGroup>> suggestions() => buildConsultSuggestions(
        db: _db,
        records: _records,
        deviceData: _tools.deviceData,
        liveAvailable: _tools.liveAvailable,
      );

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
  /// [allowLookup] 为真时模型可按需调用只读工具查数据（D-43）；为假时
  /// 只发最小上下文（D-26）。
  Future<ConsultMessage> ask(
    String sessionId,
    String question, {
    bool allowLookup = false,
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
    // 已痊愈的长期状况单列为既往病史，只作背景（D-41）。
    final past = <Map<String, Object?>>[];
    final recent30 = _daysAgo(30);
    // 同一问题各年份的报告各有一条：归成一组，按最新那条算，首次发现取
    // 最早的日期，既往写法附在 earlier 里（D-32）。
    final reviewed = <ConditionEntry>[];
    for (final rec in await _records.byType(RecordType.condition)) {
      final rev = await _records.currentRevisionOf(rec.id);
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      if (!(meta['condition']?.isProtected ?? false)) continue;
      reviewed.add(ConditionEntry(rec, rev,
          (jsonDecode(rev.data) as Map).cast<String, Object?>(), meta));
    }
    for (final group in ConditionEntry.groups(reviewed)) {
      final latest = group.first;
      final entry = {
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
        (latest.resolved ? past : longTerm).add(entry);
      } else if ((latest.date ?? '').compareTo(recent30) >= 0 &&
          !latest.resolved) {
        temporary.add(entry);
      }
    }

    final history = await messagesOf(sessionId);
    final contextNote = [
      '问题',
      if (profile.isNotEmpty) '基本资料',
      '状况档案 ${longTerm.length + temporary.length} 条',
      if (history.isNotEmpty) '本会话历史 ${history.length} 条',
    ].join(' + ');

    final asked = await _insert(sessionId, 'user', question,
        contextNote: contextNote);

    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final userText = jsonEncode({
      'today': _daysAgo(0),
      'profile': profile,
      'long_term_conditions': longTerm,
      'recent_temporary_conditions': temporary,
      'past_conditions': past,
      'conversation': [
        for (final m in history.takeLast(20)) {'role': m.role, 'text': m.body},
        {'role': 'user', 'text': question},
      ],
    });

    (String, String) answer;
    var note = contextNote;
    if (allowLookup) {
      final lookups = <String>[];
      try {
        answer = await _askWithTools(
            config, apiKey, userText, contextNote, lookups);
      } on ModelClientException catch (e) {
        // 第一轮就被拒（400/422）多半是模型或服务不支持工具：按原方式答。
        if (lookups.isNotEmpty || !(e.statusCode == 400 || e.statusCode == 422)) {
          rethrow;
        }
        AppLog.I.w('consult', '带工具的请求被拒，按不查阅的方式回答：${e.message}');
        note = '$contextNote（模型不支持查阅，按原方式回答）';
        answer = await _askOnce(config, apiKey, userText, note);
      } finally {
        if (lookups.isNotEmpty) note = '$contextNote + 查阅：${lookups.join('、')}';
        if (note != contextNote) await _updateNote(asked.id, note);
      }
    } else {
      answer = await _askOnce(config, apiKey, userText, contextNote);
    }
    final (reply, callId) = answer;

    if (reply.trim().isEmpty) {
      throw StateError('模型返回为空，稍后重试');
    }
    AppLog.I.i('consult', '咨询完成：$note');
    return _insert(sessionId, 'assistant', reply.trim(), modelCallId: callId);
  }

  /// 一问一答（不查阅）。返回回答和调用记录 ID。
  Future<(String, String)> _askOnce(ModelConfig config, String apiKey,
      String userText, String contextNote) async {
    final requestAt = ids.nowMs();
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
      await _logCall(config, requestAt, contextNote, userText, null);
      rethrow;
    }
    final call =
        await _logCall(config, requestAt, contextNote, userText, response);
    return (response.text, call.id);
  }

  /// agent 循环（D-43）：模型要查就执行工具、把结果发回，直到给出回答。
  /// 每轮一条调用记录，request_text 是这一轮新发出的内容（首轮是上下文，
  /// 之后是工具结果）。[lookups] 收集给用户看的"查了什么"。
  Future<(String, String)> _askWithTools(ModelConfig config, String apiKey,
      String userText, String contextNote, List<String> lookups) async {
    final messages = <ToolChatMessage>[UserText(userText)];
    final tools = await _tools.availableSpecs();
    var sent = userText;
    var summary = contextNote;
    for (var round = 1;; round++) {
      final requestAt = ids.nowMs();
      ToolChatResponse response;
      try {
        response = await _toolCall(
          config: config,
          apiKey: apiKey,
          system: consultSystemPrompt + consultLookupPrompt,
          messages: messages,
          tools: tools,
          allowTools: round < maxLookupRounds,
          maxTokens: 4096,
        );
      } catch (e) {
        await _logCall(config, requestAt, summary, sent, null);
        rethrow;
      }
      final call = await _logCall(
          config,
          requestAt,
          summary,
          sent,
          ModelResponse(
            text: response.toolCalls.isEmpty
                ? response.text
                : jsonEncode({
                    if (response.text.isNotEmpty) 'text': response.text,
                    'tool_calls': [
                      for (final c in response.toolCalls)
                        {'name': c.name, 'arguments': c.arguments},
                    ],
                  }),
            tokensIn: response.tokensIn,
            tokensOut: response.tokensOut,
          ));
      if (response.toolCalls.isEmpty) return (response.text, call.id);

      final results = <ToolResult>[];
      final logged = <String>[];
      final notes = <String>[];
      for (final c in response.toolCalls) {
        final outcome = await _tools.run(c);
        results.add(ToolResult(callId: c.id, content: outcome.content));
        // 实时健康数据只发给模型，调用记录里只写读了什么（D-44）。
        logged.add(outcome.ephemeral
            ? '（实时健康数据，未保存）${outcome.note}'
            : outcome.content);
        notes.add(outcome.note);
      }
      lookups.addAll(notes);
      messages
        ..add(response.assistant)
        ..add(ToolResults(results));
      sent = jsonEncode([
        for (var i = 0; i < results.length; i++)
          {'tool': response.toolCalls[i].name, 'result': logged[i]},
      ]);
      summary = '查阅结果：${notes.join('、')}';
    }
  }

  Future<ModelCall> _logCall(ModelConfig config, int requestAt,
          String summary, String requestText, ModelResponse? response) =>
      _organize.recordModelCall(
        modelConfigId: config.id,
        dataBoundary: config.dataBoundary,
        sentMessageIdsJson: '[]',
        sentAttachmentIdsJson: '[]',
        requestAt: requestAt,
        responseAt: ids.nowMs(),
        status: response == null
            ? ModelCallStatus.failed
            : ModelCallStatus.succeeded,
        tokensIn: response?.tokensIn,
        tokensOut: response?.tokensOut,
        responseText: response?.text,
        caller: ModelCaller.userConsult,
        sentSummary: summary,
        requestText: requestText,
      );

  Future<void> _updateNote(String messageId, String note) =>
      (_db.update(_db.consultMessages)..where((t) => t.id.equals(messageId)))
          .write(ConsultMessagesCompanion(contextNote: Value(note)));

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
