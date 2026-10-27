import 'dart:convert';

import '../data/condition_entry.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/time_value.dart';
import 'body_map.dart';

/// 健康档案首页的概况：各入口旁边显示的待办和数量（只有计数，不含具体
/// 内容）。
class HealthOverview {
  const HealthOverview({
    this.pendingRecordDocs = 0,
    this.unextractedRecordDocs = 0,
    this.pendingExamDocs = 0,
    this.unextractedExamDocs = 0,
    this.lastExamDate,
    this.pendingConditions = 0,
    this.attention = 0,
    this.labItems = 0,
  });

  /// 病例夹里有未核对项的文件数、还没提取的文件数。
  final int pendingRecordDocs;
  final int unextractedRecordDocs;

  /// 体检里的同上。
  final int pendingExamDocs;
  final int unextractedExamDocs;

  /// 最近一次体检的日期（yyyy-MM-dd），没有为 null。
  final String? lastExamDate;

  /// 长期状况档案里未核对的条数。
  final int pendingConditions;

  /// 人体图上需要关注的条数（同一条归到几个器官只算一次）。
  final int attention;

  /// 指标趋势里的检验项目数。
  final int labItems;

  static Future<HealthOverview> load({
    required RecordRepository records,
    required MedicalDocumentRepository documents,
    required ProfileRepository profile,
  }) async {
    // 每份文件的提取记录：有没有、有没有未核对的项。
    final pendingDocs = <String>{};
    final extractedDocs = <String>{};
    for (final rec in await records.byType(RecordType.labPanel)) {
      final rev = await records.currentRevisionOf(rec.id);
      final docId = (jsonDecode(rev.data) as Map)['medical_document_id'];
      if (docId is! String) continue;
      extractedDocs.add(docId);
      if (FieldMetaMap.decode(
        rev.fieldMeta,
      ).fields.values.any((m) => m.reviewStatus == ReviewStatus.unreviewed)) {
        pendingDocs.add(docId);
      }
    }

    var pendingRecord = 0, unextractedRecord = 0;
    var pendingExam = 0, unextractedExam = 0;
    String? lastExam;
    for (final d in await documents.all()) {
      final exam = d.docType == MedicalDocType.physicalExam;
      final pending = pendingDocs.contains(d.id);
      final unextracted = !extractedDocs.contains(d.id);
      if (exam) {
        if (pending) pendingExam++;
        if (unextracted) unextractedExam++;
        final date = d.examDate == null
            ? null
            : TimeValue.decode(d.examDate!).localDate;
        if (date != null &&
            (lastExam == null || date.compareTo(lastExam) > 0)) {
          lastExam = date;
        }
      } else {
        if (pending) pendingRecord++;
        if (unextracted) unextractedRecord++;
      }
    }

    // 与档案页同一口径：同一问题的多份报告归成一行，只看最新那条（D-32）。
    // 较早报告的记录确认、痊愈都不再动，逐条数会一直剩着。
    final conditions = <ConditionEntry>[];
    for (final rec in await records.byType(RecordType.condition)) {
      final rev = await records.currentRevisionOf(rec.id);
      conditions.add(
        ConditionEntry(
          rec,
          rev,
          (jsonDecode(rev.data) as Map).cast<String, Object?>(),
          FieldMetaMap.decode(rev.fieldMeta),
        ),
      );
    }
    final pendingConditions = ConditionEntry.groups(
      conditions,
    ).where((g) => !g.first.reviewed).length;

    final body = await BodyMapService(
      records: records,
      profile: profile,
    ).load();
    final attention = {
      for (final list in body.byOrgan.values)
        for (final f in list) '${f.recordId}|${f.kind.name}|${f.title}',
    }.length;

    return HealthOverview(
      pendingRecordDocs: pendingRecord,
      unextractedRecordDocs: unextractedRecord,
      pendingExamDocs: pendingExam,
      unextractedExamDocs: unextractedExam,
      lastExamDate: lastExam,
      pendingConditions: pendingConditions,
      attention: attention,
      labItems: (await records.labResultLatestPerItem()).length,
    );
  }
}
