import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_server.dart';
import 'day_view_page.dart';
import 'mac_messages_page.dart';
import 'model_config_page.dart';

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

  SyncState? _pullState;
  AnalysisArtifact? _latestReport;
  bool _generating = false;

  Future<void> _generateReport() async {
    setState(() => _generating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.services.analysisService.generateWeeklyReview();
      messenger.showSnackBar(const SnackBar(content: Text('周报已生成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _generating = false);
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _ensureServer();
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
    final pull = await (db.select(db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull))
          ..limit(1))
        .getSingleOrNull();
    final latestReport =
        await widget.services.analysisService.latest(AnalysisKind.weeklyReview);
    if (mounted) {
      setState(() {
        _messageCount = messages.where((m) => m.deletedAt == null).length;
        _recordCount = records.where((r) => r.deletedAt == null).length;
        _peers = peers;
        _pullState = pull;
        _latestReport = latestReport;
      });
    }
  }

  String get _syncText {
    final s = _pullState;
    if (s == null) return '还没有收到过同步';
    final t =
        DateTime.fromMillisecondsSinceEpoch(s.lastSuccessAt ?? 0).toLocal();
    return '已确认到第 ${s.ackedContiguousSeq} 条 · '
        '最近 ${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// 常驻服务：应用打开即监听，配对过的手机随时可以推送。
  Future<void> _ensureServer() async {
    if (_server != null) return;
    _server = SyncServer(
      deviceId: widget.services.ctx.deviceId,
      displayName: 'Mac',
      db: widget.services.db,
      filesDir: widget.services.filesDir,
      peers: _peerRepo,
      keyStore: widget.services.keyStore,
    )..onReplicaChanged = () {
        if (mounted) _load();
      };
    await _server!.start();
    if (mounted) setState(() {});
  }

  Future<void> _startPairing() async {
    await _ensureServer();
    final info = await _server!.startPairing();
    if (mounted) setState(() => _pairing = info);
    // 配对完成后刷新列表（简单轮询，之后换事件）。
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
                  Text('同步：$_syncText'),
                  if (_server?.running ?? false)
                    Text('接收服务：端口 ${_server!.port}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('浏览消息'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MacMessagesPage(services: widget.services)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined,
                            size: 18),
                        label: const Text('按日查看'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DayViewPage(
                                  services: widget.services, readOnly: true)),
                        ),
                      ),
                    ],
                  ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('周报分析',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_latestReport != null) ...[
                    Text(
                        '最新：${_latestReport!.periodStart} 至 ${_latestReport!.periodEnd}'),
                    const SizedBox(height: 4),
                    Text(
                      _latestReport!.contentMd,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const Text('还没有生成过周报。生成失败时旧周报保留。'),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _generating ? null : _generateReport,
                        child: Text(_generating ? '生成中…' : '生成周报'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ModelConfigPage(services: widget.services)),
                        ),
                        child: const Text('模型配置'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('周报由这台 Mac 上配置的模型生成（配置不与手机同步），'
                      '手机在"周报"页拉取查看。',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
