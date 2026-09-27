import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/health_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';
import 'package:live_a_long_life/services/health_service.dart';
import 'package:live_a_long_life/services/sleep_merge.dart';

import '../data/test_helpers.dart';

/// 本地时间快捷构造（测试机时区无关紧要，合并逻辑只看相对间隔）。
int at(int day, int hour, [int minute = 0]) =>
    DateTime(2026, 9, day, hour, minute).millisecondsSinceEpoch;

HealthSample sample({
  required String uuid,
  required int start,
  required int end,
  SleepStage? stage,
  String source = 'Apple Watch',
  HealthSampleType type = HealthSampleType.sleep,
}) =>
    HealthSample(
      id: uuid,
      userId: 'u',
      createdAt: 0,
      createdOnDevice: 'd',
      version: 1,
      platformUuid: uuid,
      sampleType: type,
      startUtc: start,
      endUtc: end,
      tz: 'Asia/Shanghai',
      tzInferred: true,
      sleepStage: stage,
      sourceName: source,
      fetchedAt: 0,
    );

void main() {
  group('睡眠合并（D-11）', () {
    test('重叠阶段去重不相加；入睡/醒来取阶段样本首尾；归到醒来那天', () {
      final segments = mergeSleepSamples([
        // 23:30–03:00 核心，02:00–04:00 深睡（重叠 1 小时）
        sample(uuid: 'a', start: at(25, 23, 30), end: at(26, 3), stage: SleepStage.core),
        sample(uuid: 'b', start: at(26, 2), end: at(26, 4), stage: SleepStage.deep),
        // 清醒不计入时长
        sample(uuid: 'c', start: at(26, 4), end: at(26, 4, 30), stage: SleepStage.awake),
        // 在床样本单独汇总
        sample(uuid: 'd', start: at(25, 23), end: at(26, 5), stage: SleepStage.inBed),
      ]);

      expect(segments, hasLength(1));
      final s = segments.single;
      // 23:30–04:00 并集 = 4.5 小时 = 270 分钟
      expect(s.sleepDurationMin, 270);
      expect(s.sleepOnsetMs, at(25, 23, 30));
      expect(s.wakeMs, at(26, 4));
      expect(s.inBedDurationMin, 6 * 60);
      expect(s.localDate, '2026-09-26'); // 醒来那天
    });

    test('间隔超过 1 小时分成两段；午睡归当天', () {
      final segments = mergeSleepSamples([
        sample(uuid: 'a', start: at(25, 23), end: at(26, 7), stage: SleepStage.core),
        sample(uuid: 'b', start: at(26, 13), end: at(26, 14), stage: SleepStage.core),
      ]);
      expect(segments, hasLength(2));
      expect(segments[0].localDate, '2026-09-26');
      expect(segments[1].sleepDurationMin, 60);
      // 一天两段时主段取时长最长的
      final main = sleepForDate(segments, '2026-09-26');
      expect(main!.sleepDurationMin, 8 * 60);
    });

    test('多来源同时有阶段数据：只用优先级最高的来源（Watch > iPhone）', () {
      final segments = mergeSleepSamples([
        sample(uuid: 'w', start: at(26, 0), end: at(26, 6), stage: SleepStage.core),
        sample(
            uuid: 'p',
            start: at(26, 0),
            end: at(26, 8), // iPhone 记得更长，但不应采用
            stage: SleepStage.asleepUnspecified,
            source: 'iPhone'),
      ]);
      expect(segments.single.sleepDurationMin, 6 * 60);
      expect(segments.single.sourceName, 'Apple Watch');
    });

    test('只有在床数据：睡眠时长未知，不把在床写入睡眠时长（D-11）', () {
      final segments = mergeSleepSamples([
        sample(uuid: 'a', start: at(25, 23), end: at(26, 7), stage: SleepStage.inBed, source: 'iPhone'),
      ]);
      final s = segments.single;
      expect(s.sleepDurationMin, isNull);
      expect(s.sleepOnsetMs, isNull);
      expect(s.inBedDurationMin, 8 * 60);
      expect(s.localDate, '2026-09-26');
    });

    test('已在来源删除的样本不参与合并', () {
      final removed = HealthSample(
        id: 'x',
        userId: 'u',
        createdAt: 0,
        createdOnDevice: 'd',
        version: 1,
        platformUuid: 'x',
        sampleType: HealthSampleType.sleep,
        startUtc: at(26, 0),
        endUtc: at(26, 6),
        tz: 'Asia/Shanghai',
        tzInferred: true,
        sleepStage: SleepStage.core,
        sourceName: 'Apple Watch',
        fetchedAt: 0,
        removedInSourceAt: 1,
      );
      expect(mergeSleepSamples([removed]), isEmpty);
    });
  });

  group('HealthService 同步（假端口）', () {
    late TestEnv env;
    late HealthRepository repo;
    late SettingsRepository settings;

    setUp(() async {
      env = await TestEnv.create();
      repo = HealthRepository(env.db, env.ctx);
      settings = SettingsRepository(env.db);
    });

    tearDown(() => env.dispose());

    HealthService serviceWith(HealthPort port) => HealthService(
        repository: repo, settings: settings, tz: 'Asia/Shanghai', port: port);

    test('样本入库、步数与活动能量按天聚合；重复同步不重复建行', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final port = _FakePort(
        samples: [
          HealthSampleInput(
            platformUuid: 'sleep-1',
            sampleType: HealthSampleType.sleep,
            startUtcMs: yesterday.millisecondsSinceEpoch,
            endUtcMs:
                yesterday.add(const Duration(hours: 7)).millisecondsSinceEpoch,
            tz: 'Asia/Shanghai',
            sleepStage: SleepStage.core,
            sourceName: 'Apple Watch',
          ),
        ],
        energy: [
          EnergyPoint(
            startMs: DateTime.now().millisecondsSinceEpoch - 3600000,
            endMs: DateTime.now().millisecondsSinceEpoch,
            kcal: 320,
            sourceName: 'Apple Watch',
          ),
          // iPhone 的重复计量不应累加
          EnergyPoint(
            startMs: DateTime.now().millisecondsSinceEpoch - 3600000,
            endMs: DateTime.now().millisecondsSinceEpoch,
            kcal: 300,
            sourceName: 'iPhone',
          ),
        ],
        steps: 8000,
      );
      final service = serviceWith(port);

      expect(await service.syncNow(), 1);
      // 再次同步：同一 UUID 不重复。
      expect(await service.syncNow(), 0);

      final today = DateTime.now();
      final localDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final steps = await repo.dailyValue(localDate, HealthMetric.steps);
      expect(steps!.value, 8000);
      final kcal =
          await repo.dailyValue(localDate, HealthMetric.activeEnergyKcal);
      expect(kcal!.value, 320); // 只取 Watch 来源

      // dayData 汇总可读。
      final day = await service.dayData(localDate);
      expect(day.steps, 8000);
      expect(day.activeEnergyKcal, 320);
    });

    test('A-12：读不到任何数据时不建行，dayData 为空（暂未读取到 ≠ 0）', () async {
      final service =
          serviceWith(_FakePort(samples: [], energy: [], steps: null));
      expect(await service.syncNow(), 0);
      final today = DateTime.now();
      final localDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(await repo.dailyValue(localDate, HealthMetric.steps), isNull);
      expect((await service.dayData(localDate)).isEmpty, isTrue);
    });

    test('healthkit_enabled_types 关掉的类型不入库（R-17 设置）', () async {
      await settings.set('healthkit_enabled_types', ['steps']);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final port = _FakePort(
        samples: [
          HealthSampleInput(
            platformUuid: 's1',
            sampleType: HealthSampleType.sleep,
            startUtcMs: yesterday.millisecondsSinceEpoch,
            endUtcMs:
                yesterday.add(const Duration(hours: 7)).millisecondsSinceEpoch,
            tz: 'Asia/Shanghai',
            sleepStage: SleepStage.core,
            sourceName: 'Apple Watch',
          ),
        ],
        energy: [
          EnergyPoint(startMs: 0, endMs: 1, kcal: 100, sourceName: 'iPhone'),
        ],
        steps: 5000,
      );
      final service = serviceWith(port);
      expect(await service.syncNow(), 0); // 睡眠被关掉
      final today = DateTime.now();
      final localDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect((await repo.dailyValue(localDate, HealthMetric.steps))!.value,
          5000);
      expect(await repo.dailyValue(localDate, HealthMetric.activeEnergyKcal),
          isNull);
    });
  });
}

class _FakePort implements HealthPort {
  _FakePort({required this.samples, required this.energy, required this.steps});

  final List<HealthSampleInput> samples;
  final List<EnergyPoint> energy;
  final int? steps;

  @override
  Future<bool> requestAuthorization() async => true;

  @override
  Future<HealthFetchResult> fetch(DateTime start, DateTime end) async =>
      HealthFetchResult(samples: samples, energy: energy);

  @override
  Future<int?> totalSteps(DateTime start, DateTime end) async => steps;
}
