import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/consult_suggestions.dart';
import 'package:live_a_long_life/services/health_service.dart';

import '../data/test_helpers.dart';

const unreviewed = FieldMeta(
    origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.unreviewed);
const confirmed = FieldMeta(
    origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.confirmed);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late RecordRepository records;
  late Map<String, DeviceDayData> device;
  late bool live;
  final now = DateTime(2026, 10, 27, 10);

  setUp(() async {
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
    device = {};
    live = false;
  });

  tearDown(() => env.dispose());

  Future<List<SuggestionGroup>> build() => buildConsultSuggestions(
        db: env.db,
        records: records,
        deviceData: (date) async =>
            device[date] ??
            const DeviceDayData(
                sleep: null, workouts: [], steps: null, activeEnergyKcal: null),
        liveAvailable: () async => live,
        now: now,
      );

  Future<void> add(String date, RecordType type, Map<String, Object?> data,
          [Map<String, FieldMeta> meta = const {}]) =>
      records.create(
        recordType: type,
        occurred: TimeValue(
            localDate: date,
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: jsonEncode(data),
        fieldMeta: FieldMetaMap(meta),
        producedBy: ProducedBy.userEdit(),
      );

  HealthSample workout(DateTime start, String type) => HealthSample(
        id: 'w',
        userId: 'u',
        createdAt: 0,
        createdOnDevice: 'd',
        version: 1,
        platformUuid: 'p',
        sampleType: HealthSampleType.workout,
        startUtc: start.millisecondsSinceEpoch,
        endUtc: start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
        tz: 'Asia/Shanghai',
        tzInferred: true,
        workoutType: type,
        sourceName: 'Apple Watch',
        fetchedAt: 0,
      );

  test('没有任何数据：只给不依赖数据的常见问题', () async {
    final groups = await build();
    expect(groups.single.key, 'general');
    expect(groups.single.needsLookup, isFalse);
  });

  test('按本机数据生成：类别顺序固定，问题里带上最近一次训练、异常指标和状况名', () async {
    device['2026-10-26'] = DeviceDayData(
      sleep: null,
      workouts: [workout(DateTime(2026, 10, 26, 18), 'cycling')],
      steps: 5000,
      activeEnergyKcal: null,
    );
    await add('2026-10-25', RecordType.sleep, {'quality_text': '还行'});
    await add('2026-10-26', RecordType.meal,
        {'status': 'eaten', 'description': '面'});
    await add('2025-05-01', RecordType.labPanel, {
      'results': [
        {'item_name_raw': '血红蛋白', 'value_raw': '140', 'value_num': 140,
         'ref_low': 130, 'ref_high': 175},
        {'item_name_raw': '尿酸', 'value_raw': '400', 'value_num': 400,
         'ref_low': 208, 'ref_high': 428},
      ],
      'findings': [
        {'section_raw': '结论', 'text_raw': '未见异常'},
      ],
    }, {
      'results.0': confirmed,
      'results.1': confirmed,
      'findings.0': confirmed,
    });
    await add('2026-05-01', RecordType.labPanel, {
      'results': [
        {'item_name_raw': '血红蛋白', 'value_raw': '145', 'value_num': 145,
         'ref_low': 130, 'ref_high': 175},
        {'item_name_raw': '尿酸', 'value_raw': '520', 'value_num': 520,
         'ref_low': 208, 'ref_high': 428},
        // 未核对的异常不拿来出题（D-04）。
        {'item_name_raw': '血糖', 'value_raw': '9.1', 'value_num': 9.1,
         'ref_low': 3.9, 'ref_high': 6.1},
      ],
    }, {
      'results.0': confirmed,
      'results.1': confirmed,
      'results.2': unreviewed,
    });
    await add('2025-01-01', RecordType.condition,
        {'name': '胆囊结石', 'persistence': 'long_term', 'status': 'active'},
        {'condition': confirmed});
    await add('2025-01-01', RecordType.condition,
        {'name': '甲状腺结节', 'persistence': 'long_term', 'status': 'active'},
        {'condition': unreviewed});

    final groups = await build();
    expect(groups.map((g) => g.key),
        ['sleep', 'exercise', 'labs', 'reports', 'conditions', 'daily']);
    final byKey = {for (final g in groups) g.key: g};
    // 不能实时读取时，训练只问强度不问心率。
    expect(byKey['exercise']!.questions.first, '10月26日的骑行强度合适吗？');
    expect(byKey['labs']!.questions,
        contains('尿酸偏高，平时要注意什么？'));
    expect(byKey['labs']!.questions.join(), isNot(contains('血糖')));
    expect(byKey['labs']!.questions, contains('尿酸这几年变化如何？'));
    expect(byKey['conditions']!.questions.first, '胆囊结石平时饮食要注意什么？');
    expect(byKey['conditions']!.needsLookup, isFalse);
    expect(byKey['daily']!.questions, ['这周饮食有什么问题？']);
  });

  test('能实时读取时：训练问心率，另加心率血氧类别', () async {
    live = true;
    device['2026-10-24'] = DeviceDayData(
      sleep: null,
      workouts: [workout(DateTime(2026, 10, 24, 7), 'running')],
      steps: null,
      activeEnergyKcal: null,
    );
    final groups = await build();
    final byKey = {for (final g in groups) g.key: g};
    expect(byKey['exercise']!.questions.first, '10月24日跑步时心率怎么样？');
    expect(byKey.containsKey('vitals'), isTrue);
  });

  test('超过 7 天的数据不出题', () async {
    device['2026-10-15'] = DeviceDayData(
      sleep: null,
      workouts: [workout(DateTime(2026, 10, 15, 7), 'running')],
      steps: null,
      activeEnergyKcal: null,
    );
    await add('2026-10-10', RecordType.meal,
        {'status': 'eaten', 'description': '面'});
    final groups = await build();
    expect(groups.single.key, 'general');
  });
}
