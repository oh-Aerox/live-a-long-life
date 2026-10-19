import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/ocr_fixes.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/repositories/model_config_repository.dart';
import '../data/repositories/organize_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/same_item.dart';
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
      "panel_raw": "所属检查大项的标题（如 血常规、尿常规、肝功能、血脂）" 或 null,
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
  看不清的数字保留原文，数值字段留 null，不要猜；
- 单位里的幂次 OCR 常丢上标：10⁹ 识别成 109、10°、10⁰，10¹² 识别成 1012，
  L 识别成 1.、I（如 "*10°/1."、"*1012/L"）。按项目判断后写成
  "10^9/L"、"10^12/L" 这样的写法；
- ocr_fixes 只是修正说明，修正后的文字必须同时写进对应字段本身（如修正了
  单位，unit_raw 就写修正后的单位），不要字段里仍留原文。

其他规则：
- 解析不出的数值字段（value_num、ref_low、ref_high）留 null，不要猜；
- source_lines 只能用输入里出现的行号，不要编造；一条内容来自多行时全部列出；
- 没有检验数值表时 results 为空数组；文字内容不进 results，放进 findings；
- panel_raw 写该项所在表格或段落的大标题（体检报告常见：血常规、尿常规、
  便常规、肝功能、肾功能、血脂、血糖、甲状腺功能、肿瘤标志物），按报告原文；
  尿常规、便常规里的项目（白细胞、红细胞、葡萄糖、蛋白质、胆红素、pH、比重、
  隐血等）一定要填，它们脱离大项就和血液里的同名项目分不清；项目名照原文写，
  不要自己加"尿""便"；
- 输入可能是一份长报告中间的几页（分批发送），表格从上一页续过来、本页没有
  大标题：这时按项目名称和英文缩写判断它属于哪个大项（如 白细胞计数(WBC)、
  红细胞计数(RBC)、血红蛋白、血小板 属于血常规），不要因为本页没有标题就留
  null；只有确实不属于任何检验大项、也判断不出的（如 身高、血压）才留 null；
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
  "results": [{"panel_raw", "item_name_raw", "value_raw", "value_num", "unit_raw", "ref_range_raw", "ref_low", "ref_high", "flag_raw"}],
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
  panel_raw 写检验项目所在的大标题（尿常规、便常规里的项目一定要填；图上
  没有标题时按项目名称判断，判断不出才留 null），
  文字内容按栏目分条放 findings，开具的药品放 medications，
  conditions 只收诊断/结论里明确写出的疾病或状况，拿不准按 long_term；
- 没有的部分给空数组。
''';

/// 文字内容整理提示词（D-35）：提取按栏目分条，超声等报告常把同一部位的
/// 所见和结论拆成两条、体检报告汇总与明细各写一遍。用户在医疗文件详情点
/// "用模型整理"时，把已提取的文字内容（来自脱敏后的文本）发给模型合并去重。
/// 改动本提示词时同步更新 docs/prompts.md。
const findingsTidySystemPrompt = '''
你在整理一份医疗文件里已经提取出的文字内容。输入是 JSON：
{"findings": [{"id": 1, "section_raw": "栏目名称或 null", "text_raw": "内容"}]}
这些条目是按报告栏目机械拆开的，常见问题：同一部位/同一项检查的"所见"和
"结论/提示"分成了两条（如 条目"甲状腺"：甲状腺形态大小正常，回声均匀；条目
"检查所见"：甲状腺未见异常）；体检报告汇总页和明细页把同一个问题写了两遍。

只输出一个 JSON 对象，不要输出其他文字：
{"findings": [{"section_raw": "栏目名称", "text_raw": "内容", "from": [合并进来的输入 id]}]}

规则：
- 同一部位或同一项检查的所见、描述、结论、提示合并成一条：section_raw 写部位或
  检查名（如"甲状腺""肝胆脾胰超声""心电图"），text_raw 按"所见：……\\n结论：……"
  分行写，标签用原栏目的叫法（所见/描述/提示/结论/印象）；只有一部分时不加标签；
