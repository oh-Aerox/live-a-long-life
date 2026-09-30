import 'package:flutter/services.dart';

/// 安卓系统设置入口（plan-android AN-M2）。原生实现见
/// android/app/src/main/kotlin/.../AndroidSettingsChannel.kt。
/// 只查状态、打开系统页面；设置由用户在系统页面里自己完成。
class AndroidSettings {
  const AndroidSettings();

  static const _channel = MethodChannel('life.long/android_settings');

  /// 省电策略是否"无限制"（系统不优化本应用的电池使用）与设备信息。
  Future<AndroidStatus> status() async {
    final raw = (await _channel.invokeMapMethod<String, Object?>('status'))!;
    return AndroidStatus(
      ignoringBatteryOptimizations:
          raw['ignoringBatteryOptimizations'] as bool? ?? false,
      device: '${raw['manufacturer']} ${raw['model']}，'
          'Android ${raw['release']}（API ${raw['sdk']}）',
    );
  }

  /// 应用详情页（小米在这里设"省电策略"）。
  Future<bool> openAppDetails() async =>
      await _channel.invokeMethod<bool>('openAppDetails') ?? false;

  /// 小米"自启动管理"；打不开时原生侧退回应用详情页。
  Future<bool> openAutoStart() async =>
      await _channel.invokeMethod<bool>('openAutoStart') ?? false;
}

class AndroidStatus {
  const AndroidStatus(
      {required this.ignoringBatteryOptimizations, required this.device});

  final bool ignoringBatteryOptimizations;
  final String device;
}
