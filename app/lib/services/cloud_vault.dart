import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart'
    show SecretBoxAuthenticationError;
import 'package:path/path.dart' as p;

import 'backup_crypto.dart';
import 'export_service.dart';

/// 云备份文件夹的格式版本。改动 vault.json 或快照清单结构时加 1。
const cloudVaultFormatVersion = 1;

/// 备份密码不对。
class WrongPassword implements Exception {}

/// 文件夹读写。iCloud 云盘里的文件要经系统协调读写（下载未下载的文件、
/// 让系统知道有新文件要上传），由原生通道实现；测试和普通目录用
/// [LocalFolderIO]。列目录、读已下载的文件直接用 dart:io。
abstract class FolderIO {
  /// 确保这些文件已下载到本机可读，返回下载不了的。
  Future<List<String>> download(List<String> paths);

  /// 把本机文件 [local] 写到 [dest]（已存在则替换），需要时建上级目录。
  Future<void> put(File local, String dest);

  /// 改名（文件或文件夹）。
  Future<void> move(String from, String to);

  /// 删除文件或文件夹，不存在不报错。
  Future<void> delete(String path);
}

class LocalFolderIO implements FolderIO {
  const LocalFolderIO();

  @override
  Future<List<String>> download(List<String> paths) async => [
    for (final path in paths)
      if (!await File(path).exists()) path,
  ];

  @override
  Future<void> put(File local, String dest) async {
    await Directory(p.dirname(dest)).create(recursive: true);
    await local.copy(dest);
  }

  @override
  Future<void> move(String from, String to) async {
    if (await FileSystemEntity.isDirectory(from)) {
      await Directory(from).rename(to);
    } else {
      await File(from).rename(to);
    }
  }

  @override
  Future<void> delete(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.notFound) return;
    await (type == FileSystemEntityType.directory
            ? Directory(path)
            : File(path))
        .delete(recursive: true);
  }
}

/// vault.json：这个备份文件夹是否加密，加密时的盐和密码校验块。
class VaultMeta {
  VaultMeta({
    required this.vaultId,
    required this.createdAt,
    required this.encrypted,
    this.salt,
    this.keyCheck,
  });

  final String vaultId;
  final int createdAt;
  final bool encrypted;
  final List<int>? salt;

  /// 用密钥加密的固定内容，解得开说明密码对。
  final List<int>? keyCheck;

  Map<String, Object?> toJson() => {
    'format_version': cloudVaultFormatVersion,
    'vault_id': vaultId,
    'created_at': createdAt,
    'encrypted': encrypted,
    if (salt != null) 'salt': base64Encode(salt!),
    if (keyCheck != null) 'key_check': base64Encode(keyCheck!),
  };

  static VaultMeta fromJson(Map<String, Object?> j) => VaultMeta(
    vaultId: j['vault_id'] as String,
    createdAt: j['created_at'] as int,
    encrypted: j['encrypted'] as bool,
    salt: j['salt'] == null ? null : base64Decode(j['salt'] as String),
    keyCheck: j['key_check'] == null
        ? null
        : base64Decode(j['key_check'] as String),
  );
}

/// 一份备份（某一时刻的完整数据）。
class CloudSnapshot {
  CloudSnapshot({
    required this.name,
    required this.createdAt,
    required this.exportFormatVersion,
    required this.encrypted,
    required this.dataSha256,
    required this.messageCount,
    required this.files,
    required this.missingFiles,
    this.fingerprint,
  });

  /// snapshots/ 下的文件夹名。
  final String name;
  final int createdAt;

  /// data.json 的导出格式版本（[exportFormatVersion]），恢复时校验。
  final int exportFormatVersion;
  final bool encrypted;
  final String dataSha256;
  final int messageCount;

  /// 这份备份引用的附件：sha256 → 导出后缀。
  final Map<String, String> files;

  /// 备份时手机上没有、云端也没有的附件。
  final List<String> missingFiles;

