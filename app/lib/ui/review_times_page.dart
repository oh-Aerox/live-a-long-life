import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/notification_service.dart';

/// 每日回顾时间（R-11、A-05）：可设多个时间，可整体关闭。
/// 修改后立即按新设置重排本地通知。
class ReviewTimesPage extends StatefulWidget {
  const ReviewTimesPage(
      {super.key, required this.services, required this.notifications});

  final AppServices services;
  final NotificationService notifications;

  @override
  State<ReviewTimesPage> createState() => _ReviewTimesPageState();
}

class _ReviewTimesPageState extends State<ReviewTimesPage> {
  List<String>? _times;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final times = (await widget.services.settings.get('review_times') as List)
        .cast<String>();
    final enabled =
        await widget.services.settings.get('review_enabled') as bool;
    if (mounted) {
      setState(() {
        _times = times;
        _enabled = enabled;
      });
    }
  }

  Future<void> _save() async {
    await widget.services.settings.set('review_times', _times);
    await widget.services.settings.set('review_enabled', _enabled);
    if (_enabled && _times!.isNotEmpty) {
      await widget.notifications.requestPermission();
    }
    await widget.notifications
        .scheduleReviewTimes(_times!, enabled: _enabled);
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 21, minute: 30));
    if (picked == null) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_times!.contains(text)) {
        _times!.add(text);
        _times!.sort();
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final times = _times;
    return Scaffold(
      appBar: AppBar(title: const Text('每日回顾')),
      body: times == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('开启提醒'),
                  subtitle: const Text('在设定的时间提醒你记录今天'),
                  value: _enabled,
                  onChanged: (v) async {
                    setState(() => _enabled = v);
                    await _save();
                  },
                ),
                const Divider(height: 1),
                for (final t in times)
                  ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(t),
                    enabled: _enabled,
                    trailing: times.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              setState(() => _times!.remove(t));
                              await _save();
                            },
                          )
                        : null,
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('添加时间'),
                  enabled: _enabled,
                  onTap: _addTime,
                ),
              ],
            ),
    );
  }
}
