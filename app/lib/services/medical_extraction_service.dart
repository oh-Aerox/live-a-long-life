import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
你是医疗文件（检验单、检查报告、病历、处方）的结构化整理器。输入是一份医疗文件
经本地文字识别（OCR）后的文本，每行有形如 P2L5 的行号（第 2 页第 5 行）。
只输出一个 JSON 对象，不要输出其他文字：
{
  "doc": {
    "doc_type": "lab_report" | "imaging_report" | "visit_record" | "prescription" | "discharge_summary" | "other",
    "institution_text": "医疗机构名称" 或 null,
    "exam_date": "YYYY-MM-DD" 或 null（检查/采样/就诊日期）,
    "report_date": "YYYY-MM-DD" 或 null（报告日期）
  },
  "results": [
    {
      "item_name_raw": "项目名称",
      "value_raw": "数值，按原文",
      "value_num": 解析出的数值 或 null,
      "unit_raw": "单位" 或 null,
      "ref_range_raw": "参考范围，按原文" 或 null,
      "ref_low": 参考范围下限 或 null,
      "ref_high": 参考范围上限 或 null,
      "flag_raw": "异常标记（↑、↓、H、L 等）" 或 null,
      "source_lines": ["该项数据来自的行号，如 P1L3"，至少一个],
      "ocr_fixes": ["识别原文→修正后"，没有修正就给空数组]
    }
  ],
  "findings": [
    {
      "section_raw": "栏目名称（如 主诉、现病史、既往史、过敏史、体格检查、辅助检查、诊断、处理意见、医嘱、超声所见、超声提示、检查结论、印象）" 或 null,
      "text_raw": "该栏目下的文字",
      "source_lines": ["来源行号"，至少一个],
      "ocr_fixes": ["识别原文→修正后"]
    }
  ],
  "medications": [
    {
      "name": "药品名称",
      "spec": "规格，如 0.25g*12片/盒" 或 null,
      "dose": "单次用量，如 1片、0.25g" 或 null,
      "route": "用法，如 口服、外用" 或 null,
      "frequency": "频次，如 每日2次" 或 null,
      "duration": "疗程或天数" 或 null,
      "quantity": "开具数量，如 2盒" 或 null,
      "source_lines": ["来源行号"，至少一个],
      "ocr_fixes": ["识别原文→修正后"]
    }
  ],
  "conditions": [
    {
      "name": "疾病或身体状况名称（如 胆囊结石、青霉素过敏）",
      "persistence": "long_term" | "temporary",
      "evidence_text": "依据的文字（诊断、结论、印象一栏）",
      "source_lines": ["来源行号"，至少一个]
    }
  ]
}

关于识别错误（重要）：
- 输入是 OCR 结果，常见三类问题：①形近字、错别字（如"会明部"应为"会阴部"、
  "感來"应为"感染"、"规辣史"应为"现病史"、"悲者"应为"患者"、"处理意第"
  应为"处理意见"）；②断行，一句话被拆到几行；③表格版式错乱，同一行的几列
  被拆成多行、与别的栏目交错（如药品名、用法、用量、规格分散在诊断条目之间）。
- 整理时根据医学常识和上下文修正明显的识别错误，把被拆散的内容按意思重新
  组合、归入正确的栏目（诊断条目归"诊断"，药品归 medications，不要因为某行
  挨着某个标题就归到那个标题下）；
- 每处文字修正都写进该条的 ocr_fixes（"原文→修正后"），供用户核对；
  拿不准的不要改，保留原文；
- 数值、单位、参考范围、日期、剂量里的数字不要按常识"修正"，只允许修正
  明确的字符混淆（如数字中间的 O→0、l→1、S→5），同样记进 ocr_fixes；
  看不清的数字保留原文，数值字段留 null，不要猜。

