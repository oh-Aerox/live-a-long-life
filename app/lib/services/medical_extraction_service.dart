import 'dart:convert';
import 'dart:io';

import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/time_value.dart';
import 'app_log.dart';
import 'key_store.dart';
import 'model_client.dart';
import 'organize_service.dart' show OrganizeModelCall;
import 'page_filter.dart';
import 'redaction.dart';
import 'text_extraction.dart';

/// 医疗文件结构化提取提示词（D-23：输入是经页筛选、脱敏的 OCR 文本，
/// 带行索引；要求逐字段引用行号，应用据此映射回坐标写 locator）。
/// 改动本提示词时同步更新 docs/prompts.md。
const labExtractSystemPrompt = '''
你是医疗文件（检验单、检查报告、病历）的结构化提取器。输入是一份医疗文件经本地文字识别后的文本，
每行有形如 P2L5 的行号（第 2 页第 5 行）。只输出一个 JSON 对象，不要输出其他文字：
{
  "doc": {
    "doc_type": "lab_report" | "imaging_report" | "visit_record" | "prescription" | "discharge_summary" | "other",
    "institution_text": "医疗机构名称，按原文" 或 null,
    "exam_date": "YYYY-MM-DD" 或 null（检查/采样日期）,
    "report_date": "YYYY-MM-DD" 或 null（报告日期）
  },
  "results": [
    {
      "item_name_raw": "报告上的项目名称，按原文",
      "value_raw": "报告上的数值，按原文",
      "value_num": 解析出的数值 或 null,
      "unit_raw": "报告上的单位，按原文" 或 null,
      "ref_range_raw": "报告上的参考范围，按原文" 或 null,
      "ref_low": 参考范围下限 或 null,
      "ref_high": 参考范围上限 或 null,
      "flag_raw": "报告上的异常标记（↑、↓、H、L 等）" 或 null,
      "source_lines": ["该项数据来自的行号，如 P1L3"，至少一个]
    }
  ],
  "findings": [
    {
      "section_raw": "栏目名称，按原文（如 主诉、现病史、诊断、处理意见、超声所见、超声提示、检查结论、印象）" 或 null,
      "text_raw": "该栏目下的文字，按原文完整抄写",
      "source_lines": ["来源行号"，至少一个]
    }
  ],
  "conditions": [
    {
      "name": "疾病或身体状况名称，按原文（如 胆囊结石、青霉素过敏）",
      "persistence": "long_term" | "temporary",
      "evidence_text": "依据的原文片段（诊断、结论、印象一栏）",
      "source_lines": ["来源行号"，至少一个]
    }
  ]
}

规则：
- *_raw 字段一律按原文抄写，不要改写、翻译或归一化；
- 解析不出的数值字段（value_num、ref_low、ref_high）留 null，不要猜；
- source_lines 只能用输入里出现的行号，不要编造；
- 没有检验数值表时 results 为空数组；文字内容不进 results，放进 findings；
- findings 收报告和病历里与健康相关的文字：病历/门诊记录的主诉、现病史、
  诊断、处理意见，超声/影像/心电图等报告的所见、提示、结论、印象，
  检验单上的结论或备注；按栏目分条，逐字抄写，不要摘要、改写或合并栏目；
  医院介绍、注意事项、签名栏不收；没有就给空数组；
- conditions 只收诊断/结论/印象/病史文字里明确写出的疾病或状况；
  结石、囊肿、结节、慢性病、过敏等不会自行消失的算 long_term，
  感冒、急性感染等预期痊愈的算 temporary，拿不准按 long_term（会由用户核对）；
  检验数值异常本身不是状况，不要凭数值推断疾病；没有就给空数组；
- 文本里的【姓名】【证件号】是脱敏占位符，不是数据，忽略它们；
- 检查日期和报告日期是两个日期，分不清时只填能确认的那个。
''';

