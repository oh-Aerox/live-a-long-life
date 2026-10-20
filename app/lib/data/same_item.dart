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

  /// 项目名前后的标记符号：京津冀鲁等地检验结果互认在项目名前加"*"或"★"，
  /// 有的医院用"※""▲"。对健康记录没有意义，留着会把同一项目分成两条。
  static final _itemMarks = RegExp(r'^[\s*＊★☆※▲△●◆]+|[\s*＊★☆※▲△●◆]+$');

  /// 展示用的项目名：去掉前后的互认标记（原文仍按报告保存，供核对）。
  static String itemName(String itemNameRaw) {
    final name = itemNameRaw.replaceAll(_itemMarks, '');
    return name.isEmpty ? itemNameRaw : name;
  }

  /// 检验项目的归一化键：去括号里的缩写与方法、去空白，再把同一指标的
  /// 不同写法归到一个名字（D-32 补充，2026-09-30）：
  /// - 末尾的"（联）"（联合检测）、不带括号的检测方法（"……电发光"）、
  ///   "测定 / 检测 / 定量 / 定性"——同一指标，不同医院、不同写法；
  /// - 白细胞分类的"比值 / 百分比 / 百分数"归百分数，"计数 / 绝对值"
  ///   归绝对值（比值是小数，建索引时换算，见 [labPercentFactor]）；
  /// - 常见别名（[_aliases]）；
  /// - 项目名前后的互认标记（"*白细胞计数"，[itemName]）；
  /// - 复测（"复测血压""收缩压（复测第1次）"）：和首次测量画在同一条趋势
  ///   上（D-39，用户选择），同一天数值不同就是两个点。
  ///
  /// [panel] 是报告上的检查大项（D-36）。尿常规、便常规里的项目名脱离大项
  /// 就分不清（尿"白细胞""葡萄糖""胆红素"与血里的同名），键前加标本
  /// （"尿白细胞""尿糖""便隐血"）；本来就带"尿/便"的名字不重复加。
  static String labKey(String itemNameRaw, {String? panel}) {
    final specimen = specimenOf(panel);
    var k = itemName(itemNameRaw)
        .replaceAll(_retest, '')
        .replaceAll(_dropParen, '')
        .replaceAll(_slashAbbr, '')
        .replaceAll(RegExp(r'[（(](?:联|定量|定性)[）)]'), '')
        .replaceAll(RegExp(r'\s'), '');
    k = k.replaceFirst(_methodSuffix, '');
    final stripped = k.replaceFirst(_testSuffix, '');
    if (stripped.length >= 2) k = stripped;
    final rdw = _rdw.firstMatch(k);
    if (rdw != null) {
      k = '红细胞体积分布宽度${RegExp('cv|变异', caseSensitive: false).hasMatch(rdw[1]!) ? '变异系数' : '标准差'}';
    }
    final wbc = _wbcDifferential.firstMatch(k);
    if (wbc != null) {
      final cell = switch (wbc[1]!) {
        '嗜酸细胞' => '嗜酸性粒细胞',
        '嗜碱细胞' => '嗜碱性粒细胞',
        final c => c,
      };
      k = '$cell${_wbcAbsolute.hasMatch(wbc[2]!) ? '绝对值' : '百分数'}';
    }
    if (specimen != null) {
      final base = k.startsWith(specimen) ? k.substring(1) : k;
      return '$specimen${_specimenAliases[base.toLowerCase()] ?? base}';
    }
    return _aliases[k] ?? k;
  }

  /// 检查大项对应的标本：尿常规/尿液分析/尿沉渣 → 尿，便常规/粪便常规 → 便；
  /// 血液类和认不出的返回 null（键不加前缀，与没有大项的旧数据一致）。
  /// "尿酸""尿素"是血液项目，"糖尿病检测"是血糖类大项（2026-10-20：其中的
  /// 空腹血糖被当成尿检，和别的报告的空腹血糖分成两项），都不算尿。
  static String? specimenOf(String? panel) {
    if (panel == null) return null;
    if (RegExp(r'(?<!糖)尿(?!酸|素|病)').hasMatch(panel)) return '尿';
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

  static final _retest = RegExp(r'^复测|[（(]复测[^）)]*[）)]');
  static final _methodSuffix = RegExp(r'(?:电化学发光|化学发光|电发光|发光法|酶免法)$');
  static final _testSuffix = RegExp(r'(?:测定|检测|定量|定性)$');

  /// "嗜酸细胞""嗜碱细胞"是嗜酸性、嗜碱性粒细胞的简称；"相对值"即百分数
  /// （2026 年的报告这样写，数值本身是百分数，不用换算）。
  static final _wbcDifferential = RegExp(
      r'^(中性粒细胞|淋巴细胞|单核细胞|嗜酸性粒细胞|嗜碱性粒细胞|嗜酸细胞|嗜碱细胞)'
      r'(比值|比例|百分比|百分率|百分数|相对值|%|计数|绝对值|数目)$');
  /// 红细胞分布宽度：RDW-CV / RDW-SD 的各种写法（"红细胞体积分布宽度-CV"
  /// "红细胞分布宽度-变异系数""红细胞体积分布宽度标准差"）。
  static final _rdw = RegExp(
      r'^红细胞(?:体积)?分布宽度[-－]?(CV|SD|变异系数|标准差)$',
      caseSensitive: false);
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
    '红细胞比积': '红细胞压积',
    '血细胞比容': '红细胞压积',
    '血小板比积': '血小板压积',
    '血小板比容': '血小板压积',
    '血小板平均体积': '平均血小板体积',
    // 红细胞参数（2026-10-20 用户数据：同一指标三家医院三种叫法）。
    // 含量（MCH，pg）和浓度（MCHC，g/L）是两个指标，不合。
    '平均血红蛋白含量': '平均红细胞血红蛋白含量',
    '平均血红蛋白量': '平均红细胞血红蛋白含量',
    '平均红细胞血红蛋白量': '平均红细胞血红蛋白含量',
    '平均血红蛋白浓度': '平均红细胞血红蛋白浓度',
    '红细胞平均体积': '平均红细胞体积',
    '血小板体积分布宽度': '血小板分布宽度',
    '血小板容积分布宽度': '血小板分布宽度',
    '促甲状腺激素': '促甲状腺素',
    '甘油三脂': '甘油三酯',
    '血肌酐': '肌酐',
    '血尿酸': '尿酸',
    // 尿胆素原只在尿里查，大项没识别出来时也归尿胆原。
    '尿胆素原': '尿胆原',
  };

  /// 白细胞分类写成小数比值（0.481，参考 0.5-0.7）时换算成百分数的倍数：
  /// 名字是比值类、没有单位或单位是"-"、参考上限（没有时看数值）不超过 1，
  /// 才乘 100；已经是百分数的返回 1。
  ///
  /// 红细胞压积同理：有的报告写 0.45（单位 L/L 或不写），有的写 45%
  /// （2026-10-20 用户数据）。
  ///
  /// 血小板压积按百分数是 0.1–0.3（"0.25"），写成小数是 0.001–0.003
  /// （"0.0022"，参考 0.0011-0.0028），两种都不带 %；按量级判断，参考上限
  /// （没有时看数值）小于 0.05 的乘 100。单位只看是不是 %：有报告把它的
  /// 单位印成了 fL。
  static double labPercentFactor(Map<Object?, Object?> r) {
    final name = r['item_name_raw'];
    if (name is! String) return 1;
    final unit = '${r['unit_raw'] ?? ''}'.trim();
    final key = labKey(name, panel: r['panel_raw'] as String?);
    if (key == '血小板压积') {
      if (unit == '%') return 1;
      final scale = (r['ref_high'] as num?) ?? (r['value_num'] as num?);
      return scale != null && scale < 0.05 ? 100 : 1;
    }
    if (key == '红细胞压积') {
      if (unit.isNotEmpty && unit != '-' && unit.toLowerCase() != 'l/l') {
        return 1;
      }
    } else {
      final raw = itemName(name)
          .replaceAll(_dropParen, '')
          .replaceAll(RegExp(r'\s'), '');
      final m = _wbcDifferential.firstMatch(raw);
      if (m == null || !RegExp(r'比值|比例').hasMatch(m[2]!)) return 1;
      if (unit.isNotEmpty && unit != '-') return 1;
    }
    final scale = (r['ref_high'] as num?) ?? (r['value_num'] as num?);
    return scale != null && scale <= 1 ? 100 : 1;
  }

  /// 血压写成一项"收缩压/舒张压"（"122/86"，参考"90-139/60-89"）时拆成
  /// 收缩压、舒张压两项，和分开写的报告画在同一条趋势上（D-39）。只在建
  /// 索引时拆，记录按报告原样保存。不是这种写法的返回 null。
  static List<Map<String, Object?>>? splitBloodPressure(
      Map<Object?, Object?> r) {
    final name = r['item_name_raw'];
    if (name is! String || labKey(name) != '血压') return null;
    final unit = '${r['unit_raw'] ?? ''}';
    final value = RegExp(r'^(\d{2,3}(?:\.\d+)?)\s*/\s*(\d{2,3}(?:\.\d+)?)$')
        .firstMatch('${r['value_raw'] ?? ''}'
            .replaceAll(RegExp(r'mmhg', caseSensitive: false), '')
            .trim());
    if (value == null) return null;
    // 没用斜杠分开的：参考范围对不上哪一项，不要；异常标记两项都带上。
    List<String?> halves(Object? raw, {required bool share}) {
      if (raw is! String) return const [null, null];
      final parts = raw.split(RegExp(r'[/／]'));
      if (parts.length == 2) return [parts[0].trim(), parts[1].trim()];
      return share ? [raw, raw] : const [null, null];
    }

    final refs = halves(r['ref_range_raw'], share: false);
    final flags = halves(r['flag_raw'], share: true);
    final range = RegExp(r'^(\d+(?:\.\d+)?)\s*[-~～—]\s*(\d+(?:\.\d+)?)$');
    return [
      for (final (i, label) in ['收缩压', '舒张压'].indexed)
        {
          'item_name_raw': label,
          'value_raw': value[i + 1],
          'value_num': double.parse(value[i + 1]!),
          'unit_raw': unit.isEmpty ? 'mmHg' : unit,
          'ref_range_raw': refs[i],
          'ref_low': double.tryParse(
              range.firstMatch(refs[i] ?? '')?.group(1) ?? ''),
          'ref_high': double.tryParse(
              range.firstMatch(refs[i] ?? '')?.group(2) ?? ''),
          'flag_raw': (flags[i]?.isEmpty ?? true) ? null : flags[i],
        },
    ];
  }

  /// 没测的占位值（"-""—""未测"）：留在报告核对里，不进趋势。
  static bool isPlaceholderValue(String valueRaw) => RegExp(
          r'^[\s\-—–－/]*$|^未[测查做检]$')
      .hasMatch(valueRaw);

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
