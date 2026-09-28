import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_context.dart';
import '../change_log.dart';
import '../db/app_database.dart';
import '../field_meta.dart';
import '../ids.dart';
import '../time_value.dart';

/// 医疗文件的一页：来自哪条消息的哪个附件、在文件中排第几页（schema §5.1）。
class MedicalPageRef {
  const MedicalPageRef({
    required this.attachmentId,
    required this.messageId,
    required this.pageNo,
  });

  final String attachmentId;
  final String messageId;
  final int pageNo;

  Map<String, Object?> toJson() => {
        'attachment_id': attachmentId,
        'message_id': messageId,
        'page_no': pageNo,
      };

  static MedicalPageRef fromJson(Map<String, Object?> json) => MedicalPageRef(
        attachmentId: json['attachment_id'] as String,
        messageId: json['message_id'] as String,
        pageNo: json['page_no'] as int,
      );

  static List<MedicalPageRef> decodeList(String json) => [
        for (final e in jsonDecode(json) as List)
          MedicalPageRef.fromJson((e as Map).cast<String, Object?>()),
      ];

  static String encodeList(List<MedicalPageRef> pages) =>
      jsonEncode([for (final p in pages) p.toJson()]);
}

/// 医疗文件（v0.4 V4-M0，schema §5.1）。手机是唯一编辑者（D-12），
/// 每次写入在同一事务里记变更日志同步 Mac。
class MedicalDocumentRepository {
  MedicalDocumentRepository(this._db, this._ctx,
      {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 新建医疗文件。页序按传入顺序；exam/report 日期允许先空着，
  /// 提取后再补（uploaded_at 与它们是三个不同的时间，D-06）。
  Future<MedicalDocument> create({
    required List<MedicalPageRef> pages,
    required MedicalDocType docType,
    String? institutionText,
    TimeValue? examDate,
    TimeValue? reportDate,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError('医疗文件至少要有一页');
    }
    final id = ids.newId();
    final now = ids.nowMs();
    return _db.transaction(() async {
      await _db.into(_db.medicalDocuments).insert(
            MedicalDocumentsCompanion.insert(
              id: id,
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              pages: MedicalPageRef.encodeList(pages),
              docType: docType,
              institutionText: Value(institutionText),
              examDate: Value(examDate?.encode()),
              reportDate: Value(reportDate?.encode()),
              uploadedAt: now,
            ),
          );
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'medical_documents', entityId: id);
      return byId(id).then((d) => d!);
    });
  }

  Future<MedicalDocument?> byId(String id) => (_db.select(_db.medicalDocuments)
        ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
      .getSingleOrNull();

  /// 全部医疗文件，新上传的在前。
  Future<List<MedicalDocument>> all() => (_db.select(_db.medicalDocuments)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)]))
      .get();

  /// 调整页序或增删页（多页报告可由不同消息的照片组成，页序用户可调）。
  Future<MedicalDocument> updatePages(
      String id, List<MedicalPageRef> pages) async {
    if (pages.isEmpty) {
      throw ArgumentError('医疗文件至少要有一页');
    }
    return _update(id, (doc) {
      return MedicalDocumentsCompanion(
        pages: Value(MedicalPageRef.encodeList(pages)),
      );
    });
  }

  /// 提取后回填文件级字段（类型、机构、检查/报告日期）。
  Future<MedicalDocument> updateInfo(
    String id, {
    MedicalDocType? docType,
    String? institutionText,
    TimeValue? examDate,
    TimeValue? reportDate,
  }) =>
      _update(id, (doc) {
        return MedicalDocumentsCompanion(
          docType: docType == null ? const Value.absent() : Value(docType),
          institutionText: institutionText == null
              ? const Value.absent()
              : Value(institutionText),
          examDate:
              examDate == null ? const Value.absent() : Value(examDate.encode()),
          reportDate: reportDate == null
              ? const Value.absent()
              : Value(reportDate.encode()),
        );
      });

  /// 文件级核对状态（关键字段确认才作为事实的规则在 lab_panel 字段级，
  /// 这里是文件整体的核对进度展示用）。
  Future<MedicalDocument> setReviewStatus(String id, ReviewStatus status) =>
      _update(
          id, (doc) => MedicalDocumentsCompanion(reviewStatus: Value(status)));

  /// 标记删除，`version` 加 1（schema §1.1）。文件副本的清理（D-22）
  /// 走 attachment_copies，不动本表。
  Future<MedicalDocument> markDeleted(String id) async {
    final doc = await byId(id);
    if (doc == null) throw StateError('医疗文件不存在：$id');
    return _db.transaction(() async {
      await (_db.update(_db.medicalDocuments)..where((t) => t.id.equals(id)))
          .write(MedicalDocumentsCompanion(
        deletedAt: Value(ids.nowMs()),
        version: Value(doc.version + 1),
      ));
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'medical_documents',
          entityId: id,
          op: ChangeOp.delete);
      return (_db.select(_db.medicalDocuments)..where((t) => t.id.equals(id)))
          .getSingle();
    });
  }

  Future<MedicalDocument> _update(String id,
      MedicalDocumentsCompanion Function(MedicalDocument doc) change) async {
    final doc = await byId(id);
    if (doc == null) throw StateError('医疗文件不存在：$id');
    return _db.transaction(() async {
      await (_db.update(_db.medicalDocuments)..where((t) => t.id.equals(id)))
          .write(change(doc).copyWith(version: Value(doc.version + 1)));
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'medical_documents', entityId: id);
      return (_db.select(_db.medicalDocuments)..where((t) => t.id.equals(id)))
          .getSingle();
    });
  }
}
