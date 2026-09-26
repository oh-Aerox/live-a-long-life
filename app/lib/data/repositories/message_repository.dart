import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 消息读写（schema.md §2.1、§2.2）。
///
/// - 写入以 `client_msg_id` 幂等（D-10）：同一 ID 重复提交只落一行，
///   发送中断后重试不产生重复（A-04）。
/// - 修改消息先把被替换的文字按其原修订号存入 `message_revisions`（A-06）。
/// - 误发消息用 `deleted_at` 标记并使 `version` 加 1（schema §2.1）。
class MessageRepository {
  MessageRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 幂等写入一条消息。已存在同 `clientMsgId` 的消息时原样返回，不重复写。
  Future<Message> send({
    required String clientMsgId,
    required MessageRole role,
    required MessageKind kind,
    String? text,
    required String sentTz,
    int? sentAtMs,
    String? inReplyTo,
    String? promptMeta,
    OrganizeState? organizeState,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.messages)
            ..where((t) => t.clientMsgId.equals(clientMsgId)))
          .getSingleOrNull();
      if (existing != null) return existing;

      final maxSeq = await (_db.selectOnly(_db.messages)
            ..addColumns([_db.messages.seq.max()]))
          .map((row) => row.read(_db.messages.seq.max()))
          .getSingle();
      final now = ids.nowMs();
      final row = MessagesCompanion.insert(
        id: ids.newId(),
        userId: _ctx.userId,
        createdAt: now,
        createdOnDevice: _ctx.deviceId,
        clientMsgId: clientMsgId,
        seq: (maxSeq ?? 0) + 1,
        role: role,
        kind: kind,
        body: Value(text),
        sentAt: sentAtMs ?? now,
        sentTz: sentTz,
        inReplyTo: Value(inReplyTo),
        promptMeta: Value(promptMeta),
        organizeState: organizeState ??
            (role == MessageRole.user
                ? OrganizeState.pending
                : OrganizeState.notApplicable),
      );
      return _db.into(_db.messages).insertReturning(row);
    });
  }

  /// 修改消息文字：被替换的文字按其原修订号（从 0 开始）存入历史，
  /// 消息 `revision_no` 与 `version` 各加 1，`organize_state` 转待重整理。
  Future<Message> edit(String messageId, String newText) {
    return _db.transaction(() async {
      final msg = await (_db.select(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .getSingle();
      if (msg.deletedAt != null) {
        throw StateError('不能修改已删除的消息');
      }
      final now = ids.nowMs();
      await _db.into(_db.messageRevisions).insert(
            MessageRevisionsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              messageId: messageId,
              revisionNo: msg.revisionNo,
              textBefore: msg.body ?? '',
              editedAt: now,
            ),
          );
      final updated = await (_db.update(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .writeReturning(MessagesCompanion(
        body: Value(newText),
        revisionNo: Value(msg.revisionNo + 1),
        version: Value(msg.version + 1),
        organizeState: const Value(OrganizeState.needsReorganize),
      ));
      return updated.single;
    });
  }

  /// 标记删除（误发消息），`version` 加 1。
  Future<Message> markDeleted(String messageId) {
    return _db.transaction(() async {
      final msg = await (_db.select(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .getSingle();
      if (msg.deletedAt != null) return msg;
      final updated = await (_db.update(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .writeReturning(MessagesCompanion(
        deletedAt: Value(ids.nowMs()),
        version: Value(msg.version + 1),
      ));
      return updated.single;
    });
  }

  Future<Message?> byId(String messageId) => (_db.select(_db.messages)
        ..where((t) => t.id.equals(messageId)))
      .getSingleOrNull();

  /// 消息的修改历史，按修订号排列（修订 0 即最初原文）。
  Future<List<MessageRevision>> revisionsOf(String messageId) =>
      (_db.select(_db.messageRevisions)
            ..where((t) => t.messageId.equals(messageId))
            ..orderBy([(t) => OrderingTerm.asc(t.revisionNo)]))
          .get();

  /// 对话流：按 `seq` 排列，不含已删除消息。
  Stream<List<Message>> watchThread() => (_db.select(_db.messages)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
      .watch();

  Future<List<Message>> thread() => (_db.select(_db.messages)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
      .get();
}