/// 提取结果：记录 + 每页的筛选判定（UI 展示"已排除"标记用）+ 遮蔽项数
/// + 近似重复候选（同检查日期同项目的已有记录，D-10）。
class MedicalExtractOutcome {
  const MedicalExtractOutcome({
    required this.record,
    required this.pageDecisions,
    required this.redactedCount,
    this.possibleDuplicateRecordIds = const [],
    this.conditionRecords = const [],
  });

  final RecordRow record;
  final List<PageDecision> pageDecisions;
  final int redactedCount;
  final List<String> possibleDuplicateRecordIds;

  /// 本次新建的身体状况建议（unreviewed，D-25）；同名已有档案时不重复建。
  final List<RecordRow> conditionRecords;
}

/// 一页的预览信息（提取前的页筛选展示：默认判定 + 用户覆盖）。
class PagePreview {
  const PagePreview({
    required this.pageNo,
    required this.attachmentId,
    required this.attachmentPage,
    required this.source,
    required this.included,
    required this.reason,
    required this.overridden,
    required this.firstLine,
  });

  final int pageNo;
  final String attachmentId;
  final int attachmentPage;
  final PageTextSource source;
  final bool included;
  final String reason;

  /// 当前判定是否来自用户覆盖（而不是规则默认）。
  final bool overridden;
  final String firstLine;
}

/// 发送草稿的一页：本地识别 + 页筛选判定 + 脱敏后的行（坐标保留）。
class DraftPage {
  const DraftPage({
    required this.pageNo,
    required this.attachmentId,
    required this.attachmentPage,
    required this.source,
    required this.included,
    required this.reason,
    required this.overridden,
    required this.lines,
    required this.redactedCount,
  });

  final int pageNo;
  final String attachmentId;
  final int attachmentPage;
  final PageTextSource source;
  final bool included;
  final String reason;

  /// 当前判定是否来自用户覆盖（而不是规则默认）。
  final bool overridden;

  /// 已脱敏的行，占位符见 [RedactionService]。
  final List<OcrLine> lines;
  final int redactedCount;
}

/// 发送草稿（D-28）：发给模型之前的完整内容，预览页所见即所发。
/// 用户在预览页可改写或删除任意行（[edits]，键 P{页}L{行}，空串 = 这行
/// 不发送）；修改只作用于这次发送，不改原件和本地识别缓存。
class SendDraft {
  SendDraft({required this.documentId, required this.pages});

  final String documentId;
  final List<DraftPage> pages;
  final Map<String, String> edits = {};

  static String lineKey(int pageNo, int lineIndex) =>
      'P${pageNo}L${lineIndex + 1}';

  List<DraftPage> get includedPages => [
        for (final p in pages)
          if (p.included) p
      ];

  /// 一行将要发送的文本（用户改过则用改后的）。
  String lineText(DraftPage page, int index) =>
      edits[lineKey(page.pageNo, index)] ?? page.lines[index].text;

  bool isEdited(DraftPage page, int index) =>
      edits.containsKey(lineKey(page.pageNo, index));

  int get redactedCount =>
      includedPages.fold(0, (sum, p) => sum + p.redactedCount);

  int get sentLineCount {
    var n = 0;
    for (final p in includedPages) {
      for (var i = 0; i < p.lines.length; i++) {
        if (lineText(p, i).trim().isNotEmpty) n++;
      }
    }
    return n;
  }

  /// 发给模型的全文：`P{页}L{行}: 文本`，删掉的行不发。
  String get payload {
    final buf = StringBuffer();
    for (final p in includedPages) {
      for (var i = 0; i < p.lines.length; i++) {
        final text = lineText(p, i);
        if (text.trim().isEmpty) continue;
        buf.writeln('${lineKey(p.pageNo, i)}: $text');
      }
    }
    return buf.toString();
  }

  /// 调用记录里的发送范围描述（A-38 同一字段）。
  String get summary => '医疗文件 ${includedPages.length}/${pages.length} 页，'
      '$sentLineCount 行文字（发送前已预览确认），自动遮蔽 $redactedCount 处'
      '${edits.isEmpty ? '' : '，手动修改 ${edits.length} 行'}';
}

