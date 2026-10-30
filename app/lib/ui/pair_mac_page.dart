import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_client.dart';

/// 扫 Mac 上的二维码完成配对（D-13）。
class PairMacPage extends StatefulWidget {
  const PairMacPage({super.key, required this.services});

  final AppServices services;

  @override
  State<PairMacPage> createState() => _PairMacPageState();
}

class _PairMacPageState extends State<PairMacPage> {
  bool _busy = false;
  String? _status;
  List<Peer> _paired = [];
  SyncState? _pushState;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final peers = await widget.services.peerRepo.all();
    final push = await (widget.services.db.select(widget.services.db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.push))
          ..limit(1))
        .getSingleOrNull();
    if (mounted) {
      setState(() {
        _paired = peers;
        _pushState = push;
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final result = await widget.services.syncService.syncNow();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.ok
              ? '已同步 ${result.sent} 条变更'
              : '同步失败：${result.error}')));
    }
    await _loadState();
  }

  String get _stateText {
    final s = _pushState;
    if (s == null) return '还没同步过';
    final parts = <String>[
      '已确认到第 ${s.ackedContiguousSeq} 条',
      if (s.pendingCount > 0) '待传 ${s.pendingCount} 条',
      if (s.lastSuccessAt != null)
        () {
          final t =
              DateTime.fromMillisecondsSinceEpoch(s.lastSuccessAt!).toLocal();
          return '最近成功 ${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }(),
      if (s.lastError != null) '错误：${s.lastError}',
    ];
    return parts.join(' · ');
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final info = PairingInfo.decode(raw);
    if (info == null) {
      setState(() => _status = '这不是长命百岁的配对二维码');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在连接 ${info.displayName}…';
    });
    try {
      final client = SyncClient(
        deviceId: widget.services.ctx.deviceId,
        displayName: Platform.isAndroid ? '安卓手机' : 'iPhone',
        peers: PeerRepository(widget.services.db),
        keyStore: widget.services.keyStore,
      );
      final peer = await client.pairWith(info);
      // 配对成功立即推一次积压的变更。
      unawaited(widget.services.syncService.syncNow());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已与 ${peer.displayName} 配对，开始同步')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '配对失败：$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('连接电脑')),
      body: Column(
        children: [
          if (_paired.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.laptop_mac),
                title: Text(_paired.map((peer) => peer.displayName).join('、')),
                subtitle: Text(_stateText),
                trailing: FilledButton.tonal(
                  onPressed: _busy ? null : _syncNow,
                  child: const Text('立即同步'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_paired.isEmpty
                ? '在电脑上打开 长命百岁 → 点「开始配对」，然后用下面的取景框对准屏幕上的二维码。'
                : '重新配对：在电脑上点「重新配对」后扫新的二维码。'),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(onDetect: _onDetect),
                // 取景框：对准二维码的视觉引导。
                IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status!),
            ),
        ],
      ),
    );
  }
}
