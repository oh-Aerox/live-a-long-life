import 'package:flutter/material.dart';

import '../app_services.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = widget.services.db;
    final messages = await db.select(db.messages).get();
    final records = await db.select(db.records).get();
    if (mounted) {
      setState(() {
        _messageCount = messages.where((m) => m.deletedAt == null).length;
        _recordCount = records.where((r) => r.deletedAt == null).length;
      });
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
          const Card(
            child: ListTile(
              leading: Icon(Icons.sync_disabled),
              title: Text('尚未与手机配对'),
              subtitle: Text('配对与同步在 V3-M2 / V3-M3 提供：'
                  '届时在这里显示二维码，用手机扫码配对。'),
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
