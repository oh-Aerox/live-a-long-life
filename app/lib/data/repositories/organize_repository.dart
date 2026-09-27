import 'package:drift/drift.dart';

import '../app_context.dart';
import '../change_log.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 整理批次与逐项结果的读写（schema §3.1、§3.1a、§3.2）。
///
/// 只负责落盘和状态机；prompt 组装、模型调用、D-05 提交规则的编排
/// 在 V2-M2 的整理服务里实现。
class OrganizeRepository {
  OrganizeRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 新建批次，初始状态 `queued`。
  Future<OrganizeRun> createRun({
    required OrganizeTrigger trigger,
    required String inputSnapshotJson,
    String? modelConfigId,
    String? modelSnapshotJson,
  }) {
    return _db.transaction(() async {
      final now = ids.nowMs();
      final run = await _db.into(_db.organizeRuns).insertReturning(
            OrganizeRunsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              trigger: trigger,
              inputSnapshot: inputSnapshotJson,
              modelConfigId: Value(modelConfigId),
              modelSnapshot: Value(modelSnapshotJson),
              status: OrganizeRunStatus.queued,
            ),
          );
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'organize_runs', entityId: run.id);
      return run;
    });
  }

  Future<OrganizeRun> updateRunStatus(
    String runId,
    OrganizeRunStatus status, {
    String? error,
    int? startedAt,
    int? finishedAt,
  }) async {
    return _db.transaction(() async {
      final updated = await (_db.update(_db.organizeRuns)
            ..where((t) => t.id.equals(runId)))
          .writeReturning(OrganizeRunsCompanion(
        status: Value(status),
        error: Value(error),
        startedAt: startedAt == null ? const Value.absent() : Value(startedAt),
        finishedAt:
            finishedAt == null ? const Value.absent() : Value(finishedAt),
      ));
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'organize_runs', entityId: runId);
      return updated.single;
    });
  }

  /// 下一个待处理批次。批次不并发：同一时间只有一个 running
  /// （schema §3.1a），由整理服务串行取用。
  Future<OrganizeRun?> nextQueuedRun() => (_db.select(_db.organizeRuns)
        ..where((t) => t.status.equalsValue(OrganizeRunStatus.queued))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        ..limit(1))
      .getSingleOrNull();

  /// 登记批次的一项。同一 (run, record) 已存在时原样返回——
  /// 重试凭 `record_id` 识别已有项，不重复建（schema §3.1a）。
  /// `initialRetryCount` 继承此前批次对同一目标记录的重排次数。
  Future<OrganizeRunItem> upsertItem({
    required String organizeRunId,
    required String recordId,
    required OrganizeItemStatus status,
    int initialRetryCount = 0,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.organizeRunItems)
            ..where((t) =>
                t.organizeRunId.equals(organizeRunId) &
                t.recordId.equals(recordId)))
          .getSingleOrNull();
      if (existing != null) return existing;
      final now = ids.nowMs();
      final item = await _db.into(_db.organizeRunItems).insertReturning(
            OrganizeRunItemsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              organizeRunId: organizeRunId,
              recordId: recordId,
              status: status,
              retryCount: Value(initialRetryCount),
            ),
          );
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'organize_run_items',
          entityId: item.id);
      return item;
    });
  }

  /// 更新一项的状态。`stale_input` / `stale_target` 时 `retry_count` 加 1，
  /// 达到 2 由调用方转 `needs_manual`（D-05 第 4 条）。
  Future<OrganizeRunItem> markItem(
    String itemId,
    OrganizeItemStatus status, {
    String? correctionSuggestionId,
  }) {
    return _db.transaction(() async {
      final item = await (_db.select(_db.organizeRunItems)
            ..where((t) => t.id.equals(itemId)))
          .getSingle();
      final bumpsRetry = status == OrganizeItemStatus.staleInput ||
          status == OrganizeItemStatus.staleTarget;
      final updated = await (_db.update(_db.organizeRunItems)
            ..where((t) => t.id.equals(itemId)))
          .writeReturning(OrganizeRunItemsCompanion(
        status: Value(status),
        retryCount:
            bumpsRetry ? Value(item.retryCount + 1) : const Value.absent(),
        correctionSuggestionId: correctionSuggestionId == null
            ? const Value.absent()
            : Value(correctionSuggestionId),
        version: Value(item.version + 1),
      ));
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'organize_run_items',
          entityId: itemId);
      return updated.single;
    });
  }

  Future<List<OrganizeRunItem>> itemsOf(String runId) =>
      (_db.select(_db.organizeRunItems)
            ..where((t) => t.organizeRunId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// 记一次模型调用（D-16 透明度）。
  Future<ModelCall> recordModelCall({
    String? organizeRunId,
    required String modelConfigId,
    required DataBoundary dataBoundary,
    required String sentMessageIdsJson,
    required String sentAttachmentIdsJson,
    required int requestAt,
    int? responseAt,
    required ModelCallStatus status,
    int? tokensIn,
    int? tokensOut,
    String? responseText,
    required ModelCaller caller,
  }) {
    return _db.transaction(() async {
      final call = await _db.into(_db.modelCalls).insertReturning(
          ModelCallsCompanion.insert(
            id: ids.newId(),
            userId: _ctx.userId,
            createdAt: ids.nowMs(),
            createdOnDevice: _ctx.deviceId,
            organizeRunId: Value(organizeRunId),
            modelConfigId: modelConfigId,
            dataBoundary: dataBoundary,
            sentMessageIds: sentMessageIdsJson,
            sentAttachmentIds: sentAttachmentIdsJson,
            requestAt: requestAt,
            responseAt: Value(responseAt),
            status: status,
            tokensIn: Value(tokensIn),
            tokensOut: Value(tokensOut),
            responseText: Value(responseText),
            caller: caller,
          ),
        );
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'model_calls', entityId: call.id);
      return call;
    });
  }

  /// 调用记录，最新在前（设置页"模型调用记录"用）。
  Future<List<ModelCall>> recentModelCalls({int limit = 50}) =>
      (_db.select(_db.modelCalls)
            ..orderBy([(t) => OrderingTerm.desc(t.requestAt)])
            ..limit(limit))
          .get();
}
