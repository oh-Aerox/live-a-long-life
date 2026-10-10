import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/change_log.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/ids.dart';
import '../data/repositories/record_repository.dart';
import '../data/time_value.dart';

/// 修正建议的接受与拒绝（schema §6.2，D-12：只在手机上执行）。
class SuggestionService {
  SuggestionService({
    required AppDatabase db,
    required RecordRepository records,
    required this.deviceId,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _records = records;

  final AppDatabase _db;
  final RecordRepository _records;
  final String deviceId;
  final IdGenerator ids;

  Future<List<CorrectionSuggestion>> pending() =>
      (_db.select(_db.correctionSuggestions)
            ..where((t) =>
                t.status.equalsValue(SuggestionStatus.pending) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// 接受：按建议内容生成记录新版本，字段状态 confirmed，
  /// produced_by 指向这条建议（schema §6.2）。
  /// 目标记录已有更新版本时建议转 obsolete，不套用。
  Future<SuggestionStatus> accept(CorrectionSuggestion suggestion) async {
    final record = await _records.byId(suggestion.targetRecordId);
    if (record == null ||
        record.deletedAt != null ||
        record.version != suggestion.targetVersion) {
      await _mark(suggestion.id, SuggestionStatus.obsolete);
      return SuggestionStatus.obsolete;
    }
    final rev = await _records.currentRevisionOf(record.id);
    final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
    final proposed =
        (jsonDecode(suggestion.proposedData) as Map).cast<String, Object?>();
    final meta = FieldMetaMap.decode(rev.fieldMeta).fields;
    proposed.forEach((field, value) {
      data[field] = value;
      meta[field] = const FieldMeta(
          origin: FieldOrigin.userStated, reviewStatus: ReviewStatus.confirmed);
    });
    await _records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: TimeValue.decode(rev.occurred),
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap(meta),
      producedBy: ProducedBy.acceptedSuggestion(suggestion.id),
    );
    await _mark(suggestion.id, SuggestionStatus.accepted);
    return SuggestionStatus.accepted;
  }

  Future<void> reject(CorrectionSuggestion suggestion) =>
      _mark(suggestion.id, SuggestionStatus.rejected);

  /// 记录被用户删除后，指向它的待处理建议转 obsolete，不再出现在待处理里。
  Future<void> obsoletePendingFor(String recordId) async {
    final rows = await (_db.select(_db.correctionSuggestions)
          ..where((t) =>
              t.targetRecordId.equals(recordId) &
              t.status.equalsValue(SuggestionStatus.pending) &
              t.deletedAt.isNull()))
        .get();
    for (final row in rows) {
      await _mark(row.id, SuggestionStatus.obsolete);
    }
  }

  Future<void> _mark(String suggestionId, SuggestionStatus status) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.correctionSuggestions)
            ..where((t) => t.id.equals(suggestionId)))
          .getSingle();
      await (_db.update(_db.correctionSuggestions)
            ..where((t) => t.id.equals(suggestionId)))
          .write(CorrectionSuggestionsCompanion(
        status: Value(status),
        version: Value(row.version + 1),
      ));
      // 处理状态同步给 Mac（schema §7.4：修正建议的处理状态 手机→Mac）。
      await _db.logChange(
          deviceId: deviceId,
          table: 'correction_suggestions',
          entityId: suggestionId);
    });
  }
}
