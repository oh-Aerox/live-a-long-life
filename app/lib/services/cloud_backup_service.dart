import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/settings_repository.dart';
import 'app_log.dart';
import 'cloud_folder.dart';
import 'cloud_vault.dart';
import 'export_service.dart';
import 'health_service.dart';
import 'key_store.dart';

/// 备份文件夹加密了，这台手机还没有密钥（换了手机、钥匙串清过）。
class NeedsPassword implements Exception {}

/// 设置页显示用的当前状态。
class CloudBackupState {
  CloudBackupState({
    required this.folderName,
    required this.inICloud,
    required this.encrypted,
    required this.auto,
    this.lastAt,
    this.lastMessages,
    this.lastFiles,
    this.lastMissing = 0,
    this.errorAt,
    this.error,
  });

  /// null 表示还没开启。
  final String? folderName;
  final bool inICloud;
  final bool encrypted;
  final bool auto;
  final DateTime? lastAt;
  final int? lastMessages;
  final int? lastFiles;
  final int lastMissing;
  final DateTime? errorAt;
  final String? error;

  bool get enabled => folderName != null;
}

class CloudBackupOutcome {
  CloudBackupOutcome({
    required this.unchanged,
    this.snapshot,
    this.uploaded = 0,
  });

  /// 和上次备份相比没有变化，没有新建备份。
  final bool unchanged;
  final CloudSnapshot? snapshot;

  /// 这次新传的附件数。
  final int uploaded;
}

/// 手机备份到 iCloud 云盘（D-51、R-26）：用户选一个 iCloud 云盘里的文件夹，
/// 每次备份写一份完整快照（附件按内容只传新的），每天留最后一份，最多 [keepDays] 天。
/// 自动备份在启动、回到前台、切到后台时做，有变化才写。
///
/// 设置（`cloud_backup_` 开头，属于这台手机，不随导出走）：
/// 书签、文件夹名、是否在 iCloud、备份库 ID、是否加密、自动开关、
/// 上次成功、上次失败。加密密钥存钥匙串 `cloud_backup_key_<备份库 ID>`。
class CloudBackupService {
  CloudBackupService({
    required AppDatabase db,
    required Directory filesDir,
    required SettingsRepository settings,
    required KeyStore keyStore,
    this.folder = const ChannelCloudFolder(),
    this.ids = const IdGenerator(),
  }) : _export = ExportService(db, filesDir: filesDir),
       _settings = settings,
       _keyStore = keyStore;

  final ExportService _export;
  final SettingsRepository _settings;
  final KeyStore _keyStore;
  final CloudFolderAccess folder;
  final IdGenerator ids;

  /// 每天留最后一份，最多留几天。
  static const keepDays = 4;

  /// 回到前台触发自动备份的最短间隔，免得来回切换时反复读整个数据库。
  static const autoInterval = Duration(minutes: 5);

  static const kBookmark = 'cloud_backup_bookmark';
  static const kFolderName = 'cloud_backup_folder_name';
  static const kInICloud = 'cloud_backup_in_icloud';
  static const kVaultId = 'cloud_backup_vault_id';
  static const kEncrypted = 'cloud_backup_encrypted';
  static const kAuto = 'cloud_backup_auto';
  static const kLast = 'cloud_backup_last';
  static const kError = 'cloud_backup_error';

  static String _keyRef(String vaultId) => 'cloud_backup_key_$vaultId';

  /// 正在做什么（"正在上传附件 3/10"），null 表示空闲。页面监听它显示进度。
  final status = ValueNotifier<String?>(null);

  bool _running = false;

  /// 恢复时置上：资料库要关掉替换，不能再起备份。
  bool blocked = false;
  DateTime? _lastAuto;

  Future<CloudBackupState> state() async {
    final last = await _settings.get(kLast) as Map?;
    final error = await _settings.get(kError) as Map?;
    DateTime? at(Map? m) =>
        m == null ? null : DateTime.fromMillisecondsSinceEpoch(m['at'] as int);
    return CloudBackupState(
      folderName: await _settings.get(kFolderName) as String?,
      inICloud: await _settings.get(kInICloud) as bool? ?? false,
      encrypted: await _settings.get(kEncrypted) as bool? ?? false,
      auto: await _settings.get(kAuto) as bool? ?? false,
      lastAt: at(last),
      lastMessages: last?['messages'] as int?,
      lastFiles: last?['files'] as int?,
      lastMissing: last?['missing'] as int? ?? 0,
      errorAt: at(error),
      error: error?['message'] as String?,
    );
  }

