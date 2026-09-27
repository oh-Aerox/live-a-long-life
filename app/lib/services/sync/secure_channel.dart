import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// 同步通道的加密与双向认证（D-13，plan-v0.3 §2 定案）：
///
/// - 配对二维码只出现在用户自己的 Mac 屏幕上，本身就是带外安全信道，
///   直接携带 32 字节对称密钥；
/// - 之后所有消息用 AES-256-GCM 加密，AAD 绑定发送方设备 ID 与时间戳
///   ——GCM 是 AEAD，认证与加密一体，没有密钥的请求解不开也伪造不了；
/// - 时间戳窗口（±5 分钟）+ 单次 nonce 缓存挡重放；
/// - 双端各存密钥的 SHA-256 指纹（peers.cert_fingerprint），密钥本体
///   在系统安全存储。解除配对即删密钥。
class SecureChannel {
  SecureChannel(this.key);

  /// 32 字节对称密钥。
  final List<int> key;

  static final _aes = AesGcm.with256bits();
  static const replayWindow = Duration(minutes: 5);

  /// 近期见过的 nonce（挡重放）。窗口外的自然过期清理。
  final _seenNonces = <String, int>{};

  static Future<List<int>> newKey() async =>
      (await _aes.newSecretKey()).extractBytes();

  static String fingerprintOf(List<int> key) =>
      crypto.sha256.convert(key).toString();

  String get fingerprint => fingerprintOf(key);

  /// 加密一条消息。[senderDeviceId] 进 AAD，接收方核对身份。
  Future<Map<String, Object?>> seal(
    Map<String, Object?> body, {
    required String senderDeviceId,
  }) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final aad = utf8.encode('$senderDeviceId|$ts');
    final box = await _aes.encrypt(
      utf8.encode(jsonEncode(body)),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return {
      'from': senderDeviceId,
      'ts': ts,
      'nonce': base64Encode(box.nonce),
      'data': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
  }

  /// 解密并校验。身份、时效或密文不对时抛 [ChannelException]。
  Future<(String senderDeviceId, Map<String, Object?> body)> open(
      Map<String, Object?> envelope) async {
    final from = envelope['from'];
    final ts = envelope['ts'];
    if (from is! String || ts is! int) {
      throw ChannelException('信封缺少身份或时间戳');
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if ((now - ts).abs() > replayWindow.inMilliseconds) {
      throw ChannelException('消息过期');
    }
    final nonceB64 = envelope['nonce'] as String? ?? '';
    if (_seenNonces.containsKey(nonceB64)) {
      throw ChannelException('重放的消息');
    }
    _seenNonces[nonceB64] = ts;
    _seenNonces.removeWhere(
        (_, seenTs) => now - seenTs > replayWindow.inMilliseconds * 2);

    try {
      final clear = await _aes.decrypt(
        SecretBox(
          base64Decode(envelope['data'] as String),
          nonce: base64Decode(nonceB64),
          mac: Mac(base64Decode(envelope['tag'] as String)),
        ),
        secretKey: SecretKey(key),
        aad: utf8.encode('$from|$ts'),
      );
      return (
        from,
        (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>()
      );
    } on SecretBoxAuthenticationError {
      throw ChannelException('认证失败：密钥不符或内容被篡改');
    } on FormatException {
      throw ChannelException('信封格式不对');
    }
  }
}

class ChannelException implements Exception {
  ChannelException(this.message);
  final String message;

  @override
  String toString() => 'ChannelException: $message';
}

/// 配对二维码的内容（V3-M2）。
class PairingInfo {
  PairingInfo({
    required this.macDeviceId,
    required this.displayName,
    required this.hosts,
    required this.port,
    required this.key,
  });

  final String macDeviceId;
  final String displayName;

  /// Mac 的局域网地址（可能多个网卡）。
  final List<String> hosts;
  final int port;
  final List<int> key;

  String encode() => jsonEncode({
        'v': 1,
        'app': 'live_a_long_life_pairing',
        'device_id': macDeviceId,
        'name': displayName,
        'hosts': hosts,
        'port': port,
        'key': base64Encode(key),
      });

  static PairingInfo? decode(String qrText) {
    try {
      final json = jsonDecode(qrText) as Map;
      if (json['app'] != 'live_a_long_life_pairing' || json['v'] != 1) {
        return null;
      }
      return PairingInfo(
        macDeviceId: json['device_id'] as String,
        displayName: json['name'] as String,
        hosts: (json['hosts'] as List).cast<String>(),
        port: json['port'] as int,
        key: base64Decode(json['key'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
