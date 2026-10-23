/// 检验结果是否异常：报告上有异常标记，或数值超出参考范围，或定性结果
/// 阳性而参考为阴性。核对页标红、人体图、趋势页、周报与咨询的"异常指标"
/// 都用这一个口径。
bool isAbnormalLab({
  String? flagRaw,
  String? valueRaw,
  double? valueNum,
  double? refLow,
  double? refHigh,
  String? refRangeRaw,
}) {
  final flag = flagRaw?.trim() ?? '';
  if (flag.isNotEmpty && !_normalFlag.hasMatch(flag)) return true;
  if (valueNum != null) {
    if (refLow != null && valueNum < refLow) return true;
    if (refHigh != null && valueNum > refHigh) return true;
  }
  final v = valueRaw ?? '';
  if ((refRangeRaw ?? '').contains('阴性') &&
      (v.contains('阳性') || RegExp(r'^\s*\++').hasMatch(v))) {
    return true;
  }
  return false;
}

/// 报告标记栏里表示正常的写法。过敏原 IgE 分级的"0级"就是阴性，检验单
/// 照样印在标记栏里。
final _normalFlag = RegExp(
  r'^(-|—|N|正常|阴性|/|0\s*级|class\s*0)$',
  caseSensitive: false,
);
