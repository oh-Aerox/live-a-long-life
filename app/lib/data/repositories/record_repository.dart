import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_context.dart';
import '../change_log.dart';
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
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'records', entityId: rid);
      if (recordType == RecordType.labPanel) {
        await _reindexLabResults(rid, revisionId, occurred, dataJson,
            fieldMeta, now);
      }
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
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'records', entityId: recordId);
      if (rec.recordType == RecordType.labPanel) {
        await _reindexLabResults(recordId, revisionId, occurred, dataJson,
            fieldMeta, now);
      }
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
    await _db.logChange(
        deviceId: _ctx.deviceId,
        table: 'record_revisions',
        entityId: revisionId);
    for (final s in sources) {
      final sourceRowId = ids.newId();
      await _db.into(_db.recordSources).insert(RecordSourcesCompanion.insert(
            id: sourceRowId,
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
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'record_sources',
          entityId: sourceRowId);
    }
    // 记录行自身由调用方在其最终状态落定后记（addRevision 的行更新
    // 发生在本方法之后，这里拍快照会拿到旧版本）。
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
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'records',
          entityId: recordId,
          op: ChangeOp.delete);
      if (rec.recordType == RecordType.labPanel) {
        await (_db.delete(_db.labResults)
              ..where((t) => t.recordId.equals(recordId)))
            .go();
      }
      return updated.single;
    });
  }

  // ---- 检验项目索引（schema §5.3，D-27）----
  // 派生数据：随 lab_panel 版本同事务重建；不入变更日志、不同步。

  static String labItemKey(String itemNameRaw) =>
      itemNameRaw.replaceAll(RegExp(r'\s'), '');

  Future<void> _reindexLabResults(
    String recordId,
    String revisionId,
    TimeValue occurred,
    String dataJson,
    FieldMetaMap fieldMeta,
    int now,
  ) async {
    await (_db.delete(_db.labResults)
          ..where((t) => t.recordId.equals(recordId)))
        .go();
    final data = jsonDecode(dataJson);
    if (data is! Map) return;
    final medicalDocumentId = data['medical_document_id'] as String?;
    final results = data['results'];
    if (results is! List) return;
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r is! Map) continue;
      final name = r['item_name_raw'];
      final valueRaw = r['value_raw'];
      if (name is! String || valueRaw is! String) continue;
      await _db.into(_db.labResults).insert(LabResultsCompanion.insert(
            recordId: recordId,
            resultIndex: i,
            revisionId: revisionId,
            medicalDocumentId: Value(medicalDocumentId),
            itemNameRaw: name,
            itemKey: labItemKey(name),
            valueRaw: valueRaw,
            valueNum: Value((r['value_num'] as num?)?.toDouble()),
            unitRaw: Value(r['unit_raw'] as String?),
            refRangeRaw: Value(r['ref_range_raw'] as String?),
            refLow: Value((r['ref_low'] as num?)?.toDouble()),
            refHigh: Value((r['ref_high'] as num?)?.toDouble()),
            flagRaw: Value(r['flag_raw'] as String?),
            examDate: Value(occurred.localDate),
            reviewStatus: Value(
                fieldMeta.fields['results.$i']?.reviewStatus ??
                    ReviewStatus.unreviewed),
            updatedAt: now,
          ));
    }
  }

  /// 整表重建索引（应用升级 / Mac 收到同步记录后按需调用）。返回行数。
  Future<int> rebuildLabResultIndex() async {
    return _db.transaction(() async {
      await _db.delete(_db.labResults).go();
      final recs = await (_db.select(_db.records)
            ..where((t) =>
                t.recordType.equalsValue(RecordType.labPanel) &
                t.deletedAt.isNull()))
          .get();
      var rows = 0;
      for (final rec in recs) {
        if (rec.currentRevisionId == null) continue;
        final rev = await (_db.select(_db.recordRevisions)
              ..where((t) => t.id.equals(rec.currentRevisionId!)))
            .getSingle();
        await _reindexLabResults(
          rec.id,
          rev.id,
          TimeValue.decode(rev.occurred),
          rev.data,
          FieldMetaMap.decode(rev.fieldMeta),
          ids.nowMs(),
        );
        rows += (await (_db.select(_db.labResults)
                  ..where((t) => t.recordId.equals(rec.id)))
                .get())
            .length;
      }
      return rows;
    });
  }

  /// 一个检验项目的历史数值，按检查日期升序（趋势视图、分析取数）。
  /// [itemKey] 用 [labItemKey] 归一化后的项目名。
  Future<List<LabResult>> labResultHistory(String itemKey) =>
      (_db.select(_db.labResults)
            ..where((t) => t.itemKey.equals(itemKey))
            ..orderBy([
              (t) => OrderingTerm.asc(t.examDate),
              (t) => OrderingTerm.asc(t.updatedAt),
            ]))
          .get();

  /// 一份医疗文件提取出的全部检验项目（详情页展示）。
  Future<List<LabResult>> labResultsOfDocument(String medicalDocumentId) =>
      (_db.select(_db.labResults)
            ..where((t) => t.medicalDocumentId.equals(medicalDocumentId))
            ..orderBy([(t) => OrderingTerm.asc(t.resultIndex)]))
          .get();

  /// 出现过的检验项目（去重），带最近一次的日期与数值，按项目名排序。
  Future<List<LabResult>> labResultLatestPerItem() async {
    final all = await (_db.select(_db.labResults)
          ..orderBy([(t) => OrderingTerm.asc(t.examDate)]))
        .get();
    final latest = <String, LabResult>{};
    for (final r in all) {
      latest[r.itemKey] = r; // 升序遍历，留下的是最新
    }
    final list = latest.values.toList()
      ..sort((a, b) => a.itemKey.compareTo(b.itemKey));
    return list;
  }

  Future<RecordRow?> byId(String recordId) => (_db.select(_db.records)
        ..where((t) => t.id.equals(recordId)))
      .getSingleOrNull();

  /// 某天的全部记录（按日视图）。不含已删除。
  Future<List<RecordRow>> byDate(String localDate) => (_db.select(_db.records)
        ..where((t) => t.localDate.equals(localDate) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  /// 自某天（含）以来的记录，日期字符串比较（yyyy-MM-dd 可比）。
  /// 整理批次用它圈定"可更新的已有记录"范围。
  Future<List<RecordRow>> since(String localDate) => (_db.select(_db.records)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.localDate.isNotNull() &
            t.localDate.isBiggerOrEqualValue(localDate))
        ..orderBy([(t) => OrderingTerm.asc(t.localDate)]))
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

  /// 精确去重：类型、日期、发生时间、data、来源消息集合都完全相同的记录，
  /// 只保留 created_at 最早的一条，其余 markDeleted（走变更日志同步）。
  /// 这种逐字段相同且来源相同的重复只会由"同一批消息被多个批次整理"
  /// 的缺陷产生（2026-09-28），正常录入不会。返回删除的条数。
  Future<int> dedupeExactDuplicates() async {
    final recs = await (_db.select(_db.records)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final seen = <String>{};
    final toDelete = <String>[];
    for (final r in recs) {
      if (r.currentRevisionId == null) continue;
      final rev = await (_db.select(_db.recordRevisions)
            ..where((t) => t.id.equals(r.currentRevisionId!)))
          .getSingle();
      final srcs = await sourcesOf(rev.id);
      final srcKey =
          (srcs.map((s) => '${s.sourceKind.name}:${s.sourceId}').toList()
                ..sort())
              .join(',');
      // 不含 occurred：同一句话被不同批次整理时 occurred 的来源标记
      // （有无时间片段等）可能有别，但内容与来源消息相同即为重复。
      // data 仍参与，A-30（同一消息两条不同运动）data 不同不会误删。
      final key = [
        enumToDb(r.recordType),
        r.localDate ?? '',
        rev.data,
        srcKey,
      ].join('||');
      if (seen.contains(key)) {
        toDelete.add(r.id);
      } else {
        seen.add(key);
      }
    }
    for (final id in toDelete) {
      await markDeleted(id);
    }
    return toDelete.length;
  }
}
