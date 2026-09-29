import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/ids.dart';

/// 备份格式版本。
const backupFormatVersion = 1;

/// 备份里的表：除 `model_configs`（key 与其引用不进备份，D-15、schema §4.3）、
/// `change_logs`/`sync_states`/`peers`/`backup_runs`（设备自身状态，恢复后重建）。
const backupTables = [
  'messages',
  'message_revisions',
  'attachments',
  'attachment_copies',
  'message_attachments',
  'profile_fields',
  'settings',
  'organize_runs',
  'organize_run_items',
  'model_calls',
  'records',
  'record_revisions',
  'record_sources',
  'correction_suggestions',
  'review_prompts',
  'health_samples',
  'health_daily',
  'analysis_artifacts',
  // v0.4（2026-09-29 联调补）：医疗文件的页组成、类型、检查日期等。
  // lab_results 是派生索引，恢复后按记录重建，不进备份（D-27）。
  'medical_documents',
];

/// 恢复演练的结果（D-15：早期完成一次"从备份恢复到新环境"）。
class RestoreDrillResult {
  RestoreDrillResult({
    required this.ok,
    required this.tableRows,
    required this.filesRestored,
    required this.missingFiles,
    this.error,
  });

  final bool ok;
  final Map<String, int> tableRows;
  final int filesRestored;

  /// 备份时就缺失的原件（区分"原件完整恢复"与"仅恢复提取数据"）。
  final List<String> missingFiles;
  final String? error;
}

/// 加密备份与恢复演练（V3-M6，D-15、schema §7.5）。
///
/// - 密钥由备份密码经 PBKDF2-HMAC-SHA256（20 万次迭代）派生；
/// - 数据快照（全表 JSON）与每个附件文件分别 AES-256-GCM 加密，
///   文件格式：nonce(12) | ciphertext | tag(16)；
/// - 生成用临时目录名，逐文件解密校验通过后才改正式名并登记 published；
/// - Mac 缺失的原件列入清单 missing，不当作业务记录删除。
class BackupService {
  /// Mac 端备份存放目录（~/Documents/长命百岁备份）；主页备份与设置页共用。
  /// 改名前的备份留在 ~/Documents/长寿记备份 不动：backup_runs 记的是
  /// 绝对路径，恢复演练按原路径找，搬走反而演练不了。
  static Directory macBackupRoot() => Directory(
      p.join(Platform.environment['HOME'] ?? '.', 'Documents', '长命百岁备份'));

  BackupService({
    required AppDatabase db,
    required Directory filesDir,
    this.ids = const IdGenerator(),
  })  : _db = db,
        _filesDir = filesDir;

  final AppDatabase _db;
  final Directory _filesDir;
  final IdGenerator ids;

  static final _aes = AesGcm.with256bits();

