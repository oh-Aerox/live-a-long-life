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

  /// 同一问题的各条记录（不同年份的报告各建一条）归成一组，组内新的在前。
  /// 看当前状况取每组第一条（D-32）。
  static List<List<ConditionEntry>> groups(Iterable<ConditionEntry> entries) =>
      SameItem.groups(entries, (c) => c.name, (c) => c.date);
}
