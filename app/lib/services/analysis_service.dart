import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/change_log.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import 'key_store.dart';
import 'model_client.dart';
import 'organize_service.dart' show OrganizeModelCall;

/// 周报提示词（D-20：只做描述与关联，不下医疗诊断）。
const weeklyReviewSystemPrompt = '''
你是健康记录的周报分析师。根据输入的一周记录写一份简短周报（Markdown），
只输出一个 JSON 对象，不要输出其他文字：
{"content_md": "周报正文", "citations": [{"claim_id": "C1", "record_revision_ids": ["..."]}]}

要求：
- 正文分节：饮食、睡眠、运动、心情与不适、值得注意的变化；
- 每条事实陈述末尾标注 [C1] [C2] 这样的引用号，citations 里给出该陈述
  依据的 record_revision_ids（用输入里给出的 revision_id，不要编造）；
- 只描述记录里有的事实和趋势，没有数据的方面写"本周没有记录"；
- 不做医疗诊断，不给用药建议；可以温和提示值得留意的模式；
- 用户手动修改过的值以记录为准，不要质疑。
''';

/// 分析结果的生成与读取（V3-M5，schema §6.1，D-14/D-20）。
/// 生成在 Mac 上进行；手机通过同步端点拉取副本。
class AnalysisService {
  AnalysisService({
    required AppDatabase db,
    required ModelConfigRepository modelConfigs,
    required OrganizeRepository organize,
    required KeyStore keyStore,
    required this.deviceId,
    OrganizeModelCall? modelCall,
    this.ids = const IdGenerator(),
  })  : _db = db,
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

  /// 生成上周周报。失败抛异常，已有的旧周报保留（product-spec §5）。
  Future<AnalysisArtifact> generateWeeklyReview() async {
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
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

    final requestAt = ids.nowMs();
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final response = await _modelCall(
      config: config,
      apiKey: apiKey,
      system: weeklyReviewSystemPrompt,
      userText: jsonEncode({
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
      }),
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
    );

    final parsed = _parse(response.text);
    if (parsed == null) {
      throw StateError('模型返回的不是预期的 JSON，本次周报未生成（旧周报保留）');
    }

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