- 意思相同的重复条目（汇总与明细、同一句换了写法）只留一条，保留写得更完整的那
  一种措辞；被去掉的条目 id 也要写进保留那条的 from；
- 主诉、现病史、既往史、诊断、处理意见、建议、医嘱等病历栏目各自独立，不要和
  检查所见合并，也不要互相合并；
- 不同部位、不同检查不要合并；拿不准是不是同一部位时不合并；
- 文字照原文，不要摘要、改写、补充或删减内容，合并时只做拼接和去掉重复的句子；
  不要修改数字、单位、大小、日期；
- 每个输入 id 必须出现在且只出现在一条输出的 from 里，不能遗漏；
- 输出顺序按报告原来的顺序（以每条最早的 id 为准）。
''';

/// 补检查大项提示词（D-36）：D-36 之前提取的报告没有 panel_raw，尿常规
/// 里的"白细胞""葡萄糖"和血里的同名项目混在一起。只按顺序发项目名称。
/// 改动本提示词时同步更新 docs/prompts.md。
const panelFillSystemPrompt = '''
你在给一份体检或检验报告里已经提取出的检验项目补上所属的检查大项。输入是 JSON：
{"results": [{"id": 1, "item_name_raw": "项目名称", "panel_raw": "已知大项" 或 null}]}
项目按报告上的顺序排列，同一大项的项目通常连在一起（如 血常规 一组、尿常规
一组、肝功能 一组）。panel_raw 已有的是提取时从报告标题读到的，作为参照；
你要给 panel_raw 为 null 的项目补上。常见情况是长报告分批提取，后一页续表的
项目没有读到标题：它们前后的项目已标了哪个大项、项目名称像哪个大项，就补哪个。

只输出一个 JSON 对象，不要输出其他文字：
{"results": [{"id": 1, "panel_raw": "大项名称" 或 null}]}
只输出输入里 panel_raw 为 null 的项目。

规则：
- 已有的大项怎么写，同一组补的就怎么写（输入写"血常规"就不要补成"血液常规"）；
- 大项用体检报告常见的叫法：血常规、尿常规、便常规、肝功能、肾功能、血脂、
  血糖、电解质、甲状腺功能、肿瘤标志物、凝血功能、乙肝五项 等；
- 根据项目名称、英文缩写和前后顺序判断：尿常规常见 比重(SG)、pH、白细胞(LEU)、
  隐血(ERY)、亚硝酸盐(NIT)、酮体(KET)、胆红素(BIL)、尿胆原(UBG)、蛋白质(PRO)、
  葡萄糖(GLU)，以及镜检的红细胞、白细胞、上皮细胞、管型、结晶；
  血常规常见 白细胞计数(WBC)、红细胞计数(RBC)、血红蛋白、血小板、各类细胞百分数；
- 同名项目（白细胞、葡萄糖、胆红素、蛋白）要看它所在的那一组和缩写判断，
  不要都归到血液；
- 拿不准的给 null，不要猜。
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

/// 文字内容整理结果（D-35）。有改动时带上整理前的数据，界面撤销时写回。
class FindingsTidyOutcome {
  const FindingsTidyOutcome({
    required this.before,
    required this.after,
    required this.record,
    this.previousData,
    this.previousFieldMeta,
  });

  final int before;
  final int after;
  final RecordRow record;
  final String? previousData;
  final String? previousFieldMeta;

  bool get changed => previousData != null;
}

/// 补检查大项结果（D-36）。有改动时带上补之前的数据，界面撤销时写回。
class PanelFillOutcome {
  const PanelFillOutcome({
    required this.filled,
    required this.record,
    this.previousData,
    this.previousFieldMeta,
  });

  /// 补上大项的项目数。
  final int filled;
  final RecordRow record;
  final String? previousData;
  final String? previousFieldMeta;
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
/// 不发送）；修改只作用于发送副本，不改原件和本地识别缓存。修改随文件
/// 保存（[stableEdits]），下次打开确认页时恢复。
class SendDraft {
  SendDraft({required this.documentId, required this.pages});

