import 'dart:convert';

import 'package:health/health.dart';

// 咨询时实时读取苹果健康（D-44）：只在回答问题时读、在内存里汇总后发给
// 模型，不入库；调用记录里只写读了什么（ToolOutcome.ephemeral）。

/// 实时读到的一个样本。
class LiveSample {
  const LiveSample({
    required this.type,
    required this.start,
    required this.end,
    required this.source,
    this.value,
    this.text,
    this.unit,
    this.extra = const {},
  });

  final HealthDataType type;
  final DateTime start;
  final DateTime end;
  final String source;
  final num? value;

  /// 非数值的结果（心电图分类、月经量、体能训练类型等）。
  final String? text;
  final String? unit;
  final Map<String, Object?> extra;
}

/// 实时数据来源，测试时替换为假实现。
abstract class LiveHealthSource {
  Future<List<LiveSample>> read(
      List<HealthDataType> types, DateTime start, DateTime end);

  /// 步数要用 HealthKit 的统计查询去重（iPhone 与手表会重复计）。
  Future<int?> totalSteps(DateTime start, DateTime end);
}

class HealthKitLiveSource implements LiveHealthSource {
  final _health = Health();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<List<LiveSample>> read(
      List<HealthDataType> types, DateTime start, DateTime end) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
        types: types, startTime: start, endTime: end);
    return [for (final p in points) _toSample(p)];
  }

  @override
  Future<int?> totalSteps(DateTime start, DateTime end) async {
    await _ensureConfigured();
    return _health.getTotalStepsInInterval(start, end);
  }

  static LiveSample _toSample(HealthDataPoint p) {
    final v = p.value;
    final summary = p.workoutSummary;
    return LiveSample(
      type: p.type,
      start: p.dateFrom.toLocal(),
      end: p.dateTo.toLocal(),
      source: p.sourceName,
      unit: p.unit.name,
      value: switch (v) {
        NumericHealthValue(:final numericValue) => numericValue,
        ElectrocardiogramHealthValue(:final averageHeartRate) =>
          averageHeartRate,
        _ => null,
      },
      text: switch (v) {
        ElectrocardiogramHealthValue(:final classification) =>
          classification?.name,
        MenstruationFlowHealthValue(:final flow) => flow?.name,
        WorkoutHealthValue(:final workoutActivityType) =>
          summary?.workoutType ?? workoutActivityType.name,
        _ => null,
      },
      extra: {
        if (v is MenstruationFlowHealthValue && v.isStartOfCycle == true)
          'cycle_start': true,
        if (summary != null && summary.totalEnergyBurned > 0)
          'energy_kcal': summary.totalEnergyBurned.round(),
        if (summary != null && summary.totalDistance > 0)
          'distance_m': summary.totalDistance.round(),
      },
    );
  }
}

enum _Kind { series, cumulative, steps, events, bloodPressure, sleep, workouts }

class _Metric {
  const _Metric(this.label, this.kind, this.types);

  final String label;
  final _Kind kind;
  final List<HealthDataType> types;
}