其他规则：
- 解析不出的数值字段（value_num、ref_low、ref_high）留 null，不要猜；
- source_lines 只能用输入里出现的行号，不要编造；一条内容来自多行时全部列出；
- 没有检验数值表时 results 为空数组；文字内容不进 results，放进 findings；
- findings 收报告和病历里与健康相关的文字：病历/门诊记录的主诉、现病史、既往史、
  过敏史、体格检查、辅助检查、诊断、处理意见、医嘱，超声/影像/心电图等报告的所见、
  提示、结论、印象，检验单上的结论或备注；按栏目分条，完整保留内容，不要摘要或合并
  栏目；医院介绍、挂号就诊须知、签名栏、打印时间不收；内容只有"—""-"或"无"的栏目
  照实写"无"；没有就给空数组；
- medications 收处方、医嘱、处理意见里开具的全部药品，一个药品一条，药名、用法、
  用量、规格按表格顺序对应组合；报告没写的字段（如频次）留 null，不要推断；
  没有就给空数组；
- conditions 只收诊断/结论/印象/病史文字里明确写出的疾病或状况，名称用修正后的；
  结石、囊肿、结节、慢性病、过敏等不会自行消失的算 long_term，
  感冒、急性感染等预期痊愈的算 temporary，拿不准按 long_term（会由用户核对）；
  检验数值异常本身不是状况，不要凭数值推断疾病；没有就给空数组；
- 文本里的【姓名】【证件号】【卡号】是脱敏占位符，不是数据，忽略它们；
- 检查日期和报告日期是两个日期，分不清时只填能确认的那个。
''';

/// 模型识图兜底提示词（V4-M3，D-23/D-24）：本机文字识别不准时，用户显式
/// 选择把（通常已裁剪的）页面图片发给多模态模型。输出结构与
/// [labExtractSystemPrompt] 相同但没有行号——定位回原件用页码 + 裁剪区域。
/// 改动本提示词时同步更新 docs/prompts.md。
const labExtractImageSystemPrompt = '''
你是医疗文件（检验单、检查报告、病历、处方）的结构化整理器。输入是用户拍摄或
导入的一页医疗文件图片，可能已被用户裁剪成局部（裁掉了姓名、证件号等）。
只输出一个 JSON 对象，不要输出其他文字，结构如下（各字段含义同检验报告提取）：
{
  "doc": {"doc_type": "lab_report" | "imaging_report" | "visit_record" | "prescription" | "discharge_summary" | "other",
          "institution_text": 医疗机构名称 或 null, "exam_date": "YYYY-MM-DD" 或 null, "report_date": "YYYY-MM-DD" 或 null},
  "results": [{"item_name_raw", "value_raw", "value_num", "unit_raw", "ref_range_raw", "ref_low", "ref_high", "flag_raw"}],
  "findings": [{"section_raw", "text_raw"}],
  "medications": [{"name", "spec", "dose", "route", "frequency", "duration", "quantity"}],
  "conditions": [{"name", "persistence": "long_term" | "temporary", "evidence_text"}]
}

规则：
- 只抄写图片上看得清的内容，看不清、被裁掉或被遮挡的不要猜，数值字段留 null；
- 数值、单位、参考范围、日期、剂量按图上原样，不要按常识改；
- 手写或潦草的字拿不准时照你能辨认的写，并宁可少收一项也不要编造；
- 图片只是局部时，只整理图上有的部分，不要推测图外的内容；
- 不要在任何字段里写出姓名、身份证号、门诊卡号、电话、住址等个人信息；
- results、findings、medications、conditions 的收录范围与分类规则同检验报告提取：
  文字内容按栏目分条放 findings，开具的药品放 medications，
  conditions 只收诊断/结论里明确写出的疾病或状况，拿不准按 long_term；
