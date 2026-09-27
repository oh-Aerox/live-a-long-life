import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_server.dart';

/// Mac 端主页（plan-v0.3 V3-M0）：副本概览骨架。
/// Mac 只保存手机同步来的副本，不能编辑（D-12）；
/// 同步、浏览、周报在 V3-M3 至 V3-M5 逐步补齐。
class MacHomePage extends StatefulWidget {
  const MacHomePage({super.key, required this.services});

  final AppServices services;

  @override
  State<MacHomePage> createState() => _MacHomePageState();
}

class _MacHomePageState extends State<MacHomePage> {
  int _messageCount = 0;
  int _recordCount = 0;
  List<Peer> _peers = [];
  SyncServer? _server;
  PairingInfo? _pairing;

  late final PeerRepository _peerRepo =
      PeerRepository(widget.services.db);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final db = widget.services.db;
    final messages = await db.select(db.messages).get();
    final records = await db.select(db.records).get();
    final peers = await _peerRepo.all();
    if (mounted) {
      setState(() {
        _messageCount = messages.where((m) => m.deletedAt == null).length;
        _recordCount = records.where((r) => r.deletedAt == null).length;
        _peers = peers;
      });
    }
  }

  Future<void> _startPairing() async {
    _server ??= SyncServer(
      deviceId: widget.services.ctx.deviceId,
      displayName: 'Mac',
      peers: _peerRepo,
      keyStore: widget.services.keyStore,
    );
    final info = await _server!.startPairing();
    if (mounted) setState(() => _pairing = info);
    // 配对完成后刷新列表（简单轮询，V3-M3 换事件）。
    Future.delayed(const Duration(seconds: 3), _pollPaired);
  }

  Future<void> _pollPaired() async {
    if (!mounted || _pairing == null) return;
    final before = _peers.length;
    await _load();
    if (_peers.length > before) {
      setState(() => _pairing = null); // 配对成功，收起二维码
    } else {
      Future.delayed(const Duration(seconds: 3), _pollPaired);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长寿记（Mac 副本）')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('这台 Mac 保存手机同步来的完整副本，只读不改；'
              '记录的新建与修改只在手机上进行。'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('副本概览', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('消息：$_messageCount 条'),
                  Text('记录：$_recordCount 条'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('配对', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final peer in _peers)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone_iphone),
                      title: Text(peer.displayName),
                      subtitle: Text(
                          '指纹 ${peer.certFingerprint.substring(0, 16)}… · '
                          '最近地址 ${peer.lastSeenAddr ?? "—"}'),
                    ),
                  if (_pairing != null) ...[
                    const Text('用手机打开 长寿记 → 设置 → 连接 Mac，扫这个码：'),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: _pairing!.encode(),
                          size: 240,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '地址 ${_pairing!.hosts.join(" / ")} 端口 ${_pairing!.port}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ] else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: _startPairing,
                        child: Text(_peers.isEmpty ? '开始配对' : '重新配对'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text('周报分析'),
              subtitle: Text('V3-M5 提供：用你配置的模型生成周报，回传手机。'),
            ),
          ),
        ],
      ),
    );
  }
}
