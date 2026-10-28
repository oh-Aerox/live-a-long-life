/// 模型的识别错误修正（ocr_fixes，"原文→修正后"）落到字段上。
///
/// 模型有时只把修正写进 ocr_fixes、字段仍是 OCR 原文——尤其是单位里丢了
/// 上标的幂次（"*1012/L→*10^12/L"、"*10°/1.→*10^9/L"）。这里按修正说明
/// 把原文替换掉。只动文字字段，不动数值原文，免得改坏数字。
class OcrFixes {
  /// 检验数值里可以按修正说明替换的字段。
  static const resultFields = [
    'panel_raw',
    'item_name_raw',
    'unit_raw',
    'ref_range_raw',
    'flag_raw',
  ];

  /// 把 [entry] 的 ocr_fixes 应用到 [fields]，返回是否有改动。
  /// 字段已含修正后文字的不再替换（幂等）。
  static bool apply(Map<String, Object?> entry, List<String> fields) {
    var changed = false;
    for (final fix in (entry['ocr_fixes'] as List? ?? const [])) {
      if (fix is! String) continue;
      final parts = fix.split(RegExp(r'→|->'));
      if (parts.length != 2) continue;
      final from = parts[0].trim();
      final to = parts[1].trim();
      if (from.isEmpty || to.isEmpty || from == to) continue;
      for (final f in fields) {
        final v = entry[f];
        if (v is! String || !v.contains(from) || v.contains(to)) continue;
        entry[f] = v.replaceAll(from, to);
        changed = true;
      }
    }
    return changed;
  }
}