  /// 备份时的内容指纹（[CloudBackupService.fingerprint]）。从这份恢复后
  /// 记为"上次备份"，内容没变就不再新建。
  final String? fingerprint;

  Map<String, Object?> toJson() => {
    'format_version': cloudVaultFormatVersion,
    'created_at': createdAt,
    'export_format_version': exportFormatVersion,
    'encrypted': encrypted,
    'data_sha256': dataSha256,
    'message_count': messageCount,
    'files': files,
    'missing_files': missingFiles,
    if (fingerprint != null) 'fingerprint': fingerprint,
  };

  static CloudSnapshot fromJson(String name, Map<String, Object?> j) =>
      CloudSnapshot(
        name: name,
        createdAt: j['created_at'] as int,
        exportFormatVersion: j['export_format_version'] as int,
        encrypted: j['encrypted'] as bool,
        dataSha256: j['data_sha256'] as String,
        messageCount: j['message_count'] as int,
        files: (j['files'] as Map).cast<String, String>(),
        missingFiles: (j['missing_files'] as List).cast<String>(),
        fingerprint: j['fingerprint'] as String?,
      );
}

/// 手机 iCloud 备份的文件夹格式（D-51）：
///
/// ```
/// 长命百岁云备份/
///   vault.json                 是否加密、盐、密码校验块
///   objects/<sha256>[.enc]     附件原件，按内容命名，已有的不再传，各份备份共用
///   snapshots/<时间>_<id>/      每次备份一个文件夹
///     manifest.json            引用哪些附件、缺哪些、数据哈希
///     data.json | data.enc     与导出相同的 data.json
/// ```
///
/// 加密时附件和 data 逐个用 [BackupCrypto] 加密，清单不加密（只有数量
/// 和哈希）。写入先用 `.part` 名，读回校验通过才改正式名。
class CloudVault {
  CloudVault(this.dir, {this.io = const LocalFolderIO()});

  /// 在用户选的文件夹下建的子文件夹名。
  static const dirName = '长命百岁云备份';

  final Directory dir;
  final FolderIO io;

  String get _metaPath => p.join(dir.path, 'vault.json');
  String get _objects => p.join(dir.path, 'objects');
  String get _snapshots => p.join(dir.path, 'snapshots');

  static const _keyCheckText = 'llal-cloud-backup';

  static String _sha(List<int> bytes) =>
      crypto.sha256.convert(bytes).toString();

  /// iCloud 里没下载的文件显示为 `.<文件名>.icloud`。
  static String _realName(String name) =>
      name.startsWith('.') && name.endsWith('.icloud')
      ? name.substring(1, name.length - '.icloud'.length)
      : name;

  /// 文件已下载或只有占位文件，都算存在。
  static Future<bool> _present(String path) async =>
      await FileSystemEntity.type(path) != FileSystemEntityType.notFound ||
      await File(
        p.join(p.dirname(path), '.${p.basename(path)}.icloud'),
      ).exists();

  Future<List<String>> _names(String dirPath) async {
    final d = Directory(dirPath);
    if (!await d.exists()) return const [];
    return [await for (final e in d.list()) _realName(p.basename(e.path))];
  }

  Future<List<int>> _read(String path) async {
    final failed = await io.download([path]);
    if (failed.isNotEmpty) {
      throw StateError('${p.basename(path)} 下载不了，检查网络和 iCloud 设置后重试');
    }
    return File(path).readAsBytes();
  }

  /// 写到本机临时文件再交给 [io]，读回核对内容。
  Future<void> _putBytes(List<int> bytes, String dest, Directory tmp) async {
    final staged = File(p.join(tmp.path, 'put_${p.basename(dest)}'));
    await staged.writeAsBytes(bytes, flush: true);
    try {
      await io.put(staged, dest);
    } finally {
      await staged.delete();
    }
    if (_sha(await File(dest).readAsBytes()) != _sha(bytes)) {
      await io.delete(dest);
      throw StateError('写入 iCloud 后校验不一致：${p.basename(dest)}');
    }
  }

