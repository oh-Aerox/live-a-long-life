import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/change_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/peer_repository.dart';
import '../app_log.dart';
import '../key_store.dart';
import 'secure_channel.dart';
import 'sync_client.dart';

/// 一次同步的结果。
class SyncResult {
  SyncResult({required this.sent, required this.pending, this.error});

  final int sent;
  final int pending;
  final String? error;

  bool get ok => error == null;
}

/// 手机端推送同步（V3-M3，schema §7.2/§7.3）：
/// 变更按 change_seq 逐条发送、逐条确认，第一版不合并；
/// 依赖附件的变更收到 need_blob 时先传文件再重发；
/// 连续游标只有前面全部确认才推进。
class SyncService {
  SyncService({
    required this.deviceId,
    required AppDatabase db,
    required PeerRepository peers,
    required KeyStore keyStore,
    required Directory filesDir,
    this.discover,
  })  : _db = db,
        _peers = peers,
        _keyStore = keyStore,
        _filesDir = filesDir;

  /// 局域网发现（V4-M5）：按 Mac 设备 ID 返回候选 `host:port`（优先的在前），
  /// 找不到为空列表。为 null 时不做发现（测试、未启用）。
  final Future<List<String>> Function(String peerDeviceId)? discover;

  final String deviceId;
  final AppDatabase _db;
  final PeerRepository _peers;
  final KeyStore _keyStore;
  final Directory _filesDir;

  bool _syncing = false;

  /// 向所有已配对设备推送待发变更。
  Future<SyncResult> syncNow() async {
    if (_syncing) return SyncResult(sent: 0, pending: 0, error: '正在同步中');
    _syncing = true;
    try {
      final peers = await _peers.all();
      if (peers.isEmpty) {
        return SyncResult(sent: 0, pending: 0, error: '还没有配对的设备');
      }
      var sent = 0;
      var pending = 0;
      String? error;
      for (final peer in peers) {
        final r = await _pushTo(peer);
        sent += r.sent;
        pending += r.pending;
        error ??= r.error;
      }
      return SyncResult(sent: sent, pending: pending, error: error);
    } finally {
      _syncing = false;
    }
  }

  /// 先按记录的地址试连；连不上时用局域网发现找 Mac 的新地址，
  /// 能连通就更新记录（Mac 换 IP 不必重新配对，V4-M5）。都不通时仍返回
  /// 记录的地址，让后续请求照常报出连接错误。
  Future<String?> _reachableAddr(Peer peer, SecureChannel channel) async {
    final stored = peer.lastSeenAddr;
    final valid = stored != null && stored.contains(':');
    if (valid && await _ping(channel, stored)) return stored;
    final find = discover;
    if (find == null) return valid ? stored : null;
    AppLog.I.i('sync', '${peer.displayName} 按记录的地址 $stored 连不上，在局域网查找');
    for (final found in await find(peer.peerDeviceId)) {
      if (found == stored) continue;
      if (!await _ping(channel, found)) {
        AppLog.I.i('sync', '候选地址 $found 连不上');
        continue;
      }
      await _peers.updateLastSeen(peer.peerDeviceId, found);
      AppLog.I.i('sync', '在局域网找到 ${peer.displayName} 的新地址：$stored → $found');
      return found;
    }
    return valid ? stored : null;
  }

