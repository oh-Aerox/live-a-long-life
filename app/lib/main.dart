import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_services.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';
import 'ui/chat_page.dart';
import 'ui/mac_home_page.dart';
import 'ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.init();

  // Mac 端（V3-M0）：只读副本 + 同步接收，不初始化手机专属插件
  // （通知、HealthKit、整理触发都属于手机，D-12）。
  if (Platform.isMacOS) {
    runApp(MacApp(services: services));
    return;
  }

  // 当前 IANA 时区，写入消息的 sent_tz（schema §2.1）。
  var tz = 'Asia/Shanghai';
  try {
    tz = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    // 取不到时区时用默认值；首次引导会让用户确认。
  }

  final notifications = NotificationService();
  await notifications.init(tz);

  // 每次启动按当前设置重排回顾提醒，保证设置修改与重装后生效（A-05）。
  final onboarded =
      await services.settings.get('onboarding_done') as bool? ?? false;
  if (onboarded) {
    final times =
        (await services.settings.get('review_times') as List).cast<String>();
    final enabled = await services.settings.get('review_enabled') as bool;
    await notifications.scheduleReviewTimes(times, enabled: enabled);
  }

  // 启动补整理：上次失败或没配模型时留下的"待整理"消息（A-10）。
  unawaited(services.organizeService.catchUp());

  // 已配对时启动即尝试推送（V3-M3；失败静默，状态在"连接 Mac"页可见）。
  unawaited(services.syncService.syncNow());

  // 健康数据（V2-M4）：用户在设置里开启后，每次启动增量同步。
  services.healthService = HealthService(
    repository: services.health,
    settings: services.settings,
    tz: tz,
  );
  if (await services.settings.get('healthkit_sync_enabled') as bool? ??
      false) {
    unawaited(services.healthService.syncNow());
  }

  // 每日回顾（V2-M5）：点开通知进入带提问的对话流，只问缺的。
  services.reviewService = ReviewService(
    messages: services.messages,
    records: services.records,
    prompts: services.reviewPrompts,
    deviceData: services.healthService.dayData,
    organize: services.organizeService,
    tz: tz,
  );
  notifications.onReviewTap =
      () => unawaited(services.reviewService.runReview());
  if (await notifications.launchedFromNotification()) {
    unawaited(services.reviewService.runReview());
  }

  runApp(App(
    services: services,
    tz: tz,
    notifications: notifications,
    onboarded: onboarded,
  ));
}

/// Mac 端应用（V3-M0 骨架）。
class MacApp extends StatelessWidget {
  const MacApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '长寿记',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      home: MacHomePage(services: services),
    );
  }
}

class App extends StatefulWidget {
  const App({
    super.key,
    required this.services,
    required this.tz,
    required this.notifications,
    required this.onboarded,
  });

  final AppServices services;
  final String tz;
  final NotificationService notifications;
  final bool onboarded;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _onboarded = widget.onboarded;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '长寿记',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      home: _onboarded
          ? ChatPage(
              services: widget.services,
              tz: widget.tz,
              notifications: widget.notifications)
          : OnboardingPage(
              services: widget.services,
              notifications: widget.notifications,
              detectedTz: widget.tz,
              onDone: () => setState(() => _onboarded = true),
            ),
    );
  }
}