  final String documentId;
  final List<DraftPage> pages;
  final Map<String, String> edits = {};

  /// 打开时从上次保存恢复了几处修改（确认页提示用）。
  int restoredEdits = 0;

  static String lineKey(int pageNo, int lineIndex) =>
      'P${pageNo}L${lineIndex + 1}';

  /// 持久化用的键：附件 + 附件内页号 + 行下标，调整页序后仍对得上。
  static String stableKey(DraftPage page, int lineIndex) =>
      '${page.attachmentId}:${page.attachmentPage}:$lineIndex';

  /// 把保存过的修改套到本次草稿上：原文还一致的行才套用。
  void restore(Map<String, LineEdit> saved) {
    for (final p in pages) {
      for (var i = 0; i < p.lines.length; i++) {
        final e = saved[stableKey(p, i)];
        if (e == null || e.orig != p.lines[i].text) continue;
        edits[lineKey(p.pageNo, i)] = e.text;
        restoredEdits++;
      }
    }
  }

  /// 要发送的页上全部行的键，按页序、行序排列（确认页多选连选用）。
  List<String> lineOrder() => [
        for (final p in includedPages)
          for (var i = 0; i < p.lines.length; i++) lineKey(p.pageNo, i)
      ];

  /// [order] 中 [a] 到 [b] 之间（含两端，先后不论）的键；任一不在返回 [b]。
  static List<String> range(List<String> order, String a, String b) {
    final i = order.indexOf(a), j = order.indexOf(b);
    if (i < 0 || j < 0) return [b];
    return order.sublist(i < j ? i : j, (i < j ? j : i) + 1);
  }

  /// 批量删掉这些行（不发送）。
  void deleteLines(Iterable<String> keys) {
    for (final k in keys) {
      edits[k] = '';
    }
  }

  /// 批量恢复这些行为本机识别的原文（撤销删除和改写）。
  void restoreLines(Iterable<String> keys) => keys.forEach(edits.remove);

  /// 当前修改换成持久化形式（带原文，供下次核对）。
  Map<String, LineEdit> stableEdits() => {
        for (final p in pages)
          for (var i = 0; i < p.lines.length; i++)
            if (edits[lineKey(p.pageNo, i)] case final text?)
              stableKey(p, i): LineEdit(orig: p.lines[i].text, text: text),
      };

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
    ProfileRepository? profile,
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
        _profile = profile,
        _modelCall = modelCall ?? _defaultCall,
        _imageCall = imageCall ?? _defaultImageCall;

  final AttachmentRepository _attachments;
  final MedicalDocumentRepository _documents;
  final RecordRepository _records;
  final OrganizeRepository _organize;
  final ModelConfigRepository _modelConfigs;
  final KeyStore _keyStore;
  final TextExtractionService _extraction;
  final ProfileRepository? _profile;
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

