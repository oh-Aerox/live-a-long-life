import 'package:drift/drift.dart';

import '../app_context.dart';
import '../change_log.dart';
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
      final inserted = await _db.into(_db.messages).insertReturning(row);
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'messages', entityId: inserted.id);
      return inserted;
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
      final revisionId = ids.newId();
      await _db.into(_db.messageRevisions).insert(
            MessageRevisionsCompanion.insert(
              id: revisionId,
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
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'message_revisions',
          entityId: revisionId);
      await _db.logChange(
          deviceId: _ctx.deviceId, table: 'messages', entityId: messageId);
      return updated.single;
    });
  }

  /// 标记删除（误发消息），`version` 加 1。
  /// 同事务把这条消息的附件引用也标记删除（schema §2.4）；
  /// 附件文件本身不删——内容可能被其他消息引用，v0.1 一律保留文件，
  /// 空间清理是 v0.4 的事（D-22）。
  Future<Message> markDeleted(String messageId) {
    return _db.transaction(() async {
      final msg = await (_db.select(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .getSingle();
      if (msg.deletedAt != null) return msg;
      final now = ids.nowMs();
      final links = await (_db.select(_db.messageAttachments)
            ..where(
                (t) => t.messageId.equals(messageId) & t.deletedAt.isNull()))
          .get();
      await (_db.update(_db.messageAttachments)
            ..where(
                (t) => t.messageId.equals(messageId) & t.deletedAt.isNull()))
          .write(MessageAttachmentsCompanion(deletedAt: Value(now)));
      final updated = await (_db.update(_db.messages)
            ..where((t) => t.id.equals(messageId)))
          .writeReturning(MessagesCompanion(
        deletedAt: Value(now),
        version: Value(msg.version + 1),
      ));
      for (final link in links) {
        await _db.logChange(
            deviceId: _ctx.deviceId,
            table: 'message_attachments',
            entityId: link.id,
            op: ChangeOp.delete);
      }
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'messages',
          entityId: messageId,
          op: ChangeOp.delete);
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

  /// 等待整理的用户消息（待整理或改后待重整理），按 seq 排列。
  Future<List<Message>> pendingOrganize() => (_db.select(_db.messages)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.role.equalsValue(MessageRole.user) &
            (t.organizeState.equalsValue(OrganizeState.pending) |
                t.organizeState.equalsValue(OrganizeState.needsReorganize)))
        ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
      .get();

  /// 某段时间内发出、仍在等待整理的用户文字消息（日视图里先列出来，
  /// 模型不可用时用户也能看到当天说过的内容）。
  Future<List<Message>> pendingOrganizeBetween(int startMs, int endMs) =>
      (_db.select(_db.messages)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.role.equalsValue(MessageRole.user) &
                t.body.isNotNull() &
                t.sentAt.isBiggerOrEqualValue(startMs) &
                t.sentAt.isSmallerThanValue(endMs) &
                (t.organizeState.equalsValue(OrganizeState.pending) |
                    t.organizeState
                        .equalsValue(OrganizeState.needsReorganize)))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  /// 更新消息的整理状态（整理服务在所有相关项落定后汇总调用，schema §3.1a）。
  Future<void> setOrganizeState(String messageId, OrganizeState state) =>
      (_db.update(_db.messages)..where((t) => t.id.equals(messageId)))
          .write(MessagesCompanion(organizeState: Value(state)));

  /// 写入应用消息的元数据（回顾提问的记账行引用等，schema §2.1 prompt_meta）。
  Future<void> setPromptMeta(String messageId, String promptMeta) =>
      (_db.update(_db.messages)..where((t) => t.id.equals(messageId)))
          .write(MessagesCompanion(promptMeta: Value(promptMeta)));
}
