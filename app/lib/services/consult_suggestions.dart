import 'dart:convert';

import '../data/condition_entry.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/lab_abnormal.dart';
import '../data/repositories/record_repository.dart';
import '../data/same_item.dart';
import '../data/workout_names.dart';
import 'health_service.dart';

/// 咨询页输入框下的一组示例问题（D-45）。
class SuggestionGroup {
  const SuggestionGroup({
    required this.key,
    required this.label,
    required this.questions,
    this.needsLookup = true,
  });

  /// 类别键，界面按它选图标：sleep / exercise / vitals / labs / reports /
  /// conditions / daily / general。
  final String key;
  final String label;
  final List<String> questions;

  /// 要查数据才能答：关掉"允许模型查阅"时置灰。身体状况本来就在
  /// 基础上下文里，不需要查。
  final bool needsLookup;
}

/// 按本机已有的数据生成示例问题（D-45）：只在本地查库，不调模型；
/// 没数据的类别不出现。问题里的日期、项目名都来自本地数据。
Future<List<SuggestionGroup>> buildConsultSuggestions({
  required AppDatabase db,
  required RecordRepository records,
  required Future<DeviceDayData> Function(String localDate) deviceData,
  required Future<bool> Function() liveAvailable,
  DateTime? now,
}) async {
  final today = now ?? DateTime.now();
  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final weekAgo = fmt(today.subtract(const Duration(days: 6)));
  final live = await liveAvailable();
  final groups = <SuggestionGroup>[];

  // 近 7 天的设备数据与日常记录。
  var hasSleep = false;
  HealthSample? lastWorkout;
  for (var i = 0; i < 7; i++) {
    final d = await deviceData(fmt(today.subtract(Duration(days: i))));
    hasSleep = hasSleep || d.sleep != null;
    for (final w in d.workouts) {
      if (lastWorkout == null || w.startUtc > lastWorkout.startUtc) {
        lastWorkout = w;
      }
    }
  }
  final recent = await records.since(weekAgo);
  bool has(RecordType t) => recent.any((r) => r.recordType == t);
  hasSleep = hasSleep || has(RecordType.sleep);

  if (hasSleep) {
    groups.add(const SuggestionGroup(
      key: 'sleep',
      label: '睡眠',
      questions: ['昨晚睡得怎么样？', '这周睡眠规律吗？'],
    ));
  }

  if (lastWorkout != null || has(RecordType.exercise)) {
    final questions = <String>[];
    if (lastWorkout != null) {
      final t = DateTime.fromMillisecondsSinceEpoch(lastWorkout.startUtc);
      final day = '${t.month}月${t.day}日';
      final what = workoutLabel(lastWorkout.workoutType, unknown: '运动');
      // 心率要实时读（D-44），读不了时只问强度。
      questions.add(live ? '$day$what时心率怎么样？' : '$day的$what强度合适吗？');
    }
    questions.add('这周运动量够吗？');
    groups.add(SuggestionGroup(
        key: 'exercise', label: '运动', questions: questions));
  }

  if (live) {
    groups.add(const SuggestionGroup(
      key: 'vitals',
      label: '心率血氧',
      questions: ['最近静息心率正常吗？', '这周血氧正常吗？'],
    ));
  }

  // 检验：只看已核对的（D-04）。最近一次异常的项目问注意事项和变化。
  final byKey = <String, List<LabResult>>{};
  for (final r in await db.select(db.labResults).get()) {
    if (r.reviewStatus == ReviewStatus.unreviewed ||
        SameItem.isPlaceholderValue(r.valueRaw)) {
      continue;
    }
    (byKey[r.itemKey] ??= []).add(r);
  }
  if (byKey.isNotEmpty) {
    LabResult? abnormal;
    String? mostTested;
    var most = 0;
    for (final MapEntry(key: key, value: rows) in byKey.entries) {
      rows.sort((a, b) => (a.examDate ?? '').compareTo(b.examDate ?? ''));
      final latest = rows.last;
      if (isAbnormalLab(
            flagRaw: latest.flagRaw,
            valueRaw: latest.valueRaw,
            valueNum: latest.valueNum,
            refLow: latest.refLow,
            refHigh: latest.refHigh,
            refRangeRaw: latest.refRangeRaw,
          ) &&
          (abnormal == null ||
              (latest.examDate ?? '').compareTo(abnormal.examDate ?? '') > 0)) {
        abnormal = latest;
      }
      if (rows.length > most) {
        most = rows.length;
        mostTested = key;
      }
    }
    final questions = <String>[];
    if (abnormal != null) {
      final v = abnormal.valueNum;
      final direction = v != null && abnormal.refHigh != null && v > abnormal.refHigh!
          ? '偏高'
          : v != null && abnormal.refLow != null && v < abnormal.refLow!
              ? '偏低'
              : '异常';
      questions.add('${abnormal.itemKey}$direction，平时要注意什么？');
    }
    // 趋势优先问正在异常的那项，它没测过几次再问测得最多的。
    final trend = abnormal != null && byKey[abnormal.itemKey]!.length >= 2
        ? abnormal.itemKey
        : (most >= 2 ? mostTested : null);
    if (trend != null) questions.add('$trend这几年变化如何？');
    questions.add('我有哪些指标不正常？');
    groups.add(SuggestionGroup(
        key: 'labs', label: '检验指标', questions: questions));
  }

  // 报告：有已核对的文字结论才出现。
  var hasReports = false;
  for (final rec in await records.byType(RecordType.labPanel)) {
    if (rec.currentRevisionId == null) continue;
    final meta = FieldMetaMap.decode(
        (await records.currentRevisionOf(rec.id)).fieldMeta);
    if (meta.fields.entries
        .any((e) => e.key.startsWith('findings.') && e.value.isProtected)) {
      hasReports = true;
      break;
    }
  }
  if (hasReports) {
    groups.add(const SuggestionGroup(
      key: 'reports',
      label: '报告',
      questions: ['我以前的报告里查出过哪些问题？', '最近一份报告有什么需要注意的？'],
    ));
  }

  // 身体状况：已确认、未痊愈的长期状况，在基础上下文里，不用查。
  final reviewed = <ConditionEntry>[];
  for (final rec in await records.byType(RecordType.condition)) {
    final rev = await records.currentRevisionOf(rec.id);
    final entry = ConditionEntry(rec, rev,
        (jsonDecode(rev.data) as Map).cast<String, Object?>(),
        FieldMetaMap.decode(rev.fieldMeta));
    if (entry.reviewed) reviewed.add(entry);
  }
  final conditions = [
    for (final g in ConditionEntry.groups(reviewed))
      if (g.first.longTerm && !g.first.resolved) g.first.name
  ];
  if (conditions.isNotEmpty) {
    final name = conditions.first;
    groups.add(SuggestionGroup(
      key: 'conditions',
      label: '身体状况',
      questions: ['$name平时饮食要注意什么？', '$name多久复查一次比较好？'],
      needsLookup: false,
    ));
  }

  if (has(RecordType.meal) || has(RecordType.mood)) {
    groups.add(SuggestionGroup(
      key: 'daily',
      label: '日常记录',
      questions: [
        if (has(RecordType.meal)) '这周饮食有什么问题？',
        if (has(RecordType.mood)) '这周心情怎么样，和睡眠有关系吗？',
      ],
    ));
  }

  // 什么数据都没有的新用户：给几个不依赖数据的问题。
  if (groups.isEmpty) {
    groups.add(const SuggestionGroup(
      key: 'general',
      label: '常见问题',
      questions: ['怎样吃得更健康？', '睡不好有什么改善办法？', '每周运动多少比较合适？'],
      needsLookup: false,
    ));
  }
  return groups;
}
