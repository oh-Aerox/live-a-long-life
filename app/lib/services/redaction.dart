import 'text_extraction.dart';

/// 发送前脱敏（D-24）：只删姓名和证件号，三层全部本地执行。
/// 占位符替换而不是删除，文本结构不塌；只作用于发送副本，
/// 原件与未脱敏 OCR 文本仅存本地。
class RedactionResult {
  const RedactionResult({required this.lines, required this.redactedCount});

  /// 脱敏后的行（坐标原样保留）。
  final List<OcrLine> lines;

  /// 遮蔽项数，记入调用记录（D-16 透明度）。
  final int redactedCount;
}

class RedactionService {
  const RedactionService();

  static const namePlaceholder = '【姓名】';
  static const idPlaceholder = '【证件号】';

  /// 第一层：锚点标签。值可能带 OCR 误读或遮星，宽松匹配；
  /// 后面跟到下一个已知字段标签或空白为止。
  static final _nameLabel = RegExp(
      r'(姓\s*名|受\s*检\s*人|体\s*检\s*人)\s*[:：]?\s*'
      r'([^\s:：]{1,8}?)'
      r'(?=$|\s|性\s*别|年\s*龄|科室|病历|门诊|住院|条码|标本|样本|编号|号码)');
  static final _idLabel = RegExp(
      r'(身份证号码?|身\s*份\s*证|证件号码?|社保卡号|医保卡号|社会保障卡号)'
      r'\s*[:：]?\s*([A-Za-z0-9*\-]{4,22})');

  /// 只有标签没有值的行（值在表格右邻格），配合坐标找同行右邻。
  static final _labelOnly =
      RegExp(r'^(姓\s*名|受\s*检\s*人|体\s*检\s*人|身份证号码?|证件号码?|社保卡号|医保卡号)\s*[:：]?$');

  /// 第二层：18 位身份证候选（含 OCR 易混字符），命中后校验位验证。
  static final _idCandidate = RegExp(r'(?<![0-9OoIl])[0-9OoIl]{17}[0-9OoIlXx](?![0-9OoIl])');

  /// 对一页做脱敏。[knownNames] 是用户本人姓名等已知姓名（第三层，
  /// 来自资料，应用是单用户的）。
  RedactionResult redactPage(List<OcrLine> lines,
      {List<String> knownNames = const []}) {
    var count = 0;
    final out = <OcrLine>[];

    // 先按坐标找"标签行 → 同行右邻值"的配对（表格版式）。
    final valueLineRedactions = <int, String>{}; // 行下标 → 占位符
    for (var i = 0; i < lines.length; i++) {
      final m = _labelOnly.firstMatch(lines[i].text.trim());
      if (m == null || !lines[i].hasBox) continue;
      final isName = m.group(1)!.replaceAll(RegExp(r'\s'), '').contains(RegExp('姓名|受检人|体检人'));
      final j = _rightNeighbor(lines, i);
      if (j != null && lines[j].text.trim().length <= 22) {
        valueLineRedactions[j] = isName ? namePlaceholder : idPlaceholder;
      }
    }

    for (var i = 0; i < lines.length; i++) {
      var text = lines[i].text;

      if (valueLineRedactions.containsKey(i)) {
        text = valueLineRedactions[i]!;
        count++;
        out.add(_withText(lines[i], text));
        continue;
      }

      // 第一层：同行"标签：值"。
      text = text.replaceAllMapped(_nameLabel, (m) {
        count++;
        return '${m.group(1)}：$namePlaceholder';
      });
      text = text.replaceAllMapped(_idLabel, (m) {
        count++;
        return '${m.group(1)}：$idPlaceholder';
      });

      // 第二层：无标签散落的 18 位身份证（校验位过了才算）。
      text = text.replaceAllMapped(_idCandidate, (m) {
        final normalized = _normalizeDigits(m.group(0)!);
        if (!isValidCitizenId(normalized)) return m.group(0)!;
        count++;
        return idPlaceholder;
      });

      // 第三层：已知姓名全文替换（≥2 字才替，防单字误伤）。
      for (final name in knownNames) {
        if (name.trim().length < 2) continue;
        if (text.contains(name)) {
          count += name.allMatches(text).length;
          text = text.replaceAll(name, namePlaceholder);
        }
      }

      out.add(_withText(lines[i], text));
    }
    return RedactionResult(lines: out, redactedCount: count);
  }

  /// 找与第 [i] 行垂直重叠、位于其右侧、水平距离最近的行。
  int? _rightNeighbor(List<OcrLine> lines, int i) {
    final a = lines[i];
    int? best;
    double bestDx = double.infinity;
    for (var j = 0; j < lines.length; j++) {
      if (j == i || !lines[j].hasBox) continue;
      final b = lines[j];
      final overlap =
          (a.y! < b.y! + b.h!) && (b.y! < a.y! + a.h!); // 垂直有交叠
      final dx = b.x! - (a.x! + a.w!);
      if (overlap && dx >= -0.01 && dx < bestDx) {
        best = j;
        bestDx = dx;
      }
    }
    return best;
  }

  OcrLine _withText(OcrLine line, String text) =>
      OcrLine(text: text, x: line.x, y: line.y, w: line.w, h: line.h);

  /// OCR 易混字符归一化（只用于号码候选，不改动原文其他部分）。
  static String _normalizeDigits(String s) => s
      .replaceAll(RegExp('[Oo]'), '0')
      .replaceAll(RegExp('[Il]'), '1')
      .replaceAll('x', 'X');

  /// GB 11643-1999 十八位公民身份号码校验位。
  static bool isValidCitizenId(String id) {
    if (id.length != 18) return false;
    if (!RegExp(r'^\d{17}[\dX]$').hasMatch(id)) return false;
    // 出生日期段粗校验，压掉纯随机 18 位数字的误报。
    final month = int.parse(id.substring(10, 12));
    final day = int.parse(id.substring(12, 14));
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const checks = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      sum += int.parse(id[i]) * weights[i];
    }
    return checks[sum % 11] == id[17];
  }
}