/// 医疗文件结构化提取（V4-M1，D-23/D-24/D-28）：
/// 本地 OCR（带缓存）→ 页筛选 → 脱敏 →【用户预览修改】→ 纯文本模型调用 → lab_panel 记录
/// （全部 unreviewed，D-04 关键字段确认后才算事实）→ 回填文件级信息。
class MedicalExtractionService {
  MedicalExtractionService({
    required AttachmentRepository attachments,
    required MedicalDocumentRepository documents,
    required RecordRepository records,
    required OrganizeRepository organize,
    required ModelConfigRepository modelConfigs,
    required KeyStore keyStore,
    required TextExtractionService extraction,
    this.pageFilter = const PageFilter(),
    this.redaction = const RedactionService(),
    OrganizeModelCall? modelCall,
    this.ids = const IdGenerator(),
  })  : _attachments = attachments,
        _documents = documents,
        _records = records,
        _organize = organize,
        _modelConfigs = modelConfigs,
        _keyStore = keyStore,
        _extraction = extraction,
        _modelCall = modelCall ?? _defaultCall;

  final AttachmentRepository _attachments;
  final MedicalDocumentRepository _documents;
  final RecordRepository _records;
  final OrganizeRepository _organize;
  final ModelConfigRepository _modelConfigs;
  final KeyStore _keyStore;
  final TextExtractionService _extraction;
  final PageFilter pageFilter;
  final RedactionService redaction;
  final OrganizeModelCall _modelCall;
  final IdGenerator ids;

  static Future<ModelResponse> _defaultCall({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    required int maxTokens,
  }) =>
      // 提取输出长（逐项抄写数值与文字），60 秒常超时，单独放宽。
      ModelClient(timeout: const Duration(seconds: 180)).complete(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens);

  /// 对一份医疗文件做结构化提取（不经预览直接发送；测试与批量场景用）。
  /// 界面走 [prepareSend] → 用户预览修改 → [sendDraft] 两步（D-28）。
  Future<MedicalExtractOutcome> extractDocument(
    String documentId, {
    List<String> knownNames = const [],
  }) async =>
      sendDraft(await prepareSend(documentId, knownNames: knownNames));

  /// 发送前准备（D-28 第一步，全程本地、不调模型）：本地识别 → 页筛选
  /// （规则默认 + 用户覆盖）→ 脱敏。返回的草稿即将要发送的全部内容，
  /// 预览页逐行展示，用户可改可删，确认后交给 [sendDraft]。
  /// [knownNames] 是脱敏用的已知姓名（D-24 第三层）。
  Future<SendDraft> prepareSend(
    String documentId, {
    List<String> knownNames = const [],
  }) async {
    final doc = await _documents.byId(documentId);
    if (doc == null) throw StateError('医疗文件不存在：$documentId');

    // 1. 本地提取（带缓存）。一个附件可能是多页 PDF，页号在文件内连续编。
    final docPages = await _loadDocPages(doc);
    if (docPages.isEmpty) throw StateError('没有可提取的页');

    // 2. 页筛选（D-23）：规则默认 + 用户覆盖（预览页每页可点选，不静默丢）。
    // 3. 脱敏（D-24）：只作用于发送副本，坐标保留供 locator 回映射。
    //    排除页也脱敏，用户在预览里改成发送时所见即所发。
    final overrides =
        MedicalDocumentRepository.decodePageOverrides(doc.pageOverrides);
    final pages = <DraftPage>[];
    for (final p in docPages) {
      final byRule = pageFilter.decide(p.page);
      final override = overrides[p.pageNo];
      final r = redaction.redactPage(p.page.lines, knownNames: knownNames);
      pages.add(DraftPage(
        pageNo: p.pageNo,
        attachmentId: p.attachmentId,
        attachmentPage: p.attachmentPage,
        source: p.page.source,
        included: override ?? byRule.included,
        reason: override == null
            ? byRule.reason
            : (override ? '用户选择发送' : '用户选择排除'),
        overridden: override != null,
        lines: r.lines,
        redactedCount: r.redactedCount,
      ));
    }
    return SendDraft(documentId: doc.id, pages: pages);
  }