  Future<bool> _ping(SecureChannel channel, String addr) async {
    try {
      await _postSealed(channel, addr.split(':').first,
          int.parse(addr.split(':').last), '/ping', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SyncResult> _pushTo(Peer peer) async {
    final generation = await _db.currentGeneration();
    final keyB64 = await _keyStore.read('sync_peer_${peer.peerDeviceId}');
    if (keyB64 == null) {
      return await _fail(peer, generation, '缺少地址或密钥，请重新配对');
    }
    final channel = SecureChannel(base64Decode(keyB64));
    final addr = await _reachableAddr(peer, channel);
    if (addr == null) {
      return await _fail(peer, generation, '缺少地址或密钥，请重新配对');
    }
    final host = addr.split(':').first;
    final port = int.parse(addr.split(':').last);

    final state = await _pushState(peer.peerDeviceId);
    var cursor = (state != null && state.generation == generation)
        ? state.ackedContiguousSeq
        : 0;

    final changes = await (_db.select(_db.changeLogs)
          ..where((t) =>
              t.generation.equals(generation) &
              t.changeSeq.isBiggerThanValue(cursor))
          ..orderBy([(t) => OrderingTerm.asc(t.changeSeq)]))
        .get();

    var sent = 0;
    try {
      for (final change in changes) {
        final reply = await _postSealed(channel, host, port, '/changes', {
          'change': {
            'generation': change.generation,
            'seq': change.changeSeq,
            'entity_type': change.entityType,
            'entity_id': change.entityId,
            'entity_version': change.entityVersion,
            'op': enumToDb(change.op),
            'payload': jsonDecode(change.payload),
            'depends_on_blob': change.dependsOnBlob,
          },
        });
        var status = reply['status'];
        if (status == 'need_blob') {
          await _uploadBlob(channel, host, port, reply['sha'] as String);
          final retry = await _postSealed(channel, host, port, '/changes', {
            'change': {
              'generation': change.generation,
              'seq': change.changeSeq,
              'entity_type': change.entityType,
              'entity_id': change.entityId,
              'entity_version': change.entityVersion,
              'op': enumToDb(change.op),
              'payload': jsonDecode(change.payload),
              'depends_on_blob': change.dependsOnBlob,
            },
          });
          status = retry['status'];
        }
        if (status == 'generation_changed') {
          return await _fail(peer, generation,
              '数据代次已变化（从导出恢复过），请在 Mac 首页确认重建副本后再同步');
        }
        if (status != 'applied') {
          return await _fail(
              peer, generation, '第 ${change.changeSeq} 条被拒：$status',
              sent: sent, pendingLeft: changes.length - sent);
        }
        cursor = change.changeSeq; // 逐条确认，连续推进
        sent++;
        await _saveState(peer.peerDeviceId, generation, cursor,
            pending: changes.length - sent);
      }
      await _saveState(peer.peerDeviceId, generation, cursor,
          pending: 0, success: true);
      return SyncResult(sent: sent, pending: 0);
    } on Exception catch (e) {
      return await _fail(peer, generation, '连接失败：$e',
          sent: sent, pendingLeft: changes.length - sent);
    }
  }

  Future<void> _uploadBlob(
      SecureChannel channel, String host, int port, String sha) async {
    final f = File(p.join(_filesDir.path, sha));
    if (!await f.exists()) {
      throw StateError('本机没有附件文件 $sha，无法上传');
    }
    final reply = await _postSealed(channel, host, port, '/blob', {
      'sha': sha,
      'bytes': base64Encode(await f.readAsBytes()),
    });
    if (reply['status'] != 'stored') {
      throw StateError('附件上传失败：${reply['status']}');
    }
  }

  Future<SyncState?> _pushState(String peerId) => (_db.select(_db.syncStates)
        ..where((t) =>
            t.peerDeviceId.equals(peerId) &
            t.direction.equalsValue(SyncDirection.push)))
      .getSingleOrNull();

  Future<void> _saveState(
    String peerId,
    String generation,
    int cursor, {
    required int pending,
    bool success = false,
    String? error,
  }) =>
      _db.into(_db.syncStates).insertOnConflictUpdate(
            SyncStatesCompanion.insert(
              peerDeviceId: peerId,
              direction: SyncDirection.push,
              generation: generation,
              ackedContiguousSeq: Value(cursor),
              pendingCount: Value(pending),
              lastSuccessAt: success
                  ? Value(DateTime.now().toUtc().millisecondsSinceEpoch)
                  : const Value.absent(),
              lastError: Value(error),
            ),
          );

  Future<SyncResult> _fail(
    Peer peer,
    String generation,
    String message, {
    int sent = 0,
    int? pendingLeft,
  }) async {
    final pending = pendingLeft ?? await _pendingCount(generation, peer);
    final state = await _pushState(peer.peerDeviceId);
    await _saveState(peer.peerDeviceId, generation,
        state?.generation == generation ? state!.ackedContiguousSeq : 0,
        pending: pending, error: message);
    return SyncResult(sent: sent, pending: pending, error: message);
  }

  Future<int> _pendingCount(String generation, Peer peer) async {
    final state = await _pushState(peer.peerDeviceId);
    final cursor = (state != null && state.generation == generation)
        ? state.ackedContiguousSeq
        : 0;
    final rows = await (_db.select(_db.changeLogs)
          ..where((t) =>
              t.generation.equals(generation) &
              t.changeSeq.isBiggerThanValue(cursor)))
        .get();
    return rows.length;
  }

  /// 从第一个已配对的 Mac 拉取最新分析结果（V3-M5）。没有或失败返回 null。
  Future<Map<String, Object?>?> fetchLatestAnalysis() async {
    final peers = await _peers.all();
    for (final peer in peers) {
      final keyB64 = await _keyStore.read('sync_peer_${peer.peerDeviceId}');
      if (keyB64 == null) continue;
      final channel = SecureChannel(base64Decode(keyB64));
      final addr = await _reachableAddr(peer, channel);
      if (addr == null) continue;
      try {
        final reply = await _postSealed(
          channel,
          addr.split(':').first,
          int.parse(addr.split(':').last),
          '/analysis',
          {},
        );
        final artifact = reply['artifact'];
        if (artifact is Map) return artifact.cast<String, Object?>();
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// 用户主动取回原件（D-22/A-21）：向已配对 Mac 请求同一 sha 的文件，
  /// 校验哈希后落盘，返回本地路径；Mac 不可达或没有该文件时返回 null。
  Future<String?> retrieveBlob(String sha) async {
    for (final peer in await _peers.all()) {
      final keyB64 = await _keyStore.read('sync_peer_${peer.peerDeviceId}');
      if (keyB64 == null) continue;
      final channel = SecureChannel(base64Decode(keyB64));
      final addr = await _reachableAddr(peer, channel);
      if (addr == null) continue;
      try {
        final reply = await _postSealed(
          channel,
          addr.split(':').first,
          int.parse(addr.split(':').last),
          '/blob_fetch',
          {'sha': sha},
        );
        if (reply['status'] != 'found') continue;
        final bytes = base64Decode(reply['bytes'] as String);
        if (crypto.sha256.convert(bytes).toString() != sha) {
          AppLog.I.w('sync', '取回文件哈希不符，丢弃：$sha');
          continue;
        }
        await _filesDir.create(recursive: true);
        final target = File(p.join(_filesDir.path, sha));
        await target.writeAsBytes(bytes);
        return target.path;
      } catch (e) {
        AppLog.I.w('sync', '取回原件失败（${peer.displayName}）：$e');
        continue;
      }
    }
    return null;
  }

  Future<Map<String, Object?>> _postSealed(
    SecureChannel channel,
    String host,
    int port,
    String path,
    Map<String, Object?> body,
  ) async {
    final envelope = await channel.seal(body, senderDeviceId: deviceId);
    final reply = await postEnvelope(host, port, path, envelope);
    final (_, opened) = await channel.open(reply);
    return opened;
  }
}