  // ---- vault.json ----

  Future<VaultMeta?> readMeta() async {
    if (!await _present(_metaPath)) return null;
    final j = (jsonDecode(utf8.decode(await _read(_metaPath))) as Map)
        .cast<String, Object?>();
    final version = j['format_version'];
    if (version is! int || version > cloudVaultFormatVersion) {
      throw StateError('这个备份由更新版本的应用生成，请先升级应用');
    }
    return VaultMeta.fromJson(j);
  }

  /// 新建备份文件夹；[password] 为 null 时不加密。返回密钥（不加密为 null）。
  Future<(VaultMeta, List<int>?)> create({
    required String vaultId,
    required int nowMs,
    String? password,
  }) async {
    if (await _present(_metaPath)) {
      throw StateError('这个文件夹里已经有备份');
    }
    List<int>? salt;
    List<int>? key;
    List<int>? keyCheck;
    if (password != null) {
      salt = BackupCrypto.randomBytes(16);
      key = await BackupCrypto.deriveKey(password, salt);
      keyCheck = await BackupCrypto.encrypt(utf8.encode(_keyCheckText), key);
    }
    final meta = VaultMeta(
      vaultId: vaultId,
      createdAt: nowMs,
      encrypted: password != null,
      salt: salt,
      keyCheck: keyCheck,
    );
    final tmp = await Directory.systemTemp.createTemp('cloud_vault');
    try {
      await _putBytes(utf8.encode(jsonEncode(meta.toJson())), _metaPath, tmp);
    } finally {
      await tmp.delete(recursive: true);
    }
    return (meta, key);
  }

  /// 用密码解出密钥；密码不对抛 [WrongPassword]。
  static Future<List<int>> unlock(VaultMeta meta, String password) async {
    final key = await BackupCrypto.deriveKey(password, meta.salt!);
    if (!await keyMatches(meta, key)) throw WrongPassword();
    return key;
  }

  static Future<bool> keyMatches(VaultMeta meta, List<int> key) async {
    try {
      final clear = await BackupCrypto.decrypt(meta.keyCheck!, key);
      return utf8.decode(clear) == _keyCheckText;
    } on SecretBoxAuthenticationError {
      return false;
    }
  }

  // ---- 写一份备份 ----

  /// 云端已有的附件（sha256）。
  Future<Set<String>> objectShas() async => {
    for (final n in await _names(_objects))
      if (!n.endsWith('.part'))
        n.endsWith('.enc') ? n.substring(0, n.length - 4) : n,
  };

  String _objectPath(String sha, bool encrypted) =>
      p.join(_objects, encrypted ? '$sha.enc' : sha);

  /// 上次中断留下的 `.part`。只有一台手机往这里写，开始写之前清掉。
  Future<void> _cleanParts() async {
    for (final d in [_objects, _snapshots]) {
      for (final n in await _names(d)) {
        if (n.endsWith('.part')) await io.delete(p.join(d, n));
      }
    }
  }

