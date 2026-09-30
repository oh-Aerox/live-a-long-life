import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/same_item.dart';

void main() {
  test('检验项目键：去英文缩写、检测方法、斜杠缩写，中文说明保留', () {
    expect(SameItem.labKey('天门冬氨酸氨基转移酶（AST）'), '天门冬氨酸氨基转移酶');
    expect(SameItem.labKey('中性粒细胞绝对值（GRA#）'), '中性粒细胞绝对值');
    expect(SameItem.labKey('甲胎蛋白(AFP)（酶免法）'), '甲胎蛋白');
    expect(SameItem.labKey('体重指数/BMI'), '体重指数');
    expect(SameItem.labKey('F-PSA/T-PSA'), 'F-PSA/T-PSA');
    expect(SameItem.labKey('白细胞（尿沉渣）'), '白细胞（尿沉渣）');
    expect(SameItem.labKey('血 红 蛋白'), '血红蛋白');
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
}
