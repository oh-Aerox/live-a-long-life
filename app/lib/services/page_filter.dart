import 'text_extraction.dart';

/// 页筛选（D-23 补充）：体检册里与健康无关的页（封面、机构介绍、导读、
/// 健康宣教、温馨提示）默认不发给模型。两个信号：锚点关键词 + 数值密度。
/// 默认筛选 + 用户可改：这里只给默认判定，UI 上每页可点选恢复，
/// 不静默丢弃；筛选只影响发送副本，OCR 缓存完整保留。
class PageDecision {
  const PageDecision(
      {required this.pageNo, required this.included, required this.reason});

  final int pageNo;
  final bool included;
  final String reason;
}

class PageFilter {
  const PageFilter();

  /// 保留锚点：检验表头、检查文字报告（散文体但健康相关）、总检结论。
  static final _keepAnchors = RegExp(
      '检验项目|检查项目|项目名称|结果|单位|参考范围|参考值|'
      '所见|提示|结论|印象|诊断|超声|彩超|主诉|现病史|病史|处理意见|'
      '总检|汇总|异常|建议|复查');

  /// 丢弃锚点：与健康无关的册页。
  static final _dropAnchors = RegExp(
      '导读|目录|尊敬的|温馨提示|健康宣教|健康知识|指标解读须知|'
      '本中心|中心简介|机构简介|关于我们|院长|致辞|服务指南|预约须知');

  /// 数值行：参考范围（1.0-2.0 / 3.5~9.5）或数值+检验单位。
  static final _refRange =
      RegExp(r'\d+(\.\d+)?\s*[-–—~～]\s*\d+(\.\d+)?');
  static final _valueUnit = RegExp(
      r'\d+(\.\d+)?\s*(10\^?\d+/L|mmol/L|umol/L|μmol/L|mg/L|g/L|mg/dL|'
      r'U/L|IU/L|IU/mL|ng/mL|pg/mL|mIU/L|fL|pg|%|/HP|/uL|/μL)');

  PageDecision decide(ExtractedPage page) {
    final text = page.plainText;
    final keep = _keepAnchors.hasMatch(text);
    final drop = _dropAnchors.hasMatch(text);
    final numericLines = page.lines
        .where((l) => _refRange.hasMatch(l.text) || _valueUnit.hasMatch(l.text))
        .length;
    final density =
        page.lines.isEmpty ? 0.0 : numericLines / page.lines.length;

    // 数据页信号最硬：数值密度高必是数据页，即使混着"温馨提示"。
    if (numericLines >= 3 && density >= 0.15) {
      return PageDecision(
          pageNo: page.pageNo, included: true, reason: '数值密度 $numericLines 行');
    }
    if (keep) {
      // 检查所见/结论/总检建议是散文体但必须保留（D-23）。
      return PageDecision(pageNo: page.pageNo, included: true, reason: '保留锚点');
    }
    if (drop) {
      return PageDecision(
          pageNo: page.pageNo, included: false, reason: '丢弃锚点（导读/宣教类）');
    }
    // 两头都不沾：默认保留比默认丢弃安全（版式认不出时宁可多发）。
    return PageDecision(
        pageNo: page.pageNo, included: true, reason: '无信号，默认保留');
  }

  List<PageDecision> decideAll(List<ExtractedPage> pages) =>
      [for (final p in pages) decide(p)];
}
