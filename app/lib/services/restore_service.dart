import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/attachment_repository.dart';
import 'export_service.dart';

/// 应用里已有数据且未确认"替换全部数据"时抛出。
class NeedsReplaceConfirmation implements Exception {}

class RestoreResult {
  RestoreResult({
    required this.messageCount,
    required this.restoredFiles,
    required this.missingFiles,
  });

  final int messageCount;
  final int restoredFiles;

  /// 导出里缺失或校验不过的文件（sha256）。非空时结果是"部分恢复"。
  final List<String> missingFiles;

  bool get partial => missingFiles.isNotEmpty;
}

/// 从导出恢复（product-spec §13、A-29）：
/// 先校验清单，在临时位置建好新资料库和附件目录，全部成功后一次
/// 替换，失败保留原资料库不动。缺失或损坏的文件
/// 单独列出，其余照常导入，结果为"部分恢复"。
class RestoreService {
  RestoreService({
    required this.dbFile,
    required this.filesDir,
    this.ids = const IdGenerator(),
  });

  /// 当前资料库文件与附件目录（将被替换的目标）。
  final File dbFile;
  final Directory filesDir;
  final IdGenerator ids;

  /// 把导出的压缩包解到 [into]，返回里面含 manifest.json 的那一层目录。
  ///
  /// 安卓从别的设备拿到导出时用压缩包（2026-09-30 小米 12 联调）：别的应用
  /// 解压出来的文件本应用无权读取（分区存储），系统文件选择器选中的压缩包
  /// 才读得到；Mac 压缩的包不带 UTF-8 文件名标记，文件管理解压后中文目录名
  /// 是乱码。这里自己解压、按 manifest.json 找根目录，目录名乱不乱都不影响。
  static Future<Directory> unpackZip(File zip, Directory into) async {
    await into.create(recursive: true);
    final root = p.canonicalize(into.path);
    final input = InputFileStream(zip.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      String? manifestDir;
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final parts = p.posix.split(entry.name.replaceAll('\\', '/'));
        // Mac 压缩附带的 __MACOSX/ 资源分叉文件跳过。
        if (parts.contains('__MACOSX')) continue;
        final out = p.canonicalize(p.joinAll([root, ...parts]));
        if (!p.isWithin(root, out)) {
          throw StateError('压缩包里有越界路径：${entry.name}');
        }
        await Directory(p.dirname(out)).create(recursive: true);
        final stream = OutputFileStream(out);
        try {
          entry.writeContent(stream);
        } finally {
          await stream.close();
        }
        if (parts.last == 'manifest.json') {
          final dir = p.dirname(out);
          // 多个 manifest 时取层级最浅的。
          if (manifestDir == null || dir.length < manifestDir.length) {
            manifestDir = dir;
          }
        }
      }
      if (manifestDir == null) {
        throw StateError('压缩包里没有导出数据：找不到 manifest.json');
      }
      return Directory(manifestDir);
    } finally {
      await input.close();
    }
  }

  /// 检查导出文件夹是否可用，返回 manifest 内容。
  Future<Map<String, Object?>> readManifest(Directory source) async {
    final manifestFile = File(p.join(source.path, 'manifest.json'));
    final dataFile = File(p.join(source.path, 'data.json'));
    if (!await manifestFile.exists() || !await dataFile.exists()) {
      throw StateError('不是有效的导出文件夹：缺少 manifest.json 或 data.json');
    }
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    // v1 导出（无 v0.2 表）仍可恢复；高于当前版本的拒绝。
    final version = manifest['format_version'];
    if (version is! int || version < 1 || version > exportFormatVersion) {
      throw StateError('导出格式版本不支持：$version');
    }
    return manifest.cast<String, Object?>();
  }

  static Variable _variableFor(Object? value) => switch (value) {
        null => const Variable(null),
        final int v => Variable.withInt(v),
        final double v => Variable.withReal(v),
        final bool v => Variable.withBool(v),
        final String v => Variable.withString(v),
        _ => throw StateError('v2 表里出现不支持的值类型：$value'),
      };

  /// `hasExistingData`：当前资料库是否已有内容；有则必须 `replaceExisting`。
  Future<RestoreResult> restore(
    Directory source, {
    required bool hasExistingData,
    bool replaceExisting = false,
    String? newDeviceId,
  }) async {
    if (hasExistingData && !replaceExisting) {
      throw NeedsReplaceConfirmation();
    }
    final manifest = await readManifest(source);
    final data = jsonDecode(
            await File(p.join(source.path, 'data.json')).readAsString())
        as Map<String, dynamic>;

    // 1. 校验清单：data.json 哈希不对直接失败；附件文件损坏记入缺件。
    final files = (manifest['files'] as Map).cast<String, dynamic>();
    final missing = <String>[
      ...((manifest['missing_files'] as List?) ?? const []).cast<String>(),
    ];
    final verifiedFiles = <String, File>{}; // sha256 -> 源文件
    for (final entry in files.entries) {
      final f = File(p.join(source.path, entry.key));
      final expected = (entry.value as Map)['sha256'] as String;
      final ok =
          await f.exists() && await AttachmentRepository.hashFile(f) == expected;
      if (entry.key == 'data.json') {
        if (!ok) throw StateError('data.json 损坏，无法恢复');
        continue;
      }
      // 导出文件带后缀（2026-09-27 起），哈希 = 去掉后缀的文件名；
      // 旧导出没有后缀，同样成立。
      final sha = p.basenameWithoutExtension(entry.key);
      if (ok) {
        verifiedFiles[sha] = f;
      } else {
        missing.add(sha);
      }
    }

    // 2. 在临时位置准备新资料库和附件目录。
    final tmpRoot = Directory(p.join(dbFile.parent.parent.path,
        'restore_tmp_${DateTime.now().millisecondsSinceEpoch}'));
    await tmpRoot.create(recursive: true);
    final tmpDb = File(p.join(tmpRoot.path, 'app.sqlite'));
    final tmpFiles = Directory(p.join(tmpRoot.path, 'files'));
    await tmpFiles.create(recursive: true);

    var messageCount = 0;
    var restoredFiles = 0;
    try {
      final db = AppDatabase(NativeDatabase(tmpDb));
      try {
        await db.transaction(() async {
          for (final row in (data['messages'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            await db.into(db.messages).insert(MessagesCompanion.insert(
                  id: m['id'] as String,
                  userId: m['user_id'] as String,
                  createdAt: m['created_at'] as int,
                  createdOnDevice: m['created_on_device'] as String,
                  version: Value(m['version'] as int),
                  changeSeq: Value(m['change_seq'] as int?),
                  deletedAt: Value(m['deleted_at'] as int?),
                  clientMsgId: m['client_msg_id'] as String,
                  seq: m['seq'] as int,
                  role: enumFromDb(MessageRole.values, m['role'] as String),
                  kind: enumFromDb(MessageKind.values, m['kind'] as String),
                  body: Value(m['text'] as String?),
                  revisionNo: Value(m['revision_no'] as int),
                  sentAt: m['sent_at'] as int,
                  sentTz: m['sent_tz'] as String,
                  inReplyTo: Value(m['in_reply_to'] as String?),
                  promptMeta: Value(m['prompt_meta'] as String?),
                  organizeState: enumFromDb(
                      OrganizeState.values, m['organize_state'] as String),
                ));
            messageCount++;
          }
          for (final row in (data['message_revisions'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            await db
                .into(db.messageRevisions)
                .insert(MessageRevisionsCompanion.insert(
                  id: m['id'] as String,
                  userId: m['user_id'] as String,
                  createdAt: m['created_at'] as int,
                  createdOnDevice: m['created_on_device'] as String,
                  version: Value(m['version'] as int),
                  deletedAt: Value(m['deleted_at'] as int?),
                  messageId: m['message_id'] as String,
                  revisionNo: m['revision_no'] as int,
                  textBefore: m['text_before'] as String,
                  editedAt: m['edited_at'] as int,
                ));
          }
          // 附件：先复制文件到临时目录，再写副本状态。
          final deviceId = newDeviceId ?? 'restored';
          for (final row in (data['attachments'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            final sha = m['sha256'] as String;
            await db.into(db.attachments).insert(AttachmentsCompanion.insert(
                  id: m['id'] as String,
                  userId: m['user_id'] as String,
                  createdAt: m['created_at'] as int,
                  createdOnDevice: m['created_on_device'] as String,
                  version: Value(m['version'] as int),
                  deletedAt: Value(m['deleted_at'] as int?),
                  sha256: sha,
                  mimeType: m['mime_type'] as String,
                  byteSize: m['byte_size'] as int,
                  originalFilename: Value(m['original_filename'] as String?),
                  firstImportedAt: m['first_imported_at'] as int,
                  width: Value(m['width'] as int?),
                  height: Value(m['height'] as int?),
                  pageCount: Value(m['page_count'] as int?),
                ));
            final source = verifiedFiles[sha];
            final now = ids.nowMs();
            if (source != null) {
              await source.copy(p.join(tmpFiles.path, sha));
              restoredFiles++;
              await db
                  .into(db.attachmentCopies)
                  .insert(AttachmentCopiesCompanion.insert(
                    id: ids.newId(),
                    userId: m['user_id'] as String,
                    createdAt: now,
                    createdOnDevice: deviceId,
                    attachmentId: m['id'] as String,
                    deviceId: deviceId,
                    state: CopyState.present,
                    // 只存文件名，读取时基于当前附件目录解析。
                    localPath: Value(sha),
                    verifiedAt: Value(now),
                  ));
            } else {
              await db
                  .into(db.attachmentCopies)
                  .insert(AttachmentCopiesCompanion.insert(
                    id: ids.newId(),
                    userId: m['user_id'] as String,
                    createdAt: now,
                    createdOnDevice: deviceId,
                    attachmentId: m['id'] as String,
                    deviceId: deviceId,
                    state: CopyState.missing,
                  ));
            }
          }
          for (final row in (data['message_attachments'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            await db
                .into(db.messageAttachments)
                .insert(MessageAttachmentsCompanion.insert(
                  id: m['id'] as String,
                  userId: m['user_id'] as String,
                  createdAt: m['created_at'] as int,
                  createdOnDevice: m['created_on_device'] as String,
                  version: Value(m['version'] as int),
                  deletedAt: Value(m['deleted_at'] as int?),
                  messageId: m['message_id'] as String,
                  attachmentId: m['attachment_id'] as String,
                  position: m['position'] as int,
                  duplicateAcknowledged:
                      Value(m['duplicate_acknowledged'] as bool),
                ));
          }
          for (final row in (data['profile_fields'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            await db
                .into(db.profileFields)
                .insert(ProfileFieldsCompanion.insert(
                  id: m['id'] as String,
                  userId: m['user_id'] as String,
                  createdAt: m['created_at'] as int,
                  createdOnDevice: m['created_on_device'] as String,
                  version: Value(m['version'] as int),
                  deletedAt: Value(m['deleted_at'] as int?),
                  fieldKey: m['field_key'] as String,
                  value: m['value'] as String,
                  state: enumFromDb(
                      ProfileFieldState.values, m['state'] as String),
                  updatedAt: m['updated_at'] as int,
                ));
          }
          for (final row in (data['settings'] as List)) {
            final m = (row as Map).cast<String, dynamic>();
            await db.into(db.settings).insert(SettingsCompanion.insert(
                  key: m['key'] as String,
                  value: m['value'] as String,
                  updatedAt: m['updated_at'] as int,
                ));
          }
          if (newDeviceId != null) {
            await db.into(db.settings).insert(SettingsCompanion.insert(
                  key: 'device_id',
                  value: jsonEncode(newDeviceId),
                  updatedAt: ids.nowMs(),
                ));
          }
          // v2 起：v0.2 新表整表回灌（v1 导出没有这个键，跳过）。
          final v2Tables =
              (data['v2_tables'] as Map?)?.cast<String, dynamic>();
          if (v2Tables != null) {
            for (final table in v2ExportTables) {
              for (final row in (v2Tables[table] as List? ?? const [])) {
                final m = (row as Map).cast<String, Object?>();
                final columns = m.keys.toList();
                final placeholders =
                    List.filled(columns.length, '?').join(', ');
                await db.customInsert(
                  'INSERT INTO $table (${columns.join(', ')}) '
                  'VALUES ($placeholders)',
                  variables: [
                    for (final c in columns) _variableFor(m[c]),
                  ],
                );
              }
            }
          }
        });
      } finally {
        await db.close();
      }

      // 3. 全部成功后一次替换；替换失败时把原库放回去。
      final oldRoot = Directory(p.join(dbFile.parent.parent.path,
          'replaced_${DateTime.now().millisecondsSinceEpoch}'));
      await oldRoot.create(recursive: true);
      final hadDb = await dbFile.exists();
      final hadFiles = await filesDir.exists();
      try {
        if (hadDb) await dbFile.rename(p.join(oldRoot.path, 'app.sqlite'));
        if (hadFiles) await filesDir.rename(p.join(oldRoot.path, 'files'));
        await dbFile.parent.create(recursive: true);
        await tmpDb.rename(dbFile.path);
        await tmpFiles.rename(filesDir.path);
      } catch (e) {
        // 回滚：把原库放回原位。
        final oldDb = File(p.join(oldRoot.path, 'app.sqlite'));
        final oldFiles = Directory(p.join(oldRoot.path, 'files'));
        if (hadDb && await oldDb.exists() && !await dbFile.exists()) {
          await oldDb.rename(dbFile.path);
        }
        if (hadFiles && await oldFiles.exists() && !await filesDir.exists()) {
          await oldFiles.rename(filesDir.path);
        }
        rethrow;
      }
      // 替换成功，清掉被换下的旧库。
      await oldRoot.delete(recursive: true);
    } finally {
      if (await tmpRoot.exists()) {
        await tmpRoot.delete(recursive: true);
      }
    }

    return RestoreResult(
      messageCount: messageCount,
      restoredFiles: restoredFiles,
      missingFiles: missing,
    );
  }
}
