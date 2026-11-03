import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/field_meta.dart';
import '../data/same_item.dart';
import 'adaptive.dart';

/// 整理检验项目名称（D-49）：待确认的标准名建议逐条确认；可以让模型把
/// 规则和目录都认不出的现有项目名对号入座；已定的标准名可以撤销。
/// 只在手机上（Mac 只读，D-12）。
class LabNamesPage extends StatefulWidget {
  const LabNamesPage({super.key, required this.services});

  final AppServices services;

  @override
  State<LabNamesPage> createState() => _LabNamesPageState();
}

class _LabNamesPageState extends State<LabNamesPage> {
  /// 用户点过"不合并"的建议（现在的键|建议名），本机设置，不再提示。
  static const dismissedKey = 'lab_name_dismissed';

  Map<(String, String), int> _pending = {};

  /// 已定的标准名：（自动归类的键, 标准名）→ 次数。
  Map<(String, String), int> _decided = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = widget.services.records;
    final pending = await records.labStdSuggestions();
    final decided = <(String, String), int>{};
    for (final r in await records.labResultRows()) {
      if (r.itemStd == null) continue;
      final pair = (SameItem.labKey(r.itemNameRaw, panel: r.panelRaw), r.itemStd!);
      if (pair.$1 == pair.$2) continue;
      decided[pair] = (decided[pair] ?? 0) + 1;
    }
    if (mounted) {
      setState(() {
        _pending = pending;
        _decided = decided;
      });
    }
  }

  Future<Set<String>> _dismissed() async =>
      {...(await widget.services.settings.get(dismissedKey) as List? ?? const [])
          .cast<String>()};

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('没有完成：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _accept(String from, String to) => _run(() async {
        await widget.services.records.updateLabResults((r) {
          if (r['item_std_suggested'] != to || SameItem.resultKey(r) != from) {
            return false;
          }
          r
            ..remove('item_std_suggested')
            ..['item_std'] = to;
          return true;
        }, producedBy: ProducedBy.userEdit());
      });

  Future<void> _reject(String from, String to) => _run(() async {
        await widget.services.settings
            .set(dismissedKey, [...await _dismissed(), '$from|$to']);
        await widget.services.records.updateLabResults((r) {
          if (r['item_std_suggested'] != to || SameItem.resultKey(r) != from) {
            return false;
          }
          r.remove('item_std_suggested');
          return true;
        }, producedBy: ProducedBy.userEdit());
      });

  Future<void> _undo(String auto, String std) => _run(() async {
        await widget.services.records.updateLabResults((r) {
          if (r['item_std'] != std ||
              SameItem.labKey('${r['item_name_raw']}',
                      panel: r['panel_raw'] as String?) !=
                  auto) {
            return false;
          }
          r.remove('item_std');
          return true;
        }, producedBy: ProducedBy.userEdit());
      });

  Future<void> _propose() async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('用模型整理项目名称'),
        content: const Text(
            '把内置目录认不出的项目名称，连同报告上的写法、所在分组和单位发给模型，'
            '让它对到标准名或已有项目上。不发数值、日期和报告内容。\n\n'
            '模型的建议列在"待确认"里，你确认后才合并。'),
        actions: [
          DialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          DialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('发送')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final n = await widget.services.medicalExtraction
          .proposeLabNames(dismissed: await _dismissed());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(n == 0 ? '模型没有找到需要合并或改名的项目' : '有 $n 条建议待确认')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary)),
        );
    return Scaffold(
      appBar: adaptiveAppBar(context, title: const Text('整理项目名称')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '同一指标在不同报告里的写法（缩写、旧称、错别字）会归成一项，'
              '按标准中文名显示。常见项目由内置目录自动归类；提取报告时模型也会'
              '对号入座，不确定的放在这里等你确认。原报告的写法都保留。',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.tonal(
              onPressed: _busy ? null : _propose,
              child: Text(_busy ? '处理中…' : '用模型整理现有项目名称'),
            ),
          ),
          header('待确认'),
          if (_pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('没有待确认的建议', style: TextStyle(color: secondary)),
            ),
          for (final MapEntry(key: (from, to), value: n) in _pending.entries)
            ListTile(
              title: Text('$from → $to'),
              subtitle: Text('$n 次结果'),
              trailing: Wrap(spacing: 4, children: [
                TextButton(
                    onPressed: _busy ? null : () => _reject(from, to),
                    child: const Text('不合并')),
                TextButton(
                    onPressed: _busy ? null : () => _accept(from, to),
                    child: const Text('合并')),
              ]),
            ),
          header('已定的标准名'),
          if (_decided.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('还没有', style: TextStyle(color: secondary)),
            ),
          for (final MapEntry(key: (auto, std), value: n) in _decided.entries)
            ListTile(
              title: Text('$auto → $std'),
              subtitle: Text('$n 次结果'),
              trailing: TextButton(
                  onPressed: _busy ? null : () => _undo(auto, std),
                  child: const Text('撤销')),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
