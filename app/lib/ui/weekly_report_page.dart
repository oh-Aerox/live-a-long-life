import 'dart:convert';

import 'package:flutter/material.dart';

import 'markdown_text.dart';
import '../app_services.dart';
import '../data/db/app_database.dart';
import 'record_detail_page.dart';

/// 周报页（V3-M5，A-17）：显示 Mac 生成的周报，
/// 数据有更新时提示"需要更新"（D-14），事实陈述可点回来源记录。
/// 手机从 Mac 拉取；Mac 端 [readOnly] 直接看本机生成的全文（2026-09-29 联调：
/// Mac 首页只有 8 行预览，看不到后面的"下周建议"）。
class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage(
      {super.key, required this.services, this.readOnly = false});

  final AppServices services;
  final bool readOnly;

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  AnalysisArtifact? _report;
  bool _stale = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final report =
        await widget.services.analysisService.latest(AnalysisKind.weeklyReview);
    final stale = report == null
        ? false
        : await widget.services.analysisService.isStale(report);
    if (mounted) {
      setState(() {
        _report = report;
        _stale = stale;
      });
    }
  }

  Future<void> _fetch() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final row = await widget.services.syncService.fetchLatestAnalysis();
    if (row != null) {
      await widget.services.analysisService.saveFetched(row);
      messenger.showSnackBar(const SnackBar(content: Text('已获取最新周报')));
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('没取到：确认 Mac 上的长寿记开着，且已生成周报')));
    }
    if (mounted) setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('周报'), actions: [
        if (!widget.readOnly)
          TextButton(
            onPressed: _busy ? null : _fetch,
            child: Text(_busy ? '获取中…' : '从 Mac 获取'),
          ),
      ]),
      body: report == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('还没有周报。在 Mac 上生成后，点右上角"从 Mac 获取"。'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_stale)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('生成之后数据有更新，这份周报可能过期：'
                        '同步后在 Mac 上重新生成（D-14）'),
                  ),
                Text('${report.periodStart} 至 ${report.periodEnd}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                MarkdownText(report.contentMd),
                const Divider(height: 32),
                Text('来源（点开查看记录）',
                    style: Theme.of(context).textTheme.titleSmall),
                ..._citationTiles(report),
              ],
            ),
    );
  }

  List<Widget> _citationTiles(AnalysisArtifact report) {
    List<dynamic> citations;
    try {
      citations = jsonDecode(report.citations) as List;
    } catch (_) {
      return const [Text('（没有来源信息）')];
    }
    return [
      for (final c in citations.whereType<Map>())
        ListTile(
          dense: true,
          leading: Text('${c['claim_id'] ?? ''}'),
          title: Text('依据 ${(c['record_revision_ids'] as List?)?.length ?? 0} 条记录'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _openFirstRecord(
              ((c['record_revision_ids'] as List?) ?? const []).cast<String>()),
        ),
    ];
  }

  Future<void> _openFirstRecord(List<String> revisionIds) async {
    if (revisionIds.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final db = widget.services.db;
    final rev = await (db.select(db.recordRevisions)
          ..where((t) => t.id.isIn(revisionIds))
          ..limit(1))
        .getSingleOrNull();
    if (rev == null || !mounted) {
      messenger
          .showSnackBar(const SnackBar(content: Text('本机没有对应的记录')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RecordDetailPage(
              services: widget.services,
              recordId: rev.recordId,
              readOnly: widget.readOnly)),
    );
  }
}