  /// 按草稿发送并建记录（D-28 第二步）：发出去的正是 [SendDraft.payload]，
  /// 与预览页所见一致；用户改过的行按改后文本发送并写入 locator 原文。
  Future<MedicalExtractOutcome> sendDraft(SendDraft draft) async {
    final doc = await _documents.byId(draft.documentId);
    if (doc == null) throw StateError('医疗文件不存在：${draft.documentId}');
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }
    final included = draft.includedPages;
    if (included.isEmpty) {
      throw StateError('全部页都被排除了：至少选一页发送');
    }
    final attachmentIds = {for (final p in draft.pages) p.attachmentId};
    final redactedTotal = draft.redactedCount;
    final sentSummary = draft.summary;

    final requestAt = ids.nowMs();
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    ModelResponse response;
    try {
      response = await _modelCall(
        config: config,
        apiKey: apiKey,
        system: labExtractSystemPrompt,
        userText: draft.payload,
        maxTokens: 8192,
      );
    } catch (e) {
      await _organize.recordModelCall(
        modelConfigId: config.id,
        dataBoundary: config.dataBoundary,
        sentMessageIdsJson: '[]',
        sentAttachmentIdsJson: jsonEncode(attachmentIds.toList()),
        requestAt: requestAt,
        responseAt: ids.nowMs(),
        status: ModelCallStatus.failed,
        caller: ModelCaller.phoneMedicalExtract,
        redactedCount: redactedTotal,
        sentSummary: sentSummary,
      );
      rethrow;
    }
    final call = await _organize.recordModelCall(
      modelConfigId: config.id,
      dataBoundary: config.dataBoundary,
      sentMessageIdsJson: '[]',
      sentAttachmentIdsJson: jsonEncode(attachmentIds.toList()),
      requestAt: requestAt,
      responseAt: ids.nowMs(),
      status: ModelCallStatus.succeeded,
      tokensIn: response.tokensIn,
      tokensOut: response.tokensOut,
      responseText: response.text,
      caller: ModelCaller.phoneMedicalExtract,
      redactedCount: redactedTotal,
      sentSummary: sentSummary,
    );

    final parsed = _parse(response.text);
    if (parsed == null) {
      AppLog.I.w('extract', '结构化提取解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，本次提取未生成记录');
    }
    final docInfo = (parsed['doc'] as Map?)?.cast<String, Object?>() ?? {};
    final rawResults = (parsed['results'] as List?) ?? const [];

    // 5. source_lines → locator（见 [_locatorsOf]）。
    final lineIndex = <String, (DraftPage, OcrLine)>{};
    for (final p in included) {
      for (var i = 0; i < p.lines.length; i++) {
        final text = draft.lineText(p, i);
        if (text.trim().isEmpty) continue; // 用户删掉的行没发送
        lineIndex['P${p.pageNo}L${i + 1}'] = (p, _withText(p.lines[i], text));
      }
    }
    final results = <Map<String, Object?>>[];
    for (final raw in rawResults) {
      if (raw is! Map) continue;
      final r = raw.cast<String, Object?>();
      if (r['item_name_raw'] is! String || r['value_raw'] is! String) continue;
      final locators = _locatorsOf(r['source_lines'], lineIndex);
      results.add({
        'item_name_raw': r['item_name_raw'],
        'value_raw': r['value_raw'],
        'value_num': r['value_num'],
        'unit_raw': r['unit_raw'],
        'ref_range_raw': r['ref_range_raw'],
        'ref_low': r['ref_low'],
        'ref_high': r['ref_high'],
        'flag_raw': r['flag_raw'],
        'locator': locators,
      });
    }

