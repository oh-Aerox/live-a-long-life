import 'db/app_database.dart';
import 'field_meta.dart';
import 'lab_abnormal.dart';
import 'same_item.dart';

/// 记录数据的纯文本摘要与取值展示（UI 列表和咨询上下文共用，无 UI 依赖）。

const _valueLabels = {
  'eaten': '吃了',
  'skipped': '明确没吃',
  'breakfast': '早餐',
  'lunch': '午餐',
  'dinner': '晚餐',
  'snack': '加餐',
  'drink': '饮水',
  'unknown': '未注明',
  'present': '有不适',
  'explicitly_none': '明确没有',
  'done': '做了',
};

String fieldValueText(Object? value) {
  if (value == null) return '—';
  if (value is bool) return value ? '是' : '否';
  if (value is String) return _valueLabels[value] ?? value;
  if (value is List) {
    return value
        .map((e) {
          if (e is Map && e['name'] != null) {
            final amount = e['amount_text'];
            return amount == null ? '${e['name']}' : '${e['name']}（$amount）';
          }
          return fieldValueText(e);
        })
        .join('、');
  }
  return value.toString();
}

/// 列表里的一行摘要。
String recordSummary(RecordType type, Map<String, Object?> data) {
  switch (type) {
    case RecordType.meal:
      final desc = data['description'] ?? fieldValueText(data['items']);
      // 没说是哪一顿的不加前缀，免得显示成"未知：苹果"（D-47）。
      final rawSlot = data['meal_slot'];
      if (rawSlot == null || rawSlot == 'unknown') {
        return data['status'] == 'skipped' ? '明确没吃' : '$desc';
      }
      final slot = fieldValueText(rawSlot);
      return data['status'] == 'skipped' ? '$slot：明确没吃' : '$slot：$desc';
    case RecordType.sleep:
      // 时间点是 {"local_date","local_time"}（schema §3.5）；早期数据有
      // sleep_onset_text 文本字段，一并兼容。
      final parts = <String>[
        for (final (key, label) in const [
          ('bedtime', '上床'),
          ('sleep_onset', '入睡'),
          ('wake_time', '醒来'),
          ('out_of_bed', '起床'),
        ])
          if (_timeOf(data[key]) case final t?) '$label $t',
        if (data['sleep_onset_text'] != null && data['sleep_onset'] == null)
          '入睡 ${data['sleep_onset_text']}',
        if (data['quality_text'] != null) '${data['quality_text']}',
      ];
      return parts.isEmpty ? '睡眠记录' : parts.join('，');
    case RecordType.mood:
      return '${data['description'] ?? '心情记录'}';
    case RecordType.symptom:
      if (data['status'] == 'explicitly_none') return '明确没有不适';
      return [
        data['body_site'],
        data['description'],
      ].whereType<Object>().join('：');
    case RecordType.exercise:
      if (data['status'] == 'explicitly_none') return '明确没有运动';
      return [
        data['activity'],
        data['duration_text'],
      ].whereType<Object>().join(' ');
    case RecordType.note:
      return '${data['text'] ?? ''}';
    case RecordType.labPanel:
      final results = (data['results'] as List?)?.length ?? 0;
      final findings = (data['findings'] as List?)?.length ?? 0;
      final medications = (data['medications'] as List?)?.length ?? 0;
      return [
        if (results > 0 || findings + medications == 0) '检验结果 $results 项',
        if (findings > 0) '文字内容 $findings 段',
        if (medications > 0) '药品 $medications 种',
      ].join('，');
    case RecordType.condition:
      final status = data['status'] == 'resolved' ? '（已痊愈）' : '';
      final kind = data['persistence'] == 'long_term' ? '长期' : '近期';
      return '$kind：${data['name'] ?? '身体状况'}$status';
  }
}

/// 时间点字段的显示：有时刻显示时刻，只有日期显示日期。
String? _timeOf(Object? value) {
  if (value is! Map) return null;
  final time = value['local_time'];
  if (time is String && time.isNotEmpty) return time;
  final date = value['local_date'];
  return date is String && date.isNotEmpty ? date : null;
}

/// 医疗文件提取记录里已核对的要点（D-04：未核对的不算事实，不对外发送）：
/// 诊断/结论类文字、异常检验值、处方药名。没有已核对的要点返回 null。
/// 咨询的"最近 7 天记录摘要"用它代替只报条数的 [recordSummary]。
String? reviewedMedicalSummary(Map<String, Object?> data, FieldMetaMap meta) {
  bool reviewed(String key) => meta[key]?.isProtected ?? false;
  final parts = <String>[];

  final findings = data['findings'] as List? ?? const [];
  for (var i = 0; i < findings.length; i++) {
    final f = findings[i] as Map;
    final section = '${f['section_raw'] ?? ''}';
    if (!reviewed('findings.$i')) continue;
    // 用模型整理合并过的条目（D-35）栏目是部位名，结论在内容里带标签。
    if (!RegExp('诊断|结论|提示|印象').hasMatch(section) &&
        !RegExp(
          r'(^|\n)(诊断|结论|提示|印象)[：:]',
        ).hasMatch('${f['text_raw'] ?? ''}')) {
      continue;
    }
    parts.add('$section：${f['text_raw']}');
  }

  final abnormal = <String>[];
  final results = data['results'] as List? ?? const [];
  for (var i = 0; i < results.length; i++) {
    final r = results[i] as Map;
    if (!reviewed('results.$i')) continue;
    if (!isAbnormalLab(
      flagRaw: r['flag_raw'] as String?,
      valueRaw: '${r['value_raw']}',
      valueNum: (r['value_num'] as num?)?.toDouble(),
      refLow: (r['ref_low'] as num?)?.toDouble(),
      refHigh: (r['ref_high'] as num?)?.toDouble(),
      refRangeRaw: r['ref_range_raw'] as String?,
    )) {
      continue;
    }
    // 尿常规的"白细胞"给模型看时带上大项，免得当成血白细胞（D-36）。
    final panel = r['panel_raw'] is String ? r['panel_raw'] as String : null;
    abnormal.add(
      [
        if (SameItem.specimenOf(panel) != null) SameItem.panelGroup(panel),
        SameItem.itemName('${r['item_name_raw']}'),
        '${r['value_raw']}${r['unit_raw'] ?? ''}',
        if (r['flag_raw'] != null) r['flag_raw'],
        if (r['ref_range_raw'] != null) '（参考 ${r['ref_range_raw']}）',
      ].join(' '),
    );
  }
  if (abnormal.isNotEmpty) parts.add('异常指标：${abnormal.join('、')}');

  final meds = data['medications'] as List? ?? const [];
  final names = [
    for (var i = 0; i < meds.length; i++)
      if (reviewed('medications.$i')) '${(meds[i] as Map)['name']}',
  ];
  if (names.isNotEmpty) parts.add('开药：${names.join('、')}');

  return parts.isEmpty ? null : parts.join('；');
}
