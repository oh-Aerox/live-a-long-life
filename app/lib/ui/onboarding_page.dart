import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/notification_service.dart';
import 'profile_page.dart';

/// 首次使用引导（product-spec §3、D-18）：
/// 确认时区 → 设置回顾时间 → 可跳过的基本资料。
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.services,
    required this.notifications,
    required this.detectedTz,
    required this.onDone,
  });

  final AppServices services;
  final NotificationService notifications;
  final String detectedTz;
  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  TimeOfDay _reviewTime = const TimeOfDay(hour: 21, minute: 30);
  bool _reviewEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _confirmTz() async {
    await widget.services.settings.set('home_tz', widget.detectedTz);
    _next();
  }

  Future<void> _confirmReview() async {
    final text = '${_reviewTime.hour.toString().padLeft(2, '0')}:'
        '${_reviewTime.minute.toString().padLeft(2, '0')}';
    await widget.services.settings.set('review_times', [text]);
    await widget.services.settings.set('review_enabled', _reviewEnabled);
    if (_reviewEnabled) {
      await widget.notifications.requestPermission();
    }
    await widget.notifications
        .scheduleReviewTimes([text], enabled: _reviewEnabled);
    _next();
  }

  Future<void> _finish() async {
    await widget.services.settings.set('onboarding_done', true);
    widget.onDone();
  }

  Widget _step({
    required IconData icon,
    required String title,
    required String body,
    required List<Widget> actions,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5)),
          if (extra != null) ...[const SizedBox(height: 20), extra],
          const SizedBox(height: 28),
          ...actions,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _step(
              icon: Icons.public,
              title: '确认时区',
              body: '记录的"今天""昨天"按这个时区理解。\n检测到你在：'
                  '${widget.detectedTz}',
              actions: [
                FilledButton(
                    onPressed: _confirmTz, child: const Text('就是这个')),
              ],
            ),
            _step(
              icon: Icons.alarm,
              title: '每日回顾时间',
              body: '每天在这个时间提醒你记录。可以之后在设置里修改、'
                  '添加多个时间或关闭。',
              extra: Column(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                          context: context, initialTime: _reviewTime);
                      if (picked != null) {
                        setState(() => _reviewTime = picked);
                      }
                    },
                    child: Text(
                        '${_reviewTime.hour.toString().padLeft(2, '0')}:'
                        '${_reviewTime.minute.toString().padLeft(2, '0')}'),
                  ),
                  SwitchListTile(
                    title: const Text('开启提醒'),
                    value: _reviewEnabled,
                    onChanged: (v) => setState(() => _reviewEnabled = v),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                    onPressed: _confirmReview, child: const Text('好')),
              ],
            ),
            _step(
              icon: Icons.person_outline,
              title: '基本资料',
              body: '出生年月、慢性病、长期用药这些资料能让以后的记录'
                  '更有用。每一项都可以跳过，之后随时在设置里填。',
              actions: [
                FilledButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProfilePage(services: widget.services)),
                    );
                    await _finish();
                  },
                  child: const Text('现在填写'),
                ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: _finish, child: const Text('跳过，开始使用')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
