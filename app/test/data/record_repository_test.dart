import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';

import 'test_helpers.dart';

TimeValue dateOnly(String date) => TimeValue(
      localDate: date,
      precision: TimePrecision.dateOnly,
      source: TimeValueSource.userStated,
    );

void main() {
  late TestEnv env;
  late RecordRepository records;

  setUp(() async {
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  test('新建记录写入第 1 版、来源链接和冗余日期', () async {
    final rec = await records.create(
      recordType: RecordType.meal,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"status":"eaten","meal_slot":"dinner","description":"面"}',
      fieldMeta: const FieldMetaMap({
        'description': FieldMeta(
            origin: FieldOrigin.userStated,
            reviewStatus: ReviewStatus.unreviewed),
      }),
      producedBy: ProducedBy.organizeRun('run-1'),
      sources: const [
        SourceLink(
            sourceKind: RecordSourceKind.message,
            sourceId: 'msg-1',
            messageRevisionNo: 0),
      ],
    );

    expect(rec.version, 1);
    expect(rec.localDate, '2026-09-26');
    expect(rec.currentRevisionId, isNotNull);

    final rev = await records.currentRevisionOf(rec.id);
    expect(rev.recordVersion, 1);
    expect(rev.baseVersion, isNull);
    expect(ProducedBy.decode(rev.producedBy).kind, 'organize_run');

    final sources = await records.sourcesOf(rev.id);
    expect(sources, hasLength(1));
    expect(sources.single.sourceId, 'msg-1');
    expect(sources.single.messageRevisionNo, 0);
  });

  test('预生成的记录 ID 原样使用（整理项提交前有稳定身份）', () async {
    final rec = await records.create(
      recordId: 'pre-generated-id',
      recordType: RecordType.note,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"text":"x"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );
    expect(rec.id, 'pre-generated-id');
  });

  test('追加版本：版本递增、历史保留、冗余日期跟随新版本', () async {
    final rec = await records.create(
      recordType: RecordType.sleep,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"quality_text":"还行"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );

    final updated = await records.addRevision(
      recordId: rec.id,
      baseVersion: 1,
      occurred: dateOnly('2026-09-25'),
      dataJson: '{"quality_text":"不好"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );

    expect(updated.version, 2);
    expect(updated.localDate, '2026-09-25');

    final revs = await records.revisionsOf(rec.id);
    expect(revs.map((r) => r.recordVersion), [1, 2]);
    expect(revs.last.baseVersion, 1);
    expect(ProducedBy.decode(revs.last.producedBy).kind, 'user_edit');
    // 旧版本原样保留。
    expect(revs.first.data, contains('还行'));
  });

  test('目标版本不符时抛 StaleTargetException，什么都不写（D-05）', () async {
    final rec = await records.create(
      recordType: RecordType.mood,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"description":"平静"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );
    await records.addRevision(
      recordId: rec.id,
      baseVersion: 1,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"description":"开心"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );

    // 另一个写入方还基于版本 1。
    await expectLater(
      records.addRevision(
        recordId: rec.id,
        baseVersion: 1,
        occurred: dateOnly('2026-09-26'),
        dataJson: '{"description":"烦躁"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('run-2'),
      ),
      throwsA(isA<StaleTargetException>()),
    );

    final revs = await records.revisionsOf(rec.id);
    expect(revs, hasLength(2));
    final cur = await records.currentRevisionOf(rec.id);
    expect(cur.data, contains('开心'));
  });

  test('按日查询不含已删除记录', () async {
    final a = await records.create(
      recordType: RecordType.meal,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"meal_slot":"lunch","status":"eaten"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );
    await records.create(
      recordType: RecordType.meal,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"meal_slot":"dinner","status":"eaten"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );

    final deleted = await records.markDeleted(a.id);
    expect(deleted.version, 2);

    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(1));
    expect(day.single.id, isNot(a.id));
  });

  test('同一天两次运动是两条记录，互不覆盖（A-30）', () async {
    final run = await records.create(
      recordType: RecordType.exercise,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"status":"done","activity":"跑步","duration_text":"30 分钟"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );
    final swim = await records.create(
      recordType: RecordType.exercise,
      occurred: dateOnly('2026-09-26'),
      dataJson: '{"status":"done","activity":"游泳","duration_text":"1 小时"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-1'),
    );

    expect(run.id, isNot(swim.id));
    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(2));
  });

  test('TimeValue 往返编码保持字段', () async {
    final tv = TimeValue(
      instantUtcMs: 1758852000000,
      tz: 'Asia/Shanghai',
      localDate: '2026-09-26',
      precision: TimePrecision.approx,
      source: TimeValueSource.userStated,
      dateAmbiguous: true,
      rawText: '昨晚大概一点',
    );
    final back = TimeValue.decode(tv.encode());
    expect(back.instantUtcMs, tv.instantUtcMs);
    expect(back.tz, 'Asia/Shanghai');
    expect(back.precision, TimePrecision.approx);
    expect(back.dateAmbiguous, isTrue);
    expect(back.rawText, '昨晚大概一点');
  });

  test('TimeValue 不变式：unknown 精度不得携带时刻，非 unknown 必须有日期', () {
    expect(
      () => TimeValue(
        instantUtcMs: 1,
        precision: TimePrecision.unknown,
        source: TimeValueSource.userStated,
      ),
      throwsArgumentError,
    );
    expect(
      () => TimeValue(
        precision: TimePrecision.dateOnly,
        source: TimeValueSource.userStated,
      ),
      throwsArgumentError,
    );
  });
}
