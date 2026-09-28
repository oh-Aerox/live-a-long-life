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

/// 检验单结构化提取提示词（D-23：输入是经页筛选、脱敏的 OCR 文本，
/// 带行索引；要求逐字段引用行号，应用据此映射回坐标写 locator）。
/// 改动本提示词时同步更新 docs/prompts.md。
const labExtractSystemPrompt = '''
你是检验报告的结构化提取器。输入是一份医疗文件经本地文字识别后的文本，
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
  ]
}

规则：
- *_raw 字段一律按原文抄写，不要改写、翻译或归一化；
- 解析不出的数值字段（value_num、ref_low、ref_high）留 null，不要猜；
- source_lines 只能用输入里出现的行号，不要编造；
- 没有检验数值表时 results 为空数组；检查所见、结论等文字内容不进 results；
- 文本里的【姓名】【证件号】是脱敏占位符，不是数据，忽略它们；
- 检查日期和报告日期是两个日期，分不清时只填能确认的那个。
''';

/// 提取结果：记录 + 每页的筛选判定（UI 展示"已排除"标记用）+ 遮蔽项数。
class MedicalExtractOutcome {
  const MedicalExtractOutcome({
    required this.record,
    required this.pageDecisions,
    required this.redactedCount,
  });

  final RecordRow record;
  final List<PageDecision> pageDecisions;
  final int redactedCount;
}

/// 检验单结构化提取（V4-M1，D-23/D-24）：
/// 本地 OCR（带缓存）→ 页筛选 → 脱敏 → 纯文本模型调用 → lab_panel 记录
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
      ModelClient().complete(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens);

  /// 对一份医疗文件做结构化提取。[knownNames] 是脱敏用的已知姓名
  /// （用户资料里的本人姓名，D-24 第三层）。
  Future<MedicalExtractOutcome> extractDocument(
    String documentId, {
    List<String> knownNames = const [],
  }) async {
    final doc = await _documents.byId(documentId);
    if (doc == null) throw StateError('医疗文件不存在：$documentId');
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }

    // 1. 本地提取（带缓存）。一个附件可能是多页 PDF，页号在文件内连续编。
    final docPages = <_DocPage>[];
    var pageNo = 0;
    final attachmentIds = <String>{};
    for (final ref in MedicalPageRef.decodeList(doc.pages)) {
      final att = await _attachments.byId(ref.attachmentId);
      final path = await _attachments.localPathOf(ref.attachmentId);
      if (att == null || path == null) {
        throw StateError('附件本地文件不可用，先取回原件再提取（D-22）');
      }
      attachmentIds.add(att.id);
      final extracted = await _extraction.extract(
          sha256: att.sha256, file: File(path), mimeType: att.mimeType);
      for (final p in extracted) {
        pageNo += 1;
        docPages.add(_DocPage(
          pageNo: pageNo,
          attachmentId: att.id,
          page: ExtractedPage(
              pageNo: pageNo, source: p.source, lines: p.lines),
        ));
      }
    }
    if (docPages.isEmpty) throw StateError('没有可提取的页');

    // 2. 页筛选（D-23）：默认判定，被排除页不进入发送副本。
    final decisions = [for (final p in docPages) pageFilter.decide(p.page)];
    final included = <_DocPage>[
      for (var i = 0; i < docPages.length; i++)
        if (decisions[i].included) docPages[i],
    ];
    if (included.isEmpty) {
      throw StateError('全部页都被筛除了：在导入页恢复要发送的页再试');
    }

    // 3. 脱敏（D-24）：只作用于发送副本，坐标保留供 locator 回映射。
    var redactedTotal = 0;
    final redactedPages = <_DocPage>[];
    for (final p in included) {
      final r = redaction.redactPage(p.page.lines, knownNames: knownNames);
      redactedTotal += r.redactedCount;
      redactedPages.add(_DocPage(
        pageNo: p.pageNo,
        attachmentId: p.attachmentId,
        page: ExtractedPage(
            pageNo: p.pageNo, source: p.page.source, lines: r.lines),
      ));
    }

    // 4. 组装输入：P{页}L{行}: 文本。
    final buf = StringBuffer();
    for (final p in redactedPages) {
      for (var i = 0; i < p.page.lines.length; i++) {
        buf.writeln('P${p.pageNo}L${i + 1}: ${p.page.lines[i].text}');
      }
    }

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
        userText: buf.toString(),
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
    );

    final parsed = _parse(response.text);
    if (parsed == null) {
      AppLog.I.w('extract', '结构化提取解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，本次提取未生成记录');
    }
    final docInfo = (parsed['doc'] as Map?)?.cast<String, Object?>() ?? {};
    final rawResults = (parsed['results'] as List?) ?? const [];

    // 5. source_lines → locator（附件 ID + 页号 + 坐标；文字层无坐标时只有页号和原文行）。
    final lineIndex = <String, (String, int, OcrLine)>{};
    for (final p in redactedPages) {
      for (var i = 0; i < p.page.lines.length; i++) {
        lineIndex['P${p.pageNo}L${i + 1}'] =
            (p.attachmentId, p.pageNo, p.page.lines[i]);
      }
    }
    final results = <Map<String, Object?>>[];
    for (final raw in rawResults) {
      if (raw is! Map) continue;
      final r = raw.cast<String, Object?>();
      if (r['item_name_raw'] is! String || r['value_raw'] is! String) continue;
      final locators = <Map<String, Object?>>[];
      for (final key in (r['source_lines'] as List? ?? const [])) {
        final hit = lineIndex[key];
        if (hit == null) continue; // 编造的行号丢弃
        final (attId, page, line) = hit;
        locators.add({
          'attachment_id': attId,
          'page_no': page,
          if (line.hasBox)
            'box': {'x': line.x, 'y': line.y, 'w': line.w, 'h': line.h},
          'line_text': line.text,
        });
      }
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
    final meta = <String, FieldMeta>{
      for (var i = 0; i < results.length; i++)
        'results.$i': const FieldMeta(
            origin: FieldOrigin.modelInferred,
            reviewStatus: ReviewStatus.unreviewed),
    };
    final record = await _records.create(
      recordType: RecordType.labPanel,
      occurred: occurred,
      dataJson: jsonEncode({
        'medical_document_id': doc.id,
        'results': results,
      }),
      fieldMeta: FieldMetaMap(meta),
      producedBy: ProducedBy.medicalExtract(call.id),
      sources: [
        for (final id in attachmentIds)
          SourceLink(sourceKind: RecordSourceKind.attachment, sourceId: id),
      ],
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

    AppLog.I.i('extract',
        '结构化提取完成：${results.length} 项，遮蔽 $redactedTotal 处，'
        '发送 ${redactedPages.length}/${docPages.length} 页');
    return MedicalExtractOutcome(
        record: record, pageDecisions: decisions, redactedCount: redactedTotal);
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
  const _DocPage(
      {required this.pageNo, required this.attachmentId, required this.page});

  final int pageNo;
  final String attachmentId;
  final ExtractedPage page;
}
