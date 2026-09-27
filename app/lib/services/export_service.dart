import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/repositories/attachment_repository.dart';

/// 导出格式版本。改动 data.json 结构时加 1，恢复时校验。
/// v2（2026-09-27）：增加 `v2_tables`——记录、版本、来源、整理批次与逐项、
/// 修正建议、回顾记账、健康样本与按天聚合。不含 `model_configs`（schema
/// §4.3 不进备份）、`model_calls`（本机调试记录）、`health_anchors`
/// （锚点在新环境重建）。
const exportFormatVersion = 2;

/// v2 起随导出走的表（名字 = SQLite 表名，行按数据库原值转储）。
const v2ExportTables = [
  'records',
  'record_revisions',
  'record_sources',
  'organize_runs',
  'organize_run_items',
  'correction_suggestions',
  'review_prompts',
  'health_samples',
  'health_daily',
];

class ExportResult {
  ExportResult({
    required this.directory,
    required this.messageCount,
    required this.fileCount,
    required this.missingFiles,
  });

  final Directory directory;
  final int messageCount;
  final int fileCount;

  /// 本机没有副本、无法带出的附件（sha256）。
  final List<String> missingFiles;
}

/// 导出为一个文件夹（product-spec §3、RV-06）：
/// data.json（消息、修改历史、附件关联、资料、设置；不含模型配置和 key）
/// + files/（附件原件，按 SHA-256 命名）+ manifest.json（逐文件哈希）。
/// 导出完成后逐个文件重新哈希校验，通过才算成功。
class ExportService {
  ExportService(this._db, {required this.filesDir});

  final AppDatabase _db;

  /// 本机附件目录。`local_path` 存的是文件名，导出时基于它解析
  /// （iOS 覆盖安装会更换容器绝对路径，见 AttachmentRepository）。
  final Directory filesDir;

  static String _extOf(Attachment a) {
    final fromName =
        a.originalFilename == null ? '' : p.extension(a.originalFilename!);
    if (fromName.isNotEmpty) return fromName;
    return switch (a.mimeType) {
      'application/pdf' => '.pdf',
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/heic' => '.heic',
      'image/webp' => '.webp',
      'image/gif' => '.gif',
      _ => '',
    };
  }

