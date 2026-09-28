import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API key 的安全存储（schema §4.3、D-16）。
/// key 只进系统 Keychain，数据库、导出、备份里只有引用名 `keychain_ref`。
class KeyStore {
  KeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // macOS：数据保护钥匙串需要 keychain-access-groups entitlement，
              // 免费/本机签名下报 -34018；用传统钥匙串即可（2026-09-28 联调发现）。
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  final FlutterSecureStorage _storage;

  static const _prefix = 'model_key_';

  /// 保存 key，返回写入数据库的引用名。
  Future<String> save(String configId, String apiKey) async {
    final ref = '$_prefix$configId';
    await _storage.write(key: ref, value: apiKey);
    return ref;
  }

  Future<String?> read(String keychainRef) => _storage.read(key: keychainRef);

  /// 按显式引用名保存（同步配对密钥等非模型 key 的场景）。
  Future<void> saveRaw(String keychainRef, String value) =>
      _storage.write(key: keychainRef, value: value);

  Future<void> delete(String keychainRef) =>
      _storage.delete(key: keychainRef);
}
