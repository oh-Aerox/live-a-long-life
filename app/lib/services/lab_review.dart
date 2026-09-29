import 'dart:convert';

import '../data/field_meta.dart';

/// 逐项核对的纯数据变换（D-04：项目、数值、单位、参考范围、检查日期
/// 五个关键字段 confirmed/edited 后，该项才作为事实参与分析）。
/// 写库走 RecordRepository.addRevision，索引随版本自动重建（D-27）。
class LabReview {
  /// 确认第 [index] 项无误：字段值不变，results.{i} 状态转 confirmed。
  static (String, FieldMetaMap) confirmResult(
      String dataJson, FieldMetaMap meta, int index) {
    _requireIndex(dataJson, index);
    final fields = Map<String, FieldMeta>.from(meta.fields);
    final old = fields['results.$index'];
    fields['results.$index'] = FieldMeta(
      origin: old?.origin ?? FieldOrigin.modelInferred,
      reviewStatus: ReviewStatus.confirmed,
    );
    return (dataJson, FieldMetaMap(fields));
  }

  /// 确认全部项（检验数值与文字内容）。
  static (String, FieldMetaMap) confirmAll(String dataJson, FieldMetaMap meta) {
    final results = _results(dataJson);
    var out = (dataJson, meta);
    for (var i = 0; i < results.length; i++) {
      out = confirmResult(out.$1, out.$2, i);
    }
    for (var i = 0; i < _findings(dataJson).length; i++) {
      out = confirmFinding(out.$1, out.$2, i);
    }
    return out;
  }

  /// 确认第 [index] 段文字内容（诊断、所见、结论等，D-28）无误。
  static (String, FieldMetaMap) confirmFinding(
      String dataJson, FieldMetaMap meta, int index) {
    if (index < 0 || index >= _findings(dataJson).length) {
      throw RangeError('文字内容不存在：$index');
    }
    final fields = Map<String, FieldMeta>.from(meta.fields);
    final old = fields['findings.$index'];
    fields['findings.$index'] = FieldMeta(
      origin: old?.origin ?? FieldOrigin.modelInferred,
      reviewStatus: ReviewStatus.confirmed,
    );
    return (dataJson, FieldMetaMap(fields));
  }

  /// 修改第 [index] 段文字内容：findings.{i} 状态转 edited。
  static (String, FieldMetaMap) editFinding(
    String dataJson,
    FieldMetaMap meta,
    int index, {
    required String sectionRaw,
    required String textRaw,
  }) {
    final data = jsonDecode(dataJson) as Map<String, Object?>;
    final findings = (data['findings'] as List).cast<Map<String, Object?>>();
    if (index < 0 || index >= findings.length) {
      throw RangeError('文字内容不存在：$index');
    }
    findings[index] = {
      ...findings[index],
      'section_raw': sectionRaw.isEmpty ? null : sectionRaw,
      'text_raw': textRaw,
    };
    data['findings'] = findings;
    final fields = Map<String, FieldMeta>.from(meta.fields);
    fields['findings.$index'] = const FieldMeta(
        origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited);
    return (jsonEncode(data), FieldMetaMap(fields));
  }

  /// 修改第 [index] 项：只更新传入的字段，results.{i} 状态转 edited。
  /// 数值原文改动时同步重算 value_num（能解析才填，不猜）。
  static (String, FieldMetaMap) editResult(
    String dataJson,
    FieldMetaMap meta,
    int index, {
    String? itemNameRaw,
    String? valueRaw,
    String? unitRaw,
    String? refRangeRaw,
  }) {
    final data = jsonDecode(dataJson) as Map<String, Object?>;
    final results = (data['results'] as List).cast<Map<String, Object?>>();
    if (index < 0 || index >= results.length) {
      throw RangeError('结果项不存在：$index');
    }
    final r = Map<String, Object?>.from(results[index]);
    if (itemNameRaw != null) r['item_name_raw'] = itemNameRaw;
    if (valueRaw != null) {
      r['value_raw'] = valueRaw;
      r['value_num'] = num.tryParse(valueRaw.trim());
    }
    if (unitRaw != null) r['unit_raw'] = unitRaw.isEmpty ? null : unitRaw;
    if (refRangeRaw != null) {
      r['ref_range_raw'] = refRangeRaw.isEmpty ? null : refRangeRaw;
      final range = _parseRange(refRangeRaw);
      r['ref_low'] = range?.$1;
      r['ref_high'] = range?.$2;
    }
    results[index] = r;
    data['results'] = results;

    final fields = Map<String, FieldMeta>.from(meta.fields);
    fields['results.$index'] = const FieldMeta(
        origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited);
    return (jsonEncode(data), FieldMetaMap(fields));
  }

  static (num, num)? _parseRange(String raw) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*[-–—~～]\s*(\d+(?:\.\d+)?)')
        .firstMatch(raw);
    if (m == null) return null;
    return (num.parse(m.group(1)!), num.parse(m.group(2)!));
  }

  static List<Object?> _results(String dataJson) =>
      (jsonDecode(dataJson) as Map)['results'] as List? ?? const [];

  /// 旧记录（D-28 之前提取的）没有 findings 字段，按空处理。
  static List<Object?> _findings(String dataJson) =>
      (jsonDecode(dataJson) as Map)['findings'] as List? ?? const [];

  static void _requireIndex(String dataJson, int index) {
    final results = _results(dataJson);
    if (index < 0 || index >= results.length) {
      throw RangeError('结果项不存在：$index');
    }
  }
}
