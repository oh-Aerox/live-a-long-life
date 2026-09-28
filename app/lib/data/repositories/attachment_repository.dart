import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../app_context.dart';
import '../change_log.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 导入结果：要么是新附件，要么命中了已有内容（SHA-256 相同，D-10）。
/// 命中重复时由界面给出三选项（查看已有 / 仍然添加 / 取消），
/// "仍然添加"通过 [AttachmentRepository.linkToMessage] 的
/// `duplicateAcknowledged` 落库。
class ImportResult {
  ImportResult({required this.attachment, required this.isDuplicate});

  final Attachment attachment;
  final bool isDuplicate;
}

/// 附件导入与副本状态（schema.md §2.3、§2.3a）。
///
/// - 文件按 SHA-256 命名存放在 [filesDir] 下；
/// - 先落盘、重新哈希校验通过后才建 `present` 副本（界面此前不得显示"已保存"）；
/// - 校验发现文件丢失或内容不符时转 `missing`，附件身份与引用保留；
/// - `local_path` 只存文件名：iOS 覆盖安装会更换沙盒容器的绝对路径，
///   读取时基于当前 [filesDir] 解析。旧数据存过绝对路径，按文件名兜底。
class AttachmentRepository {
  AttachmentRepository(
    this._db,
    this._ctx, {
    required this.filesDir,
    this.ids = const IdGenerator(),
  });

  final AppDatabase _db;
  final AppContext _ctx;
  final Directory filesDir;
  final IdGenerator ids;

  static Future<String> hashFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  File _storedFile(String sha256Hex) =>
      File(p.join(filesDir.path, sha256Hex));

  /// 把库里的 `local_path`（文件名，或旧数据的绝对路径）解析成当前路径。
  String _resolve(String storedPath) =>
      p.join(filesDir.path, p.basename(storedPath));