  /// 把 [snap] 写成一份新备份。附件只传云端还没有的；本机没有原件但
  /// 云端已有的（清理过手机原件）照样引用。[onProgress] 报告已传/待传数。
  Future<CloudSnapshot> write(
    ExportSnapshot snap, {
    required String snapshotId,
    required int nowMs,
    List<int>? key,
    String? fingerprint,
    void Function(int done, int total)? onProgress,
  }) async {
    final encrypted = key != null;
    final tmp = await Directory.systemTemp.createTemp('cloud_backup');
    try {
      await _cleanParts();
      final have = await objectShas();
      final files = <String, String>{};
      final missing = <String>[];
      final toUpload = [
        for (final f in snap.files)
          if (!have.contains(f.sha256) && f.local != null) f,
      ];
      var done = 0;
      for (final f in snap.files) {
        if (files.containsKey(f.sha256)) continue;
        if (have.contains(f.sha256)) {
          files[f.sha256] = f.ext;
          continue;
        }
        final local = f.local;
        final clear = local == null ? null : await local.readAsBytes();
        // 本机文件和哈希对不上（损坏）当作缺失，不把坏文件传上去。
        if (clear == null || _sha(clear) != f.sha256) {
          missing.add(f.sha256);
          continue;
        }
        final body = encrypted ? await BackupCrypto.encrypt(clear, key) : clear;
        final dest = _objectPath(f.sha256, encrypted);
        await _putBytes(body, '$dest.part', tmp);
        await io.move('$dest.part', dest);
        files[f.sha256] = f.ext;
        onProgress?.call(++done, toUpload.length);
      }

      final dataClear = utf8.encode(jsonEncode(snap.data));
      final dataSha = _sha(dataClear);
      final t = DateTime.fromMillisecondsSinceEpoch(nowMs);
      String two(int v) => v.toString().padLeft(2, '0');
      final name =
          '${t.year}${two(t.month)}${two(t.day)}-'
          '${two(t.hour)}${two(t.minute)}${two(t.second)}_'
          '${snapshotId.substring(snapshotId.length - 8)}';
      final building = p.join(_snapshots, '$name.part');
      final dataName = encrypted ? 'data.enc' : 'data.json';
      await _putBytes(
        encrypted ? await BackupCrypto.encrypt(dataClear, key) : dataClear,
        p.join(building, dataName),
        tmp,
      );
      if (encrypted) {
        // 解密回来核对，确认用这把密钥恢复得了。
        final back = await BackupCrypto.decrypt(
          await File(p.join(building, dataName)).readAsBytes(),
          key,
        );
        if (_sha(back) != dataSha) throw StateError('备份数据校验失败');
      }
      final result = CloudSnapshot(
        name: name,
        createdAt: nowMs,
        exportFormatVersion: snap.data['format_version'] as int,
        encrypted: encrypted,
        dataSha256: dataSha,
        messageCount: snap.messageCount,
        files: files,
        missingFiles: missing,
        fingerprint: fingerprint,
      );
      await _putBytes(
        utf8.encode(jsonEncode(result.toJson())),
        p.join(building, 'manifest.json'),
        tmp,
      );
      await io.move(building, p.join(_snapshots, name));
      return result;
    } finally {
      await tmp.delete(recursive: true);
    }
  }

  // ---- 列出、轮换 ----

  /// 全部备份，新的在前。读不出清单的跳过。
  Future<List<CloudSnapshot>> list() async => (await _list()).$1;

