import 'dart:convert';
import 'dart:io';

import '../../data/db/app_database.dart';
import '../../data/repositories/peer_repository.dart';
import '../key_store.dart';
import 'secure_channel.dart';

/// 手机端同步客户端（V3-M2 先做配对与连通性；V3-M3 加推送）。
class SyncClient {
  SyncClient({
    required this.deviceId,
    required this.displayName,
    required PeerRepository peers,
    required KeyStore keyStore,
  })  : _peers = peers,
        _keyStore = keyStore;

  final String deviceId;
  final String displayName;
  final PeerRepository _peers;
  final KeyStore _keyStore;

  /// 用扫到的二维码完成配对。逐个地址尝试，成功即双端绑定。
  Future<Peer> pairWith(PairingInfo info) async {
    final channel = SecureChannel(info.key);
    Object? lastError;
    for (final host in info.hosts) {
      try {
        final reply = await _post(
          host,
          info.port,
          '/pair',
          await channel.seal({'name': displayName}, senderDeviceId: deviceId),
        );
        final (peerId, payload) = await channel.open(reply);
        if (peerId != info.macDeviceId) {
          throw ChannelException('对方身份与二维码不符');
        }
        final peer = await _peers.pair(
          peerDeviceId: peerId,
          displayName: payload['name'] as String? ?? info.displayName,
          certFingerprint: channel.fingerprint,
          lastSeenAddr: host,
        );
        await _keyStore.saveRaw(
            'sync_peer_$peerId', base64Encode(info.key));
        return peer;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('无法连接 Mac（试过 ${info.hosts.join('、')}）：$lastError');
  }

  /// 连通性检查（配对后验证通道）。
  Future<bool> ping(Peer peer) async {
    final keyB64 = await _keyStore.read('sync_peer_${peer.peerDeviceId}');
    final addr = peer.lastSeenAddr;
    if (keyB64 == null || addr == null) return false;
    final channel = SecureChannel(base64Decode(keyB64));
    try {
      final reply = await _post(addr, _portOf(peer) ?? 0, '/ping',
          await channel.seal({}, senderDeviceId: deviceId));
      await channel.open(reply);
      return true;
    } catch (_) {
      return false;
    }
  }

  // lastSeenAddr 只有 IP；端口在 V3-M3 与发现机制一起完善，
  // 这里先允许调用方带端口的地址（ip:port）。
  int? _portOf(Peer peer) {
    final addr = peer.lastSeenAddr;
    if (addr == null || !addr.contains(':')) return null;
    return int.tryParse(addr.split(':').last);
  }

  Future<Map<String, Object?>> _post(
    String host,
    int port,
    String path,
    Map<String, Object?> envelope,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.post(
          host.contains(':') ? host.split(':').first : host,
          host.contains(':') ? int.parse(host.split(':').last) : port,
          path);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(envelope));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('HTTP ${response.statusCode}：$text');
      }
      return (jsonDecode(text) as Map).cast<String, Object?>();
    } finally {
      client.close(force: true);
    }
  }
}