  /// 打开书签对应的文件夹做事，做完释放访问权。用户选的就是
  /// [CloudVault.dirName] 本身时直接用，否则用它下面的这个子文件夹。
  Future<T> withVault<T>(
    String bookmark,
    Future<T> Function(CloudVault vault) action,
  ) async {
    final opened = await folder.open(bookmark);
    try {
      if (opened.bookmark != null &&
          await _settings.get(kBookmark) == bookmark) {
        await _settings.set(kBookmark, opened.bookmark);
      }
      final root = opened.path;
      final dir = p.basename(root) == CloudVault.dirName
          ? Directory(root)
          : Directory(p.join(root, CloudVault.dirName));
      return await action(CloudVault(dir, io: folder));
    } finally {
      await folder.close(opened.path);
    }
  }

  Future<String?> bookmark() async => await _settings.get(kBookmark) as String?;

  /// 现在备份用的文件夹，没开启返回 null。
  Future<PickedFolder?> currentFolder() async {
    final bookmark = await this.bookmark();
    if (bookmark == null) return null;
    return PickedFolder(
      bookmark: bookmark,
      name: await _settings.get(kFolderName) as String? ?? '',
      inICloud: await _settings.get(kInICloud) as bool? ?? false,
    );
  }

  /// 本机钥匙串里这个备份库的密钥，没有或对不上返回 null。
  Future<List<int>?> savedKey(VaultMeta meta) async {
    final raw = await _keyStore.read(_keyRef(meta.vaultId));
    if (raw == null) return null;
    final key = base64Decode(raw);
    return await CloudVault.keyMatches(meta, key) ? key : null;
  }

  Future<void> saveKey(VaultMeta meta, List<int> key) =>
      _keyStore.saveRaw(_keyRef(meta.vaultId), base64Encode(key));

  /// 在选好的文件夹里新建备份库。[password] 为 null 不加密。
  Future<VaultMeta> createVault(String bookmark, {String? password}) =>
      withVault(bookmark, (vault) async {
        final (meta, key) = await vault.create(
          vaultId: ids.newId(),
          nowMs: ids.nowMs(),
          password: password,
        );
        if (key != null) await saveKey(meta, key);
        return meta;
      });

  /// 记下这个文件夹，之后备份都写到这里。
  Future<void> connect(
    PickedFolder picked,
    VaultMeta meta, {
    bool auto = true,
  }) async {
    for (final e in deviceSettings(picked, meta, auto: auto).entries) {
      await _settings.set(e.key, e.value);
    }
    await _settings.set(kLast, null);
    await _settings.set(kError, null);
  }

  /// 连接这个文件夹要写的设置。从 iCloud 恢复时随新资料库一起写入，恢复后
  /// 接着备份到同一个文件夹；[restoredFrom] 记为上次备份，内容没变就不再新建。
  static Map<String, Object?> deviceSettings(
    PickedFolder picked,
    VaultMeta meta, {
    bool auto = true,
    CloudSnapshot? restoredFrom,
  }) => {
    kBookmark: picked.bookmark,
    kFolderName: picked.name,
    kInICloud: picked.inICloud,
    kVaultId: meta.vaultId,
    kEncrypted: meta.encrypted,
    kAuto: auto,
    if (restoredFrom != null) kLast: _lastJson(restoredFrom),
  };

  static Map<String, Object?> _lastJson(CloudSnapshot s) => {
    'at': s.createdAt,
    'snapshot': s.name,
    'fingerprint': s.fingerprint,
    'messages': s.messageCount,
    'files': s.files.length,
    'missing': s.missingFiles.length,
  };

  /// 停用：只忘掉文件夹，云端已有的备份不删。
  Future<void> disconnect() async {
    for (final k in [
      kBookmark,
      kFolderName,
      kInICloud,
      kVaultId,
      kEncrypted,
      kAuto,
      kLast,
      kError,
    ]) {
      await _settings.set(k, null);
    }
  }

  Future<void> setAuto(bool on) => _settings.set(kAuto, on);

