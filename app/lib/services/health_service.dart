import 'dart:async';
import 'dart:io';

import 'package:health/health.dart';

import '../data/db/app_database.dart';
import '../data/repositories/health_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'app_log.dart';
import 'health_live.dart';
import 'sleep_merge.dart';

/// 一天的设备数据（没有的项为 null，表示"暂未读取到"，不是 0，D-11）。
class DeviceDayData {
  const DeviceDayData({
    required this.sleep,
    required this.workouts,
    required this.steps,
    required this.activeEnergyKcal,
  });

  final SleepSegment? sleep;
  final List<HealthSample> workouts;
  final double? steps;
  final double? activeEnergyKcal;

  bool get isEmpty =>
      sleep == null &&
      workouts.isEmpty &&
      steps == null &&
      activeEnergyKcal == null;
}

/// 活动能量原始点（求和前先按来源去重）。
class EnergyPoint {
  const EnergyPoint({
    required this.startMs,
    required this.endMs,
    required this.kcal,
    required this.sourceName,
  });

  final int startMs;
  final int endMs;
  final double kcal;
  final String sourceName;
}

class HealthFetchResult {
  const HealthFetchResult({required this.samples, required this.energy});

  final List<HealthSampleInput> samples;
  final List<EnergyPoint> energy;
}

/// 对 health 插件的最小抽象，测试用假实现替换。
///
/// health 插件的限制（docs/development.md §4.1）：health 插件不支持 HKAnchoredObjectQuery，
/// 拿不到"已删除样本"，也没有锚点。所以：
/// - 增量按时间窗重读（上次同步往前多读 2 天），UUID 幂等去重；
/// - 苹果健康里删除的样本暂时无法同步删除（A-31 删除部分待原生实现）；
/// - 缺席不判定删除，符合 D-11。
abstract class HealthPort {
  Future<bool> requestAuthorization();

  /// 自动同步前确认读取授权，不会反复打扰用户（见 [HealthService.autoSync]）。
  Future<void> ensureReadAuthorization();
  Future<HealthFetchResult> fetch(DateTime start, DateTime end);
  Future<int?> totalSteps(DateTime start, DateTime end);
}

/// health 插件：iOS 读 HealthKit，安卓读 Health Connect（plan-android AN-M5）。
class HealthKitPort implements HealthPort {
  HealthKitPort({required this.tz});

  /// 读取时设备的时区；样本上标为推断（schema §2.5）。
  final String tz;

  final _health = Health();
  bool _configured = false;

