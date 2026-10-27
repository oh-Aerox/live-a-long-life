import 'db/app_database.dart';
import 'field_meta.dart';
import 'same_item.dart';

/// 一条身体状况记录的当前版本（D-25）。档案页、人体图、咨询上下文共用。
class ConditionEntry {
  ConditionEntry(this.record, this.rev, this.data, this.meta);

  final RecordRow record;
  final RecordRevision rev;
  final Map<String, Object?> data;
  final FieldMetaMap meta;

  String get name => data['name'] as String? ?? '未命名';
  bool get longTerm => data['persistence'] == 'long_term';
  bool get resolved => data['status'] == 'resolved';
  bool get reviewed => meta['condition']?.isProtected ?? false;
  String? get date => record.localDate;
  String? get medicalDocumentId => data['medical_document_id'] as String?;

  /// 用户手动合并到的问题名（D-46）；没合并过为 null。
  String? get mergedInto => data['group_name'] as String?;

  /// 分组用的名字：合并过的用合并到的名字。
  String get groupKey => mergedInto ?? name;

  /// 同一问题的各条记录（不同年份的报告各建一条）归成一组，组内新的在前。
  /// 看当前状况取每组第一条（D-32）。两条的分组名或原名任一说的是同一
  /// 问题就归一组（D-46：合并后，以后报告里的旧写法也跟着归进来）。
  static List<List<ConditionEntry>> groups(Iterable<ConditionEntry> entries) {
    final list = entries.toList();
    final parent = List.generate(list.length, (i) => i);
    int find(int i) => parent[i] == i ? i : parent[i] = find(parent[i]);
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i], b = list[j];
        if (SameItem.sameProblem(a.groupKey, b.groupKey) ||
            SameItem.sameProblem(a.name, b.name)) {
          parent[find(j)] = find(i);
        }
      }
    }
    final byRoot = <int, List<ConditionEntry>>{};
    for (var i = 0; i < list.length; i++) {
      (byRoot[find(i)] ??= []).add(list[i]);
    }
    // 组内新的在前、组按最新日期新→旧；日期相同保持原顺序。
    final out = [for (final g in byRoot.values) _newestFirst(g, (c) => c.date)];
    return _newestFirst(out, (g) => g.first.date);
  }

  /// 按日期新→旧的稳定排序（List.sort 不保证稳定，带上原下标兜底）。
  static List<E> _newestFirst<E>(List<E> list, String? Function(E) date) {
    final indexed = list.indexed.toList()
      ..sort((a, b) {
        final c = (date(b.$2) ?? '').compareTo(date(a.$2) ?? '');
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return [for (final (_, e) in indexed) e];
  }
}