- 没有的部分给空数组。
''';

/// 识图调用：比 [OrganizeModelCall] 多一张图片（base64 PNG）。
typedef MedicalImageCall = Future<ModelResponse> Function({
  required ModelConfig config,
  required String apiKey,
  String? system,
  required String userText,
  required int maxTokens,
  required String imagePngBase64,
});

/// 识图兜底要发送的一页：裁剪后的 PNG（只在内存里，D-24 不落库）。
class ImageSend {
  const ImageSend({
    required this.attachmentId,
    required this.pageNo,
    required this.attachmentPage,
    required this.png,
    required this.width,
    required this.height,
    this.cropBox,
  });

  final String attachmentId;

  /// 文件内全局页号、附件内页号（locator 用）。
  final int pageNo;
  final int attachmentPage;
  final Uint8List png;
  final int width;
  final int height;

  /// 裁剪区域（相对原页的归一化坐标 x/y/w/h）；null = 整页没裁剪。
  final Map<String, double>? cropBox;
}

/// 识图兜底可选的一页。
class ImagePageChoice {
  const ImagePageChoice({
    required this.pageNo,
    required this.attachmentId,
    required this.attachmentPage,
  });

  final int pageNo;
  final String attachmentId;
  final int attachmentPage;
}

/// 提取结果：记录 + 每页的筛选判定（UI 展示"已排除"标记用）+ 遮蔽项数
/// + 近似重复候选（同检查日期同项目的已有记录，D-10）。
class MedicalExtractOutcome {
  const MedicalExtractOutcome({
    required this.record,
    required this.pageDecisions,
    required this.redactedCount,
    this.possibleDuplicateRecordIds = const [],
    this.conditionRecords = const [],
    this.failedPages = const [],
  });

  final RecordRow record;
  final List<PageDecision> pageDecisions;
  final int redactedCount;
  final List<String> possibleDuplicateRecordIds;

  /// 本次新建的身体状况建议（unreviewed，D-25）；同名已有档案时不重复建。
  final List<RecordRow> conditionRecords;

  /// 分批发送时重试后仍失败的页（其余批次的结果照常保存，可重新提取补上）。
  final List<int> failedPages;
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
  String get payload => payloadOf(includedPages);

  /// 若干页的发送文本（分批发送时每批一段）。
  String payloadOf(List<DraftPage> pages) {
    final buf = StringBuffer();
    for (final p in pages) {
      for (var i = 0; i < p.lines.length; i++) {
        final text = lineText(p, i);
        if (text.trim().isEmpty) continue;
        buf.writeln('${lineKey(p.pageNo, i)}: $text');
      }
    }
    return buf.toString();
  }

  int sentLinesOf(DraftPage page) => [
        for (var i = 0; i < page.lines.length; i++)
          if (lineText(page, i).trim().isNotEmpty) i
      ].length;

  /// 按发送行数把要发的页切成批（整页不拆）：体检报告十几页、几百行，一次
  /// 发给模型要逐项抄写几百个数值，既超时又超出单次输出上限（2026-09-29
  /// 联调：12 页 364 行 180 秒超时）。每批约 [maxLines] 行；单页超过也单独成批。
  List<List<DraftPage>> batches({int maxLines = batchMaxLines}) {
    final out = <List<DraftPage>>[];
    var current = <DraftPage>[];
    var lines = 0;
    for (final p in includedPages) {
      final n = sentLinesOf(p);
      if (current.isNotEmpty && lines + n > maxLines) {
        out.add(current);
        current = [];
        lines = 0;
      }
      current.add(p);
      lines += n;
    }
    if (current.isNotEmpty) out.add(current);
    return out;
  }

  static const batchMaxLines = 90;

  /// 调用记录里的发送范围描述（A-38 同一字段）。
  String get summary => '医疗文件 ${includedPages.length}/${pages.length} 页，'
      '$sentLineCount 行文字（发送前已预览确认），自动遮蔽 $redactedCount 处'
      '${edits.isEmpty ? '' : '，手动改动 ${edits.length} 行（含删掉的）'}';
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
    MedicalImageCall? imageCall,
    this.batchMaxLines = SendDraft.batchMaxLines,
    this.ids = const IdGenerator(),
  })  : _attachments = attachments,
        _documents = documents,
        _records = records,
        _organize = organize,
        _modelConfigs = modelConfigs,
        _keyStore = keyStore,
        _extraction = extraction,
        _modelCall = modelCall ?? _defaultCall,
        _imageCall = imageCall ?? _defaultImageCall;

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
  final MedicalImageCall _imageCall;

  /// 每批发送的行数上限（见 [SendDraft.batches]）。
  final int batchMaxLines;
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

  static Future<ModelResponse> _defaultImageCall({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    required int maxTokens,
    required String imagePngBase64,
  }) =>
      ModelClient(timeout: const Duration(seconds: 180)).complete(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens,
          imagePngBase64: imagePngBase64);

  /// 默认模型是否能识图：看测试连接探测写入的 capabilities（schema §4.3、
  /// D-16）。没测过或只支持文本都算不能——界面据此提示换模型，不报失败。
  Future<bool> defaultModelSupportsImage() async {
    final config = await _modelConfigs.defaultConfig();
    if (config == null) return false;
    try {
      return (jsonDecode(config.capabilities) as List).contains('image');
    } catch (_) {
      return false;
    }
  }

  /// 识图兜底可选的页（多页 PDF 逐页列出）。本机不在的原件不列。
  Future<List<ImagePageChoice>> imagePages(String documentId) async {
    final doc = await _documents.byId(documentId);
    if (doc == null) return const [];
    return [
      for (final p in await _loadDocPages(doc))
        ImagePageChoice(
            pageNo: p.pageNo,
            attachmentId: p.attachmentId,
            attachmentPage: p.attachmentPage),
    ];
  }

  /// 一页的原图字节，交给裁剪页（PDF 页现场渲染，不留文件）。
  Future<Uint8List> pageImage(ImagePageChoice page) async {
    final att = await _attachments.byId(page.attachmentId);
    final path = await _attachments.localPathOf(page.attachmentId);
    if (att == null || path == null) {
      throw StateError('附件本地文件不可用，先取回原件再识图（D-22）');
    }
    return _extraction.pageImage(
        file: File(path),
        mimeType: att.mimeType,
        attachmentPage: page.attachmentPage);
  }

  /// 模型识图兜底（V4-M3，D-24）：用户显式发起，发送的是裁剪页上确认过的
  /// 图片（或确认风险后的整页），只用于这一次调用、不落库。结果与文字路径
  /// 同样建成 lab_panel（全部 unreviewed），定位为页码 + 裁剪区域。
  Future<MedicalExtractOutcome> extractFromImage(
      String documentId, ImageSend send) async {
    final doc = await _documents.byId(documentId);
    if (doc == null) throw StateError('医疗文件不存在：$documentId');
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }
    if (!await defaultModelSupportsImage()) {
      throw StateError('当前默认模型不支持图片：在"模型配置"里换一个支持图片的模型，'
          '或重新测试连接');
    }
    final box = send.cropBox;
    final area = box == null
        ? null
        : ((box['w'] ?? 1) * (box['h'] ?? 1) * 100).round();
    final sentSummary = '模型识图：第 ${send.pageNo} 页'
        '${box == null ? '整页（未裁剪）' : '裁剪后的局部（约占整页 $area%）'}，'
        '图片 ${send.width}×${send.height}，只用于这次发送，不保存';
    const userText = '请整理这张医疗文件图片。';
    final requestAt = ids.nowMs();
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final requestText = '$userText\n[附图 ${send.width}×${send.height} PNG，'
        '${box == null ? '整页' : '裁剪区域 x=${box['x']!.toStringAsFixed(2)} '
            'y=${box['y']!.toStringAsFixed(2)} w=${box['w']!.toStringAsFixed(2)} '
            'h=${box['h']!.toStringAsFixed(2)}'}；图片本身不存进调用记录]';
    ModelResponse response;
    try {
      response = await _imageCall(
        config: config,
        apiKey: apiKey,
        system: labExtractImageSystemPrompt,
        userText: userText,
        maxTokens: 8192,
        imagePngBase64: base64Encode(send.png),
      );
    } catch (e) {
      await _organize.recordModelCall(
        modelConfigId: config.id,
        dataBoundary: config.dataBoundary,
        sentMessageIdsJson: '[]',
        sentAttachmentIdsJson: jsonEncode([send.attachmentId]),
        requestAt: requestAt,
        responseAt: ids.nowMs(),
        status: ModelCallStatus.failed,
        caller: ModelCaller.phoneMedicalExtract,
        sentSummary: sentSummary,
        requestText: requestText,
      );
      rethrow;
    }
    final call = await _organize.recordModelCall(
      modelConfigId: config.id,
      dataBoundary: config.dataBoundary,
      sentMessageIdsJson: '[]',
      sentAttachmentIdsJson: jsonEncode([send.attachmentId]),
      requestAt: requestAt,
      responseAt: ids.nowMs(),
      status: ModelCallStatus.succeeded,
      tokensIn: response.tokensIn,
      tokensOut: response.tokensOut,
      responseText: response.text,
      caller: ModelCaller.phoneMedicalExtract,
      sentSummary: sentSummary,
      requestText: requestText,
    );
    final parsed = _parse(response.text);
    if (parsed == null) {
      AppLog.I.w('extract', '识图结果解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，本次识图未生成记录');
    }
    final saved = await _saveParsed(
      doc,
      parsed,
      lineIndex: const {},
      fallback: {
        'attachment_id': send.attachmentId,
        'page_no': send.pageNo,
        'attachment_page': send.attachmentPage,
        'box': ?box,
      },
      callId: call.id,
      attachmentIds: {send.attachmentId},
    );
    AppLog.I.i('extract',
        '识图提取完成：${saved.results} 项，文字 ${saved.findings} 段，'
        '药品 ${saved.medications} 种，${box == null ? '整页' : '裁剪 $area%'}');
    return MedicalExtractOutcome(
      record: saved.record,
      pageDecisions: const [],
      redactedCount: 0,
      possibleDuplicateRecordIds: saved.duplicates,
      conditionRecords: saved.conditions,
    );
  }

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
  Future<MedicalExtractOutcome> sendDraft(SendDraft draft,
      {void Function(int done, int total)? onProgress}) async {
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
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');

    // 分批发送（体检报告页多行多）：最多两批同时在途，每批失败重试一次。
    final batches = draft.batches(maxLines: batchMaxLines);
    final outcomes = List<_BatchOutcome?>.filled(batches.length, null);
    Object? lastError;
    var next = 0;
    var done = 0;
    onProgress?.call(0, batches.length);
    Future<void> worker() async {
      while (next < batches.length) {
        final i = next++;
        for (var attempt = 0; attempt < 2 && outcomes[i] == null; attempt++) {
          try {
            outcomes[i] = await _sendBatch(draft, batches[i], i, batches.length,
                config: config, apiKey: apiKey, attachmentIds: attachmentIds);
          } catch (e) {
            lastError = e;
            AppLog.I.w('extract',
                '第 ${i + 1}/${batches.length} 批第 ${attempt + 1} 次失败：$e');
          }
        }
        onProgress?.call(++done, batches.length);
      }
    }

    await Future.wait([worker(), if (batches.length > 1) worker()]);
    final succeeded = [for (final o in outcomes) ?o];
    if (succeeded.isEmpty) {
      throw lastError ?? StateError('模型调用失败，本次提取未生成记录');
    }
    final failedPages = [
      for (var i = 0; i < batches.length; i++)
        if (outcomes[i] == null) for (final p in batches[i]) p.pageNo
    ];
    final parsed = _mergeParsed([for (final o in succeeded) o.parsed]);
    // 记录的 produced_by 指向第一批的调用；每批调用都在调用记录里可查。
    final callId = succeeded.first.callId;

    // 5. source_lines → locator（见 [_locatorsOf]）。
    final lineIndex = <String, (DraftPage, OcrLine)>{};
    for (final p in included) {
      for (var i = 0; i < p.lines.length; i++) {
        final text = draft.lineText(p, i);
        if (text.trim().isEmpty) continue; // 用户删掉的行没发送
        lineIndex['P${p.pageNo}L${i + 1}'] = (p, _withText(p.lines[i], text));
      }
    }
    final saved = await _saveParsed(doc, parsed,
        lineIndex: lineIndex, callId: callId, attachmentIds: attachmentIds);
    AppLog.I.i('extract',
        '结构化提取完成：${saved.results} 项，文字 ${saved.findings} 段，'
        '药品 ${saved.medications} 种，'
        '遮蔽 $redactedTotal 处，'
        '发送 ${included.length}/${draft.pages.length} 页，分 ${batches.length} 批'
        '${failedPages.isEmpty ? '' : '，第 ${failedPages.join('、')} 页失败'}'
        '${saved.conditions.isEmpty ? '' : '，新增 ${saved.conditions.length} 条状况建议'}'
        '${saved.duplicates.isEmpty ? '' : '，疑似与 ${saved.duplicates.length} 条已有记录重复'}');
    return MedicalExtractOutcome(
      record: saved.record,
      pageDecisions: [
        for (final p in draft.pages)
          PageDecision(pageNo: p.pageNo, included: p.included, reason: p.reason),
      ],
      redactedCount: redactedTotal,
      possibleDuplicateRecordIds: saved.duplicates,
      conditionRecords: saved.conditions,
      failedPages: failedPages,
    );
  }

  /// 发一批页：调用模型、记调用记录、解析。解析失败按调用失败处理（抛出，
  /// 由调用方重试）。
  Future<_BatchOutcome> _sendBatch(
    SendDraft draft,
    List<DraftPage> pages,
    int index,
    int total, {
    required ModelConfig config,
    required String apiKey,
    required Set<String> attachmentIds,
  }) async {
    final payload = draft.payloadOf(pages);
    final lines = pages.fold(0, (n, p) => n + draft.sentLinesOf(p));
    final summary = total == 1
        ? draft.summary
        : '${draft.summary} · 分 $total 批，第 ${index + 1} 批：'
            '第 ${pages.map((p) => p.pageNo).join('、')} 页 $lines 行';
    final redacted = pages.fold(0, (n, p) => n + p.redactedCount);
    final requestAt = ids.nowMs();
    ModelResponse response;
    try {
      response = await _modelCall(
        config: config,
        apiKey: apiKey,
        system: labExtractSystemPrompt,
        userText: payload,
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
        redactedCount: redacted,
        sentSummary: summary,
        requestText: payload,
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
      redactedCount: redacted,
      sentSummary: summary,
      requestText: payload,
    );
    final parsed = _parse(response.text);
    if (parsed == null) {
      AppLog.I.w('extract', '结构化提取解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，本次提取未生成记录');
    }
    return _BatchOutcome(parsed: parsed, callId: call.id);
  }

  /// 合并各批结果：文件级信息取第一个非空值（批次按页序），各列表按页序拼接。
  /// 同名状况在建档时去重（[_createConditionSuggestions]）。
  static Map<String, Object?> _mergeParsed(List<Map<String, Object?>> parts) {
    if (parts.length == 1) return parts.single;
    final doc = <String, Object?>{};
    for (final part in parts) {
      final d = (part['doc'] as Map?)?.cast<String, Object?>() ?? const {};
      for (final e in d.entries) {
        if (e.value != null) doc.putIfAbsent(e.key, () => e.value);
      }
    }
    List<Object?> all(String key) => [
          for (final part in parts) ...(part[key] as List? ?? const []),
        ];
    return {
      'doc': doc,
      'results': all('results'),
      'findings': all('findings'),
      'medications': all('medications'),
      'conditions': all('conditions'),
    };
  }

  /// 模型返回 → 记录（文字路径与识图路径共用）：检验数值、文字内容、药品
  /// 建成 lab_panel（全部 unreviewed，D-04；重新提取追加版本），回填文件级
  /// 信息，查近似重复，建状况建议。source_lines 对不上 [lineIndex] 时用
  /// [fallback] 定位（识图路径没有行号：页码 + 裁剪区域）。
  Future<_Saved> _saveParsed(
    MedicalDocument doc,
    Map<String, Object?> parsed, {
    required Map<String, (DraftPage, OcrLine)> lineIndex,
    Map<String, Object?>? fallback,
    required String callId,
    required Set<String> attachmentIds,
  }) async {
    final docInfo = (parsed['doc'] as Map?)?.cast<String, Object?>() ?? {};
    final rawResults = (parsed['results'] as List?) ?? const [];

    final results = <Map<String, Object?>>[];
    for (final raw in rawResults) {
      if (raw is! Map) continue;
      final r = raw.cast<String, Object?>();
      if (r['item_name_raw'] is! String || r['value_raw'] is! String) continue;
      final locators = _locatorsOf(r['source_lines'], lineIndex, fallback);
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
        'ocr_fixes': _ocrFixes(r['ocr_fixes']),
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
        'locator': _locatorsOf(raw['source_lines'], lineIndex, fallback),
        'ocr_fixes': _ocrFixes(raw['ocr_fixes']),
      });
    }

    // 处方药品（D-28）：病历/处方里开具的药，一个药一条。
    final medications = <Map<String, Object?>>[];
    for (final raw in (parsed['medications'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final name = raw['name'];
      if (name is! String || name.trim().isEmpty) continue;
      medications.add({
        'name': name.trim(),
        for (final k in _medicationFields)
          k: raw[k] is String && (raw[k] as String).trim().isNotEmpty
              ? (raw[k] as String).trim()
              : null,
        'locator': _locatorsOf(raw['source_lines'], lineIndex, fallback),
        'ocr_fixes': _ocrFixes(raw['ocr_fixes']),
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
      for (var i = 0; i < medications.length; i++)
        'medications.$i': unreviewed,
    };
    final dataJson = jsonEncode({
      'medical_document_id': doc.id,
      'results': results,
      'findings': findings,
      'medications': medications,
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
            producedBy: ProducedBy.medicalExtract(callId),
            sources: sources,
          )
        : await _records.addRevision(
            recordId: existing.id,
            baseVersion: existing.version,
            occurred: occurred,
            dataJson: dataJson,
            fieldMeta: FieldMetaMap(meta),
            producedBy: ProducedBy.medicalExtract(callId),
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
      fallback: fallback,
      examDate: examDate,
      documentId: doc.id,
      callId: callId,
      attachmentIds: attachmentIds,
    );
    return _Saved(
      record: record,
      results: results.length,
      findings: findings.length,
      medications: medications.length,
      duplicates: duplicates,
      conditions: conditions,
    );
  }

  /// 删除一份医疗文件（重复上传的清理入口）：文件、它的提取记录、从它
  /// 建议出来但还没核对的状况一起标记删除（走变更日志同步，历史版本保留）。
  /// 用户已确认的状况是事实，保留（R-34）；原始照片/PDF 仍在消息流里（D-27）。
  Future<void> deleteDocument(String documentId) async {
    final panel = await _records.labPanelOfDocument(documentId);
    if (panel != null) await _records.markDeleted(panel.id);
    for (final rec in await _records.byType(RecordType.condition)) {
      final rev = await _records.currentRevisionOf(rec.id);
      final data = jsonDecode(rev.data) as Map;
      if (data['medical_document_id'] != documentId) continue;
      final status = FieldMetaMap.decode(rev.fieldMeta)['condition']?.reviewStatus;
      if (status == null || status == ReviewStatus.unreviewed) {
        await _records.markDeleted(rec.id);
      }
    }
    await _documents.markDeleted(documentId);
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
    Map<String, Object?>? fallback,
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

      final locators = _locatorsOf(c['source_lines'], lineIndex, fallback);
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
      Object? sourceLines, Map<String, (DraftPage, OcrLine)> lineIndex,
      [Map<String, Object?>? fallback]) {
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
    if (locators.isEmpty && fallback != null) locators.add(fallback);
    return locators;
  }

  /// 药品除名称外的可空文本字段（schema §5.2 medications）。
  static const _medicationFields = [
    'spec',
    'dose',
    'route',
    'frequency',
    'duration',
    'quantity',
  ];

  /// 模型对 OCR 识别错误的修正（"原文→修正后"），只收字符串，给核对页展示。
  static List<String> _ocrFixes(Object? raw) => [
        for (final f in (raw as List? ?? const []))
          if (f is String && f.trim().isNotEmpty) f.trim()
      ];

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

class _Saved {
  const _Saved({
    required this.record,
    required this.results,
    required this.findings,
    required this.medications,
    required this.duplicates,
    required this.conditions,
  });

  final RecordRow record;
  final int results;
  final int findings;
  final int medications;
  final List<String> duplicates;
  final List<RecordRow> conditions;
}

class _BatchOutcome {
  const _BatchOutcome({required this.parsed, required this.callId});

  final Map<String, Object?> parsed;
  final String callId;
}
