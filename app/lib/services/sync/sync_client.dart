import 'dart:convert';
import 'dart:io';

import '../../data/db/app_database.dart';
import '../../data/repositories/peer_repository.dart';
import '../key_store.dart';
import 'secure_channel.dart';

/// 发送一个加密信封并取回响应信封（同步各端点共用）。
Future<Map<String, Object?>> postEnvelope(
  String host,
  int port,
  String path,
  Map<String, Object?> envelope,
) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.post(host, port, path);
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

/// 手机端配对客户端。推送在 SyncService。
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

  /// 用扫到的二维码完成配对。逐个地址尝试，成功即双端绑定；
  /// 地址连同端口存入 peers.last_seen_addr，之后推送直接用。
  Future<Peer> pairWith(PairingInfo info) async {
    final channel = SecureChannel(info.key);
    Object? lastError;
    for (final host in info.hosts) {
      try {
        final reply = await postEnvelope(
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
          lastSeenAddr: '$host:${info.port}',
        );
        await _keyStore.saveRaw('sync_peer_$peerId', base64Encode(info.key));
        return peer;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('无法连接电脑（试过 ${info.hosts.join('、')}）：$lastError');
  }

  /// 连通性检查（配对后验证通道）。
  Future<bool> ping(Peer peer) async {
    final keyB64 = await _keyStore.read('sync_peer_${peer.peerDeviceId}');
    final addr = peer.lastSeenAddr;
    if (keyB64 == null || addr == null || !addr.contains(':')) return false;
    final channel = SecureChannel(base64Decode(keyB64));
    try {
      final reply = await postEnvelope(
        addr.split(':').first,
        int.parse(addr.split(':').last),
        '/ping',
        await channel.seal({}, senderDeviceId: deviceId),
      );
      await channel.open(reply);
      return true;
    } catch (_) {
      return false;
    }
  }
}
