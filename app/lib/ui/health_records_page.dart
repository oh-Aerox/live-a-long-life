import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/health_overview.dart';
import 'adaptive.dart';
import 'body_map_page.dart';
import 'conditions_page.dart';
import 'lab_trends_page.dart';
import 'medical_folder_page.dart';
import 'suggestions_page.dart';
import 'visit_timeline_page.dart';
import 'weekly_report_page.dart';

/// 健康档案（首页底栏入口）：病例夹、体检、长期状况、时间线、人体图、
/// 指标趋势、周报、修正建议集中在这一页，每个入口旁边是待办和数量。
/// 原来是一个操作菜单，趋势、时间线藏在第二层；周报、修正建议只在设置里。
class HealthRecordsPage extends StatefulWidget {
  const HealthRecordsPage({super.key, required this.services});

  final AppServices services;

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  HealthOverview? _overview;
  int _suggestions = 0;
  AnalysisArtifact? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final overview = await HealthOverview.load(
        records: s.records, documents: s.medicalDocuments, profile: s.profile);
    final suggestions = (await s.suggestionService.pending()).length;
    final report = await s.analysisService.latest(AnalysisKind.weeklyReview);
    if (mounted) {
      setState(() {
        _overview = overview;
        _suggestions = suggestions;
        _report = report;
      });
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _load();
  }

  /// "3 份待核对 · 1 份未提取"，都没有时用 [fallback]。
  static String _docStatus(int pending, int unextracted, String fallback) {
    final parts = [
      if (pending > 0) '$pending 份待核对',
      if (unextracted > 0) '$unextracted 份未提取',
    ];
    return parts.isEmpty ? fallback : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cupertino = useCupertino(context);
    final o = _overview;
    final s = widget.services;
    Widget? count(int n) => n == 0 ? null : _CountBadge(n);

    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      Widget? badge,
      required Widget Function() page,
    }) =>
        AdaptiveTile(
          title: Row(children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Flexible(child: Text(title)),
          ]),
          subtitle: Text(subtitle),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            ?badge,
            const SizedBox(width: 4),
            cupertino
                ? const CupertinoListTileChevron()
                : const Icon(Icons.chevron_right),
          ]),
          onTap: () => _open(page()),
        );

    return Scaffold(
      backgroundColor: cupertino
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : null,
      appBar: adaptiveAppBar(context, title: const Text('健康档案')),
      body: o == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(children: [
              AdaptiveSection(header: '病历与体检', children: [
                tile(
                  icon: Icons.folder_shared_outlined,
                  title: '我的病例夹',
                  subtitle: _docStatus(o.pendingRecordDocs,
                      o.unextractedRecordDocs, '病历、检查检验报告、处方'),
                  badge: count(o.pendingRecordDocs + o.unextractedRecordDocs),
                  page: () =>
                      MedicalFolderPage(services: s, physicalExam: false),
                ),
                tile(
                  icon: Icons.monitor_heart_outlined,
                  title: '我的体检',
                  subtitle: [
                    if (o.lastExamDate != null) '最近一次 ${o.lastExamDate}',
                    _docStatus(o.pendingExamDocs, o.unextractedExamDocs,
                        o.lastExamDate == null ? '体检报告' : ''),
                  ].where((t) => t.isNotEmpty).join(' · '),
                  badge: count(o.pendingExamDocs + o.unextractedExamDocs),
                  page: () =>
                      MedicalFolderPage(services: s, physicalExam: true),
                ),
                tile(
                  icon: Icons.medical_services_outlined,
                  title: '长期状况档案',
                  subtitle: o.pendingConditions > 0
                      ? '${o.pendingConditions} 条待核对'
                      : '结石、过敏等长期状况与近期疾病',
                  badge: count(o.pendingConditions),
                  page: () => ConditionsPage(services: s),
                ),
                tile(
                  icon: Icons.timeline_outlined,
                  title: '就诊时间线',
                  subtitle: '症状、就诊、检查按时间排列',
                  page: () => VisitTimelinePage(services: s),
                ),
              ]),
              AdaptiveSection(header: '指标与分析', children: [
                tile(
                  icon: Icons.accessibility_new,
                  title: '人体图',
                  subtitle: o.attention > 0
                      ? '${o.attention} 项需要关注'
                      : '按身体部位看异常与状况',
                  page: () => BodyMapPage(services: s),
                ),
                tile(
                  icon: Icons.show_chart,
                  title: '指标趋势',
                  subtitle: o.labItems > 0
                      ? '${o.labItems} 项检验指标的历史变化'
                      : '每项检验指标的历史变化',
                  page: () => LabTrendsPage(services: s),
                ),
                tile(
                  icon: Icons.summarize_outlined,
                  title: '周报',
                  subtitle: _report == null
                      ? '每周的总结和下周建议，事实可点回来源'
                      : '最近一份 ${_report!.periodStart} 至 ${_report!.periodEnd}',
                  page: () => WeeklyReportPage(services: s),
                ),
                tile(
                  icon: Icons.rule_outlined,
                  title: '修正建议',
                  subtitle: _suggestions > 0
                      ? '$_suggestions 条待处理'
                      : '整理与已核对内容冲突时，在这里确认',
                  badge: count(_suggestions),
                  page: () => SuggestionsPage(services: s),
                ),
              ]),
            ]),
    );
  }
}

/// 入口右侧的数量角标。
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => Badge(
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: Colors.orange,
      );
}
