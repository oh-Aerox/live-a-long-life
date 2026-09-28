import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
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

  TimeValue day(String d) => TimeValue(
      localDate: d,
      precision: TimePrecision.dateOnly,
      source: TimeValueSource.userStated);

  Map<String, Object?> hb(String value, {num? num_}) => {
        'item_name_raw': '血红蛋白 (HGB)',
        'value_raw': value,
        'value_num': num_,
        'unit_raw': 'g/L',
        'ref_range_raw': '130-175',
        'ref_low': 130,
        'ref_high': 175,
        'flag_raw': null,
        'locator': [],
      };

  Future<RecordRow> createPanel(String date, String value, {num? num_}) =>
      records.create(
        recordType: RecordType.labPanel,
        occurred: day(date),
        dataJson: jsonEncode({
          'medical_document_id': 'doc-1',
          'results': [hb(value, num_: num_)],
        }),
        fieldMeta: FieldMetaMap({
          'results.0': const FieldMeta(
              origin: FieldOrigin.modelInferred,
              reviewStatus: ReviewStatus.unreviewed),
        }),
        producedBy: ProducedBy.medicalExtract('call-1'),
      );

  test('创建 lab_panel：索引行同事务生成，itemKey 去空白（schema §5.3）',
      () async {
    await createPanel('2026-09-20', '145', num_: 145);
    final rows = await env.db.select(env.db.labResults).get();
    expect(rows, hasLength(1));
    expect(rows.single.itemKey, '血红蛋白(HGB)');
    expect(rows.single.valueNum, 145);
    expect(rows.single.examDate, '2026-09-20');
    expect(rows.single.medicalDocumentId, 'doc-1');
    expect(rows.single.reviewStatus, ReviewStatus.unreviewed);
    // 派生表不入变更日志（D-27）。
    final changes = await env.db.select(env.db.changeLogs).get();
    expect(changes.where((c) => c.entityType == 'lab_results'), isEmpty);
  });

  test('核对出新版本：索引随版本重建，核对状态跟上', () async {
    final rec = await createPanel('2026-09-20', '145', num_: 145);
    await records.addRevision(
      recordId: rec.id,
      baseVersion: rec.version,
      occurred: day('2026-09-20'),
      dataJson: jsonEncode({
        'medical_document_id': 'doc-1',
        'results': [hb('148', num_: 148)],
      }),
      fieldMeta: FieldMetaMap({
        'results.0': const FieldMeta(
            origin: FieldOrigin.userEdited,
            reviewStatus: ReviewStatus.confirmed),
      }),
      producedBy: ProducedBy.userEdit(),
    );
    final rows = await env.db.select(env.db.labResults).get();
    expect(rows, hasLength(1));
    expect(rows.single.valueNum, 148);
    expect(rows.single.reviewStatus, ReviewStatus.confirmed);
  });

  test('按项目查历史：跨记录按检查日期升序（趋势数据源）', () async {
    await createPanel('2026-03-10', '138', num_: 138);
    await createPanel('2026-09-20', '145', num_: 145);
    final history =
        await records.labResultHistory(RecordRepository.labItemKey('血红蛋白 (HGB)'));
    expect(history.map((r) => r.valueNum).toList(), [138, 145]);
    expect(history.map((r) => r.examDate).toList(),
        ['2026-03-10', '2026-09-20']);
  });

  test('删除记录：索引行清掉；整表重建可恢复', () async {
    final a = await createPanel('2026-03-10', '138', num_: 138);
    await createPanel('2026-09-20', '145', num_: 145);
    await records.markDeleted(a.id);
    expect(await env.db.select(env.db.labResults).get(), hasLength(1));

    // 人为清空后重建（升级/Mac 收到同步后的场景）。
    await env.db.delete(env.db.labResults).go();
    final rebuilt = await records.rebuildLabResultIndex();
    expect(rebuilt, 1); // 已删除的记录不回来
    final rows = await env.db.select(env.db.labResults).get();
    expect(rows.single.examDate, '2026-09-20');
  });
}
