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
