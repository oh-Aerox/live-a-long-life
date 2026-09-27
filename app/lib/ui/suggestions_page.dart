import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import 'record_detail_page.dart';
import 'record_ui.dart';

/// 修正建议：接受生成 confirmed 新版本，拒绝只改状态（schema §6.2，D-12）。
class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key, required this.services});

  final AppServices services;

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  List<CorrectionSuggestion> _pending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pending = await widget.services.suggestionService.pending();
    if (mounted) setState(() => _pending = pending);
  }

  Future<void> _act(CorrectionSuggestion s, bool acceptIt) async {
    final messenger = ScaffoldMessenger.of(context);
    if (acceptIt) {
      final result = await widget.services.suggestionService.accept(s);
      messenger.showSnackBar(SnackBar(
          content: Text(result == SuggestionStatus.accepted
              ? '已按建议更新记录'
              : '记录已有更新的版本，这条建议已失效')));
    } else {
      await widget.services.suggestionService.reject(s);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修正建议')),
      body: _pending.isEmpty
          ? const Center(child: Text('没有待处理的修正建议'))
          : ListView(
              children: [for (final s in _pending) _tile(s)],
            ),
    );
  }

  Widget _tile(CorrectionSuggestion s) {
    final proposed =
        (jsonDecode(s.proposedData) as Map).cast<String, Object?>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.reason),
            const SizedBox(height: 6),
            for (final e in proposed.entries)
              Text('${fieldLabels[e.key] ?? e.key} → ${fieldValueText(e.value)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RecordDetailPage(
                            services: widget.services,
                            recordId: s.targetRecordId)),
                  ),
                  child: const Text('看记录'),
                ),
                const Spacer(),
                TextButton(
                    onPressed: () => _act(s, false), child: const Text('拒绝')),
                FilledButton.tonal(
                    onPressed: () => _act(s, true), child: const Text('接受')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
