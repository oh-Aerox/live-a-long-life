import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

/// 变更日志埋点（schema §7.2，V3-M1）。
///
/// 各仓库在业务写入的**同一事务里**调用 [logChange]：
/// - 对行拍快照作为 payload，保证负载与 entity_version 一致
///   （Codex 7_reply：不能发送时才读当前行）；
/// - change_seq 本代次内单调递增无空洞；
/// - 同时回写实体的通用 change_seq 字段（schema §1.1）。
///
/// 代次（generation）持久在 settings 的 `data_generation`，
/// 不随导出走；恢复后首次写入自动生成全新代次（D-13）。
extension ChangeLogging on AppDatabase {
  static const generationKey = 'data_generation';
  static const backfillKey = 'change_log_backfilled';

  Future<String> currentGeneration() async {
    final row = await (select(settings)
          ..where((t) => t.key.equals(generationKey)))
        .getSingleOrNull();
    if (row != null) return jsonDecode(row.value) as String;
    final generation = const Uuid().v4();
    await into(settings).insert(SettingsCompanion.insert(
      key: generationKey,
      value: jsonEncode(generation),
      updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
    return generation;
  }

  /// 同步范围内、需要回填存量的表（schema §7.4 手机→Mac，按弱依赖排序）。
  /// attachments 需要带 sha256 作为 depends_on_blob。
  static const _backfillTables = [
    'attachments',
    'messages',
    'message_revisions',
    'message_attachments',
    'profile_fields',
    'organize_runs',
    'organize_run_items',
    'model_calls',
    'records',
    'record_revisions',
    'record_sources',
    'correction_suggestions',
    'medical_documents',
    'health_samples',
    'health_daily',
  ];

  /// 回填：把当前代次日志里还没有的行补进日志，否则这些数据永远同步
  /// 不到 Mac。两种情况会用到：变更日志埋点（V3-M1）之前的存量数据；
  /// 从导出恢复后换了新代次——新代次里要有完整的手机数据，Mac 才能按新
  /// 代次重建副本（schema §7.3）。settings 的 `change_log_backfilled`
  /// 记下已回填的代次（旧版本存的是 true），代次不同就再做一次；当前代次
  /// 日志里已有的实体（按 entity_type+entity_id）跳过，可安全重复调用。
  Future<int> backfillChangeLogIfNeeded(String deviceId) async {
    final generation = await currentGeneration();
    final done = await (select(settings)
          ..where((t) => t.key.equals(backfillKey)))
        .getSingleOrNull();
    if (done != null && jsonDecode(done.value) == generation) return 0;

    var count = 0;
    await transaction(() async {
      final logged = <String>{
        for (final row in await customSelect(
                'SELECT entity_type, entity_id FROM change_logs '
                'WHERE generation = ?',
                variables: [Variable.withString(generation)]).get())
          '${row.data['entity_type']}|${row.data['entity_id']}',
      };
      // 本机有文件的附件才带 depends_on_blob：清理过或恢复时缺件的附件
      // 本机传不出文件，带上会让 Mac 一直要文件、同步卡在这一条。
      final localFiles = <String>{
        for (final row in await customSelect(
            'SELECT attachment_id FROM attachment_copies '
            'WHERE device_id = ? AND state = ?',
            variables: [
              Variable.withString(deviceId),
              Variable.withString(enumToDb(CopyState.present)),
            ]).get())
          row.data['attachment_id'] as String,
      };
      for (final table in _backfillTables) {
        final rows =
            await customSelect('SELECT * FROM $table').get();
        for (final row in rows) {
          final id = row.data['id'] as String?;
          if (id == null || logged.contains('$table|$id')) continue;
          await logChange(
            deviceId: deviceId,
            table: table,
            entityId: id,
            op: (row.data['deleted_at'] != null)
                ? ChangeOp.delete
                : ChangeOp.upsert,
            dependsOnBlob: table == 'attachments' && localFiles.contains(id)
                ? row.data['sha256'] as String?
                : null,
          );
          count++;
        }
      }
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(
        key: backfillKey,
        value: jsonEncode(generation),
        updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      ));
    });
    return count;
  }

  /// 记一条变更。必须在业务写入的同一事务内调用；
  /// [table] 是 SQLite 表名，行按当前状态拍快照。
  Future<void> logChange({
    required String deviceId,
    required String table,
    required String entityId,
    ChangeOp op = ChangeOp.upsert,
    String? dependsOnBlob,
  }) async {
    final rows = await customSelect(
      'SELECT * FROM $table WHERE id = ?',
      variables: [Variable.withString(entityId)],
    ).get();
    if (rows.isEmpty) {
      throw StateError('logChange：$table 里没有 $entityId');
    }
    final payload = rows.single.data;

    final generation = await currentGeneration();
    final maxSeq = await customSelect(
      'SELECT COALESCE(MAX(change_seq), 0) AS m FROM change_logs '
      'WHERE generation = ?',
      variables: [Variable.withString(generation)],
    ).getSingle();
    final seq = (maxSeq.data['m'] as int) + 1;

    await into(changeLogs).insert(ChangeLogsCompanion.insert(
      sourceDeviceId: deviceId,
      generation: generation,
      changeSeq: seq,
      entityType: table,
      entityId: entityId,
      entityVersion: (payload['version'] as int?) ?? 1,
      op: op,
      payload: jsonEncode(payload),
      dependsOnBlob: Value(dependsOnBlob),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
    // 回写实体的通用 change_seq（schema §1.1）。快照在回写前拍好，
    // 负载里的 change_seq 是上一条的值，接收端不使用该字段。
    await customUpdate(
      'UPDATE $table SET change_seq = ? WHERE id = ?',
      variables: [Variable.withInt(seq), Variable.withString(entityId)],
      updates: {},
    );
  }
}