  /// 导入一个文件。内容已存在时返回已有附件（isDuplicate = true），
  /// 不重复占用空间；新内容则复制进应用存储并校验后登记。
  Future<ImportResult> importFile(
    File source, {
    required String mimeType,
    String? originalFilename,
    int? width,
    int? height,
    int? pageCount,
  }) async {
    final hash = await hashFile(source);

    final existing = await (_db.select(_db.attachments)
          ..where((t) => t.sha256.equals(hash)))
        .getSingleOrNull();
    if (existing != null) {
      // 内容相同即同一附件身份。本机副本若曾清理或丢失，取回同一
      // SHA-256 文件后转回 present（schema §2.3a）。
      await _restoreCopyIfAbsent(existing, source, hash);
      return ImportResult(attachment: existing, isDuplicate: true);
    }

    await filesDir.create(recursive: true);
    final target = _storedFile(hash);
    await source.copy(target.path);

    // 落盘后重新哈希，校验通过才登记为 present（schema §2.3a）。
    final writtenHash = await hashFile(target);
    if (writtenHash != hash) {
      await target.delete();
      throw StateError('附件落盘校验失败：内容与来源不一致');
    }

    final byteSize = await target.length();
    final now = ids.nowMs();
    return _db.transaction(() async {
      final attachment = await _db.into(_db.attachments).insertReturning(
            AttachmentsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              sha256: hash,
              mimeType: mimeType,
              byteSize: byteSize,
              originalFilename: Value(originalFilename),
              firstImportedAt: now,
              width: Value(width),
              height: Value(height),
              pageCount: Value(pageCount),
            ),
          );
      await _db.into(_db.attachmentCopies).insert(
            AttachmentCopiesCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              attachmentId: attachment.id,
              deviceId: _ctx.deviceId,
              state: CopyState.present,
              localPath: Value(p.basename(target.path)),
              verifiedAt: Value(now),
            ),
          );
      // 附件身份入变更日志；文件本体依赖 sha 确认（副本状态独立通告，§7.2）。
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'attachments',
          entityId: attachment.id,
          dependsOnBlob: hash);
      return ImportResult(attachment: attachment, isDuplicate: false);
    });
  }

  Future<void> _restoreCopyIfAbsent(
      Attachment attachment, File source, String hash) async {
    final copy = await _copyOf(attachment.id);
    if (copy != null && copy.state == CopyState.present) return;

    await filesDir.create(recursive: true);
    final target = _storedFile(hash);
    await source.copy(target.path);
    final writtenHash = await hashFile(target);
    if (writtenHash != hash) {
      await target.delete();
      throw StateError('附件落盘校验失败：内容与来源不一致');
    }
    final now = ids.nowMs();
    if (copy == null) {
      await _db.into(_db.attachmentCopies).insert(
            AttachmentCopiesCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              attachmentId: attachment.id,
              deviceId: _ctx.deviceId,
              state: CopyState.present,
              localPath: Value(p.basename(target.path)),
              verifiedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.attachmentCopies)
            ..where((t) => t.id.equals(copy.id)))
          .write(AttachmentCopiesCompanion(
        state: const Value(CopyState.present),
        localPath: Value(p.basename(target.path)),
        verifiedAt: Value(now),
        offloadedAt: const Value(null),
        copyVersion: Value(copy.copyVersion + 1),
      ));
    }
  }

  Future<AttachmentCopy?> _copyOf(String attachmentId) =>
      (_db.select(_db.attachmentCopies)
            ..where((t) =>
                t.attachmentId.equals(attachmentId) &
                t.deviceId.equals(_ctx.deviceId)))
          .getSingleOrNull();

  /// 重新校验本机副本：文件缺失或内容不符时转 `missing`，
  /// 附件身份、消息引用与历史数据全部保留（schema §2.3a）。
  Future<CopyState> verifyCopy(String attachmentId) async {
    final copy = await _copyOf(attachmentId);
    if (copy == null) return CopyState.missing;
    if (copy.state != CopyState.present) return copy.state;

    final attachment = await (_db.select(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .getSingle();
    final path =
        copy.localPath == null ? null : _resolve(copy.localPath!);
    var ok = false;
    if (path != null && await File(path).exists()) {
      ok = await hashFile(File(path)) == attachment.sha256;
    }
    if (ok) {
      await (_db.update(_db.attachmentCopies)
            ..where((t) => t.id.equals(copy.id)))
          .write(AttachmentCopiesCompanion(verifiedAt: Value(ids.nowMs())));
      return CopyState.present;
    }
    await (_db.update(_db.attachmentCopies)..where((t) => t.id.equals(copy.id)))
        .write(AttachmentCopiesCompanion(
      state: const Value(CopyState.missing),
      copyVersion: Value(copy.copyVersion + 1),
    ));
    return CopyState.missing;
  }

  /// 把附件挂到消息上。同一 (消息, 附件) 只挂一次，重复调用幂等。
  Future<void> linkToMessage({
    required String messageId,
    required String attachmentId,
    required int position,
    bool duplicateAcknowledged = false,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.messageAttachments)
            ..where((t) =>
                t.messageId.equals(messageId) &
                t.attachmentId.equals(attachmentId)))
          .getSingleOrNull();
      if (existing != null) return;
      final linkId = ids.newId();
      await _db.into(_db.messageAttachments).insert(
            MessageAttachmentsCompanion.insert(
              id: linkId,
              userId: _ctx.userId,
              createdAt: ids.nowMs(),
              createdOnDevice: _ctx.deviceId,
              messageId: messageId,
              attachmentId: attachmentId,
              position: position,
              duplicateAcknowledged: Value(duplicateAcknowledged),
            ),
          );
      await _db.logChange(
          deviceId: _ctx.deviceId,
          table: 'message_attachments',
          entityId: linkId);
    });
  }

  /// 本机副本的当前绝对路径；不在本机（offloaded / missing）时为 null。
  Future<Attachment?> byId(String attachmentId) => (_db.select(_db.attachments)
        ..where((t) => t.id.equals(attachmentId) & t.deletedAt.isNull()))
      .getSingleOrNull();

  Future<String?> localPathOf(String attachmentId) async {
    final copy = await _copyOf(attachmentId);
    if (copy == null || copy.state != CopyState.present) return null;
    return copy.localPath == null ? null : _resolve(copy.localPath!);
  }

  /// 引用某附件的消息 ID，按引用时间排列（用于重复提示的"查看已有"）。
  Future<List<String>> messageIdsReferencing(String attachmentId) async {
    final rows = await (_db.select(_db.messageAttachments)
          ..where((t) =>
              t.attachmentId.equals(attachmentId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map((r) => r.messageId).toList();
  }

  Future<List<(MessageAttachment, Attachment)>> attachmentsOf(
      String messageId) async {
    final query = _db.select(_db.messageAttachments).join([
      innerJoin(_db.attachments,
          _db.attachments.id.equalsExp(_db.messageAttachments.attachmentId)),
    ])
      ..where(_db.messageAttachments.messageId.equals(messageId) &
          _db.messageAttachments.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(_db.messageAttachments.position)]);
    final rows = await query.get();
    return rows
        .map((r) =>
            (r.readTable(_db.messageAttachments), r.readTable(_db.attachments)))
        .toList();
  }
}
