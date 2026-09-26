import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 每日回顾提醒（product-spec §3、A-05）。
/// 只用本地通知，免费签名不支持远程推送也不受影响（D-19）。
/// iOS 上已排期的本地通知重启后仍会触发；每次启动按设置重排一遍，
/// 保证设置修改后生效。
class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<void> init(String ianaTz) async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(ianaTz));
    } catch (_) {
      // 未知时区名时用库默认（UTC），提醒时间会有偏差但不崩溃。
    }
    await _plugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(
          // 权限在首次引导设置回顾时间时再申请，先不弹窗。
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// 按设置重排所有每日回顾通知。`times` 形如 ["21:30", "08:00"]。
  Future<void> scheduleReviewTimes(List<String> times,
      {required bool enabled}) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    if (!enabled) return;
    for (var i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      final hour = int.tryParse(parts[0]) ?? 21;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30;
      await _plugin.zonedSchedule(
        i,
        '今天过得怎么样？',
        '有什么想记下来的，点开说一句就行。',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'daily_review',
            '每日回顾',
            channelDescription: '在设定的时间提醒记录',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // 每天重复
      );
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