/// 能实时读的指标。键是工具参数里的 metric 值。
const _metrics = <String, _Metric>{
  // 心脏
  'heart_rate': _Metric('心率', _Kind.series, [HealthDataType.HEART_RATE]),
  'resting_heart_rate':
      _Metric('静息心率', _Kind.series, [HealthDataType.RESTING_HEART_RATE]),
  'walking_heart_rate':
      _Metric('步行平均心率', _Kind.series, [HealthDataType.WALKING_HEART_RATE]),
  'hrv': _Metric('心率变异性（SDNN）', _Kind.series,
      [HealthDataType.HEART_RATE_VARIABILITY_SDNN]),
  'heart_events': _Metric('心率提醒', _Kind.events, [
    HealthDataType.HIGH_HEART_RATE_EVENT,
    HealthDataType.LOW_HEART_RATE_EVENT,
    HealthDataType.IRREGULAR_HEART_RATE_EVENT,
  ]),
  'afib_burden': _Metric(
      '房颤负荷', _Kind.series, [HealthDataType.ATRIAL_FIBRILLATION_BURDEN]),
  'ecg': _Metric('心电图', _Kind.events, [HealthDataType.ELECTROCARDIOGRAM]),
  // 呼吸与体征
  'blood_oxygen': _Metric('血氧', _Kind.series, [HealthDataType.BLOOD_OXYGEN]),
  'respiratory_rate':
      _Metric('呼吸频率', _Kind.series, [HealthDataType.RESPIRATORY_RATE]),
  'body_temperature':
      _Metric('体温', _Kind.series, [HealthDataType.BODY_TEMPERATURE]),
  'wrist_temperature': _Metric(
      '睡眠时手腕温度', _Kind.series, [HealthDataType.SLEEP_WRIST_TEMPERATURE]),
  'blood_pressure': _Metric('血压', _Kind.bloodPressure, [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ]),
  'blood_glucose':
      _Metric('血糖', _Kind.series, [HealthDataType.BLOOD_GLUCOSE]),
  // 身体测量
  'weight': _Metric('体重', _Kind.series, [HealthDataType.WEIGHT]),
  'height': _Metric('身高', _Kind.series, [HealthDataType.HEIGHT]),
  'bmi': _Metric('BMI', _Kind.series, [HealthDataType.BODY_MASS_INDEX]),
  'body_fat':
      _Metric('体脂率', _Kind.series, [HealthDataType.BODY_FAT_PERCENTAGE]),
  'lean_body_mass':
      _Metric('去脂体重', _Kind.series, [HealthDataType.LEAN_BODY_MASS]),
  'waist': _Metric('腰围', _Kind.series, [HealthDataType.WAIST_CIRCUMFERENCE]),
  // 活动
  'steps': _Metric('步数', _Kind.steps, [HealthDataType.STEPS]),
  'distance_walking_running': _Metric('步行跑步距离', _Kind.cumulative,
      [HealthDataType.DISTANCE_WALKING_RUNNING]),
  'distance_cycling':
      _Metric('骑行距离', _Kind.cumulative, [HealthDataType.DISTANCE_CYCLING]),
  'distance_swimming':
      _Metric('游泳距离', _Kind.cumulative, [HealthDataType.DISTANCE_SWIMMING]),
  'flights_climbed':
      _Metric('爬楼层数', _Kind.cumulative, [HealthDataType.FLIGHTS_CLIMBED]),
  'exercise_time':
      _Metric('锻炼分钟数', _Kind.cumulative, [HealthDataType.EXERCISE_TIME]),
  'stand_time':
      _Metric('站立时间', _Kind.cumulative, [HealthDataType.APPLE_STAND_TIME]),
  'walking_speed':
      _Metric('步行速度', _Kind.series, [HealthDataType.WALKING_SPEED]),
  'active_energy': _Metric(
      '活动能量', _Kind.cumulative, [HealthDataType.ACTIVE_ENERGY_BURNED]),
  'basal_energy':
      _Metric('静息能量', _Kind.cumulative, [HealthDataType.BASAL_ENERGY_BURNED]),
  'workouts': _Metric('体能训练', _Kind.workouts, [HealthDataType.WORKOUT]),
  // 睡眠
  'sleep_stages': _Metric('睡眠分期', _Kind.sleep, [
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ]),
  // 营养与生活
  'water': _Metric('饮水', _Kind.cumulative, [HealthDataType.WATER]),
  'dietary_energy': _Metric(
      '摄入热量', _Kind.cumulative, [HealthDataType.DIETARY_ENERGY_CONSUMED]),
  'caffeine':
      _Metric('咖啡因', _Kind.cumulative, [HealthDataType.DIETARY_CAFFEINE]),
  'carbs':
      _Metric('碳水', _Kind.cumulative, [HealthDataType.DIETARY_CARBS_CONSUMED]),
  'protein': _Metric(
      '蛋白质', _Kind.cumulative, [HealthDataType.DIETARY_PROTEIN_CONSUMED]),
  'fat':
      _Metric('脂肪', _Kind.cumulative, [HealthDataType.DIETARY_FATS_CONSUMED]),
  'sugar': _Metric('糖', _Kind.cumulative, [HealthDataType.DIETARY_SUGAR]),
  'mindfulness':
      _Metric('正念', _Kind.events, [HealthDataType.MINDFULNESS]),
  // 其他
  'headache': _Metric('头痛', _Kind.events, [
    HealthDataType.HEADACHE_NOT_PRESENT,
    HealthDataType.HEADACHE_MILD,
    HealthDataType.HEADACHE_MODERATE,
    HealthDataType.HEADACHE_SEVERE,
    HealthDataType.HEADACHE_UNSPECIFIED,
  ]),
  'menstruation':
      _Metric('月经', _Kind.events, [HealthDataType.MENSTRUATION_FLOW]),
};

