import '../data/db/app_database.dart';
import 'health_service.dart';

/// 一个待问的缺口（D-08、schema §3.5 缺口检测表）。
class Gap {
  const Gap(this.key, this.question);

  final String key;
  final String question;

  String get templateId => '$key-v1';
}

/// 检测某天的缺口。已有记录、明确"没有"、设备已提供的都不算缺
/// （A-14、A-32）。返回顺序即提问优先级。
Future<List<Gap>> detectGaps(
  String localDate, {
  required List<(RecordType, Map<String, Object?>)> records,
  required DeviceDayData device,
}) async {
  final gaps = <Gap>[];

  bool hasMeal(String slot) => records.any((r) =>
      r.$1 == RecordType.meal &&
      (r.$2['meal_slot'] == slot ||
          // 没说是哪顿但明确没吃：不追问（skipped 是有效回答，D-08）。
          (r.$2['meal_slot'] == null && r.$2['status'] == 'skipped')));

  if (!hasMeal('breakfast')) {
    gaps.add(const Gap('meal.breakfast', '早饭吃了什么？没吃的话也说一声。'));
  }
  if (!hasMeal('lunch')) gaps.add(const Gap('meal.lunch', '午饭吃了什么？'));
  if (!hasMeal('dinner')) gaps.add(const Gap('meal.dinner', '晚饭吃了什么？'));

  final sleepRecords =
      records.where((r) => r.$1 == RecordType.sleep).map((r) => r.$2).toList();
  bool sleepField(List<String> keys) => sleepRecords
      .any((d) => keys.any((k) => d[k] != null && '${d[k]}'.isNotEmpty));

  // 设备已提供时间时只问感受（D-08）。
  final deviceHasTimes = device.sleep?.sleepOnsetMs != null;
  if (!deviceHasTimes) {
    if (!sleepField(['sleep_onset', 'sleep_onset_text', 'bedtime', 'bedtime_text'])) {
      gaps.add(const Gap('sleep.sleep_onset', '昨晚几点睡的？'));
    }
    if (!sleepField(['wake_time', 'wake_time_text'])) {
      gaps.add(const Gap('sleep.wake_time', '今天几点醒的？'));
    }
  }
  if (!sleepField(['quality_text', 'quality_score'])) {
    gaps.add(const Gap('sleep.quality_text', '昨晚睡得怎么样？'));
  }

  // 运动：有记录、明确没有，或设备记到体能训练，都不问。
  final hasExercise = records.any((r) => r.$1 == RecordType.exercise) ||
      device.workouts.isNotEmpty;
  if (!hasExercise) {
    gaps.add(const Gap('exercise.any', '今天有运动吗？'));
  }

  if (!records.any((r) => r.$1 == RecordType.mood)) {
    gaps.add(const Gap('mood.any', '今天心情怎么样？'));
  }
  if (!records.any((r) => r.$1 == RecordType.symptom)) {
    gaps.add(const Gap('symptom.any', '身体有没有哪里不舒服？没有的话也说一声。'));
  }
  return gaps;
}
