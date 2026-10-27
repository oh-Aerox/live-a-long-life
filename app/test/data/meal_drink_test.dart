import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/record_summary.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late RecordRepository records;

  setUp(() async {
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  test('饮食摘要（D-47）：饮水显示"饮水"，没说哪一顿的不加"未知"前缀', () {
    expect(
        recordSummary(RecordType.meal,
            {'status': 'eaten', 'meal_slot': 'drink', 'description': '红茶'}),
        '饮水：红茶');
    expect(
        recordSummary(RecordType.meal,
            {'status': 'eaten', 'meal_slot': 'unknown', 'description': '苹果'}),
        '苹果');
    expect(
        recordSummary(RecordType.meal,
            {'status': 'eaten', 'meal_slot': 'lunch', 'description': '面'}),
        '午餐：面');
  });

  Future<RecordRow> meal(Map<String, Object?> data,
          {Map<String, FieldMeta> meta = const {}}) =>
      records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
            localDate: '2026-10-27',
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: jsonEncode(data),
        fieldMeta: FieldMetaMap(meta),
        producedBy: ProducedBy.organizeRun('r1'),
      );

  Future<Object?> slotOf(RecordRow r) async =>
      (jsonDecode((await records.currentRevisionOf(r.id)).data)
          as Map)['meal_slot'];

  test('修复（D-47）：未注明餐次且全是饮品的、模型自编"饮水"的归回 drink；其余不动', () async {
    final tea = await meal({
      'status': 'eaten',
      'meal_slot': 'unknown',
      'description': '今日饮水主要是红茶',
      'items': [
        {'name': '红茶'}
      ],
    });
    final invented = await meal({
      'status': 'eaten',
      'meal_slot': '饮水',
      'description': '喝红茶',
      'items': [
        {'name': '红茶'}
      ],
    });
    final apple = await meal({
      'status': 'eaten',
      'meal_slot': 'unknown',
      'items': [
        {'name': '苹果'},
        {'name': '牛奶'},
      ],
    });
    final lunchTea = await meal({
      'status': 'eaten',
      'meal_slot': 'lunch',
      'items': [
        {'name': '茶'}
      ],
    });
    // 用户核对过餐次的不动。
    final reviewed = await meal({
      'status': 'eaten',
      'meal_slot': 'unknown',
      'items': [
        {'name': '咖啡'}
      ],
    }, meta: {
      'meal_slot': const FieldMeta(
          origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited),
    });

    expect(await records.repairDrinkSlots(), 2);
    expect(await records.repairDrinkSlots(), 0); // 幂等
    expect(await slotOf(tea), 'drink');
    expect(await slotOf(invented), 'drink');
    expect(await slotOf(apple), 'unknown');
    expect(await slotOf(lunchTea), 'lunch');
    expect(await slotOf(reviewed), 'unknown');
    // 写的是新版本，旧版本保留。
    expect(await records.revisionsOf(tea.id), hasLength(2));
  });
}
