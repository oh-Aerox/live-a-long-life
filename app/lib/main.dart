import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_services.dart';
import 'data/change_log.dart';
import 'data/data_profile.dart';
import 'services/app_log.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';
import 'ui/chat_page.dart';
import 'ui/mac_home_page.dart';
import 'ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLog.init();
  // 未捕获的框架异常也进日志，便于事后排查。
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.I.e('flutter', details.summary.toString(), details.exception,
        details.stack);
  };
  // 未等待的 Future 抛出的异常不走 FlutterError.onError，也要进日志
  // （2026-10-26：健康数据同步连续失败，app.log 里一条都没有）。
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLog.I.e('app', '未捕获的异步异常', error, stack);
    return true;
  };
  final services = await AppServices.init();

  // 检验项目索引是派生数据、不同步也不导出（D-27）：启动时按记录整表重建。
  // Mac 补上接收时没建的行（2026-09-29 联调：Mac 上检验结果为空）；手机补上
  // 从导出恢复后的索引（2026-09-30：恢复后指标趋势为空）。
  try {
    final rows = await services.records.rebuildLabResultIndex();
    AppLog.I.i('app', '检验项目索引重建：$rows 行');
  } catch (e, st) {
    AppLog.I.e('app', '检验项目索引重建失败', e, st);
  }

  // 电脑端（Mac 与 Windows）：只读副本 + 同步接收，不初始化手机专属
  // 插件（通知、HealthKit、整理触发都属于手机，D-12）。
  if (Platform.isMacOS || Platform.isWindows) {
    // 日视图的设备数据区只读数据库，不会调用 HealthKit。
    services.healthService = HealthService(
      repository: services.health,
      settings: services.settings,
      tz: 'Asia/Shanghai',
    );
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
    // 从导出或 iCloud 恢复到新装的应用时跳过了引导，通知权限还没申请过：
    // 这里补申请（已决定过的不会再弹）。排期失败不能挡住启动——iOS 未授权时
    // zonedSchedule 直接抛错，曾导致恢复后打开一片空白（2026-11-02）。
    try {
      if (enabled) await notifications.requestPermission();
      await notifications.scheduleReviewTimes(times, enabled: enabled);
    } catch (e, st) {
      AppLog.I.e('app', '回顾提醒排期失败', e, st);
    }
  }

  // 启动补整理：上次失败或没配模型时留下的"待整理"消息（A-10）。
  unawaited(services.organizeService.catchUp());
  // 回到前台也补整理：模型恢复后不必等到下次启动或退避计时。
  AppLifecycleListener(
      onResume: () => unawaited(services.organizeService.catchUp()));

  // 变更日志埋点前的存量数据一次性回填；清理一次重复记录（修复前遗留）；
  // 再推送（失败静默，状态在"连接 Mac"页可见）。
  unawaited(() async {
    await services.db.backfillChangeLogIfNeeded(services.ctx.deviceId);
    final exams = await services.medicalDocuments.repairPhysicalExamType();
    if (exams > 0) AppLog.I.i('medical', '体检报告类型改回：$exams 份');
    final repaired = await services.records.repairMissingSources();
    if (repaired > 0) AppLog.I.i('records', '补回来源链接：$repaired 个版本');
    final drinks = await services.records.repairDrinkSlots();
    if (drinks > 0) AppLog.I.i('records', '饮水记录归回饮水：$drinks 条');
    final fixed = await services.records.repairUnappliedOcrFixes();
    if (fixed > 0) AppLog.I.i('records', '补上识别修正：$fixed 份检验报告');
    final removed = await services.records.dedupeExactDuplicates();
    if (removed > 0) AppLog.I.i('records', '清理重复记录 $removed 条');
    await services.syncService.syncNow();
    // iCloud 备份（D-51）：开了自动备份时，启动、回到前台、切到后台各试
    // 一次，内容没变不写。切到后台时向系统要时间写完。
    await services.cloudBackup.autoBackup();
  }());
  AppLifecycleListener(
    onResume: () => unawaited(services.cloudBackup.autoBackup()),
    onHide: () =>
        unawaited(services.cloudBackup.autoBackup(background: true)),
  );

  // 健康数据：用户在设置里开启后，启动和回到前台时增量同步。
  services.healthService = HealthService(
    repository: services.health,
    settings: services.settings,
    tz: tz,
  );
  unawaited(services.healthService.autoSync());
  AppLifecycleListener(
      onResume: () => unawaited(services.healthService.autoSync()));

  // 每日回顾：点开通知进入带提问的对话流，只问缺的。
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

/// 电脑端应用：Mac 与 Windows 共用。
class MacApp extends StatelessWidget {
  const MacApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '长命百岁',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      home: MacHomePage(services: services),
      // 开发用数据档案（plan-android AN-M6）：角标提醒这不是日常在用的副本。
      builder: DataProfile.isDefault
          ? null
          : (context, child) => Banner(
                message: DataProfile.name,
                location: BannerLocation.topEnd,
                child: child!,
              ),
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
      title: '长命百岁',
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