    // 文字内容（D-28）：病历的主诉/诊断/处理意见、超声等报告的所见/结论。
    // 只有文字、没有数值的报告靠它保留，不因 results 为空而丢掉。
    final findings = <Map<String, Object?>>[];
    for (final raw in (parsed['findings'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final text = raw['text_raw'];
      if (text is! String || text.trim().isEmpty) continue;
      final section = raw['section_raw'];
      findings.add({
        'section_raw': section is String && section.trim().isNotEmpty
            ? section.trim()
            : null,
        'text_raw': text.trim(),
        'locator': _locatorsOf(raw['source_lines'], lineIndex),
      });
    }

    // 6. 建 lab_panel 记录：全部字段 modelInferred + unreviewed（D-04：
    //    五个关键字段确认后才作为事实参与分析）。
    final examDate = docInfo['exam_date'] as String?;
    final occurred = TimeValue(
      localDate: examDate ?? _today(),
      precision:
          examDate != null ? TimePrecision.dateOnly : TimePrecision.unknown,
      source: examDate != null
          ? TimeValueSource.userStated
          : TimeValueSource.inferredFromSentAt,
      rawText: examDate,
    );
    const unreviewed = FieldMeta(
        origin: FieldOrigin.modelInferred,
        reviewStatus: ReviewStatus.unreviewed);
    final meta = <String, FieldMeta>{
      for (var i = 0; i < results.length; i++) 'results.$i': unreviewed,
      for (var i = 0; i < findings.length; i++) 'findings.$i': unreviewed,
    };
    final dataJson = jsonEncode({
      'medical_document_id': doc.id,
      'results': results,
      'findings': findings,
    });
    final sources = [
      for (final id in attachmentIds)
        SourceLink(sourceKind: RecordSourceKind.attachment, sourceId: id),
    ];
    // 重新提取：在同一条记录上追加新版本（旧版本与核对历史保留，R-34），
    // 不另建一条——否则同一份文件的数值会在索引和分析里出现两遍。
    final existing = await _records.labPanelOfDocument(doc.id);
    final record = existing == null
        ? await _records.create(
            recordType: RecordType.labPanel,
            occurred: occurred,
            dataJson: dataJson,
            fieldMeta: FieldMetaMap(meta),
            producedBy: ProducedBy.medicalExtract(call.id),
            sources: sources,
          )
        : await _records.addRevision(
            recordId: existing.id,
            baseVersion: existing.version,
            occurred: occurred,
            dataJson: dataJson,
            fieldMeta: FieldMetaMap(meta),
            producedBy: ProducedBy.medicalExtract(call.id),
            sources: sources,
          );

    // 7. 回填文件级信息（uploaded_at 不动，三个时间各自独立，D-06）。
    final docTypeRaw = docInfo['doc_type'] as String?;
    MedicalDocType? docType;
    if (docTypeRaw != null) {
      try {
        docType = enumFromDb(MedicalDocType.values, docTypeRaw);
      } catch (_) {}
    }
    await _documents.updateInfo(
      doc.id,
      docType: docType,
      institutionText: docInfo['institution_text'] as String?,
      examDate: examDate == null
          ? null
          : TimeValue(
              localDate: examDate,
              precision: TimePrecision.dateOnly,
              source: TimeValueSource.userStated),
      reportDate: docInfo['report_date'] is String
          ? TimeValue(
              localDate: docInfo['report_date'] as String,
              precision: TimePrecision.dateOnly,
              source: TimeValueSource.userStated)
          : null,
    );

    final duplicates =
        await _findNearDuplicates(record.id, examDate, results);
    final conditions = await _createConditionSuggestions(
      parsed['conditions'] as List? ?? const [],
      lineIndex: lineIndex,
      examDate: examDate,
      documentId: doc.id,
      callId: call.id,
      attachmentIds: attachmentIds,
    );
    AppLog.I.i('extract',
        '结构化提取完成：${results.length} 项，文字 ${findings.length} 段，'
        '遮蔽 $redactedTotal 处，'
        '发送 ${included.length}/${draft.pages.length} 页'
        '${conditions.isEmpty ? '' : '，新增 ${conditions.length} 条状况建议'}'
        '${duplicates.isEmpty ? '' : '，疑似与 ${duplicates.length} 条已有记录重复'}');
    return MedicalExtractOutcome(
      record: record,
      pageDecisions: [
        for (final p in draft.pages)
          PageDecision(pageNo: p.pageNo, included: p.included, reason: p.reason),
      ],
      redactedCount: redactedTotal,
      possibleDuplicateRecordIds: duplicates,
      conditionRecords: conditions,
    );
  }

  /// 本地提取一份文件的全部页（不调模型，供提取与页预览共用）。
  Future<List<_DocPage>> _loadDocPages(MedicalDocument doc) async {
    final docPages = <_DocPage>[];
    var pageNo = 0;
    for (final ref in MedicalPageRef.decodeList(doc.pages)) {
      final att = await _attachments.byId(ref.attachmentId);
      final path = await _attachments.localPathOf(ref.attachmentId);
      if (att == null || path == null) {
        throw StateError('附件本地文件不可用，先取回原件再提取（D-22）');
      }
      final extracted = await _extraction.extract(
          sha256: att.sha256, file: File(path), mimeType: att.mimeType);
      for (final p in extracted) {
        pageNo += 1;
        docPages.add(_DocPage(
          pageNo: pageNo,
          attachmentId: att.id,
          attachmentPage: p.pageNo,
          page: ExtractedPage(pageNo: pageNo, source: p.source, lines: p.lines),
        ));
      }
    }
    return docPages;
  }

  /// 页预览（提取前）：本地 OCR + 规则判定 + 用户覆盖合并，全程不调模型。
  /// 导入页用它渲染每页的"已排除"标记（D-23 不静默丢弃）。
  Future<List<PagePreview>> previewPages(String documentId) async {
    final doc = await _documents.byId(documentId);
    if (doc == null) throw StateError('医疗文件不存在：$documentId');
    final docPages = await _loadDocPages(doc);
    final overrides =
        MedicalDocumentRepository.decodePageOverrides(doc.pageOverrides);
    return [
      for (final p in docPages)
        () {
          final byRule = pageFilter.decide(p.page);
          final override = overrides[p.pageNo];
          return PagePreview(
            pageNo: p.pageNo,
            attachmentId: p.attachmentId,
            attachmentPage: p.attachmentPage,
            source: p.page.source,
            included: override ?? byRule.included,
            reason: override == null
                ? byRule.reason
                : (override ? '用户选择发送' : '用户选择排除'),
            overridden: override != null,
            firstLine:
                p.page.lines.isEmpty ? '（空白页）' : p.page.lines.first.text,
          );
        }(),
    ];
  }

  /// 身体状况建议（D-25）：模型从诊断/结论文字提取，全部 unreviewed，
  /// 用户在档案页核对后才算事实。同名（去空白）状况已有档案时不重复建。
  Future<List<RecordRow>> _createConditionSuggestions(
    List<Object?> raw, {
    required Map<String, (DraftPage, OcrLine)> lineIndex,
    required String? examDate,
    required String documentId,
    required String callId,
    required Set<String> attachmentIds,
  }) async {
    if (raw.isEmpty) return const [];
    // 已有状况的名称键（含未核对的：同一份报告重新提取不重复建）。
    final existingKeys = <String>{};
    for (final rec in await _records.byType(RecordType.condition)) {
      final rev = await _records.currentRevisionOf(rec.id);
      final name = (jsonDecode(rev.data) as Map)['name'];
      if (name is String) {
        existingKeys.add(RecordRepository.labItemKey(name));
      }
    }

    final created = <RecordRow>[];
    for (final c in raw) {
      if (c is! Map) continue;
      final name = c['name'];
      final persistence = c['persistence'];
      if (name is! String || name.trim().isEmpty) continue;
      if (persistence != 'long_term' && persistence != 'temporary') continue;
      final key = RecordRepository.labItemKey(name);
      if (!existingKeys.add(key)) continue; // 同名已有，不重复建档

      final locators = _locatorsOf(c['source_lines'], lineIndex);
      final locator = locators.isEmpty ? null : locators.first;
      final record = await _records.create(
        recordType: RecordType.condition,
        occurred: TimeValue(
          localDate: examDate ?? _today(),
          precision:
              examDate != null ? TimePrecision.dateOnly : TimePrecision.unknown,
          source: examDate != null
              ? TimeValueSource.userStated
              : TimeValueSource.inferredFromSentAt,
        ),
        dataJson: jsonEncode({
          'name': name.trim(),
          'persistence': persistence,
          'status': 'active',
          'source_kind': 'report',
          'evidence_text': c['evidence_text'],
          'development_text': null,
          'last_checked_date': null,
          'medical_document_id': documentId,
          'locator': locator,
        }),
        fieldMeta: FieldMetaMap({
          'condition': const FieldMeta(
              origin: FieldOrigin.modelInferred,
              reviewStatus: ReviewStatus.unreviewed),
        }),
        producedBy: ProducedBy.medicalExtract(callId),
        sources: [
          for (final id in attachmentIds)
            SourceLink(sourceKind: RecordSourceKind.attachment, sourceId: id),
        ],
      );
      created.add(record);
    }
    return created;
  }

  /// source_lines → locator（附件 ID + 文件页号 + 附件内页号 + 坐标；
  /// 文字层无坐标时只有页号和原文行）。编造或未发送的行号丢弃。
  static List<Map<String, Object?>> _locatorsOf(
      Object? sourceLines, Map<String, (DraftPage, OcrLine)> lineIndex) {
    final locators = <Map<String, Object?>>[];
    for (final key in (sourceLines as List? ?? const [])) {
      final hit = lineIndex[key];
      if (hit == null) continue;
      final (page, line) = hit;
      locators.add({
        'attachment_id': page.attachmentId,
        'page_no': page.pageNo,
        'attachment_page': page.attachmentPage,
        if (line.hasBox)
          'box': {'x': line.x, 'y': line.y, 'w': line.w, 'h': line.h},
        'line_text': line.text,
      });
    }
    return locators;
  }

  static OcrLine _withText(OcrLine l, String text) =>
      OcrLine(text: text, x: l.x, y: l.y, w: l.w, h: l.h);

  /// 近似重复（D-10 第一版）：同检查日期、同项目 key 的其他 lab_panel 记录。
  Future<List<String>> _findNearDuplicates(
      String newRecordId, String? examDate, List<Map<String, Object?>> results) async {
    if (examDate == null) return const [];
    final hits = <String>{};
    for (final r in results) {
      final name = r['item_name_raw'];
      if (name is! String) continue;
      final history =
          await _records.labResultHistory(RecordRepository.labItemKey(name));
      for (final row in history) {
        if (row.recordId != newRecordId && row.examDate == examDate) {
          hits.add(row.recordId);
        }
      }
    }
    return hits.toList();
  }

  String _today() {
    final t = DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  /// 容错解析（联调经验：中转站不保证严格 JSON）。
  Map<String, Object?>? _parse(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final nl = t.indexOf('\n');
      if (nl > 0) t = t.substring(nl + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
      t = t.trim();
    }
    for (final s in [t, _sliceBraces(t)]) {
      if (s == null || s.isEmpty) continue;
      try {
        final json = jsonDecode(s);
        if (json is Map) return json.cast<String, Object?>();
      } catch (_) {}
    }
    return null;
  }

  String? _sliceBraces(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return s.substring(start, end + 1);
  }

  String _snippet(String s) => s.length <= 200 ? s : '${s.substring(0, 200)}…';
}

class _DocPage {
  const _DocPage({
    required this.pageNo,
    required this.attachmentId,
    required this.attachmentPage,
    required this.page,
  });

  /// 文件内的全局页号（多个附件顺序连编，locator 与 UI 用它）。
  final int pageNo;
  final String attachmentId;

  /// 附件内页号（1 起）：多页 PDF 渲染定位用。
  final int attachmentPage;
  final ExtractedPage page;
}
