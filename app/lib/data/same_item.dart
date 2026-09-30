/// 判断两条记录说的是不是同一件事（D-32）。体检报告前面的汇总把问题
/// 列一遍、后面的明细再写一遍，写法还不完全一样（"天门冬氨酸氨基转移酶"
/// 与"天门冬氨酸氨基转移酶（AST）"，"颈椎轻度骨质增生"与"颈（3）-（6）
/// 椎体缘轻度骨质增生"）；不同年份的报告写同一个问题，程度会变
/// （脂肪肝轻度→中度）。这里只做本地规则，不调模型。
class SameItem {
  /// 检验项目名里可以去掉的括号：英文缩写（ALT、HDL-CHO、GRA#）和检测
  /// 方法（酶免法、发光法）。中文说明（尿沉渣）不去，免得不同标本混在一起。
  static final _dropParen = RegExp(
      r'[（(](?:[\x00-\x7fµγβα%＃#/\-\s]+|[^（()）]*法)[）)]');

  /// 检验项目的归一化键：去括号里的缩写与方法、去空白。
  static String labKey(String itemNameRaw) => itemNameRaw
      .replaceAll(_dropParen, '')
      .replaceAll(_slashAbbr, '')
      .replaceAll(RegExp(r'\s'), '');

  /// 中文名后面用斜杠跟的英文缩写（"体重指数/BMI"）。纯英文的比值
  /// （"F-PSA/T-PSA"）不动。
  static final _slashAbbr = RegExp(r'(?<=[\u4e00-\u9fff])\s*/\s*[A-Za-z][\x00-\x7f]*$');

  /// 检验结果的值（比较用）：有解析出的数值用数值，否则用原文去掉单位与空白。
  static String labValue(Map<Object?, Object?> r) {
    final n = r['value_num'];
    if (n is num) return n.toDouble().toString();
    var v = '${r['value_raw'] ?? ''}'.replaceAll(RegExp(r'\s'), '');
    final unit = '${r['unit_raw'] ?? ''}'.replaceAll(RegExp(r'\s'), '');
    if (unit.isNotEmpty && v.endsWith(unit)) {
      v = v.substring(0, v.length - unit.length);
    }
    return v;
  }

  /// 同一份文件里重复的检验结果（同项目同数值）只留一条：留信息更全的
  /// （有参考范围、异常标记，值里没混单位），一样全的留后面的（明细在后）。
  static List<Map<String, Object?>> dedupeResults(
      List<Map<String, Object?>> results) {
    final keep = <String, int>{};
    final out = <Map<String, Object?>?>[];
    for (final r in results) {
      final name = r['item_name_raw'];
      final key = name is String ? '${labKey(name)}|${labValue(r)}' : null;
      final prev = key == null ? null : keep[key];
      if (prev == null) {
        if (key != null) keep[key] = out.length;
        out.add(r);
        continue;
      }
      if (_richness(r) >= _richness(out[prev]!)) {
        out[prev] = null;
        keep[key!] = out.length;
        out.add(r);
      }
    }
    return [for (final r in out) ?r];
  }

  static int _richness(Map<String, Object?> r) {
    bool has(String k) => r[k] != null && '${r[k]}'.trim().isNotEmpty;
    final value = '${r['value_raw'] ?? ''}';
    final unit = '${r['unit_raw'] ?? ''}';
    return (has('ref_range_raw') ? 2 : 0) +
        (has('ref_low') || has('ref_high') ? 1 : 0) +
        (has('flag_raw') ? 1 : 0) +
        (unit.isNotEmpty && value.endsWith(unit) ? 0 : 1);
  }

  /// 报告文字里一句话说的问题：去掉开头的序号（"4." "(1)."）和检查名前缀
  /// （"腹部超声提示：" "耳鼻喉科提示："）。前缀只用来说明是哪项检查，
  /// 留着会让"耳鼻喉科"把鼻炎也归到耳和咽喉上。
  static String problemText(String sentence) {
    var s = sentence.trim().replaceFirst(_numbering, '');
    final m = RegExp(r'^[^：:，,。]{1,12}[：:]').firstMatch(s);
    if (m != null && m.end < s.length) s = s.substring(m.end);
    return s.replaceFirst(_numbering, '').trim();
  }

  static final _numbering = RegExp(r'^(?:\s*[（(]?\d{1,2}[）)]?[.、．。]?\s*)+');

  static final _qualifier = RegExp(
      '轻度|中度|重度|多发|单发|多个|少许|少量|可疑|考虑|左侧|右侧|双侧|有');
  static final _noise = RegExp(r'[\s\d.．,，、;；:：\-~～/（）()\[\]【】]');

  /// 问题名称的核心：去括号内容、程度与左右等修饰、数字与标点。
  static String core(String name) => problemText(name)
      .replaceAll(RegExp(r'[（(][^（()）]*[）)]'), '')
      .replaceAll(_qualifier, '')
      .replaceAll(RegExp('[左右双]'), '')
      .replaceAll(_noise, '');

  /// 两个问题名称是否说的同一件事：核心相同；或较短的核心不少于 3 个字、
  /// 按顺序出现在较长的里、且最后两个字（问题本身：结石、增生、囊肿）相同。
  static bool sameProblem(String a, String b) {
    final ka = core(a), kb = core(b);
    if (ka.isEmpty || kb.isEmpty) return a.trim() == b.trim();
    if (ka == kb) return true;
    final (short, long) = ka.length <= kb.length ? (ka, kb) : (kb, ka);
    if (short.length < 3) return false;
    if (short.substring(short.length - 2) != long.substring(long.length - 2)) {
      return false;
    }
    var i = 0;
    for (final ch in long.split('')) {
      if (i < short.length && short[i] == ch) i++;
    }
    return i == short.length;
  }

  /// 按"同一问题"分组，组内新的在前（日期相同保持原顺序），组按各自
  /// 最新日期新→旧排。看当前状况取每组第一条，其余是既往（D-32）。
  static List<List<T>> groups<T>(Iterable<T> items, String Function(T) name,
      String? Function(T) date) {
    final out = <List<T>>[];
    for (final item in items) {
      final g = out.indexWhere((g) => sameProblem(name(g.first), name(item)));
      if (g < 0) {
        out.add([item]);
      } else {
        out[g].add(item);
      }
    }
    // List.sort 不保证稳定，带上原下标兜底。
    List<E> stable<E>(List<E> list, String? Function(E) d) {
      final indexed = list.indexed.toList()
        ..sort((a, b) {
          final c = (d(b.$2) ?? '').compareTo(d(a.$2) ?? '');
          return c != 0 ? c : a.$1.compareTo(b.$1);
        });
      return [for (final (_, e) in indexed) e];
    }

    return stable([for (final g in out) stable(g, date)], (g) => date(g.first));
  }
}
