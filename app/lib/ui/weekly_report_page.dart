import 'dart:convert';

import 'package:flutter/material.dart';

import 'markdown_text.dart';
import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/analysis_service.dart';
import 'record_detail_page.dart';

/// 周报页（A-17）：显示最新一份周报，事实陈述可点回来源记录。
/// 手机上可以生成，数据有更新时提示"需要更新"（D-14）；电脑端 [readOnly]
/// 只看手机同步过来的全文（电脑端首页只有 8 行预览，看不到后面的"下周建议"）。
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
  String? _autoError;

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
        _autoError = widget.services.analysisService.lastAutoError;
      });
    }
  }

  /// 生成近 7 天的周报。失败时旧周报保留（D-20）。
  Future<void> _generate() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.services.analysisService.generateWeeklyReview();
      messenger.showSnackBar(const SnackBar(content: Text('周报已生成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(
              '周报生成失败：${AnalysisService.failureReason(e)}（旧周报保留）')));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Widget _notice(String text) => Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('周报'), actions: [
        if (!widget.readOnly)
          TextButton(
            onPressed: _busy ? null : _generate,
            child: Text(_busy ? '生成中…' : '生成'),
          ),
      ]),
      body: report == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(widget.readOnly
                    ? '还没有周报。周报在手机上生成，同步过来后在这里查看。'
                    : _autoError != null
                        ? '上周周报自动生成失败：$_autoError\n\n'
                            '可以点右上角"生成"重试。'
                        : '还没有周报。点右上角"生成"，用默认模型总结近 7 天；'
                            '也可以在设置里打开"自动生成周报"。'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_autoError != null && !widget.readOnly)
                  _notice('上周周报自动生成失败：$_autoError。'
                      '下面是之前的周报，可以点右上角"生成"重试。'),
                if (_stale)
                  _notice('生成之后记录或健康数据有更新，这份周报可能过期，'
                      '可以点右上角"生成"重新生成。'),
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
