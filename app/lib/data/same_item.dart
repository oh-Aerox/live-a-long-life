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

  /// 检验项目的归一化键：去括号里的缩写与方法、去空白，再把同一指标的
  /// 不同写法归到一个名字（D-32 补充，2026-09-30）：
  /// - 末尾的"（联）"（联合检测）、不带括号的检测方法（"……电发光"）、
  ///   "测定 / 检测 / 定量 / 定性"——同一指标，不同医院、不同写法；
  /// - 白细胞分类的"比值 / 百分比 / 百分数"归百分数，"计数 / 绝对值"
  ///   归绝对值（比值是小数，建索引时换算，见 [labPercentFactor]）；
  /// - 常见别名（[_aliases]）。
  ///
  /// [panel] 是报告上的检查大项（D-36）。尿常规、便常规里的项目名脱离大项
  /// 就分不清（尿"白细胞""葡萄糖""胆红素"与血里的同名），键前加标本
  /// （"尿白细胞""尿糖""便隐血"）；本来就带"尿/便"的名字不重复加。
  static String labKey(String itemNameRaw, {String? panel}) {
    final specimen = specimenOf(panel);
    var k = itemNameRaw
        .replaceAll(_dropParen, '')
        .replaceAll(_slashAbbr, '')
        .replaceAll(RegExp(r'[（(]联[）)]'), '')
        .replaceAll(RegExp(r'\s'), '');
    k = k.replaceFirst(_methodSuffix, '');
    final stripped = k.replaceFirst(_testSuffix, '');
    if (stripped.length >= 2) k = stripped;
    final wbc = _wbcDifferential.firstMatch(k);
    if (wbc != null) {
      k = '${wbc[1]}${_wbcAbsolute.hasMatch(wbc[2]!) ? '绝对值' : '百分数'}';
    }
    if (specimen != null) {
      final base = k.startsWith(specimen) ? k.substring(1) : k;
      return '$specimen${_specimenAliases[base.toLowerCase()] ?? base}';
    }
    return _aliases[k] ?? k;
  }

  /// 检查大项对应的标本：尿常规/尿液分析/尿沉渣 → 尿，便常规/粪便常规 → 便；
  /// 血液类和认不出的返回 null（键不加前缀，与没有大项的旧数据一致）。
  static String? specimenOf(String? panel) {
    if (panel == null) return null;
    if (RegExp(r'尿(?!酸|素)').hasMatch(panel)) return '尿';
    if (RegExp('便|粪').hasMatch(panel)) return '便';
    return null;
  }

  /// 尿、便检查里同一项目的不同写法（去掉开头的"尿/便"后）→ 统一名。
  /// pH 不叫"酸碱度"以外的名字：键"尿pH"会被人体图的 Hp（幽门螺杆菌）规则
  /// 不分大小写命中。
  static const _specimenAliases = {
    '胆素原': '胆原',
    'ph': '液酸碱度',
    'ph值': '液酸碱度',
    '酸碱度': '液酸碱度',
    '潜血': '隐血',
    '蛋白质': '蛋白',
    '葡萄糖': '糖',
  };

  /// 趋势列表的分组名（D-36）：尿液分析、尿沉渣、粪便常规等归成"尿常规"
  /// "便常规"（尿微量白蛋白这类单项保留原名），其他大项去空白和
  /// "检查/检测/测定"后缀；没有大项的归"其他"。
  static String panelGroup(String? panel) {
    final specimen = specimenOf(panel);
    if (specimen != null &&
        RegExp('常规|分析|沉渣|尿液|尿检|大便|粪便').hasMatch(panel!)) {
      return '$specimen常规';
    }
    final p = (panel ?? '').replaceAll(RegExp(r'\s'), '');
    final stripped = p.replaceFirst(RegExp(r'(?:检查|检测|测定)$'), '');
    return stripped.isEmpty ? '其他' : stripped;
  }

  /// 中文名后面用斜杠或空格跟的英文缩写（"体重指数/BMI""升主动脉内径 AOD"）。
  /// 纯英文的比值（"F-PSA/T-PSA"）不动。
  static final _slashAbbr = RegExp(
      r'(?<=[\u4e00-\u9fff])\s*(?:/\s*|\s+)[A-Za-z][\x00-\x7f]*$');

  static final _methodSuffix = RegExp(r'(?:电化学发光|化学发光|电发光|发光法|酶免法)$');
  static final _testSuffix = RegExp(r'(?:测定|检测|定量|定性)$');

  static final _wbcDifferential = RegExp(
      r'^(中性粒细胞|淋巴细胞|单核细胞|嗜酸性粒细胞|嗜碱性粒细胞)'
      r'(比值|比例|百分比|百分率|百分数|%|计数|绝对值|数目)$');
  static final _wbcAbsolute = RegExp(r'计数|绝对值|数目');

  /// 常见别名 → 本应用用的名字。只收同一指标、同一标本的叫法，
  /// 不收"尿素氮 / 尿素"这类单位或口径不同的。
  static const _aliases = {
    '谷丙转氨酶': '丙氨酸氨基转移酶',
    '谷草转氨酶': '天门冬氨酸氨基转移酶',
    '天冬氨酸氨基转移酶': '天门冬氨酸氨基转移酶',
    'γ-谷氨酰转肽酶': 'γ-谷氨酰转移酶',
    '谷氨酰转肽酶': 'γ-谷氨酰转移酶',
    'γ-谷氨酰基转移酶': 'γ-谷氨酰转移酶',
    '血小板计数': '血小板',
    '红细胞比容': '红细胞压积',
    '促甲状腺激素': '促甲状腺素',
    '甘油三脂': '甘油三酯',
    '血肌酐': '肌酐',
    '血尿酸': '尿酸',
  };

  /// 白细胞分类写成小数比值（0.481，参考 0.5-0.7）时换算成百分数的倍数：
  /// 名字是比值类、没有单位或单位是"-"、参考上限（没有时看数值）不超过 1，
  /// 才乘 100；已经是百分数的返回 1。
  static double labPercentFactor(Map<Object?, Object?> r) {
    final name = r['item_name_raw'];
    if (name is! String) return 1;
    final raw = name.replaceAll(_dropParen, '').replaceAll(RegExp(r'\s'), '');
    final m = _wbcDifferential.firstMatch(raw);
    if (m == null || !RegExp(r'比值|比例').hasMatch(m[2]!)) return 1;
    final unit = '${r['unit_raw'] ?? ''}'.trim();
    if (unit.isNotEmpty && unit != '-') return 1;
    final scale = (r['ref_high'] as num?) ?? (r['value_num'] as num?);
    return scale != null && scale <= 1 ? 100 : 1;
  }

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
      final key = name is String
          ? '${labKey(name, panel: r['panel_raw'] as String?)}|${labValue(r)}'
          : null;
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