/// 需要申请读取授权的全部实时类型（与已入库的四类一起申请，D-44）。
final liveReadTypes = {
  for (final m in _metrics.values) ...m.types,
}.toList();

const _eventLabels = {
  HealthDataType.HIGH_HEART_RATE_EVENT: '心率过高',
  HealthDataType.LOW_HEART_RATE_EVENT: '心率过低',
  HealthDataType.IRREGULAR_HEART_RATE_EVENT: '心律不齐',
  HealthDataType.HEADACHE_NOT_PRESENT: '无头痛',
  HealthDataType.HEADACHE_MILD: '轻度头痛',
  HealthDataType.HEADACHE_MODERATE: '中度头痛',
  HealthDataType.HEADACHE_SEVERE: '重度头痛',
  HealthDataType.HEADACHE_UNSPECIFIED: '头痛（未注明程度）',
  HealthDataType.MINDFULNESS: '正念',
  HealthDataType.MENSTRUATION_FLOW: '月经',
  HealthDataType.ELECTROCARDIOGRAM: '心电图',
};

const _stageLabels = {
  HealthDataType.SLEEP_DEEP: '深睡',
  HealthDataType.SLEEP_LIGHT: '核心睡眠',
  HealthDataType.SLEEP_REM: '快速眼动',
  HealthDataType.SLEEP_ASLEEP: '睡眠（未分期）',
  HealthDataType.SLEEP_AWAKE: '清醒',
  HealthDataType.SLEEP_IN_BED: '在床',
};

/// 实时读取并汇总（D-44）。返回 (发给模型的 JSON, 给用户看的一句话)。
/// 高频数据（心率等）分桶汇总，不逐点发送。
class HealthLiveReader {
  HealthLiveReader(this._source);

  final LiveHealthSource _source;

  static List<String> get metricKeys => _metrics.keys.toList();

  /// 工具说明里列出的指标与中文名。
  static String get metricGuide =>
      [for (final e in _metrics.entries) '${e.key}=${e.value.label}']
          .join('，');

  static const _maxPoints = 60;
  static const _buckets = 48;
  static const _maxEvents = 100;

  Future<(String, String)> read(
      String metric, DateTime start, DateTime end) async {
    final m = _metrics[metric];
    if (m == null) throw FormatException('没有这个指标：$metric');
    final Map<String, Object?> out;
    final String count;
    switch (m.kind) {
      case _Kind.steps:
        out = await _steps(start, end);
        count = '${(out['days'] as List).length} 天';
      default:
        final samples = await _source.read(m.types, start, end);
        (out, count) = switch (m.kind) {
          _Kind.series => _series(samples),
          _Kind.cumulative => _cumulative(samples),
          _Kind.events => _events(samples),
          _Kind.bloodPressure => _bloodPressure(samples),
          _Kind.sleep => _sleep(samples),
          _Kind.workouts => _workouts(samples),
          _Kind.steps => throw StateError('unreachable'),
        };
    }
    return (
      jsonEncode({
        'metric': m.label,
        'start': _time(start),
        'end': _time(end),
        ...out,
      }),
      '${m.label} ${_time(start)}~${_time(end)}（$count）',
    );
  }

