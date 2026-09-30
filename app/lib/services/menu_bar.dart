import 'package:flutter/services.dart';

/// Mac 菜单栏常驻图标（P-34）。原生实现见 macos/Runner/MainFlutterWindow.swift
/// 的 MenuBarChannel：关窗只隐藏、同步服务照常运行，菜单里显示这里给的状态。
class MacMenuBar {
  const MacMenuBar();

  static const _channel = MethodChannel('life.long/menu_bar');

  /// 更新菜单第一行的同步状态。非 Mac 或测试环境没有原生侧，静默忽略。
  Future<void> setStatus(String text) async {
    try {
      await _channel.invokeMethod<bool>('setStatus', {'text': text});
    } on MissingPluginException {
      // 没有原生侧
    }
  }
}
