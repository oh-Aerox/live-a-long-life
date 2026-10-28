import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../data/time_value.dart';

export '../data/record_summary.dart';

/// 记录类型的展示名与图标（product-spec §7）。
const recordTypeLabels = {
  RecordType.meal: '饮食',
  RecordType.sleep: '睡眠',
  RecordType.mood: '心情',
  RecordType.symptom: '身体不适',
  RecordType.exercise: '运动',
  RecordType.note: '其他',
  RecordType.labPanel: '报告提取',
  RecordType.condition: '身体状况',
};

const recordTypeIcons = {
  RecordType.meal: Icons.restaurant_outlined,
  RecordType.sleep: Icons.bedtime_outlined,
  RecordType.mood: Icons.mood_outlined,
  RecordType.symptom: Icons.healing_outlined,
  RecordType.exercise: Icons.directions_run_outlined,
  RecordType.note: Icons.notes_outlined,
  RecordType.labPanel: Icons.biotech_outlined,
  RecordType.condition: Icons.medical_services_outlined,
};

/// data 字段的展示名；没列出的按原字段名显示。
const fieldLabels = {
  'status': '状态',
  'meal_slot': '哪一顿',
  'description': '描述',
  'items': '内容',
  'notes': '备注',
  'bedtime': '上床时间',
  'sleep_onset': '入睡时间',
  'sleep_onset_text': '入睡时间',
  'wake_time': '醒来时间',
  'out_of_bed': '起床时间',
  'quality_text': '睡眠感受',
  'quality_score': '睡眠评分',
  'score': '评分',
  'body_site': '部位',
  'severity_text': '严重程度',
  'ongoing': '是否持续',
  'activity': '项目',
  'duration_text': '时长',
  'duration_min': '时长（分钟）',
  'intensity_text': '强度',
  'text': '内容',
  'tags': '标签',
};

const _partOfDayLabels = {
  PartOfDay.earlyMorning: '凌晨',
  PartOfDay.morning: '上午',
  PartOfDay.noon: '中午',
  PartOfDay.afternoon: '下午',
  PartOfDay.evening: '傍晚',
  PartOfDay.night: '夜里',
};

/// 发生时间的展示文字，忠实于精度（不编造时刻）。
String timeValueText(TimeValue tv) {
  final date = tv.localDate == null ? '' : _dateText(tv.localDate!);
  switch (tv.precision) {
    case TimePrecision.exact:
    case TimePrecision.approx:
      final t = DateTime.fromMillisecondsSinceEpoch(tv.instantUtcMs!).toLocal();
      final hm = '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
      return tv.precision == TimePrecision.approx ? '$date $hm 前后' : '$date $hm';
    case TimePrecision.partOfDay:
      return '$date${_partOfDayLabels[tv.partOfDay]}';
    case TimePrecision.dateOnly:
      return date;
    case TimePrecision.unknown:
      return date.isEmpty ? '时间不详' : '$date（按发送时间推断）';
  }
}

String _dateText(String localDate) {
  final d = DateTime.parse(localDate);
  return '${d.month}月${d.day}日';
}

Map<String, Object?> decodeData(RecordRevision rev) =>
    (jsonDecode(rev.data) as Map).cast<String, Object?>();
