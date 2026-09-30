import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/android_settings.dart';
import '../services/notification_service.dart';

/// 后台与提醒（plan-android AN-M2，platform-matrix 小米 12 注意事项）：
/// 小米等系统会清理后台应用，提醒可能不响、后台同步不发生。这里列出各项
/// 设置的当前状态，点进去由用户在系统页面里开启；回到本页自动刷新。
class AndroidBackgroundPage extends StatefulWidget {
  const AndroidBackgroundPage(
      {super.key, required this.services, required this.notifications});

  final AppServices services;
  final NotificationService notifications;

  @override
  State<AndroidBackgroundPage> createState() => _AndroidBackgroundPageState();
}

class _AndroidBackgroundPageState extends State<AndroidBackgroundPage>
    with WidgetsBindingObserver {
  static const _settings = AndroidSettings();

  bool? _notifications;
  bool? _exact;
  AndroidStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统设置页回来：刷新状态，并按新权限重排提醒（精确 / 非精确）。
    if (state == AppLifecycleState.resumed) _load(reschedule: true);
  }

  Future<void> _load({bool reschedule = false}) async {
    final n = await widget.notifications.notificationsEnabled();
    final e = await widget.notifications.canScheduleExact();
    AndroidStatus? s;
    try {
      s = await _settings.status();
    } catch (_) {}
    if (reschedule) {
      final times = (await widget.services.settings.get('review_times') as List)
          .cast<String>();
      final enabled =
          await widget.services.settings.get('review_enabled') as bool;
      await widget.notifications.scheduleReviewTimes(times, enabled: enabled);
    }
    if (mounted) {
      setState(() {
        _notifications = n;
        _exact = e;
        _status = s;
      });
    }
  }

  Widget _state(bool? ok) => switch (ok) {
        true => const Text('已开启', style: TextStyle(color: Colors.green)),
        false => const Text('未开启', style: TextStyle(color: Colors.orange)),
        null => const Text('—'),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('后台与提醒')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('部分安卓手机（如小米）会清理后台应用，回顾提醒可能不响、'
                '和 Mac 的同步可能不发生。按下面几项设置后提醒最可靠。'),
          ),
          ListTile(
            title: const Text('通知'),
            subtitle: const Text('允许本应用发通知'),
            trailing: _state(_notifications),
            onTap: () async {
              await widget.notifications.requestPermission();
              await _load(reschedule: true);
            },
          ),
          ListTile(
            title: const Text('闹钟和提醒'),
            subtitle: const Text('准时提醒需要；未开启时提醒可能推迟'),
            trailing: _state(_exact),
            onTap: () => widget.notifications.requestExactPermission(),
          ),
          ListTile(
            title: const Text('省电策略'),
            subtitle: const Text('在应用详情 → 省电策略里选"无限制"'),
            trailing: _state(_status?.ignoringBatteryOptimizations),
            onTap: () => _settings.openAppDetails(),
          ),
          ListTile(
            title: const Text('自启动'),
            subtitle: const Text('允许开机后和被清理后自动启动；系统不提供状态查询，'
                '请在打开的页面里确认本应用已开启'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _settings.openAutoStart(),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Text('本机：${_status!.device}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
