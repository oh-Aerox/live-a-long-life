import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/condition_entry.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/services/condition_category.dart';

ConditionEntry entry(String id, String name, String date,
        {String? mergedInto}) =>
    ConditionEntry(
      RecordRow(
        id: id,
        userId: 'u',
        createdAt: 0,
        createdOnDevice: 'd',
        version: 1,
        recordType: RecordType.condition,
        localDate: date,
        currentRevisionId: 'r-$id',
      ),
      RecordRevision(
        id: 'r-$id',
        recordId: id,
        recordVersion: 1,
        userId: 'u',
        createdAt: 0,
        createdOnDevice: 'd',
        version: 1,
        occurred: '{}',
        data: '{}',
        fieldMeta: '{}',
        producedBy: '{}',
      ),
      {
        'name': name,
        'persistence': 'long_term',
        'status': 'active',
        'group_name': ?mergedInto,
      },
      const FieldMetaMap({}),
    );

void main() {
  test('分组：同义写法自动归一组，组内新的在前，组按最新日期排', () {
    final groups = ConditionEntry.groups([
      entry('a', '变应性鼻炎', '2026-03-23'),
      entry('b', '胆囊结石（多发）', '2024-12-10'),
      entry('c', '过敏性鼻炎［变应性鼻炎］', '2024-05-30'),
      entry('d', '胆囊结石', '2023-11-30'),
    ]);
    expect([for (final g in groups) g.map((e) => e.record.id).toList()], [
      ['a', 'c'],
      ['b', 'd'],
    ]);
  });

  test('手动合并（D-46）：合并过的按合并到的名字归组；以后报告里的旧写法也跟着归进来', () {
    final groups = ConditionEntry.groups([
      entry('new', '轻度慢性非萎缩性胃炎', '2025-12-09'),
      entry('old', '胃炎', '2024-05-30', mergedInto: '轻度慢性非萎缩性胃炎'),
      // 以后的报告又写了"胃炎"，没有合并标记：和已合并的原名相同，归进来。
      entry('later', '胃炎', '2026-06-01'),
      entry('other', '皮疹', '2026-01-27'),
    ]);
    expect([for (final g in groups) g.map((e) => e.record.id).toList()], [
      ['later', 'new', 'old'],
      ['other'],
    ]);
  });

  test('按身体系统分类', () {
    expect(conditionCategory('正常高值血压'), '心血管');
    expect(conditionCategory('窦性心律不齐'), '心血管');
    expect(conditionCategory('胆囊结石（多发）'), '消化');
    expect(conditionCategory('前列腺钙化灶'), '泌尿生殖与乳腺');
    expect(conditionCategory('超重'), '内分泌与代谢');
    expect(conditionCategory('颈椎生理曲度变直'), '骨骼肌肉');
    expect(conditionCategory('腕关节扭伤'), '骨骼肌肉');
    expect(conditionCategory('寻常疣'), '皮肤');
    expect(conditionCategory('变应性鼻炎'), '眼耳鼻喉口腔');
    expect(conditionCategory('飞蚊症'), '眼耳鼻喉口腔');
    expect(conditionCategory('支气管哮喘'), '呼吸');
    expect(conditionCategory('酒精过敏'), '过敏与免疫');
    expect(conditionCategory('风热感冒证'), '感染');
    expect(conditionCategory('湿热证'), '其他');
  });
}
