import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/repositories/attachment_repository.dart';

/// 导出格式版本。改动 data.json 结构时加 1，恢复时校验。
/// v2（2026-09-27）：增加 `v2_tables`——记录、版本、来源、整理批次与逐项、
/// 修正建议、回顾记账、健康样本与按天聚合。
/// v3（2026-09-30）：`v2_tables` 补上 v0.3/v0.4 的表——医疗文件（病例夹与
/// 体检列表）、周报等分析结果、咨询记录。此前的导出恢复后病例夹为空。
/// 旧版应用遇到 v3 会拒绝恢复，而不是悄悄丢掉不认识的表。
const exportFormatVersion = 3;

/// 随导出走的表（名字 = SQLite 表名，行按数据库原值转储）。键名沿用
/// `v2_tables`，v2 导出里缺的表恢复时按空表处理。
/// 新增表必须在这里或 [exportExcludedTables] 里登记（有单测把关）。
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
  'medical_documents',
  'analysis_artifacts',
  'consult_messages',
];

/// 不随导出走的表及原因。
const exportExcludedTables = {
  // 单独导出（data.json 顶层键）
  'messages': '顶层 messages',
  'message_revisions': '顶层 message_revisions',
  'attachments': '顶层 attachments',
  'message_attachments': '顶层 message_attachments',
  'profile_fields': '顶层 profile_fields',
  'settings': '顶层 settings',
  // 属于这台设备，恢复时重建
  'attachment_copies': '按导出里实际带出的文件重建',
  'lab_results': '检验项目索引，派生数据，启动时按记录重建（D-27）',
  'health_anchors': '锚点在新环境重建',
  'change_logs': '同步变更日志属于本机代次，恢复后回填',
  'sync_states': '同步游标属于本机与对端',
  'peers': '配对关系属于本机，恢复后重新配对',
  'backup_runs': 'Mac 备份记录',
  // 不进备份（schema §4.3）
  'model_configs': '模型配置与 key 不导出',
  'model_calls': '本机调试记录',
};

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

/// 导出为一个文件夹（product-spec §13）：
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

  /// [shas] 中哪些在导出目录里还留着副本（导出布局：
  /// `<exportsRoot>/<每次导出>/files/<sha256><扩展名>`）。清理手机原件不动
  /// 导出目录，清理确认时据此说明（2026-09-29 联调）。目录不存在返回空。
  static Future<Set<String>> exportedCopies(
      Directory exportsRoot, Set<String> shas) async {
    final found = <String>{};
    if (shas.isEmpty || !await exportsRoot.exists()) return found;
    await for (final run in exportsRoot.list()) {
      if (run is! Directory) continue;
      final files = Directory(p.join(run.path, 'files'));
      if (!await files.exists()) continue;
      await for (final f in files.list()) {
        final name = p.basenameWithoutExtension(f.path);
        if (shas.contains(name)) found.add(name);
      }
    }
    return found;
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

    // 设备标识、数据代次与回填标记属于这台设备，不随内容导出：恢复后
    // 首次写入会生成全新代次（schema §7.2，同一份备份恢复两次得到两个
    // 代次），并在新代次里回填全部数据。
    const deviceOnlyKeys = {
      'device_id',
      'data_generation',
      'change_log_backfilled',
    };
    final exportedSettings = settings
        .where((s) => !deviceOnlyKeys.contains(s.key))
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

    // 导出后校验：逐个核对哈希（product-spec §13）。
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