  /// 用模型整理文字内容（D-35）：把当前版本的 findings 发给模型，同一部位的
  /// 所见与结论合并、重复的去掉，写成记录的新版本（旧版本保留，可撤销）。
  /// 只发已提取的文字（来自脱敏后的文本），不发图片和原始识别文本。
  /// 每段输入都要落进某一条输出，漏了就整个不改；没合并任何一条时不写新版本。
  /// 原样保留的条目保持核对状态，合并出来的条目回到未核对。
  Future<FindingsTidyOutcome> tidyFindings(String documentId) async {
    final record = await _records.labPanelOfDocument(documentId);
    if (record == null) throw StateError('这份文件还没有提取');
    final rev = await _records.currentRevisionOf(record.id);
    final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
    final findings = [
      for (final f in data['findings'] as List? ?? const [])
        (f as Map).cast<String, Object?>()
    ];
    if (findings.length < 2) throw StateError('文字内容不到两段，不用整理');

    final payload = jsonEncode({
      'findings': [
        for (var i = 0; i < findings.length; i++)
          {
            'id': i + 1,
            'section_raw': findings[i]['section_raw'],
            'text_raw': findings[i]['text_raw'],
          }
      ],
    });
    final (response, callId) = await _callAndRecord(
      system: findingsTidySystemPrompt,
      payload: payload,
      summary: '医疗文件已提取的文字内容 ${findings.length} 段（合并去重）',
    );

    final parsed = _parse(response.text);
    final out = parsed?['findings'];
    if (out is! List) {
      AppLog.I.w('extract', '文字整理解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，没有改动');
    }
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    final tidied = <Map<String, Object?>>[];
    final fields = Map<String, FieldMeta>.from(meta.fields)
      ..removeWhere((k, _) => k.startsWith('findings.'));
    final covered = <int>{};
    for (final raw in out) {
      if (raw is! Map) continue;
      final text = raw['text_raw'];
      if (text is! String || text.trim().isEmpty) continue;
      final from = <int>[
        for (final id in raw['from'] as List? ?? const [])
          if (id is num && id >= 1 && id <= findings.length) id.toInt() - 1
      ];
      if (from.isEmpty) continue;
      from.sort();
      covered.addAll(from);
      final section = raw['section_raw'];
      final entry = <String, Object?>{
        'section_raw': section is String && section.trim().isNotEmpty
            ? section.trim()
            : null,
        'text_raw': text.trim(),
        // 定位与识别修正跟着来源走，合并后仍能逐处回原件。
        'locator': {
          for (final i in from)
            for (final l in findings[i]['locator'] as List? ?? const [])
              jsonEncode(l): l
        }.values.toList(),
        'ocr_fixes': {
          for (final i in from) ..._ocrFixes(findings[i]['ocr_fixes'])
        }.toList(),
      };
      final source = findings[from.first];
      final unchanged = from.length == 1 &&
          entry['section_raw'] == source['section_raw'] &&
          entry['text_raw'] == source['text_raw'];
      final kept = unchanged ? meta['findings.${from.first}'] : null;
      fields['findings.${tidied.length}'] = kept ??
          const FieldMeta(
              origin: FieldOrigin.modelInferred,
              reviewStatus: ReviewStatus.unreviewed);
      tidied.add(entry);
    }
    final missing = [
      for (var i = 0; i < findings.length; i++)
        if (!covered.contains(i)) i + 1
    ];
    if (missing.isNotEmpty) {
      AppLog.I.w('extract', '文字整理漏了第 ${missing.join('、')} 段，未改动');
      throw StateError('模型整理时漏掉了第 ${missing.join('、')} 段，没有改动，可以再试一次');
    }
    if (tidied.length == findings.length) {
      AppLog.I.i('extract', '文字整理：${findings.length} 段没有可合并的');
      return FindingsTidyOutcome(
          before: findings.length, after: tidied.length, record: record);
    }
    data['findings'] = tidied;
    final updated = await _records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: TimeValue.decode(rev.occurred),
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap(fields),
      producedBy: ProducedBy.medicalExtract(callId),
    );
    AppLog.I.i('extract', '文字整理：${findings.length} 段合并为 ${tidied.length} 段');
    return FindingsTidyOutcome(
        before: findings.length,
        after: tidied.length,
        record: updated,
        previousData: rev.data,
        previousFieldMeta: rev.fieldMeta);
  }

