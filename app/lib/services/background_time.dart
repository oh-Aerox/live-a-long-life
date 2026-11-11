import 'dart:io';

import 'package:flutter/services.dart';

import 'app_log.dart';

/// 向 iOS 多要一点后台时间（AppDelegate.swift 的 BackgroundTaskChannel）：
/// 切到后台或锁屏后，系统通常再给约 30 秒，在途的模型请求与写库能做完，
/// 不会被挂起后断在半路。其他平台不挂起，直接执行。
class BackgroundTime {
  const BackgroundTime._();

  static const _channel = MethodChannel('life.long/background_task');

  static Future<T> run<T>(String name, Future<T> Function() body) async {
    if (!Platform.isIOS) return body();
    int? id;
    try {
      id = await _channel.invokeMethod<int>('begin', {'name': name});
    } catch (e) {
      AppLog.I.w('app', '申请后台时间失败（$name）：$e');
    }
    try {
      return await body();
    } finally {
      if (id != null) {
        try {
          await _channel.invokeMethod('end', {'id': id});
        } catch (_) {}
      }
    }
  }
}
