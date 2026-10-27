import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:live_a_long_life/services/health_live.dart';

/// 假数据源：按类型返回预置样本（只返回落在查询范围内的），记下每次查询。
class FakeLiveSource implements LiveHealthSource {
  final samples = <LiveSample>[];
  final stepsByDay = <String, int>{};
  final queries = <List<HealthDataType>>[];

  @override
  Future<List<LiveSample>> read(
      List<HealthDataType> types, DateTime start, DateTime end) async {
    queries.add(types);
    return [
      for (final s in samples)
        if (types.contains(s.type) &&
            !s.end.isBefore(start) &&
            s.start.isBefore(end))
          s
    ];
  }

  @override
  Future<int?> totalSteps(DateTime start, DateTime end) async =>
      stepsByDay['${start.month}-${start.day}'];
}

LiveSample sample(HealthDataType type, DateTime start,
        {DateTime? end, num? value, String? text, String source = 'Apple Watch',
        Map<String, Object?> extra = const {}}) =>
    LiveSample(
      type: type,
      start: start,
      end: end ?? start,
      source: source,
      value: value,
      text: text,
      unit: 'UNIT',
      extra: extra,
    );

void main() {
  late FakeLiveSource source;
  late HealthLiveReader reader;

  setUp(() {
    source = FakeLiveSource();
    reader = HealthLiveReader(source);
  });

  Future<(Map<String, Object?>, String)> read(
      String metric, DateTime start, DateTime end) async {
    final (content, note) = await reader.read(metric, start, end);
    return ((jsonDecode(content) as Map).cast<String, Object?>(), note);
  }

  final day = DateTime(2026, 10, 26);

  test('心率：点少时逐点给，统计最低/最高/平均；说明里写读了什么', () async {
    for (var i = 0; i < 3; i++) {
      source.samples.add(sample(HealthDataType.HEART_RATE,
          day.add(Duration(hours: 18, minutes: i * 10)),
          value: 120 + i * 10));
    }
    final (out, note) = await read('heart_rate',
        day.add(const Duration(hours: 18)), day.add(const Duration(hours: 19)));
    expect(out['metric'], '心率');
    expect(out['count'], 3);
    expect(out['min'], 120);
    expect(out['max'], 140);
    expect(out['avg'], 130);
    expect(out['points'] as List, hasLength(3));
    expect(note, '心率 2026-10-26 18:00~2026-10-26 19:00（3 个点）');
  });

  test('心率：点多时分段汇总，不逐点发送', () async {
    for (var i = 0; i < 500; i++) {
      source.samples.add(sample(
          HealthDataType.HEART_RATE, day.add(Duration(minutes: i)),
          value: 60 + i % 40));
    }
    final (out, _) =
        await read('heart_rate', day, day.add(const Duration(days: 1)));
    expect(out.containsKey('points'), isFalse);
    final buckets = out['buckets'] as List;
    expect(buckets.length, lessThanOrEqualTo(49));
    expect(buckets.length, greaterThan(40));
    expect(out['count'], 500);
  });

  test('累计量按天合计，多来源只取合计最大的一个，不重复累加', () async {
    source.samples.addAll([
      sample(HealthDataType.DISTANCE_WALKING_RUNNING,
          day.add(const Duration(hours: 9)), value: 1000, source: 'iPhone'),
      sample(HealthDataType.DISTANCE_WALKING_RUNNING,
          day.add(const Duration(hours: 9)), value: 1200),
      sample(HealthDataType.DISTANCE_WALKING_RUNNING,
          day.add(const Duration(hours: 17)), value: 300),
    ]);
    final (out, note) = await read(
        'distance_walking_running', day, day.add(const Duration(days: 1)));
    expect(out['days'], [
      {'date': '2026-10-26', 'total': 1500}
    ]);
    expect(note, contains('1 天'));
  });

  test('步数用统计查询按天取', () async {
    source.stepsByDay['10-25'] = 4000;
    source.stepsByDay['10-26'] = 8000;
    final (out, _) = await read(
        'steps', DateTime(2026, 10, 25), DateTime(2026, 10, 27));
    expect(out['days'], [
      {'date': '2026-10-25', 'steps': 4000},
      {'date': '2026-10-26', 'steps': 8000},
    ]);
  });

  test('睡眠分期：按段汇总，只取分期最多的来源；入睡醒来与各阶段分钟数', () async {
    final night = DateTime(2026, 10, 25, 23, 0);
    DateTime t(int min) => night.add(Duration(minutes: min));
    source.samples.addAll([
      sample(HealthDataType.SLEEP_IN_BED, t(-30), end: t(480), source: 'iPhone'),
      sample(HealthDataType.SLEEP_LIGHT, t(0), end: t(120)),
      sample(HealthDataType.SLEEP_DEEP, t(120), end: t(210)),
      sample(HealthDataType.SLEEP_AWAKE, t(210), end: t(220)),
      sample(HealthDataType.SLEEP_REM, t(220), end: t(300)),
      sample(HealthDataType.SLEEP_LIGHT, t(300), end: t(420)),
    ]);
    final (out, note) = await read('sleep_stages',
        DateTime(2026, 10, 25, 18), DateTime(2026, 10, 26, 12));
    final s = (out['sessions'] as List).single as Map;
    expect(s['source'], 'Apple Watch');
    expect(s['sleep_onset'], '2026-10-25 23:00');
    expect(s['wake'], '2026-10-26 06:00');
    expect(s['asleep_minutes'], 410); // 120 + 90 + 80 + 120
    expect(s['stages_minutes'], {'核心睡眠': 240, '深睡': 90, '清醒': 10, '快速眼动': 80});
    expect(s['awake_times'], 1);
    expect(note, contains('1 段'));
  });

  test('体能训练给起止时间和提示，事件类给中文名，心电图带分类与平均心率', () async {
    source.samples.addAll([
      sample(HealthDataType.WORKOUT, day.add(const Duration(hours: 18)),
          end: day.add(const Duration(hours: 18, minutes: 40)),
          text: 'RUNNING',
          extra: {'energy_kcal': 320, 'distance_m': 5000}),
      sample(HealthDataType.HEADACHE_MODERATE, day.add(const Duration(hours: 9)),
          end: day.add(const Duration(hours: 11))),
      sample(HealthDataType.ELECTROCARDIOGRAM, day.add(const Duration(hours: 8)),
          value: 72, text: 'SINUS_RHYTHM'),
    ]);
    final end = day.add(const Duration(days: 1));
    final (w, _) = await read('workouts', day, end);
    final workout = (w['workouts'] as List).single as Map;
    expect(workout['start'], '2026-10-26 18:00');
    expect(workout['minutes'], 40);
    expect(workout['energy_kcal'], 320);
    expect(w['hint'], contains('heart_rate'));

    final (h, _) = await read('headache', day, end);
    final e = (h['events'] as List).single as Map;
    expect(e['what'], '中度头痛');
    expect(e['minutes'], 120);

    final (ecg, _) = await read('ecg', day, end);
    final r = (ecg['events'] as List).single as Map;
    expect(r['result'], 'SINUS_RHYTHM');
    expect(r['average_heart_rate'], 72);
  });

  test('血压按时间配对；没有数据时明说；不认识的指标报错', () async {
    final t = day.add(const Duration(hours: 8));
    source.samples.addAll([
      sample(HealthDataType.BLOOD_PRESSURE_SYSTOLIC, t, value: 122),
      sample(HealthDataType.BLOOD_PRESSURE_DIASTOLIC, t, value: 80),
    ]);
    final end = day.add(const Duration(days: 1));
    final (bp, _) = await read('blood_pressure', day, end);
    expect(bp['readings'], [
      {'time': '2026-10-26 08:00', 'systolic': 122, 'diastolic': 80}
    ]);
    final (none, note) = await read('blood_oxygen', day, end);
    expect(none['data'], contains('没有读到'));
    expect(note, contains('没有数据'));
    expect(() => reader.read('location', day, end), throwsFormatException);
  });

  test('授权申请的类型包含全部实时指标', () {
    expect(liveReadTypes, containsAll([
      HealthDataType.HEART_RATE,
      HealthDataType.ELECTROCARDIOGRAM,
      HealthDataType.MENSTRUATION_FLOW,
      HealthDataType.BLOOD_GLUCOSE,
    ]));
    expect(liveReadTypes, isNot(contains(HealthDataType.WORKOUT_ROUTE)));
  });
}