  static const _iosTypes = [
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT, // iOS 的 asleepCore
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Health Connect 没有"在床"类型，睡眠会话（SleepSessionRecord）是整段
  /// 从入睡到起床，按在床处理；阶段各自对应（D-11：在床不计入睡眠时长）。
  static const _androidTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// 安卓读体能训练时插件会顺带读会话内的距离与总能量，没授权这两项时
  /// 训练摘要缺字段；只申请权限，不单独读取。
  static const _androidAuthOnly = [
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static List<HealthDataType> get _types =>
      Platform.isAndroid ? _androidTypes : _iosTypes;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestAuthorization() async {
    await _ensureConfigured();
    if (Platform.isAndroid) {
      // 系统没有 Health Connect（或需要更新）时不弹权限页，按未授权处理。
      final status = await _health.getHealthConnectSdkStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) return false;
      final types = [..._androidTypes, ..._androidAuthOnly];
      return _health.requestAuthorization(types,
          permissions: [for (final _ in types) HealthDataAccess.READ]);
    }
    // 咨询实时读取的类型一并申请（D-44）：授权已决定的不再弹框，新增的
    // 类型在下次启动 autoSync 时弹一次。
    return _health.requestAuthorization({..._types, ...liveReadTypes}.toList());
  }

  /// iOS：授权已决定过时不弹框、直接返回；只有"未决定"时才弹。重装换签名后
  /// 授权会变回"未决定"，不申请的话每次读取都报 Authorization not determined
  /// （2026-10-26 排查：10-24、10-25 设备数据为空）。
  /// 安卓：Health Connect 每次申请都会打开权限页，自动同步时不申请，
  /// 仍由设置页的开关负责。
  @override
  Future<void> ensureReadAuthorization() async {
    if (!Platform.isIOS) return;
    await requestAuthorization();
  }

  @override
  Future<HealthFetchResult> fetch(DateTime start, DateTime end) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: _types.where((t) => t != HealthDataType.STEPS).toList(),
      startTime: start,
      endTime: end,
    );
    final samples = <HealthSampleInput>[];
    final energy = <EnergyPoint>[];
    for (final dp in points) {
      if (dp.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        final v = dp.value;
        if (v is NumericHealthValue) {
          energy.add(EnergyPoint(
            startMs: dp.dateFrom.millisecondsSinceEpoch,
            endMs: dp.dateTo.millisecondsSinceEpoch,
            kcal: v.numericValue.toDouble(),
            sourceName: dp.sourceName,
          ));
        }
        continue;
      }
      final input = _toSampleInput(dp);
      if (input != null) samples.add(input);
    }
    return HealthFetchResult(samples: samples, energy: energy);
  }

  @override
  Future<int?> totalSteps(DateTime start, DateTime end) async {
    await _ensureConfigured();
    return _health.getTotalStepsInInterval(start, end);
  }

  HealthSampleInput? _toSampleInput(HealthDataPoint dp) {
    if (dp.type == HealthDataType.WORKOUT) {
      final summary = dp.workoutSummary;
      return HealthSampleInput(
        platformUuid: dp.uuid,
        sampleType: HealthSampleType.workout,
        startUtcMs: dp.dateFrom.toUtc().millisecondsSinceEpoch,
        endUtcMs: dp.dateTo.toUtc().millisecondsSinceEpoch,
        tz: tz,
        tzInferred: true,
        sourceBundleId: dp.sourceId,
        workoutType: summary?.workoutType,
        energyKcal: summary?.totalEnergyBurned.toDouble(),
        distanceM: summary?.totalDistance.toDouble(),
        sourceName: dp.sourceName,
      );
    }
    final stage = switch (dp.type) {
      HealthDataType.SLEEP_IN_BED ||
      HealthDataType.SLEEP_SESSION =>
        SleepStage.inBed,
      HealthDataType.SLEEP_ASLEEP => SleepStage.asleepUnspecified,
      HealthDataType.SLEEP_AWAKE => SleepStage.awake,
      HealthDataType.SLEEP_DEEP => SleepStage.deep,
      HealthDataType.SLEEP_REM => SleepStage.rem,
      HealthDataType.SLEEP_LIGHT => SleepStage.core,
      _ => null,
    };
    if (stage == null) return null;
    return HealthSampleInput(
      platformUuid: dp.uuid,
      sampleType: HealthSampleType.sleep,
      startUtcMs: dp.dateFrom.toUtc().millisecondsSinceEpoch,
      endUtcMs: dp.dateTo.toUtc().millisecondsSinceEpoch,
      tz: tz,
      tzInferred: true,
      sourceBundleId: dp.sourceId,
      sleepStage: stage,
      sourceName: dp.sourceName,
    );
  }
}

/// 健康数据同步（D-11、schema §2.5/§2.6）。
class HealthService {
  HealthService({
    required HealthRepository repository,
    required SettingsRepository settings,
    required String tz,
    HealthPort? port,
  })  : _repo = repository,
        _settings = settings,
        _tz = tz {
    _port = port ?? HealthKitPort(tz: tz);
  }

  final HealthRepository _repo;
  final SettingsRepository _settings;
  final String _tz;
  late final HealthPort _port;

  static const _lastSyncKey = 'health_last_sync_ms';

  Future<bool> requestAuthorization() => _port.requestAuthorization();

  Future<int>? _running;

  /// 启动和回到前台时调用：设置里开了才读，先确认授权再同步。
  /// 失败只记日志、不抛出——调用方都是 unawaited，异常否则无处可见。
  Future<void> autoSync() async {
    try {
      final enabled =
          await _settings.get('healthkit_sync_enabled') as bool? ?? false;
      if (!enabled) return;
      await _port.ensureReadAuthorization();
      final n = await syncNow();
      AppLog.I.i('health', '健康数据同步完成：新样本 $n 条');
    } catch (e, st) {
      AppLog.I.e('health', '健康数据同步失败', e, st);
    }
  }

  /// 读取并入库。返回写入的新样本数；读不到就是 0——
  /// 未授权和确实没有数据无法区分，界面按"暂未读取到"处理（D-11、A-12）。
  /// 同步进行中再调用时共用同一次（启动、回前台、设置页开关可能同时触发）。
  Future<int> syncNow() =>
      _running ??= _sync().whenComplete(() => _running = null);