  (Map<String, Object?>, String) _series(List<LiveSample> s) {
    final values = [
      for (final x in s)
        if (x.value != null) x
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (values.isEmpty) return (_none, '没有数据');
    final nums = values.map((x) => x.value!.toDouble()).toList();
    final out = <String, Object?>{
      'unit': values.first.unit,
      'count': nums.length,
      'min': _r(nums.reduce((a, b) => a < b ? a : b)),
      'max': _r(nums.reduce((a, b) => a > b ? a : b)),
      'avg': _r(nums.reduce((a, b) => a + b) / nums.length),
      'sources': values.map((x) => x.source).toSet().toList(),
    };
    if (values.length <= _maxPoints) {
      out['points'] = [
        for (final x in values) {'time': _time(x.start), 'value': _r(x.value!)}
      ];
    } else {
      // 均分成若干段，每段给平均、最低、最高。
      final t0 = values.first.start.millisecondsSinceEpoch;
      final span = values.last.start.millisecondsSinceEpoch - t0 + 1;
      final buckets = <int, List<LiveSample>>{};
      for (final x in values) {
        final i = (x.start.millisecondsSinceEpoch - t0) * _buckets ~/ span;
        (buckets[i] ??= []).add(x);
      }
      out['buckets'] = [
        for (final b in buckets.values)
          {
            'from': _time(b.first.start),
            'to': _time(b.last.start),
            'avg': _r(b.map((x) => x.value!).reduce((a, c) => a + c) / b.length),
            'min': _r(b.map((x) => x.value!).reduce((a, c) => a < c ? a : c)),
            'max': _r(b.map((x) => x.value!).reduce((a, c) => a > c ? a : c)),
          },
      ];
    }
    return (out, '${nums.length} 个点');
  }

  /// 累计量按天合计。iPhone 与手表会重复记录，每天取合计最大的一个来源。
  (Map<String, Object?>, String) _cumulative(List<LiveSample> s) {
    final byDay = <String, Map<String, double>>{};
    String? unit;
    for (final x in s) {
      if (x.value == null) continue;
      unit ??= x.unit;
      final bySource = byDay[_date(x.start)] ??= {};
      bySource[x.source] = (bySource[x.source] ?? 0) + x.value!.toDouble();
    }
    if (byDay.isEmpty) return (_none, '没有数据');
    final days = [
      for (final e in byDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)))
        {
          'date': e.key,
          'total': _r(e.value.values.reduce((a, b) => a > b ? a : b)),
        },
    ];
    return (
      {
        'unit': unit,
        'days': days,
        'note': '多个来源重复记录时每天只取合计最大的一个来源',
      },
      '${days.length} 天'
    );
  }

  Future<Map<String, Object?>> _steps(DateTime start, DateTime end) async {
    final days = <Map<String, Object?>>[];
    for (var d = DateTime(start.year, start.month, start.day);
        d.isBefore(end);
        d = d.add(const Duration(days: 1))) {
      final from = d.isBefore(start) ? start : d;
      final next = d.add(const Duration(days: 1));
      final to = next.isAfter(end) ? end : next;
      final steps = await _source.totalSteps(from, to);
      if (steps != null && steps > 0) {
        days.add({'date': _date(d), 'steps': steps});
      }
    }
    return {'days': days};
  }

  (Map<String, Object?>, String) _events(List<LiveSample> s) {
    final sorted = [...s]..sort((a, b) => a.start.compareTo(b.start));
    if (sorted.isEmpty) return (_none, '没有数据');
    final list = [
      for (final x in sorted.reversed.take(_maxEvents).toList().reversed)
        {
          'time': _time(x.start),
          'what': _eventLabels[x.type] ?? x.type.name,
          if (x.end.difference(x.start).inMinutes > 0)
            'minutes': x.end.difference(x.start).inMinutes,
          if (x.text != null) 'result': x.text,
          // 心电图带平均心率；其余类别的数值是分类编码，不发。
          if (x.type == HealthDataType.ELECTROCARDIOGRAM && x.value != null)
            'average_heart_rate': _r(x.value!),
          ...x.extra,
        },
    ];
    return (
      {
        'events': list,
        if (sorted.length > list.length) 'omitted_earlier': sorted.length - list.length,
      },
      '${sorted.length} 条'
    );
  }

  (Map<String, Object?>, String) _bloodPressure(List<LiveSample> s) {
    final byTime = <DateTime, Map<HealthDataType, num>>{};
    for (final x in s) {
      if (x.value != null) (byTime[x.start] ??= {})[x.type] = x.value!;
    }
    final readings = [
      for (final e in byTime.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)))
        {
          'time': _time(e.key),
          'systolic': e.value[HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
          'diastolic': e.value[HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        },
    ];
    if (readings.isEmpty) return (_none, '没有数据');
    return ({'unit': 'mmHg', 'readings': readings}, '${readings.length} 次');
  }

  /// 睡眠按段汇总：间隔超过 3 小时算另一段。每段只取一个来源（分期样本
  /// 最多的那个，通常是手表），避免手机和手表的记录叠加。
  (Map<String, Object?>, String) _sleep(List<LiveSample> s) {
    if (s.isEmpty) return (_none, '没有数据');
    final sorted = [...s]..sort((a, b) => a.start.compareTo(b.start));
    final sessions = <List<LiveSample>>[];
    DateTime? lastEnd;
    for (final x in sorted) {
      if (lastEnd == null || x.start.difference(lastEnd).inHours >= 3) {
        sessions.add([]);
      }
      sessions.last.add(x);
      if (lastEnd == null || x.end.isAfter(lastEnd)) lastEnd = x.end;
    }
    final out = <Map<String, Object?>>[];
    for (final session in sessions) {
      final staged = <String, int>{};
      for (final x in session) {
        if (x.type != HealthDataType.SLEEP_IN_BED) {
          staged[x.source] = (staged[x.source] ?? 0) + 1;
        }
      }
      final source = staged.isEmpty
          ? session.first.source
          : (staged.entries.toList()..sort((a, b) => b.value - a.value))
              .first
              .key;
      final mine = session.where((x) => x.source == source).toList();
      final minutes = <HealthDataType, int>{};
      for (final x in mine) {
        minutes[x.type] =
            (minutes[x.type] ?? 0) + x.end.difference(x.start).inMinutes;
      }
      final asleep = mine.where((x) =>
          x.type != HealthDataType.SLEEP_IN_BED &&
          x.type != HealthDataType.SLEEP_AWAKE);
      final asleepMin = [
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_ASLEEP,
      ].fold(0, (sum, t) => sum + (minutes[t] ?? 0));
      out.add({
        'source': source,
        if (asleep.isNotEmpty) 'sleep_onset': _time(asleep.first.start),
        if (asleep.isNotEmpty)
          'wake': _time(asleep
              .map((x) => x.end)
              .reduce((a, b) => a.isAfter(b) ? a : b)),
        'asleep_minutes': asleepMin,
        'stages_minutes': {
          for (final e in minutes.entries) _stageLabels[e.key]: e.value,
        },
        'awake_times':
            mine.where((x) => x.type == HealthDataType.SLEEP_AWAKE).length,
      });
    }
    return ({'sessions': out}, '${out.length} 段');
  }

  (Map<String, Object?>, String) _workouts(List<LiveSample> s) {
    final sorted = [...s]..sort((a, b) => a.start.compareTo(b.start));
    if (sorted.isEmpty) return (_none, '没有数据');
    return (
      {
        'workouts': [
          for (final x in sorted)
            {
              'type': x.text,
              'start': _time(x.start),
              'end': _time(x.end),
              'minutes': x.end.difference(x.start).inMinutes,
              'source': x.source,
              ...x.extra,
            },
        ],
        'hint': '要看某次训练的心率，用 heart_rate 并把起止时间设为这次训练的 start/end',
      },
      '${sorted.length} 次'
    );
  }

  static const _none = <String, Object?>{'data': '这段时间没有读到记录（可能没戴设备或未授权）'};

  static num _r(num v) => v is int ? v : double.parse(v.toStringAsFixed(2));

  static String _date(DateTime t) =>
      '${t.year}-${_pad(t.month)}-${_pad(t.day)}';

  static String _time(DateTime t) => '${_date(t)} ${_pad(t.hour)}:${_pad(t.minute)}';

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
