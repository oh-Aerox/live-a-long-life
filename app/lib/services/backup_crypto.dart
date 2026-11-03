import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// 备份加密（D-15、D-51）：电脑端备份和手机 iCloud 备份共用。
///
/// - 密钥由备份密码经 PBKDF2-HMAC-SHA256（20 万次迭代）派生；
/// - 每个文件单独 AES-256-GCM 加密，格式：nonce(12) | ciphertext | tag(16)；
/// - 密码不对或内容被改，解密抛 [SecretBoxAuthenticationError]。
class BackupCrypto {
  BackupCrypto._();

  static final _aes = AesGcm.with256bits();

  static List<int> randomBytes(int n) {
    final r = Random.secure();
    return List.generate(n, (_) => r.nextInt(256));
  }

  static Future<List<int>> deriveKey(String passphrase, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 200000,
      bits: 256,
    );
    return pbkdf2
        .deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt)
        .then((k) => k.extractBytes());
  }

  static Future<List<int>> encrypt(List<int> clear, List<int> key) async {
    final box = await _aes.encrypt(clear, secretKey: SecretKey(key));
    return [...box.nonce, ...box.cipherText, ...box.mac.bytes];
  }

  static Future<List<int>> decrypt(List<int> data, List<int> key) async {
    if (data.length < 28) throw const FormatException('加密文件太短');
    final box = SecretBox(
      data.sublist(12, data.length - 16),
      nonce: data.sublist(0, 12),
      mac: Mac(data.sublist(data.length - 16)),
    );
    return _aes.decrypt(box, secretKey: SecretKey(key));
  }
}
