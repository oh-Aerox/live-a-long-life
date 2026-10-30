import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/backup_service.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_server.dart';
import 'desktop_text.dart';
import 'log_page.dart';
import 'model_calls_page.dart';
import 'model_config_page.dart';

/// Mac 端设置（2026-09-29 联调）：按 Mac 实际有的功能取舍，不照搬手机——
/// 模型（周报与咨询用）、手机连接与配对、备份位置与密码、运行日志、关于。
/// 回顾提醒、健康数据、个人资料、医疗文件空间、导出都是手机的事（D-12）。
class MacSettingsPage extends StatefulWidget {
  const MacSettingsPage({
    super.key,
    required this.services,
    required this.server,
    required this.pairedEvents,
  });

  final AppServices services;

  /// 主页常驻的同步接收服务；配对二维码由它生成。
  final SyncServer? server;

  /// 配对成功时递增（主页在 [SyncServer.onPaired] 里触发）。
  final ValueListenable<int> pairedEvents;

  @override
  State<MacSettingsPage> createState() => _MacSettingsPageState();
}

class _MacSettingsPageState extends State<MacSettingsPage> {
  late final PeerRepository _peerRepo = PeerRepository(widget.services.db);
  List<Peer> _peers = [];
  SyncState? _pull;
  PairingInfo? _pairing;
  String _version = '';
  Directory? _backupDir;

  @override
  void initState() {
    super.initState();
    widget.pairedEvents.addListener(_onPaired);
    _load();
  }

  @override
  void dispose() {
    widget.pairedEvents.removeListener(_onPaired);
    // 离开设置页时收起配对窗口，未扫码的一次性配对不留着。
    if (_pairing != null) widget.server?.cancelPairing();
    super.dispose();
  }

  void _onPaired() {
    if (!mounted) return;
    setState(() => _pairing = null);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('配对成功')));
    _load();
  }

  Future<void> _load() async {
    final db = widget.services.db;
    final peers = await _peerRepo.all();
    final pull = await (db.select(db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull))
          ..limit(1))
        .getSingleOrNull();
    final info = await PackageInfo.fromPlatform();
    final backupDir = await BackupService.backupRoot();
    if (mounted) {
      setState(() {
        _peers = peers;
        _pull = pull;
        _version = '${info.version} (${info.buildNumber})';
        _backupDir = backupDir;
      });
    }
  }

  Future<void> _startPairing() async {
    final server = widget.server;
    if (server == null) return;
    final info = await server.startPairing();
    if (mounted) setState(() => _pairing = info);
  }

  void _cancelPairing() {
    widget.server?.cancelPairing();
    setState(() => _pairing = null);
  }

  String _time(int? ms) {
    if (ms == null) return '—';
    final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeBackupPassphrase() async {
    final a = TextEditingController();
    final b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更换备份密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('新密码只用于之后的备份；已有的备份仍要用当时的密码解开。',
                style: TextStyle(fontSize: 12)),
            TextField(
                controller: a,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(labelText: '新密码')),
            TextField(
                controller: b,
                obscureText: true,
                decoration: const InputDecoration(labelText: '再输一次')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pass = a.text.trim();
    if (pass.isEmpty || pass != b.text.trim()) {
      messenger.showSnackBar(const SnackBar(content: Text('两次输入不一致，密码没有更换')));
      return;
    }
    await widget.services.keyStore.saveRaw('backup_passphrase', pass);
    messenger.showSnackBar(const SnackBar(content: Text('备份密码已更换，下次备份起生效')));
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      );

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final server = widget.server;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _section('模型'),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('模型配置'),
            subtitle: Text(desktopText('周报和咨询使用电脑端配置的模型，配置不与手机同步')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(ModelConfigPage(services: s)),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('模型调用记录'),
            subtitle: Text(desktopText('电脑端发给模型的内容与返回（周报、咨询）')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(ModelCallsPage(services: s)),
          ),
          _section('手机连接'),
          for (final peer in _peers)
            ListTile(
              leading: const Icon(Icons.phone_iphone),
              title: Text(peer.displayName),
              subtitle: Text('指纹 ${peer.certFingerprint.substring(0, 16)}… · '
                  '最近地址 ${peer.lastSeenAddr ?? "—"}'),
            ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('同步接收'),
            subtitle: Text([
              (server?.running ?? false)
                  ? '服务运行中，端口 ${server!.port}'
                  : '服务未运行',
              _pull == null
                  ? '还没有收到过同步'
                  : '已确认到第 ${_pull!.ackedContiguousSeq} 条 · 最近 ${_time(_pull!.lastSuccessAt)}',
            ].join('\n')),
          ),
          if (_pairing != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('用手机打开 长命百岁 → 设置 → 连接电脑，扫这个码：'),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(data: _pairing!.encode(), size: 240),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '地址 ${_pairing!.hosts.join(" / ")} 端口 ${_pairing!.port}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  TextButton(
                      onPressed: _cancelPairing, child: const Text('取消配对')),
                ],
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(_peers.isEmpty ? '配对手机' : '重新配对'),
              subtitle: const Text('显示二维码，用手机扫码建立加密连接'),
              enabled: server != null,
              onTap: _startPairing,
            ),
          _section('备份'),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('备份位置'),
            subtitle: Text(_backupDir?.path ?? ''),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: _backupDir == null
                ? null
                : () async {
                    final dir = _backupDir!;
                    await dir.create(recursive: true);
                    // Windows 用资源管理器打开，Mac 用访达。
                    await Process.run(
                        Platform.isWindows ? 'explorer' : 'open', [dir.path]);
                  },
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('更换备份密码'),
            subtitle: Text(desktopText('密码存在电脑端的钥匙串里；忘记密码备份无法解开')),
            onTap: _changeBackupPassphrase,
          ),
          _section('其他'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('运行日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(const LogPage()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: Text(desktopText('长命百岁电脑端 · 版本 $_version')),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              '回顾提醒、健康数据、个人资料、医疗文件空间和导出都在手机上设置。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