  static Future<List<int>> _deriveKey(String passphrase, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 200000,
      bits: 256,
    );
    return pbkdf2
        .deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt)
        .then((k) => k.extractBytes());
  }

  Future<List<int>> _encrypt(List<int> clear, List<int> key) async {
    final box = await _aes.encrypt(clear, secretKey: SecretKey(key));
    return [...box.nonce, ...box.cipherText, ...box.mac.bytes];
  }

  Future<List<int>> _decrypt(List<int> data, List<int> key) async {
    if (data.length < 28) throw const FormatException('加密文件太短');
    final box = SecretBox(
      data.sublist(12, data.length - 16),
      nonce: data.sublist(0, 12),
      mac: Mac(data.sublist(data.length - 16)),
    );
    return _aes.decrypt(box, secretKey: SecretKey(key));
  }

  /// 生成加密备份到 [targetRoot] 下。校验通过才改正式名并登记 published。
  Future<BackupRun> backup({
    required Directory targetRoot,
    required String passphrase,
  }) async {
    final backupId = ids.newId();
    final now = ids.nowMs();
    // 截止点：Mac 上的数据是手机同步来的，快照对应的是手机的数据代次和
    // 接收游标（D-14，与周报同口径）。2026-09-29 联调发现此前取的是 Mac 本机
    // 代次与本机变更日志（只有 Mac 自己产生的几十条），与快照内容对不上。
    // 游标在快照之前读：期间新到的变更也在快照里，截止点是下限，恢复后从这里
    // 续传，重复变更按幂等忽略（D-13）。没有接收游标（未配对）时用本机的。
    final pull = await (_db.select(_db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull))
          ..limit(1))
        .getSingleOrNull();
    final generation = pull?.generation ?? await _generation();
    final cutoffSeq = pull?.ackedContiguousSeq ?? await _maxSeq(generation);

    final tmpDir =
        Directory(p.join(targetRoot.path, 'backup_building_$backupId'));
    await Directory(p.join(tmpDir.path, 'files')).create(recursive: true);

    await _db.into(_db.backupRuns).insert(
          BackupRunsCompanion.insert(
            backupId: backupId,
            dataGeneration: generation,
            cutoffSeq: cutoffSeq,
            manifest: '{}',
            status: BackupStatus.building,
            targetPath: tmpDir.path,
            createdAt: now,
          ),
        );

    try {
      // 盐取密码学随机字节（借用一次随机密钥的前 16 字节）。
      final actualSalt =
          (await (await _aes.newSecretKey()).extractBytes()).sublist(0, 16);
      final key = await _deriveKey(passphrase, actualSalt);

      // 1. 数据快照：全表 JSON。
      final data = <String, Object?>{
        'format_version': backupFormatVersion,
        'tables': {
          for (final table in backupTables)
            table: [
              for (final row
                  in await _db.customSelect('SELECT * FROM $table').get())
                row.data,
            ],
        },
      };
      // key 的引用名不进备份：settings 里没有 key；data_generation 保留——
      // 备份恢复属于换代次场景，恢复端会另行生成（见 restoreDrill 注）。
      final dataJson = utf8.encode(jsonEncode(data));
      final dbSha = crypto.sha256.convert(dataJson).toString();
      await File(p.join(tmpDir.path, 'data.enc'))
          .writeAsBytes(await _encrypt(dataJson, key));

      // 2. 附件：逐个加密；缺失的列入清单（不当作删除）。
      final attachments = await _db.select(_db.attachments).get();
      final fileEntries = <String, Object?>{};
      final missing = <String>[];
      for (final a in attachments) {
        final src = File(p.join(_filesDir.path, a.sha256));
        if (!await src.exists()) {
          missing.add(a.sha256);
          continue;
        }
        final bytes = await src.readAsBytes();
        fileEntries[a.sha256] = {'bytes': bytes.length};
        await File(p.join(tmpDir.path, 'files', '${a.sha256}.enc'))
            .writeAsBytes(await _encrypt(bytes, key));
      }

      final manifest = {
        'format_version': backupFormatVersion,
        'backup_id': backupId,
        'created_at': now,
        'salt': base64Encode(actualSalt),
        'generation': generation,
        'cutoff_seq': cutoffSeq,
        'db_sha256': dbSha,
        'files': fileEntries,
        'missing_files': missing,
      };
      await File(p.join(tmpDir.path, 'manifest.json'))
          .writeAsString(jsonEncode(manifest));

      // 3. 校验：解密回来逐项核对哈希。
      await _updateStatus(backupId, BackupStatus.verifying);
      final decrypted = await _decrypt(
          await File(p.join(tmpDir.path, 'data.enc')).readAsBytes(), key);
      if (crypto.sha256.convert(decrypted).toString() != dbSha) {
        throw StateError('数据快照校验失败');
      }
      for (final sha in fileEntries.keys) {
        final clear = await _decrypt(
            await File(p.join(tmpDir.path, 'files', '$sha.enc')).readAsBytes(),
            key);
        if (crypto.sha256.convert(clear).toString() != sha) {
          throw StateError('附件 $sha 校验失败');
        }
      }

      // 4. 转正式名。
      final finalDir = Directory(p.join(targetRoot.path,
          'backup_${DateTime.fromMillisecondsSinceEpoch(now).toIso8601String().replaceAll(':', '-').substring(0, 19)}_$backupId'));
      await tmpDir.rename(finalDir.path);
      final updated = await (_db.update(_db.backupRuns)
            ..where((t) => t.backupId.equals(backupId)))
          .writeReturning(BackupRunsCompanion(
        status: const Value(BackupStatus.published),
        manifest: Value(jsonEncode(manifest)),
        targetPath: Value(finalDir.path),
        verifiedAt: Value(ids.nowMs()),
      ));
      return updated.single;
    } catch (e) {
      await (_db.update(_db.backupRuns)
            ..where((t) => t.backupId.equals(backupId)))
          .write(BackupRunsCompanion(
        status: const Value(BackupStatus.failed),
        error: Value('$e'),
      ));
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      rethrow;
    }
  }

  /// 恢复演练：解密备份到 [restoreTo]，校验全部哈希，报告行数与缺件。
  /// 不动当前库。真正恢复到新环境时数据代次按 schema §7.2 重新生成。
  Future<RestoreDrillResult> restoreDrill({
    required Directory backupDir,
    required String passphrase,
    required Directory restoreTo,
  }) async {
    try {
      final manifest = (jsonDecode(
              await File(p.join(backupDir.path, 'manifest.json'))
                  .readAsString()) as Map)
          .cast<String, Object?>();
      final salt = base64Decode(manifest['salt'] as String);
      final key = await _deriveKey(passphrase, salt);

      final dataClear = await _decrypt(
          await File(p.join(backupDir.path, 'data.enc')).readAsBytes(), key);
      if (crypto.sha256.convert(dataClear).toString() !=
          manifest['db_sha256']) {
        throw StateError('数据快照哈希与清单不符');
      }
      final data =
          (jsonDecode(utf8.decode(dataClear)) as Map).cast<String, Object?>();
      final tables = (data['tables'] as Map).cast<String, Object?>();
      final tableRows = {
        for (final e in tables.entries) e.key: (e.value as List).length,
      };

      await Directory(p.join(restoreTo.path, 'files'))
          .create(recursive: true);
      await File(p.join(restoreTo.path, 'data.json'))
          .writeAsBytes(dataClear);
      var filesRestored = 0;
      for (final sha in (manifest['files'] as Map).keys) {
        final clear = await _decrypt(
            await File(p.join(backupDir.path, 'files', '$sha.enc'))
                .readAsBytes(),
            key);
        if (crypto.sha256.convert(clear).toString() != sha) {
          throw StateError('附件 $sha 哈希不符');
        }
        await File(p.join(restoreTo.path, 'files', '$sha')).writeAsBytes(clear);
        filesRestored++;
      }
      return RestoreDrillResult(
        ok: true,
        tableRows: tableRows,
        filesRestored: filesRestored,
        missingFiles:
            ((manifest['missing_files'] as List?) ?? const []).cast<String>(),
      );
    } on SecretBoxAuthenticationError {
      return RestoreDrillResult(
          ok: false,
          tableRows: const {},
          filesRestored: 0,
          missingFiles: const [],
          error: '密码不对或备份被篡改');
    } catch (e) {
      return RestoreDrillResult(
          ok: false,
          tableRows: const {},
          filesRestored: 0,
          missingFiles: const [],
          error: '$e');
    }
  }

  Future<BackupRun?> latest() => (_db.select(_db.backupRuns)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<void> _updateStatus(String backupId, BackupStatus status) =>
      (_db.update(_db.backupRuns)..where((t) => t.backupId.equals(backupId)))
          .write(BackupRunsCompanion(status: Value(status)));

  Future<String> _generation() async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals('data_generation')))
        .getSingleOrNull();
    return row == null ? '' : jsonDecode(row.value) as String;
  }

  Future<int> _maxSeq(String generation) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(change_seq), 0) AS m FROM change_logs '
          'WHERE generation = ?',
          variables: [Variable.withString(generation)],
        )
        .getSingle();
    return row.data['m'] as int;
  }
}
