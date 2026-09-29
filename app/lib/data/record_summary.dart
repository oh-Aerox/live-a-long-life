import 'db/app_database.dart';

/// 记录数据的纯文本摘要与取值展示（UI 列表和咨询上下文共用，无 UI 依赖）。

const _valueLabels = {
  'eaten': '吃了',
  'skipped': '明确没吃',
  'breakfast': '早餐',
  'lunch': '午餐',
  'dinner': '晚餐',
  'snack': '加餐',
  'unknown': '未知',
  'present': '有不适',
  'explicitly_none': '明确没有',
  'done': '做了',
};

String fieldValueText(Object? value) {
  if (value == null) return '—';
  if (value is bool) return value ? '是' : '否';
  if (value is String) return _valueLabels[value] ?? value;
  if (value is List) {
    return value.map((e) {
      if (e is Map && e['name'] != null) {
        final amount = e['amount_text'];
        return amount == null ? '${e['name']}' : '${e['name']}（$amount）';
      }
      return fieldValueText(e);
    }).join('、');
  }
  return value.toString();
}

/// 列表里的一行摘要。
String recordSummary(RecordType type, Map<String, Object?> data) {
  switch (type) {
    case RecordType.meal:
      final slot = fieldValueText(data['meal_slot']);
      final desc = data['description'] ?? fieldValueText(data['items']);
      return data['status'] == 'skipped' ? '$slot：明确没吃' : '$slot：$desc';
    case RecordType.sleep:
      final parts = <String>[
        if (data['sleep_onset_text'] != null) '入睡 ${data['sleep_onset_text']}',
        if (data['quality_text'] != null) '${data['quality_text']}',
      ];
      return parts.isEmpty ? '睡眠记录' : parts.join('，');
    case RecordType.mood:
      return '${data['description'] ?? '心情记录'}';
    case RecordType.symptom:
      if (data['status'] == 'explicitly_none') return '明确没有不适';
      return [data['body_site'], data['description']]
          .whereType<Object>()
          .join('：');
    case RecordType.exercise:
      if (data['status'] == 'explicitly_none') return '明确没有运动';
      return [data['activity'], data['duration_text']]
          .whereType<Object>()
          .join(' ');
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
