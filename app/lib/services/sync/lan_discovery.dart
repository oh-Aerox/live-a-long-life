import 'package:flutter/services.dart';

import '../app_log.dart';

/// 局域网发现（V4-M5 mDNS）：Mac 广播同步服务，手机按 Mac 的设备 ID 找回
/// 当前地址。原生实现见 ios/Runner/AppDelegate.swift、
/// macos/Runner/MainFlutterWindow.swift 的 BonjourChannel。
///
/// 只用来找地址；连接仍要通过配对时建立的加密认证（D-13），所以广播名被
/// 冒用也连不上。发现失败不报错，调用方退回原地址或手动重新配对。
class LanDiscovery {
  const LanDiscovery();

  static const _channel = MethodChannel('life.long/bonjour');

  /// 服务名：`llal-<设备 ID>`（UUIDv7 36 字符，远小于 Bonjour 的 63 字节上限）。
  static String serviceName(String deviceId) => 'llal-$deviceId';

  /// Mac 端：同步服务启动后广播。[hosts] 是本机局域网地址，写进 TXT 记录：
  /// Mac 在每块网卡上各广播一份，手机可能只从数据线那条链路收到解析结果，
  /// TXT 里的地址保证手机拿得到 Wi-Fi 上的局域网地址。
  Future<void> publish(String deviceId, int port, List<String> hosts) async {
    try {
      await _channel.invokeMethod<bool>('publish', {
        'name': serviceName(deviceId),
        'port': port,
        'hosts': hosts.join(','),
      });
      AppLog.I.i('sync',
          '局域网广播：${serviceName(deviceId)} 端口 $port，地址 ${hosts.join('、')}');
    } catch (e) {
      AppLog.I.w('sync', '局域网广播失败（手机仍可按地址连接）：$e');
    }
  }

  /// 手机端：按 Mac 的设备 ID 找当前地址，返回候选 `host:port`（已按
  /// [preferOrder] 排序）；找不到返回空列表。
  Future<List<String>> resolve(String deviceId,
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final raw = await _channel.invokeMethod<String>('resolve', {
        'name': serviceName(deviceId),
        'timeoutMs': timeout.inMilliseconds,
      });
      if (raw == null || raw.isEmpty) {
        AppLog.I.i('sync', '局域网没有找到 ${serviceName(deviceId)}');
        return const [];
      }
      final found = preferOrder(raw.split(','));
      AppLog.I.i('sync', '局域网找到 Mac 候选地址：${found.join('、')}');
      return found;
    } catch (e) {
      AppLog.I.w('sync', '局域网查找 Mac 失败：$e');
      return const [];
    }
  }

  /// 局域网地址优先，169.254 链路本地地址（数据线直连、AWDL）放最后：
  /// 后者拔线或换场景就不通，记下来会让下次同步又得重新查找。
  static List<String> preferOrder(Iterable<String> addrs) {
    final list = addrs.toSet().toList();
    bool linkLocal(String a) => a.startsWith('169.254.');
    return [
      ...list.where((a) => !linkLocal(a)),
      ...list.where(linkLocal),
    ];
  }
}
