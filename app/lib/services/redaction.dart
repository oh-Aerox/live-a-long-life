import 'text_extraction.dart';

/// 发送前脱敏（D-24）：删姓名、证件号和门诊卡号（2026-09-29 用户补充；
/// 出生日期用户明确保留），三层全部本地执行。
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
  static const cardPlaceholder = '【卡号】';

  /// 第一层：锚点标签。值可能带 OCR 误读或遮星，宽松匹配；
  /// 后面跟到下一个已知字段标签或空白为止。
  static final _nameLabel = RegExp(
      r'(姓\s*名|受\s*检\s*人|体\s*检\s*人)\s*[:：]?\s*'
      r'([^\s:：]{1,8}?)'
      r'(?=$|\s|性\s*别|年\s*龄|科室|病历|门\s*[1lI|丨]?\s*诊|就诊|住院|条码|标本|样本|编号|号码)');
  static final _idLabel = RegExp(
      r'(身份证号码?|身\s*份\s*证|证件号码?|社保卡号|医保卡号|社会保障卡号)'
      r'\s*[:：]?\s*([A-Za-z0-9*\-]{4,22})');

  /// 医院就诊卡号（门诊卡号及同义叫法）。OCR 常在"门诊"中间插进杂字符
  /// （真机样本"门1诊卡号"），标签字之间容忍一个 1/l/I/| 类误读。
  static const _cardLabelText =
      r'门\s*[1lI|丨]?\s*诊\s*卡\s*号|就\s*诊\s*卡\s*号|诊\s*疗\s*卡\s*号|门\s*诊\s*号';
  static final _cardLabel = RegExp(
      '($_cardLabelText)' r'\s*[:：]?\s*([A-Za-z0-9*\-]{4,22})');

  /// 只有标签没有值的行（值在表格右邻格），配合坐标找同行右邻。
  static final _labelOnly = RegExp(
      r'^(姓\s*名|受\s*检\s*人|体\s*检\s*人|身份证号码?|证件号码?|社保卡号|医保卡号|'
      '$_cardLabelText' r')\s*[:：]?$');

  /// 敬称版式（封皮常见"尊敬的张三先生"、单独一行"张三 女士"），
  /// 只用来收集姓名，不单独遮蔽：收集到的姓名再走第三层全文替换。
  static final _honorific = RegExp(
      r'^(?:尊\s*敬\s*的\s*)?([\u4e00-\u9fa5·]{2,6}?)\s*(?:先\s*生|女\s*士)\s*[:：,，]?$');
  static final _salutation = RegExp(
      r'尊\s*敬\s*的\s*([\u4e00-\u9fa5·]{2,6}?)\s*(?:先\s*生|女\s*士)');

  /// 收集到的姓名要像人名：2～6 个汉字（含少数民族名的间隔点）。
  static final _plausibleName = RegExp(r'^[\u4e00-\u9fa5·]{2,6}$');

  /// 第二层：18 位身份证候选（含 OCR 易混字符），命中后校验位验证。
  static final _idCandidate = RegExp(r'(?<![0-9OoIl])[0-9OoIl]{17}[0-9OoIlXx](?![0-9OoIl])');

  /// 从一份文件的全部页里收集姓名：标签旁的值（同行或表格右邻）与敬称版式。
  /// 同一份文件里姓名常只在个人信息页带标签，封皮、页眉单独出现；
  /// 收集后作为已知姓名对每页全文替换（D-24 第三层）。
  Set<String> harvestNames(Iterable<List<OcrLine>> pages) {
    final names = <String>{};
    void add(String? raw) {
      final v = raw?.replaceAll(RegExp(r'\s'), '');
      if (v != null && _plausibleName.hasMatch(v)) names.add(v);
    }

    for (final lines in pages) {
      for (var i = 0; i < lines.length; i++) {
        final text = lines[i].text.trim();
        for (final m in _nameLabel.allMatches(text)) {
          add(m.group(2));
        }
        add(_honorific.firstMatch(text)?.group(1));
        for (final m in _salutation.allMatches(text)) {
          add(m.group(1));
        }
        final label = _labelOnly.firstMatch(text)?.group(1);
        if (label != null &&
            lines[i].hasBox &&
            label.replaceAll(RegExp(r'\s'), '').contains(RegExp('姓名|受检人|体检人'))) {
          final j = _rightNeighbor(lines, i);
          if (j != null) add(lines[j].text);
        }
      }
    }
    return names;
  }

  /// 对一页做脱敏。[knownNames] 是用户本人姓名等已知姓名（第三层，
  /// 来自资料，应用是单用户的）。
  RedactionResult redactPage(List<OcrLine> lines,
      {List<String> knownNames = const []}) {
    var count = 0;
    final out = <OcrLine>[];
    final namePatterns = [
      for (final name in {
        for (final n in knownNames) n.replaceAll(RegExp(r'\s'), '')
      })
        if (name.length >= 2)
          RegExp(name.split('').map(RegExp.escape).join(r'\s*')),
    ];

    // 先按坐标找"标签行 → 同行右邻值"的配对（表格版式）。
    final valueLineRedactions = <int, String>{}; // 行下标 → 占位符
    for (var i = 0; i < lines.length; i++) {
      final m = _labelOnly.firstMatch(lines[i].text.trim());
      if (m == null || !lines[i].hasBox) continue;
      final label = m.group(1)!;
      final isName =
          label.replaceAll(RegExp(r'\s'), '').contains(RegExp('姓名|受检人|体检人'));
      final isCard = RegExp('^($_cardLabelText)\$').hasMatch(label);
      final j = _rightNeighbor(lines, i);
      if (j != null && lines[j].text.trim().length <= 22) {
        valueLineRedactions[j] = isName
            ? namePlaceholder
            : (isCard ? cardPlaceholder : idPlaceholder);
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
      text = text.replaceAllMapped(_cardLabel, (m) {
        count++;
        return '${m.group(1)}：$cardPlaceholder';
      });

      // 第二层：无标签散落的 18 位身份证（校验位过了才算）。
      text = text.replaceAllMapped(_idCandidate, (m) {
        final normalized = _normalizeDigits(m.group(0)!);
        if (!isValidCitizenId(normalized)) return m.group(0)!;
        count++;
        return idPlaceholder;
      });

      // 第三层：已知姓名全文替换（≥2 字才替，防单字误伤）。
      // 字间容忍空白：封皮大字常加字距，OCR 读成"张  三"。
      for (final pattern in namePatterns) {
        text = text.replaceAllMapped(pattern, (_) {
          count++;
          return namePlaceholder;
        });
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