  Future<int> _sync() async {
    final now = DateTime.now();
    final lastMs = await _settings.get(_lastSyncKey) as int?;
    // 首次读近 30 天；之后从上次同步往前多读 2 天，UUID 去重。
    final start = lastMs == null
        ? now.subtract(const Duration(days: 30))
        : DateTime.fromMillisecondsSinceEpoch(lastMs)
            .subtract(const Duration(days: 2));

    final enabled =
        ((await _settings.get('healthkit_enabled_types') as List?) ??
                ['sleep', 'steps', 'workout', 'active_energy'])
            .cast<String>();

    final result = await _port.fetch(start, now);
    final inputs = result.samples.where((s) {
      if (s.sampleType == HealthSampleType.sleep) {
        return enabled.contains('sleep');
      }
      return enabled.contains('workout');
    }).toList();
    final inserted = await _repo.upsertSamples(inputs);

    // 按天聚合：窗口内逐天写入（同一天重复读取覆盖，schema §2.6）。
    for (var day = DateTime(start.year, start.month, start.day);
        !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      final dayEnd = day.add(const Duration(days: 1));
      final localDate =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (enabled.contains('steps')) {
        final steps = await _port.totalSteps(day, dayEnd);
        if (steps != null) {
          await _repo.upsertDaily(
            localDate: localDate,
            aggTz: _tz,
            intervalStartUtcMs: day.toUtc().millisecondsSinceEpoch,
            intervalEndUtcMs: dayEnd.toUtc().millisecondsSinceEpoch,
            metric: HealthMetric.steps,
            value: steps.toDouble(),
          );
        }
      }
      if (enabled.contains('active_energy')) {
        final kcal = _activeEnergyOfDay(result.energy, day, dayEnd);
        if (kcal != null) {
          await _repo.upsertDaily(
            localDate: localDate,
            aggTz: _tz,
            intervalStartUtcMs: day.toUtc().millisecondsSinceEpoch,
            intervalEndUtcMs: dayEnd.toUtc().millisecondsSinceEpoch,
            metric: HealthMetric.activeEnergyKcal,
            value: kcal,
          );
        }
      }
    }

    await _settings.set(_lastSyncKey, now.millisecondsSinceEpoch);
    return inserted;
  }

  /// 活动能量：health 插件没有统计查询，直接求和会把多来源重复累加，
  /// 所以先按来源优先级（Watch > iPhone > 其他）取一个来源再求和。
  /// 与苹果健康 App 的口径差异按 A-31 原则记录，不承诺一致。
  double? _activeEnergyOfDay(
      List<EnergyPoint> energy, DateTime day, DateTime dayEnd) {
    final dayStart = day.millisecondsSinceEpoch;
    final dayEndMs = dayEnd.millisecondsSinceEpoch;
    final ofDay = energy
        .where((e) => e.startMs < dayEndMs && e.endMs > dayStart)
        .toList();
    if (ofDay.isEmpty) return null;
    int rank(String s) => s.toLowerCase().contains('watch')
        ? 0
        : s.toLowerCase().contains('iphone')
            ? 1
            : 2;
    final bestRank =
        ofDay.map((e) => rank(e.sourceName)).reduce((a, b) => a < b ? a : b);
    var total = 0.0;
    for (final e in ofDay.where((e) => rank(e.sourceName) == bestRank)) {
      total += e.kcal;
    }
    return total;
  }

  /// 某天的设备数据汇总（日视图与睡眠记录的设备参考用，schema §3.7）。
  /// 设备值在显示时计算，不写入记录版本；排序上永远让位于用户值（D-07）。
  Future<DeviceDayData> dayData(String localDate) async {
    final day = DateTime.parse(localDate);
    final windowStart =
        day.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final windowEnd = day.add(const Duration(days: 1)).millisecondsSinceEpoch;

    final sleepSamples = await _repo.samplesBetween(
      sampleType: HealthSampleType.sleep,
      startUtcMs: windowStart,
      endUtcMs: windowEnd,
    );
    final sleep = sleepForDate(mergeSleepSamples(sleepSamples), localDate);

    final workouts = await _repo.samplesBetween(
      sampleType: HealthSampleType.workout,
      startUtcMs: day.millisecondsSinceEpoch,
      endUtcMs: day.add(const Duration(days: 1)).millisecondsSinceEpoch,
    );

    return DeviceDayData(
      sleep: sleep,
      workouts: workouts,
      steps: (await _repo.dailyValue(localDate, HealthMetric.steps))?.value,
      activeEnergyKcal:
          (await _repo.dailyValue(localDate, HealthMetric.activeEnergyKcal))
              ?.value,
    );
  }
}