  Future<ExportResult> export(Directory target) async {
    await target.create(recursive: true);
    final filesOut = Directory(p.join(target.path, 'files'));
    await filesOut.create(recursive: true);

    final messages = await _db.select(_db.messages).get();
    final revisions = await _db.select(_db.messageRevisions).get();
    final attachments = await _db.select(_db.attachments).get();
    final links = await _db.select(_db.messageAttachments).get();
    final profile = await _db.select(_db.profileFields).get();
    final settings = await _db.select(_db.settings).get();

    // 设备标识与数据代次属于这台设备，不随内容导出：恢复后首次写入会
    // 生成全新代次（schema §7.2，同一份备份恢复两次得到两个代次）。
    final exportedSettings = settings
        .where((s) => s.key != 'device_id' && s.key != 'data_generation')
        .toList();

    final data = {
      'format_version': exportFormatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'messages': [for (final r in messages) _messageJson(r)],
      'message_revisions': [for (final r in revisions) _revisionJson(r)],
      'attachments': [for (final r in attachments) _attachmentJson(r)],
      'message_attachments': [for (final r in links) _linkJson(r)],
      'profile_fields': [for (final r in profile) _profileJson(r)],
      'settings': [
        for (final r in exportedSettings)
          {'key': r.key, 'value': r.value, 'updated_at': r.updatedAt},
      ],
      // v0.2 新表按数据库原值整表转储（列名 = SQLite 列名）。
      'v2_tables': {
        for (final table in v2ExportTables)
          table: [
            for (final row
                in await _db.customSelect('SELECT * FROM $table').get())
              row.data,
          ],
      },
    };
    final dataFile = File(p.join(target.path, 'data.json'));
    await dataFile.writeAsString(jsonEncode(data));

    // 附件原件：只有本机 present 的副本能带出。
    final copies = await (_db.select(_db.attachmentCopies)
          ..where((t) => t.state.equals('present')))
        .get();
    final copyByAttachment = {for (final c in copies) c.attachmentId: c};
    final missing = <String>[];
    var fileCount = 0;
    for (final a in attachments) {
      final copy = copyByAttachment[a.id];
      final stored = copy?.localPath;
      final path = stored == null
          ? null
          : p.join(filesDir.path, p.basename(stored));
      if (path == null || !await File(path).exists()) {
        missing.add(a.sha256);
        continue;
      }
      // 带后缀导出，"文件"应用里能直接打开；恢复时按去掉后缀的哈希匹配。
      await File(path)
          .copy(p.join(filesOut.path, '${a.sha256}${_extOf(a)}'));
      fileCount++;
    }

    // manifest：逐文件哈希与大小，恢复时先校验清单。
    final manifestFiles = <String, Object>{};
    Future<void> addManifest(String relPath, File f) async {
      manifestFiles[relPath] = {
        'sha256': await AttachmentRepository.hashFile(f),
        'bytes': await f.length(),
      };
    }

    await addManifest('data.json', dataFile);
    await for (final entity in filesOut.list()) {
      if (entity is File) {
        await addManifest('files/${p.basename(entity.path)}', entity);
      }
    }
    final manifest = {
      'format_version': exportFormatVersion,
      'exported_at': data['exported_at'],
      'message_count': messages.length,
      'file_count': fileCount,
      'missing_files': missing,
      'files': manifestFiles,
    };
    await File(p.join(target.path, 'manifest.json'))
        .writeAsString(jsonEncode(manifest));

    // 导出后校验：逐个核对哈希（product-spec §3）。
    for (final entry in manifestFiles.entries) {
      final f = File(p.join(target.path, entry.key));
      final expected = (entry.value as Map)['sha256'] as String;
      final actual = await AttachmentRepository.hashFile(f);
      if (actual != expected) {
        throw StateError('导出校验失败：${entry.key} 哈希不一致');
      }
    }

    return ExportResult(
      directory: target,
      messageCount: messages.length,
      fileCount: fileCount,
      missingFiles: missing,
    );
  }

  // ---- 行序列化（字段名与 schema.md 一致）----

  static Map<String, Object?> _common(dynamic r) => {
        'id': r.id,
        'user_id': r.userId,
        'created_at': r.createdAt,
        'created_on_device': r.createdOnDevice,
        'version': r.version,
        'change_seq': r.changeSeq,
        'deleted_at': r.deletedAt,
      };

  static Map<String, Object?> _messageJson(Message r) => {
        ..._common(r),
        'client_msg_id': r.clientMsgId,
        'seq': r.seq,
        'role': enumToDb(r.role),
        'kind': enumToDb(r.kind),
        'text': r.body,
        'revision_no': r.revisionNo,
        'sent_at': r.sentAt,
        'sent_tz': r.sentTz,
        'in_reply_to': r.inReplyTo,
        'prompt_meta': r.promptMeta,
        'organize_state': enumToDb(r.organizeState),
      };

  static Map<String, Object?> _revisionJson(MessageRevision r) => {
        ..._common(r),
        'message_id': r.messageId,
        'revision_no': r.revisionNo,
        'text_before': r.textBefore,
        'edited_at': r.editedAt,
      };

  static Map<String, Object?> _attachmentJson(Attachment r) => {
        ..._common(r),
        'sha256': r.sha256,
        'mime_type': r.mimeType,
        'byte_size': r.byteSize,
        'original_filename': r.originalFilename,
        'first_imported_at': r.firstImportedAt,
        'width': r.width,
        'height': r.height,
        'page_count': r.pageCount,
      };

  static Map<String, Object?> _linkJson(MessageAttachment r) => {
        ..._common(r),
        'message_id': r.messageId,
        'attachment_id': r.attachmentId,
        'position': r.position,
        'duplicate_acknowledged': r.duplicateAcknowledged,
      };

  static Map<String, Object?> _profileJson(ProfileField r) => {
        ..._common(r),
        'field_key': r.fieldKey,
        'value': r.value,
        'state': enumToDb(r.state),
        'updated_at': r.updatedAt,
      };
}
