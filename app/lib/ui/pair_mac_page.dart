import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_services.dart';
import '../data/repositories/peer_repository.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_client.dart';

/// 扫 Mac 上的二维码完成配对（V3-M2，D-13）。
class PairMacPage extends StatefulWidget {
  const PairMacPage({super.key, required this.services});

  final AppServices services;

  @override
  State<PairMacPage> createState() => _PairMacPageState();
}

class _PairMacPageState extends State<PairMacPage> {
  bool _busy = false;
  String? _status;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final info = PairingInfo.decode(raw);
    if (info == null) {
      setState(() => _status = '这不是长寿记的配对二维码');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在连接 ${info.displayName}…';
    });
    try {
      final client = SyncClient(
        deviceId: widget.services.ctx.deviceId,
        displayName: 'iPhone',
        peers: PeerRepository(widget.services.db),
        keyStore: widget.services.keyStore,
      );
      final peer = await client.pairWith(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已与 ${peer.displayName} 配对')));
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
      appBar: AppBar(title: const Text('连接 Mac')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('在 Mac 上打开 长寿记 → 点「开始配对」，'
                '然后用下面的取景框对准屏幕上的二维码。'),
          ),
          Expanded(child: MobileScanner(onDetect: _onDetect)),
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
