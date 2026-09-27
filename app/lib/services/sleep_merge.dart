import '../data/db/app_database.dart';

/// 合并后的一段睡眠（D-11 睡眠汇总规则）。
class SleepSegment {
  SleepSegment({
    required this.sleepOnsetMs,
    required this.wakeMs,
    required this.sleepDurationMin,
    this.inBedStartMs,
    this.inBedEndMs,
    this.inBedDurationMin,
    required this.sourceName,
  });

  /// 第一个 / 最后一个睡眠阶段样本的起止；只有"在床上"时为 null。
  final int? sleepOnsetMs;
  final int? wakeMs;

  /// 各睡眠阶段（不含清醒、不含在床）去重叠后的总时长；
  /// 没有阶段数据时为 null（"在床 X 小时，睡眠时长未知"）。
  final int? sleepDurationMin;

  final int? inBedStartMs;
  final int? inBedEndMs;
  final int? inBedDurationMin;

  /// 采用的来源（合并口径：Watch > iPhone > 其他）。
  final String sourceName;

  /// 归属日期 = 醒来时刻的自然日（D-06）；只有在床数据时按在床结束算。
  String get localDate {
    final endMs = wakeMs ?? inBedEndMs!;
    final d = DateTime.fromMillisecondsSinceEpoch(endMs).toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// 来源优先级：Apple Watch > iPhone > 其他（D-11，本应用自己的合并口径）。
int _sourceRank(String sourceName) {
  final s = sourceName.toLowerCase();
  if (s.contains('watch')) return 0;
  if (s.contains('iphone')) return 1;
  return 2;
}

bool _isStage(HealthSample s) =>
    s.sleepStage != null && s.sleepStage != SleepStage.inBed;

bool _isAsleepStage(HealthSample s) =>
    _isStage(s) && s.sleepStage != SleepStage.awake;

/// 把睡眠样本合并成若干段（D-11）：
/// 1. 有阶段数据的来源里取优先级最高的一个，避免多来源重复累加；
/// 2. 按时间排序，相邻间隔 ≤ [maxGap]（默认 1 小时，试验参数）归同一段；
/// 3. 睡眠时长 = 睡眠阶段区间去重叠后的总和；在床样本单独汇总。
List<SleepSegment> mergeSleepSamples(
  List<HealthSample> samples, {
  Duration maxGap = const Duration(hours: 1),
}) {
  final valid = samples
      .where((s) =>
          s.sampleType == HealthSampleType.sleep && s.removedInSourceAt == null)
      .toList();
  if (valid.isEmpty) return [];

  // 选阶段数据来源：有阶段样本的来源中优先级最高者；没有任何阶段数据时为 null。
  final stageSources = valid.where(_isStage).map((s) => s.sourceName).toSet();
  final String? stageSource = stageSources.isEmpty
      ? null
      : (stageSources.toList()
            ..sort((a, b) => _sourceRank(a).compareTo(_sourceRank(b))))
          .first;

  // 参与合并的样本：选中来源的阶段样本 + 全部在床样本（在床可以来自别的来源）。
  final used = valid
      .where((s) =>
          (stageSource != null && _isStage(s) && s.sourceName == stageSource) ||
          s.sleepStage == SleepStage.inBed)
      .toList()
    ..sort((a, b) => a.startUtc.compareTo(b.startUtc));
  if (used.isEmpty) return [];

  // 相邻间隔超过 maxGap 分段。
  final groups = <List<HealthSample>>[[used.first]];
  var groupEnd = used.first.endUtc;
  for (final s in used.skip(1)) {
    if (s.startUtc - groupEnd > maxGap.inMilliseconds) {
      groups.add([s]);
    } else {
      groups.last.add(s);
    }
    if (s.endUtc > groupEnd) groupEnd = s.endUtc;
  }

  final segments = <SleepSegment>[];
  for (final group in groups) {
    final stages = group.where(_isAsleepStage).toList();
    final inBed = group.where((s) => s.sleepStage == SleepStage.inBed).toList();
    if (stages.isEmpty && inBed.isEmpty) continue;

    int? onset, wake, sleepMin;
    if (stages.isNotEmpty) {
      onset = stages.map((s) => s.startUtc).reduce((a, b) => a < b ? a : b);
      wake = stages.map((s) => s.endUtc).reduce((a, b) => a > b ? a : b);
      sleepMin = _unionMinutes([for (final s in stages) (s.startUtc, s.endUtc)]);
    }
    int? inBedStart, inBedEnd, inBedMin;
    if (inBed.isNotEmpty) {
      inBedStart = inBed.map((s) => s.startUtc).reduce((a, b) => a < b ? a : b);
      inBedEnd = inBed.map((s) => s.endUtc).reduce((a, b) => a > b ? a : b);
      inBedMin = _unionMinutes([for (final s in inBed) (s.startUtc, s.endUtc)]);
    }
    segments.add(SleepSegment(
      sleepOnsetMs: onset,
      wakeMs: wake,
      sleepDurationMin: sleepMin,
      inBedStartMs: inBedStart,
      inBedEndMs: inBedEnd,
      inBedDurationMin: inBedMin,
      sourceName: stages.isNotEmpty ? stages.first.sourceName : inBed.first.sourceName,
    ));
  }
  return segments;
}

/// 区间并集的总分钟数（去重叠，D-11：不能直接相加）。
int _unionMinutes(List<(int, int)> intervals) {
  if (intervals.isEmpty) return 0;
  final sorted = [...intervals]..sort((a, b) => a.$1.compareTo(b.$1));
  var total = 0;
  var (curStart, curEnd) = sorted.first;
  for (final (s, e) in sorted.skip(1)) {
    if (s > curEnd) {
      total += curEnd - curStart;
      curStart = s;
      curEnd = e;
    } else if (e > curEnd) {
      curEnd = e;
    }
  }
  total += curEnd - curStart;
  return (total / 60000).round();
}

/// 某天的睡眠段（归属 = 醒来那天）；一天多段时取时长最长的为主段。
SleepSegment? sleepForDate(List<SleepSegment> segments, String localDate) {
  final ofDay = segments.where((s) => s.localDate == localDate).toList();
  if (ofDay.isEmpty) return null;
  ofDay.sort((a, b) => (b.sleepDurationMin ?? b.inBedDurationMin ?? 0)
      .compareTo(a.sleepDurationMin ?? a.inBedDurationMin ?? 0));
  return ofDay.first;
}