  /// 事后整理类调用（文字整理、补大项）：用默认模型发一段已提取的数据，
  /// 成功失败都记调用记录。不带附件、不带图片。
  Future<(ModelResponse, String)> _callAndRecord({
    required String system,
    required String payload,
    required String summary,
  }) async {
    final config = await _modelConfigs.defaultConfig();
    if (config == null) {
      throw StateError('还没有配置模型：先在"模型配置"里添加');
    }
    final apiKey = config.keychainRef.isEmpty
        ? ''
        : (await _keyStore.read(config.keychainRef) ?? '');
    final requestAt = ids.nowMs();
    ModelResponse response;
    try {
      response = await _modelCall(
        config: config,
        apiKey: apiKey,
        system: system,
        userText: payload,
        maxTokens: 8192,
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
        caller: ModelCaller.phoneMedicalExtract,
        sentSummary: summary,
        requestText: payload,
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
      caller: ModelCaller.phoneMedicalExtract,
      sentSummary: summary,
      requestText: payload,
    );
    return (response, call.id);
  }

  /// 给没有检查大项的检验项目补上（D-36）：按顺序发项目名称和已有的大项
  /// （分批提取时后一页续表的项目常读不到标题，靠前后已标的补），模型标出
  /// 所属大项，写成新版本。已有大项的不改；不发数值；核对状态不变（大项
  /// 不是 D-04 的关键字段，详情页按大项分组展示供用户看）。
  Future<PanelFillOutcome> fillPanels(String documentId) async {
    final record = await _records.labPanelOfDocument(documentId);
    if (record == null) throw StateError('这份文件还没有提取');
    final rev = await _records.currentRevisionOf(record.id);
    final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
    final results = [
      for (final r in data['results'] as List? ?? const [])
        (r as Map).cast<String, Object?>()
    ];
    if (!results.any((r) => r['panel_raw'] == null)) {
      return PanelFillOutcome(filled: 0, record: record);
    }
    final payload = jsonEncode({
      'results': [
        for (var i = 0; i < results.length; i++)
          {
            'id': i + 1,
            'item_name_raw': results[i]['item_name_raw'],
            'panel_raw': results[i]['panel_raw'],
          }
      ],
    });
    final (response, callId) = await _callAndRecord(
      system: panelFillSystemPrompt,
      payload: payload,
      summary: '医疗文件检验项目名称 ${results.length} 个及已知大项'
          '（补 ${results.where((r) => r['panel_raw'] == null).length} 个的大项，不含数值）',
    );
    final out = _parse(response.text)?['results'];
    if (out is! List) {
      AppLog.I.w('extract', '补大项解析失败：${_snippet(response.text)}');
      throw StateError('模型返回无法解析，没有改动');
    }
    var filled = 0;
    for (final raw in out) {
      if (raw is! Map) continue;
      final id = raw['id'];
      final panel = raw['panel_raw'];
      if (id is! num || id < 1 || id > results.length) continue;
      if (panel is! String || panel.trim().isEmpty) continue;
      final r = results[id.toInt() - 1];
      if (r['panel_raw'] != null) continue;
      r['panel_raw'] = panel.trim();
      filled++;
    }
    if (filled == 0) {
      AppLog.I.i('extract', '补大项：模型没有标出任何一项');
      return PanelFillOutcome(filled: 0, record: record);
    }
    data['results'] = results;
    final updated = await _records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: TimeValue.decode(rev.occurred),
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap.decode(rev.fieldMeta),
      producedBy: ProducedBy.medicalExtract(callId),
    );
    AppLog.I.i('extract', '补大项：${results.length} 项中补上 $filled 项');
    return PanelFillOutcome(
        filled: filled,
        record: updated,
        previousData: rev.data,
        previousFieldMeta: rev.fieldMeta);
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
  /// [knownNames] 是额外的已知姓名；资料里的本人姓名和本文件标签旁
  /// 识别出的姓名会自动并入（D-24 第三层）。
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
    //    姓名先全文件收集再逐页替换：封皮、页眉上单独出现的姓名没有标签，
    //    要靠个人信息页标签旁的值和资料里的本人姓名认出来。
    final names = <String>{
      ...knownNames,
      ...await _profileNames(),
      ...redaction.harvestNames([for (final p in docPages) p.page.lines]),
    }.toList();
    final overrides =
        MedicalDocumentRepository.decodePageOverrides(doc.pageOverrides);
    final pages = <DraftPage>[];
    for (final p in docPages) {
      final byRule = pageFilter.decide(p.page);
      final override = overrides[p.pageNo];
      final r = redaction.redactPage(p.page.lines, knownNames: names);
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
    return SendDraft(documentId: doc.id, pages: pages)
      ..restore(MedicalDocumentRepository.decodeLineEdits(doc.lineEdits));
  }

  /// 资料里填写的本人姓名（只用于发送前遮蔽）。
  Future<List<String>> _profileNames() async {
    final row = await _profile?.current(ProfileRepository.fullNameKey);
    if (row == null || row.$1.state != ProfileFieldState.provided) return const [];
    final v = '${row.$2 ?? ''}'.trim();
    return v.isEmpty ? const [] : [v];
  }

  /// 保存确认页的行修改（每改一行都存，离开确认页或提交失败后不丢）。
  Future<void> saveLineEdits(SendDraft draft) =>
      _documents.setLineEdits(draft.documentId, draft.stableEdits());

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

    var results = <Map<String, Object?>>[];
    for (final raw in rawResults) {
      if (raw is! Map) continue;
      final r = raw.cast<String, Object?>();
      if (r['item_name_raw'] is! String || r['value_raw'] is! String) continue;
      final locators = _locatorsOf(r['source_lines'], lineIndex, fallback);
      final panel = r['panel_raw'];
      results.add({
        'panel_raw': panel is String && panel.trim().isNotEmpty
            ? panel.trim()
            : null,
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
      // 模型只写了修正说明、字段没改时补上（如单位幂次）。
      OcrFixes.apply(results.last, OcrFixes.resultFields);
    }

    // 体检报告前面汇总、后面明细会把同一项写两遍，分批时还落在不同批里：
    // 同项目同数值只留一条（D-32）。
    results = SameItem.dedupeResults(results);

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
    // 文件类型只在还是"其他"（病例夹里新加、未分类）时用模型的判断补上；
    // 从"我的体检"加的文件类型是用户选的，不覆盖（2026-09-29 联调：体检
    // 报告被改成检验报告后从体检列表消失，模型的可选类型里也没有体检）。
    final docTypeRaw = docInfo['doc_type'] as String?;
    MedicalDocType? docType;
    if (docTypeRaw != null && doc.docType == MedicalDocType.other) {
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
  /// 用户在档案页核对后才算事实。
  ///
  /// 同一份文件里说的是同一个问题的只建一条（汇总与明细各写一遍，写法
  /// 不同，D-32），留名称更具体的那条；这份文件或同一检查日期的文件（同一
  /// 份报告重复上传）已经建过的不再建。其他日期报告里的同一问题照样建：
  /// 每份报告各有一条、各自关联原文件，看当前状况时按日期取最新（D-32）。
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
    final existingNames = <String>[];
    for (final rec in await _records.byType(RecordType.condition)) {
      final rev = await _records.currentRevisionOf(rec.id);
      final data = jsonDecode(rev.data) as Map;
      final sameReport = data['medical_document_id'] == documentId ||
          (examDate != null && rec.localDate == examDate);
      if (!sameReport) continue;
      if (data['name'] is String) existingNames.add(data['name'] as String);
    }

    final picked = <Map<Object?, Object?>>[];
    for (final c in raw) {
      if (c is! Map) continue;
      final name = c['name'];
      final persistence = c['persistence'];
      if (name is! String || name.trim().isEmpty) continue;
      if (persistence != 'long_term' && persistence != 'temporary') continue;
      if (existingNames.any((n) => SameItem.sameProblem(n, name))) continue;
      final same = picked.indexWhere(
          (p) => SameItem.sameProblem(p['name'] as String, name));
      if (same < 0) {
        picked.add(c);
      } else if (name.trim().length >
          (picked[same]['name'] as String).trim().length) {
        picked[same] = c;
      }
    }

    final created = <RecordRow>[];
    for (final c in picked) {
      final name = c['name'] as String;
      final persistence = c['persistence'];
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
      final history = await _records.labResultHistory(RecordRepository.labItemKey(
          name,
          panel: r['panel_raw'] as String?));
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
