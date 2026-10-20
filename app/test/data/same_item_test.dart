import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/same_item.dart';

void main() {
  test('互认标记：项目名前后的"*""★"等去掉，和不带标记的同一项目合并', () {
    expect(SameItem.labKey('*白细胞计数'), SameItem.labKey('白细胞计数'));
    expect(SameItem.labKey('＊ 血红蛋白(HGB)'), SameItem.labKey('血红蛋白'));
    expect(SameItem.labKey('★谷丙转氨酶'), SameItem.labKey('谷丙转氨酶'));
    expect(SameItem.labKey('※尿酸*'), SameItem.labKey('尿酸'));
    expect(SameItem.labKey('*白细胞', panel: '尿常规'), '尿白细胞');
    expect(SameItem.itemName('*白细胞计数'), '白细胞计数');
    expect(SameItem.itemName('中性粒细胞绝对值（GRA#）'), '中性粒细胞绝对值（GRA#）');
    expect(SameItem.itemName('*'), '*');
  });

  test('检验项目键：去英文缩写、检测方法、斜杠缩写，中文说明保留', () {
    expect(SameItem.labKey('天门冬氨酸氨基转移酶（AST）'), '天门冬氨酸氨基转移酶');
    expect(SameItem.labKey('中性粒细胞绝对值（GRA#）'), '中性粒细胞绝对值');
    expect(SameItem.labKey('甲胎蛋白(AFP)（酶免法）'), '甲胎蛋白');
    expect(SameItem.labKey('体重指数/BMI'), '体重指数');
    expect(SameItem.labKey('F-PSA/T-PSA'), 'F-PSA/T-PSA');
    expect(SameItem.labKey('白细胞（尿沉渣）'), '白细胞（尿沉渣）');
    expect(SameItem.labKey('血 红 蛋白'), '血红蛋白');
  });

  test('同一指标的不同写法归到一个键（D-32 补充，用户 2019 与 2022 体检实测）', () {
    // 白细胞分类：比值 / 百分数 → 百分数；计数 / 绝对值 → 绝对值。
    expect(SameItem.labKey('中性粒细胞比值（GRA）'), '中性粒细胞百分数');
    expect(SameItem.labKey('中性粒细胞百分数（GRA%）'), '中性粒细胞百分数');
    expect(SameItem.labKey('淋巴细胞百分比'), '淋巴细胞百分数');
    expect(SameItem.labKey('淋巴细胞计数'), '淋巴细胞绝对值');
    expect(SameItem.labKey('单核细胞绝对值(MONO#)'), '单核细胞绝对值');
    // 联合检测、不带括号的检测方法、测定 / 检测 / 定量。
    expect(SameItem.labKey('甲胎蛋白（联）'), SameItem.labKey('甲胎蛋白(AFP)（酶免法）'));
    expect(SameItem.labKey('前列腺特异性抗原（联）'),
        SameItem.labKey('前列腺特异性抗原（T-PSA）（发光法）'));
    expect(SameItem.labKey('促甲状腺素（TSH）电发光'), '促甲状腺素');
    expect(SameItem.labKey('幽门螺杆菌抗体检测'), SameItem.labKey('幽门螺杆菌抗体定量'));
    expect(SameItem.labKey('抗甲状腺球蛋白抗体测定（TG-Ab）（发光法）'), '抗甲状腺球蛋白抗体');
    expect(SameItem.labKey('升主动脉内径 AOD'), '升主动脉内径');
    // 常见别名。
    expect(SameItem.labKey('谷丙转氨酶'), SameItem.labKey('丙氨酸氨基转移酶（ALT）'));
    expect(SameItem.labKey('γ-谷氨酰转肽酶'), SameItem.labKey('γ-谷氨酰转移酶（GGT）'));
    // 不该合的仍分开：尿常规的白细胞与血常规的白细胞计数、真正的比值。
    expect(SameItem.labKey('白细胞(LEU)'), isNot(SameItem.labKey('白细胞计数（WBC）')));
    expect(SameItem.labKey('E/A比值'), 'E/A比值');
    expect(SameItem.labKey('EB病毒衣壳抗原IgA抗体（联）'), 'EB病毒衣壳抗原IgA抗体');
    // 去掉后缀剩不到两个字的不去。
    expect(SameItem.labKey('检测'), '检测');
  });

  test('白细胞分类写成小数比值才换算成百分数', () {
    Map<String, Object?> r(String name, num v, {String? unit, num? high}) =>
        {'item_name_raw': name, 'value_num': v, 'unit_raw': unit, 'ref_high': high};
    expect(SameItem.labPercentFactor(r('中性粒细胞比值（GRA）', 0.481, unit: '-', high: 0.7)), 100);
    expect(SameItem.labPercentFactor(r('淋巴细胞比值', 0.41)), 100);
    // 已经是百分数、带 % 单位、或数值本来就大于 1 的不动。
    expect(SameItem.labPercentFactor(r('中性粒细胞百分数（GRA%）', 53.3, unit: '%', high: 75)), 1);
    expect(SameItem.labPercentFactor(r('淋巴细胞比值', 36.2, unit: '%')), 1);
    expect(SameItem.labPercentFactor(r('淋巴细胞比值', 36.2)), 1);
    expect(SameItem.labPercentFactor(r('E/A比值', 0.8)), 1);
  });

  test('同一份报告汇总与明细重复的检验结果只留信息更全的', () {
    final out = SameItem.dedupeResults([
      {'item_name_raw': '天门冬氨酸氨基转移酶', 'value_raw': '12.7U/L', 'value_num': 12.7, 'unit_raw': 'U/L', 'flag_raw': '低'},
      {'item_name_raw': '身高', 'value_raw': '165', 'value_num': 165},
      {'item_name_raw': '天门冬氨酸氨基转移酶（AST）', 'value_raw': '12.7', 'value_num': 12.7, 'unit_raw': 'U/L', 'ref_range_raw': '15.00- 40.00', 'flag_raw': '↓'},
      // 同项目不同数值（两次测量）都留。
      {'item_name_raw': '血压', 'value_raw': '121/81'},
      {'item_name_raw': '血压', 'value_raw': '118/79'},
    ]);
    expect(out.map((r) => r['item_name_raw']),
        ['身高', '天门冬氨酸氨基转移酶（AST）', '血压', '血压']);
  });

  test('同一问题：汇总与明细写法不同、程度不同都算同一个', () {
    expect(SameItem.sameProblem('脂肪肝（轻度）', '脂肪肝（中度）'), isTrue);
    expect(SameItem.sameProblem('颈椎轻度骨质增生', '颈（3）-（6）椎体缘轻度骨质增生'), isTrue);
    expect(SameItem.sameProblem('胆结石', '胆囊结石（多发）'), isTrue);
    expect(SameItem.sameProblem('腹部超声提示：脂肪肝（中度）', '脂肪肝'), isTrue);
    expect(SameItem.sameProblem('前列腺囊肿', '前列腺钙化灶'), isFalse);
    expect(SameItem.sameProblem('颈椎生理曲度变直', '颈椎轻度骨质增生'), isFalse);
    expect(SameItem.sameProblem('肝囊肿', '肾囊肿'), isFalse);
    expect(SameItem.sameProblem('结膜炎', '结膜肉芽肿'), isFalse);
  });

  test('问题文字去序号与检查名前缀', () {
    expect(SameItem.problemText('3.耳鼻喉科提示：慢性鼻炎'), '慢性鼻炎');
    expect(SameItem.problemText('(1).肝囊肿'), '肝囊肿');
    expect(SameItem.problemText('脂肪肝（中度）'), '脂肪肝（中度）');
  });

  test('分组：组内新的在前，组按最新日期排', () {
    final items = [
      ('脂肪肝（轻度）', '2019-05-11'),
      ('肝囊肿', '2019-05-11'),
      ('脂肪肝（中度）', '2022-07-17'),
    ];
    final groups = SameItem.groups(items, (i) => i.$1, (i) => i.$2);
    expect(groups.map((g) => g.map((i) => i.$1).toList()), [
      ['脂肪肝（中度）', '脂肪肝（轻度）'],
      ['肝囊肿'],
    ]);
  });

  test('尿常规、便常规的项目键带标本（D-36，用户 2019/2022/2023 体检实测）', () {
    String urine(String name) => SameItem.labKey(name, panel: '尿常规');
    expect(urine('白细胞(LEU)'), '尿白细胞');
    expect(urine('葡萄糖(GLU)'), '尿糖');
    expect(urine('葡萄糖 （Glu）'), '尿糖');
    expect(urine('胆红素(BIL)'), '尿胆红素');
    expect(urine('蛋白质(PRO)'), '尿蛋白');
    expect(urine('隐血(ERY)'), '尿隐血');
    // 不同年份写法不同的对上。
    expect(urine('比重（SG）'), urine('尿比重'));
    expect(urine('尿胆原(UBG)'), urine('尿胆素原'));
    expect(urine('pH值(pH)'), urine('PH值'));
    expect(urine('pH值(pH)'), isNot(contains('尿酸')));
    // 镜检和干化学分开；与血里的同名项目分开。
    expect(urine('白细胞（高倍视野）'), isNot(urine('白细胞(LEU)')));
    expect(urine('葡萄糖(GLU)'), isNot(SameItem.labKey('葡萄糖(GLU)', panel: '血糖')));
    expect(SameItem.labKey('潜血', panel: '便常规'), '便隐血');
    // 血液类大项、没有大项的不加前缀，和旧数据一致。
    expect(SameItem.labKey('白细胞计数（WBC）', panel: '血常规'), '白细胞计数');
    expect(SameItem.labKey('尿酸（UA）', panel: '肾功能'), '尿酸');
    expect(SameItem.labKey('白细胞(LEU)'), '白细胞');
  });

  test('趋势分组名（D-36）', () {
    expect(SameItem.panelGroup('尿液分析'), '尿常规');
    expect(SameItem.panelGroup('尿沉渣'), '尿常规');
    expect(SameItem.panelGroup('粪便常规'), '便常规');
    expect(SameItem.panelGroup('尿微量白蛋白'), '尿微量白蛋白');
    expect(SameItem.panelGroup('肝功能检查'), '肝功能');
    expect(SameItem.panelGroup(' 血常规 '), '血常规');
    expect(SameItem.panelGroup(null), '其他');
  });
}
