import 'ids.dart';
import 'repositories/settings_repository.dart';

/// 当前用户与设备标识。第一版只有一个用户（R-02），
/// 首次启动时生成并存入 settings，之后保持不变。
class AppContext {
  AppContext({required this.userId, required this.deviceId});

  final String userId;
  final String deviceId;

  static Future<AppContext> load(
    SettingsRepository settings, {
    IdGenerator ids = const IdGenerator(),
  }) async {
    var userId = await settings.get('user_id') as String?;
    if (userId == null) {
      userId = ids.newId();
      await settings.set('user_id', userId);
    }
    var deviceId = await settings.get('device_id') as String?;
    if (deviceId == null) {
      deviceId = ids.newId();
      await settings.set('device_id', deviceId);
    }
    return AppContext(userId: userId, deviceId: deviceId);
  }
}
