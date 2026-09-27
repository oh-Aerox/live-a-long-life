import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_services.dart';
import 'services/notification_service.dart';
import 'ui/chat_page.dart';
import 'ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.init();

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

  runApp(App(
    services: services,
    tz: tz,
    notifications: notifications,
    onboarded: onboarded,
  ));
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