  /// 内容指纹：data.json（去掉导出时间）加本机有原件的附件。没变就不新建备份。
  /// 记账类的字段不算变化：每次回到前台都会改写的健康数据上次读取时间、
  /// 每行的变更序号。
  static String fingerprint(ExportSnapshot snap) {
    // 变更序号是同步记账：恢复后开新数据代次重新编号（D-34），不算内容变化。
    Object? strip(Object? rows) => [
      for (final r in rows as List)
        {
          for (final e in (r as Map).entries)
            if (e.key != 'change_seq') e.key: e.value,
        },
    ];
    final data = <String, Object?>{
      for (final e in snap.data.entries)
        if (e.key != 'exported_at')
          e.key: switch (e.key) {
            'settings' => [
              for (final s in e.value as List)
                if ((s as Map)['key'] != HealthService.lastSyncKey) s,
            ],
            'v2_tables' => {
              for (final t in (e.value as Map).entries) t.key: strip(t.value),
            },
            _ when e.value is List => strip(e.value),
            _ => e.value,
          },
    };
    final local = [
      for (final f in snap.files)
        if (f.local != null) f.sha256,
    ]..sort();
    return crypto.sha256
        .convert(utf8.encode('${jsonEncode(data)}\n${local.join(',')}'))
        .toString();
  }

  /// 立即备份。[force] 为 false 时内容没变就跳过。没开启时抛 [StateError]，
  /// 加密但本机没有密钥时抛 [NeedsPassword]。
  Future<CloudBackupOutcome> backupNow({bool force = false}) async {
    if (_running || blocked) throw StateError('正在备份，请稍候');
    final bookmark = await _settings.get(kBookmark) as String?;
    final vaultId = await _settings.get(kVaultId) as String?;
    if (bookmark == null || vaultId == null) throw StateError('还没开启 iCloud 备份');
    _running = true;
    try {
      final outcome = await withVault(bookmark, (vault) async {
        status.value = '正在读取备份文件夹';
        final meta = await vault.readMeta();
        if (meta == null || meta.vaultId != vaultId) {
          throw StateError('备份文件夹里找不到原来的备份，可能被移动或删除了，请重新选择文件夹');
        }
        List<int>? key;
        if (meta.encrypted) {
          key = await savedKey(meta);
          if (key == null) throw NeedsPassword();
        }
        status.value = '正在整理数据';
        final snap = await _export.snapshot();
        final fp = fingerprint(snap);
        final last = await _settings.get(kLast) as Map?;
        if (!force &&
            last != null &&
            last['fingerprint'] == fp &&
            await vault.hasSnapshot(last['snapshot'] as String)) {
          return CloudBackupOutcome(unchanged: true);
        }
        final before = await vault.objectShas();
        final written = await vault.write(
          snap,
          snapshotId: ids.newId(),
          nowMs: ids.nowMs(),
          key: key,
          fingerprint: fp,
          onProgress: (done, total) => status.value = '正在上传附件 $done/$total',
        );
        status.value = '正在清理旧备份';
        await vault.prune(days: keepDays);
        await _settings.set(kLast, _lastJson(written));
        return CloudBackupOutcome(
          unchanged: false,
          snapshot: written,
          uploaded: written.files.keys.where((s) => !before.contains(s)).length,
        );
      });
      await _settings.set(kError, null);
      return outcome;
    } catch (e) {
      await _settings.set(kError, {
        'at': ids.nowMs(),
        'message': e is NeedsPassword ? '需要输入备份密码' : '$e',
      });
      rethrow;
    } finally {
      _running = false;
      status.value = null;
    }
  }

  /// 自动备份：开了自动才做；失败只记日志和设置页的"上次失败"。
  /// 启动、回到前台距上次尝试不到 [autoInterval] 时跳过；切到后台
  /// （[background]）不跳过——刚记完的内容靠这一次备上去，并向系统要后台时间。
  Future<void> autoBackup({bool background = false}) async {
    if (!ChannelCloudFolder.supported || _running || blocked) return;
    if (await _settings.get(kAuto) != true) return;
    final now = DateTime.now();
    if (!background &&
        _lastAuto != null &&
        now.difference(_lastAuto!) < autoInterval) {
      return;
    }
    _lastAuto = now;
    if (background) await folder.beginBackground();
    try {
      final r = await backupNow();
      if (!r.unchanged) {
        AppLog.I.i('cloud', '自动备份完成：${r.snapshot!.name}，新传 ${r.uploaded} 个附件');
      }
    } catch (e, st) {
      AppLog.I.e('cloud', '自动备份失败', e, st);
    } finally {
      if (background) await folder.endBackground();
    }
  }
}
