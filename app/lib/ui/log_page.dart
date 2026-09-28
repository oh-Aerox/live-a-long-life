import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_log.dart';

/// 运行日志查看（2026-09-28）：最近日志、复制、清空。
/// 文件在 Application Support/logs/app.log。
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<String> _lines = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _lines = AppLog.I.recent());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: '复制全部',
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: _lines.reversed.join('\n')));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空',
            onPressed: () async {
              await AppLog.I.clear();
              _refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (AppLog.I.filePath != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SelectableText('日志文件：${AppLog.I.filePath}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          Expanded(
            child: _lines.isEmpty
                ? const Center(child: Text('暂无日志'))
                : ListView.builder(
                    itemCount: _lines.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      child: SelectableText(
                        _lines[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _lines[i].contains(' E/') ||
                                  _lines[i].contains(' W/')
                              ? Colors.orange
                              : null,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
