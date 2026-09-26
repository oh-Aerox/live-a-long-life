import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_services.dart';
import '../services/notification_service.dart';
import '../services/signing_info.dart';
import 'profile_page.dart';
import 'review_times_page.dart';

/// 设置页（product-spec §3 v0.1 页面）。
class SettingsPage extends StatefulWidget {
  const SettingsPage(
      {super.key, required this.services, required this.notifications});

  final AppServices services;
  final NotificationService notifications;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _reviewSummary = '';
  DateTime? _signingExpiry;
  String _version = '';

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
    final expiry = await SigningInfo.provisioningExpiry();
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _reviewSummary = enabled ? times.join('、') : '已关闭';
        _signingExpiry = expiry;
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

  String get _signingText {
    final expiry = _signingExpiry;
    if (expiry == null) return '—';
    final days = expiry.difference(DateTime.now()).inDays;
    final local = expiry.toLocal();
    final date = '${local.month}月${local.day}日';
    if (days < 0) return '已过期（$date）';
    if (days == 0) return '今天到期';
    return '$days 天后（$date）';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('每日回顾'),
            subtitle: Text(_reviewSummary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ReviewTimesPage(
                        services: widget.services,
                        notifications: widget.notifications)),
              );
              await _load();
            },
          ),
          ListTile(
            title: const Text('基本资料'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfilePage(services: widget.services)),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('数据存储位置'),
            subtitle: const Text('全部数据只保存在这台手机上'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('数据存储位置'),
                content: const Text('消息、照片、PDF 和资料都保存在本机应用'
                    '沙盒里，没有任何网络上传。删除应用会一并删除数据，'
                    '重要内容请先用"导出数据"备份。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了')),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('导出数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _todo(context),
          ),
          ListTile(
            title: const Text('从导出恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _todo(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('签名到期'),
            subtitle: const Text('免费签名 7 天有效，到期前连接 Mac 重签'),
            trailing: Text(_signingText),
          ),
          ListTile(
            title: const Text('版本'),
            trailing: Text(_version),
          ),
        ],
      ),
    );
  }

  void _todo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这个功能在 M5 实现')));
  }
}
