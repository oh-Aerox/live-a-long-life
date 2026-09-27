import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../field_meta.dart';
import '../ids.dart';
import '../time_value.dart';

/// 一条来源链接的写入参数（schema §3.6）。
class SourceLink {
  const SourceLink({
    required this.sourceKind,
    required this.sourceId,
    this.fieldPath,
    this.messageRevisionNo,
    this.span,
  });

  final RecordSourceKind sourceKind;
  final String sourceId;
  final String? fieldPath;
  final int? messageRevisionNo;
  final String? span;
}

/// 目标记录已被更新（版本不符），调用方按 D-05 记 `stale_target` 并重排。
class StaleTargetException implements Exception {
  StaleTargetException(this.recordId, this.expected, this.actual);
  final String recordId;
  final int expected;
  final int actual;

  @override
  String toString() =>
      'StaleTargetException: 记录 $recordId 期望版本 $expected，实际 $actual';
}

/// 记录读写（schema §3.3–§3.6）。
///
/// - 记录的通用 `version` 与最新版本行的 `record_version` 保持一致，
///   整理提交用它做过时检查（D-05 第 2 条）；
/// - 每个新版本连同来源链接、记录表的冗余字段在同一事务写入；
/// - `records.local_date` 冗余自当前版本 `occurred.local_date`，按日查询用。
class RecordRepository {
  RecordRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 新建记录及其第 1 版。`recordId` 可由调用方预生成
  /// （整理批次在提交前就要有稳定 ID，schema §3.1a）。
  Future<RecordRow> create({
    String? recordId,
    required RecordType recordType,
    required TimeValue occurred,
    TimeValue? occurredEnd,
    required String dataJson,
    required FieldMetaMap fieldMeta,
    required ProducedBy producedBy,
    List<SourceLink> sources = const [],
  }) {
    return _db.transaction(() async {
      final rid = recordId ?? ids.newId();
      final now = ids.nowMs();
      final revisionId = ids.newId();
      await _db.into(_db.records).insert(RecordsCompanion.insert(
            id: rid,
            userId: _ctx.userId,
            createdAt: now,
            createdOnDevice: _ctx.deviceId,
            recordType: recordType,
            currentRevisionId: Value(revisionId),
            localDate: Value(occurred.localDate),
          ));
      await _insertRevision(
        revisionId: revisionId,
        recordId: rid,
        recordVersion: 1,
        baseVersion: null,
        occurred: occurred,
        occurredEnd: occurredEnd,
        dataJson: dataJson,
        fieldMeta: fieldMeta,
        producedBy: producedBy,
        sources: sources,
        now: now,
      );
      return (_db.select(_db.records)..where((t) => t.id.equals(rid)))
          .getSingle();
    });
  }

  /// 追加新版本。`baseVersion` 是调用方读取时的记录版本：
  /// 与当前版本不符时抛 [StaleTargetException]，什么都不写（D-05 第 2 条）。
  Future<RecordRow> addRevision({
    required String recordId,
    required int baseVersion,
    required TimeValue occurred,
    TimeValue? occurredEnd,
    required String dataJson,
    required FieldMetaMap fieldMeta,
    required ProducedBy producedBy,
    List<SourceLink> sources = const [],
  }) {
    return _db.transaction(() async {
      final rec = await (_db.select(_db.records)
            ..where((t) => t.id.equals(recordId)))
          .getSingle();
      if (rec.version != baseVersion) {
        throw StaleTargetException(recordId, baseVersion, rec.version);
      }
      final now = ids.nowMs();
      final revisionId = ids.newId();
      final newVersion = rec.version + 1;
      await _insertRevision(
        revisionId: revisionId,
        recordId: recordId,
        recordVersion: newVersion,
        baseVersion: baseVersion,
        occurred: occurred,
        occurredEnd: occurredEnd,
        dataJson: dataJson,
        fieldMeta: fieldMeta,
        producedBy: producedBy,
        sources: sources,
        now: now,
      );
      final updated = await (_db.update(_db.records)
            ..where((t) => t.id.equals(recordId)))
          .writeReturning(RecordsCompanion(
        currentRevisionId: Value(revisionId),
        localDate: Value(occurred.localDate),
        version: Value(newVersion),
      ));
      return updated.single;
    });
  }

  Future<void> _insertRevision({
    required String revisionId,
    required String recordId,
    required int recordVersion,
    required int? baseVersion,
    required TimeValue occurred,
    required TimeValue? occurredEnd,
    required String dataJson,
    required FieldMetaMap fieldMeta,
    required ProducedBy producedBy,
    required List<SourceLink> sources,
    required int now,
  }) async {
    await _db.into(_db.recordRevisions).insert(RecordRevisionsCompanion.insert(
          id: revisionId,
          userId: _ctx.userId,
          createdAt: now,
          createdOnDevice: _ctx.deviceId,
          recordId: recordId,
          recordVersion: recordVersion,
          baseVersion: Value(baseVersion),
          occurred: occurred.encode(),
          occurredEnd: Value(occurredEnd?.encode()),
          data: dataJson,
          producedBy: producedBy.encode(),
          fieldMeta: fieldMeta.encode(),
        ));
    for (final s in sources) {
      await _db.into(_db.recordSources).insert(RecordSourcesCompanion.insert(
            id: ids.newId(),
            userId: _ctx.userId,
            createdAt: now,
            createdOnDevice: _ctx.deviceId,
            recordRevisionId: revisionId,
            fieldPath: Value(s.fieldPath),
            sourceKind: s.sourceKind,
            sourceId: s.sourceId,
            messageRevisionNo: Value(s.messageRevisionNo),
            span: Value(s.span),
          ));
    }
  }

  /// 标记删除，`version` 加 1（schema §1.1）。
  Future<RecordRow> markDeleted(String recordId) {
    return _db.transaction(() async {
      final rec = await (_db.select(_db.records)
            ..where((t) => t.id.equals(recordId)))
          .getSingle();
      if (rec.deletedAt != null) return rec;
      final updated = await (_db.update(_db.records)
            ..where((t) => t.id.equals(recordId)))
          .writeReturning(RecordsCompanion(
        deletedAt: Value(ids.nowMs()),
        version: Value(rec.version + 1),
      ));
      return updated.single;
    });
  }

  Future<RecordRow?> byId(String recordId) => (_db.select(_db.records)
        ..where((t) => t.id.equals(recordId)))
      .getSingleOrNull();

  /// 某天的全部记录（按日视图）。不含已删除。
  Future<List<RecordRow>> byDate(String localDate) => (_db.select(_db.records)
        ..where((t) => t.localDate.equals(localDate) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<RecordRevision> currentRevisionOf(String recordId) async {
    final rec = await (_db.select(_db.records)
          ..where((t) => t.id.equals(recordId)))
        .getSingle();
    return (_db.select(_db.recordRevisions)
          ..where((t) => t.id.equals(rec.currentRevisionId!)))
        .getSingle();
  }

  /// 全部版本，按版本号升序。
  Future<List<RecordRevision>> revisionsOf(String recordId) =>
      (_db.select(_db.recordRevisions)
            ..where((t) => t.recordId.equals(recordId))
            ..orderBy([(t) => OrderingTerm.asc(t.recordVersion)]))
          .get();

  Future<List<RecordSource>> sourcesOf(String revisionId) =>
      (_db.select(_db.recordSources)
            ..where((t) => t.recordRevisionId.equals(revisionId)))
          .get();
}
