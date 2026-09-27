import 'dart:convert';
import 'dart:io';

import '../../data/repositories/peer_repository.dart';
import '../key_store.dart';
import 'secure_channel.dart';

/// Mac 端同步服务（V3-M2）：本地 HTTP + SecureChannel 信封。
///
/// - `POST /pair`：用二维码里的密钥加密的配对请求；成功后双端各记 peers；
/// - `POST /ping`：已配对设备的连通性检查；
/// - 其余端点（/changes、/ack、/blob）在 V3-M3 加。
/// 没有有效密钥的请求解不开信封，一律 401（未配对的设备被拒绝，D-13）。
class SyncServer {
  SyncServer({
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

  HttpServer? _server;

  /// 正在展示的配对密钥（二维码有效期内）。配对成功或停止展示后清空。
  SecureChannel? _pendingPairing;

  /// 已配对设备的通道缓存（peerDeviceId → channel）。
  final _channels = <String, SecureChannel>{};

  int? get port => _server?.port;
  bool get running => _server != null;

  /// 启动服务并生成配对二维码内容。重复调用会换一个新的配对密钥。
  Future<PairingInfo> startPairing() async {
    _server ??= await HttpServer.bind(InternetAddress.anyIPv4, 0)
      ..listen(_handle);
    final key = await SecureChannel.newKey();
    _pendingPairing = SecureChannel(key);
    return PairingInfo(
      macDeviceId: deviceId,
      displayName: displayName,
      hosts: await _lanAddresses(),
      port: _server!.port,
      key: key,
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _pendingPairing = null;
    _channels.clear();
  }

  static Future<List<String>> _lanAddresses() async {
    final result = <String>[];
    for (final ni in await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: false)) {
      for (final addr in ni.addresses) {
        if (!addr.isLoopback) result.add(addr.address);
      }
    }
    return result;
  }

  Future<SecureChannel?> _channelFor(String peerDeviceId) async {
    final cached = _channels[peerDeviceId];
    if (cached != null) return cached;
    final peer = await _peers.active(peerDeviceId);
    if (peer == null) return null;
    final key = await _keyStore.read('sync_peer_$peerDeviceId');
    if (key == null) return null;
    final channel = SecureChannel(base64Decode(key));
    _channels[peerDeviceId] = channel;
    return channel;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final envelope =
          (jsonDecode(body) as Map).cast<String, Object?>();
      final from = envelope['from'] as String?;

      final Map<String, Object?> response;
      SecureChannel channel;
      switch (request.uri.path) {
        case '/pair':
          final pending = _pendingPairing;
          if (pending == null) {
            _reject(request, HttpStatus.forbidden, '当前没有在等待配对');
            return;
          }
          channel = pending;
          final (peerId, payload) = await channel.open(envelope);
          await _peers.pair(
            peerDeviceId: peerId,
            displayName: payload['name'] as String? ?? peerId,
            certFingerprint: channel.fingerprint,
            lastSeenAddr:
                request.connectionInfo?.remoteAddress.address,
          );
          await _keyStore.saveRaw(
              'sync_peer_$peerId', base64Encode(channel.key));
          _channels[peerId] = channel;
          _pendingPairing = null; // 密钥一次配对即绑定
          response = {'device_id': deviceId, 'name': displayName};
        case '/ping':
          final c = from == null ? null : await _channelFor(from);
          if (c == null) {
            _reject(request, HttpStatus.unauthorized, '未配对的设备');
            return;
          }
          channel = c;
          await channel.open(envelope); // 校验，不看内容
          if (from != null) {
            await _peers.updateLastSeen(
                from, request.connectionInfo?.remoteAddress.address ?? '');
          }
          response = {'device_id': deviceId, 'ok': true};
        default:
          _reject(request, HttpStatus.notFound, '未知端点');
          return;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response
          .write(jsonEncode(await channel.seal(response, senderDeviceId: deviceId)));
      await request.response.close();
    } on ChannelException catch (e) {
      _reject(request, HttpStatus.unauthorized, e.message);
    } catch (e) {
      _reject(request, HttpStatus.badRequest, '请求无法处理');
    }
  }

  void _reject(HttpRequest request, int status, String message) {
    try {
      request.response.statusCode = status;
      request.response.write(jsonEncode({'error': message}));
      request.response.close();
    } catch (_) {}
  }
}