  /// (读得出的备份, 备份文件夹总数)。
  Future<(List<CloudSnapshot>, int)> _list() async {
    final result = <CloudSnapshot>[];
    var total = 0;
    for (final n in await _names(_snapshots)) {
      if (n.endsWith('.part')) continue;
      total++;
      try {
        final j =
            (jsonDecode(
                      utf8.decode(
                        await _read(p.join(_snapshots, n, 'manifest.json')),
                      ),
                    )
                    as Map)
                .cast<String, Object?>();
        result.add(CloudSnapshot.fromJson(n, j));
      } catch (_) {
        // 下载不了或损坏：不算可用备份。
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return (result, total);
  }

  Future<bool> hasSnapshot(String name) =>
      _present(p.join(_snapshots, name, 'manifest.json'));

  /// 每天只留最后一份，最多留最近 [days] 天（按本机日期），再删掉没有备份
  /// 引用的附件。有备份的清单读不出时不删附件（宁可多留，不能删掉还被
  /// 引用的）。返回删掉的备份数。
  Future<int> prune({int days = 4}) async {
    final (all, total) = await _list();
    final kept = <CloudSnapshot>[];
    final old = <CloudSnapshot>[];
    final seenDays = <String>{};
    for (final s in all) {
      // all 新的在前：每天第一次遇到的就是当天最后一份。
      final t = DateTime.fromMillisecondsSinceEpoch(s.createdAt);
      final day = '${t.year}-${t.month}-${t.day}';
      if (!seenDays.contains(day) && seenDays.length < days) {
        seenDays.add(day);
        kept.add(s);
      } else {
        old.add(s);
      }
    }
    for (final s in old) {
      await io.delete(p.join(_snapshots, s.name));
    }
    if (all.length != total) return old.length;
    final referenced = {for (final s in kept) ...s.files.keys};
    for (final n in await _names(_objects)) {
      if (n.endsWith('.part')) continue;
      final sha = n.endsWith('.enc') ? n.substring(0, n.length - 4) : n;
      if (!referenced.contains(sha)) await io.delete(p.join(_objects, n));
    }
    return old.length;
  }

  // ---- 恢复 ----

  /// 把一份备份解成导出文件夹的样子（data.json + files/ + manifest.json），
  /// 交给 [RestoreService]。附件下载不了、解不开或哈希不对的记为缺失，
  /// 恢复结果是"部分恢复"；data 读不出直接失败。
  Future<Directory> stage(
    CloudSnapshot s, {
    required Directory into,
    List<int>? key,
    void Function(int done, int total)? onProgress,
  }) async {
    if (s.encrypted && key == null) throw StateError('需要备份密码');
    final dir = p.join(_snapshots, s.name);
    final raw = await _read(
      p.join(dir, s.encrypted ? 'data.enc' : 'data.json'),
    );
    final List<int> dataClear;
    try {
      dataClear = s.encrypted ? await BackupCrypto.decrypt(raw, key!) : raw;
    } on SecretBoxAuthenticationError {
      throw WrongPassword();
    }
    if (_sha(dataClear) != s.dataSha256) throw StateError('备份数据损坏，换一份备份试试');

    final filesOut = Directory(p.join(into.path, 'files'));
    await filesOut.create(recursive: true);
    await File(p.join(into.path, 'data.json')).writeAsBytes(dataClear);
    final manifestFiles = <String, Object>{
      'data.json': {'sha256': s.dataSha256, 'bytes': dataClear.length},
    };
    final missing = [...s.missingFiles];

    // 分批下载，边下边解，进度按附件个数报。
    final entries = s.files.entries.toList();
    var done = 0;
    for (var i = 0; i < entries.length; i += 20) {
      final batch = entries.skip(i).take(20).toList();
      final paths = [for (final e in batch) _objectPath(e.key, s.encrypted)];
      final failed = (await io.download(paths)).toSet();
      for (final e in batch) {
        final path = _objectPath(e.key, s.encrypted);
        try {
          if (failed.contains(path)) throw StateError('下载失败');
          final body = await File(path).readAsBytes();
          final clear = s.encrypted
              ? await BackupCrypto.decrypt(body, key!)
              : body;
          if (_sha(clear) != e.key) throw StateError('哈希不一致');
          final rel = 'files/${e.key}${e.value}';
          await File(p.join(into.path, rel)).writeAsBytes(clear);
          manifestFiles[rel] = {'sha256': e.key, 'bytes': clear.length};
        } catch (_) {
          missing.add(e.key);
        }
        onProgress?.call(++done, entries.length);
      }
    }
    await File(p.join(into.path, 'manifest.json')).writeAsString(
      jsonEncode({
        'format_version': s.exportFormatVersion,
        'exported_at': DateTime.fromMillisecondsSinceEpoch(
          s.createdAt,
        ).toUtc().toIso8601String(),
        'message_count': s.messageCount,
        'file_count': manifestFiles.length - 1,
        'missing_files': missing,
        'files': manifestFiles,
      }),
    );
    return into;
  }
}
