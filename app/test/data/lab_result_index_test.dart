import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  test('创建 lab_panel：索引行同事务生成，itemKey 去空白与英文缩写（schema §5.3，D-32）',
      () async {
    await createPanel('2026-09-20', '145', num_: 145);
    final rows = await env.db.select(env.db.labResults).get();
    expect(rows, hasLength(1));
    expect(rows.single.itemKey, '血红蛋白');
    expect(rows.single.valueNum, 145);
    expect(rows.single.examDate, '2026-09-20');
    expect(rows.single.medicalDocumentId, 'doc-1');
    expect(rows.single.reviewStatus, ReviewStatus.unreviewed);
    // 派生表不入变更日志（D-27）。
    final changes = await env.db.select(env.db.changeLogs).get();
    expect(changes.where((c) => c.entityType == 'lab_results'), isEmpty);
  });

  test('2019 比值与 2022 百分数进同一条趋势：比值换算成百分数，原文留在参考说明',
      () async {
    Future<void> panel(String date, Map<String, Object?> result) =>
        records.create(
          recordType: RecordType.labPanel,
          occurred: day(date),
          dataJson: jsonEncode({
            'medical_document_id': 'doc-$date',
            'results': [result],
          }),
          fieldMeta: FieldMetaMap({}),
          producedBy: ProducedBy.medicalExtract('call-$date'),
        );
    await panel('2019-05-11', {
      'item_name_raw': '中性粒细胞比值（GRA）',
      'value_raw': '0.481',
      'value_num': 0.481,
      'unit_raw': '-',
      'ref_range_raw': '0.5- 0.7',
      'ref_low': 0.5,
      'ref_high': 0.7,
      'flag_raw': '↓',
    });
    await panel('2022-07-17', {
      'item_name_raw': '中性粒细胞百分数（GRA%）',
      'value_raw': '53.30',
      'value_num': 53.3,
      'unit_raw': '%',
      'ref_range_raw': '40- 75',
      'ref_low': 40,
      'ref_high': 75,
      'flag_raw': null,
    });

    final history = await records.labResultHistory('中性粒细胞百分数');
    expect(history, hasLength(2));
    final old = history.first;
    expect(old.examDate, '2019-05-11');
    expect(old.valueNum, closeTo(48.1, 1e-9));
    expect(old.valueRaw, '48.1');
    expect(old.unitRaw, '%');
    expect(old.refLow, closeTo(50, 1e-9));
    expect(old.refHigh, closeTo(70, 1e-9));
    expect(old.refRangeRaw, '50-70（原文为比值 0.481，参考 0.5- 0.7）');
    expect(old.flagRaw, '↓');
    expect(history.last.valueNum, 53.3);
    expect(history.last.refRangeRaw, '40- 75');
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

  test('检查大项进索引；尿常规的白细胞与血常规的分开建键（D-36）', () async {
    await records.create(
      recordType: RecordType.labPanel,
      occurred: day('2022-07-17'),
      dataJson: jsonEncode({
        'medical_document_id': 'doc-1',
        'results': [
          {'panel_raw': '血常规', 'item_name_raw': '白细胞计数（WBC）', 'value_raw': '5.33', 'value_num': 5.33},
          {'panel_raw': '尿常规', 'item_name_raw': '白细胞(LEU)', 'value_raw': 'neg'},
          {'panel_raw': '尿常规', 'item_name_raw': '比重（SG）', 'value_raw': '1.025', 'value_num': 1.025},
        ],
      }),
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.medicalExtract('call-1'),
    );
    final rows = await (env.db.select(env.db.labResults)
          ..orderBy([(t) => OrderingTerm.asc(t.resultIndex)]))
        .get();
    expect([for (final r in rows) r.itemKey], ['白细胞计数', '尿白细胞', '尿比重']);
    expect(rows[1].panelRaw, '尿常规');
    expect(await records.labResultHistory('尿比重'), hasLength(1));
  });
  test('识别修正只写进 ocr_fixes 的单位：启动修复按说明改字段，已核对的不动', () async {
    Map<String, Object?> rbc(String name) => {
          'item_name_raw': name,
          'value_raw': '4.86',
          'value_num': 4.86,
          'unit_raw': '*1012/L',
          'ref_range_raw': '4.3-5.8',
          'ref_low': 4.3,
          'ref_high': 5.8,
          'flag_raw': null,
          'locator': [],
          'ocr_fixes': ['*1012/L→*10^12/L'],
        };
    final rec = await records.create(
      recordType: RecordType.labPanel,
      occurred: day('2026-10-01'),
      dataJson: jsonEncode({
        'results': [rbc('红细胞计数'), rbc('网织红细胞计数')],
      }),
      fieldMeta: FieldMetaMap({
        'results.0': const FieldMeta(
            origin: FieldOrigin.modelInferred,
            reviewStatus: ReviewStatus.unreviewed),
        'results.1': const FieldMeta(
            origin: FieldOrigin.modelInferred,
            reviewStatus: ReviewStatus.confirmed),
      }),
      producedBy: ProducedBy.medicalExtract('call-1'),
    );

    expect(await records.repairUnappliedOcrFixes(), 1);
    expect(await records.repairUnappliedOcrFixes(), 0); // 幂等

    final rows = await (env.db.select(env.db.labResults)
          ..where((t) => t.recordId.equals(rec.id))
          ..orderBy([(t) => OrderingTerm.asc(t.resultIndex)]))
        .get();
    expect(rows[0].unitRaw, '*10^12/L');
    expect(rows[0].valueRaw, '4.86');
    expect(rows[1].unitRaw, '*1012/L'); // 用户已确认，不改
  });
}
