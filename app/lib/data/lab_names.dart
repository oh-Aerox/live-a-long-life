import 'lab_catalog.dart';
import 'same_item.dart';

/// 检验项目的标准名（D-49）：提取时模型对号入座给出的名字，经本地检查后
/// 写进结果的 `item_std`（直接生效）或 `item_std_suggested`（待用户确认）。
///
/// 优先顺序：用户在记录里定过的（已有 `item_std` 的同一写法）> 内置目录
/// > 模型给的已有项目名 > 模型给的新名字（待确认）> 规则清洗后的原文名。
/// 本地检查：标本不同不直接合（尿糖与血糖），单位对不上不合（尿素与尿
/// 素氮常用单位不同时），规则或目录已认得的写法不听模型的。
class LabNames {
  const LabNames._();

  /// 键的标本：尿 / 便；血液和其他为 null（"尿酸""尿素"是血液项目）。
  static String? specimenOfKey(String key) => key.startsWith('便')
      ? '便'
      : RegExp(r'^尿(?!酸|素)').hasMatch(key)
          ? '尿'
          : null;

  /// 比较用的单位：小写、去空白和幂次写法；没有单位或"-"为空串。
  static String normUnit(String? unit) {
    final u = (unit ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s^*×]'), '')
        .replaceAll(RegExp('[μµ]'), 'u');
    return u == '-' ? '' : u;
  }

  /// 模型给的名字清洗成键：同样去缩写括号、按大项加标本前缀，再查目录。
  static String? cleanStd(Object? std, {String? panel}) {
    if (std is! String || std.trim().isEmpty) return null;
    final k = LabCatalog.canonical(SameItem.ruleKey(std, panel: panel));
    return k.isEmpty ? null : k;
  }

  /// 一项结果的单位和目标项目已有的单位对不上（两边都有单位时）。
  static bool unitConflict(String? unit, Set<String>? targetUnits) {
    final u = normUnit(unit);
    if (u.isEmpty || targetUnits == null) return false;
    final known = targetUnits.where((t) => t.isNotEmpty).toSet();
    return known.isNotEmpty && !known.contains(u);
  }

  /// 提取时给一项结果定标准名（就地写 [r]）。
  ///
  /// [known] 是记录里已有的"自动归类的键 → 标准名"（用户合并、拆出或确认
  /// 过的），[existingKeys] 是趋势里已有的项目，[units] 是各项目出现过的
  /// 单位（[normUnit] 后）。
  static void assign(
    Map<String, Object?> r, {
    required Object? modelStd,
    required Map<String, String> known,
    required Set<String> existingKeys,
    required Map<String, Set<String>> units,
  }) {
    r.remove('item_std');
    r.remove('item_std_suggested');
    final raw = r['item_name_raw'];
    if (raw is! String) return;
    final panel = r['panel_raw'] is String ? r['panel_raw'] as String : null;
    final auto = SameItem.labKey(raw, panel: panel);

    // 1. 同一写法以前定过的，照旧（跨标本的只对当时那一条，不往下传）。
    final prior = known[auto];
    if (prior != null) {
      if (specimenOfKey(prior) == specimenOfKey(auto)) r['item_std'] = prior;
      return;
    }
    // 2. 规则或目录已经认得的，不听模型的。
    if (LabCatalog.contains(SameItem.ruleKey(raw, panel: panel))) return;

    final std = cleanStd(modelStd, panel: panel);
    if (std == null || std == auto) return;
    if (unitConflict(r['unit_raw'] as String?, units[std])) return;
    // 3. 标本不同（多半是报告没标大项）：可能对，但要用户确认。
    final sameSpecimen = specimenOfKey(std) == specimenOfKey(auto);
    // 4. 目录里或已有的项目：直接生效；新名字：待确认。
    if (sameSpecimen &&
        (LabCatalog.byName.containsKey(std) || existingKeys.contains(std))) {
      r['item_std'] = std;
    } else {
      r['item_std_suggested'] = std;
    }
  }

  /// 整理现有名称时模型的一条建议（[from] 是趋势里现在的键）：清洗后
  /// 通过检查的返回标准名，不通过返回 null。跨标本的不收：没有上下文
  /// 判断不了，由用户改大项（D-36）。
  static String? checkProposal(
    String from,
    Object? std, {
    required Set<String> fromUnits,
    required Map<String, Set<String>> units,
  }) {
    final k = cleanStd(std);
    if (k == null || k == from) return null;
    if (specimenOfKey(k) != specimenOfKey(from)) return null;
    if (fromUnits.any((u) => unitConflict(u, units[k]))) return null;
    return k;
  }
}
