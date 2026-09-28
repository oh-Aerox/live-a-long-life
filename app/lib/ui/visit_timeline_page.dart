import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/time_value.dart';
import 'medical_document_page.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;
import 'record_detail_page.dart';

/// 就诊时间线（v0.4）：症状起始、身体状况（诊断/发现）、检查报告
/// 按日期倒序排成一条线。康复复查是追加的新事件，既往不改写（R-34）。
class VisitTimelinePage extends StatefulWidget {
  const VisitTimelinePage({super.key, required this.services});

  final AppServices services;

  @override
  State<VisitTimelinePage> createState() => _VisitTimelinePageState();
}

class _TimelineEvent {
  _TimelineEvent({
    required this.date,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.recordId,
    this.documentId,
  });

  final String date; // yyyy-MM-dd，未知排最后
  final IconData icon;
  final String title;
  final String subtitle;
  final String? recordId;
  final String? documentId;
}

class _VisitTimelinePageState extends State<VisitTimelinePage> {
  List<_TimelineEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final events = <_TimelineEvent>[];

    // 症状（起始事件）。
    for (final rec in await s.records.byType(RecordType.symptom)) {
      final rev = await s.records.currentRevisionOf(rec.id);
      final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
      if (data['status'] == 'explicitly_none') continue;
      events.add(_TimelineEvent(
        date: rec.localDate ?? '',
        icon: Icons.healing_outlined,
        title: [data['body_site'], data['description']]
            .whereType<Object>()
            .join('：')
            .replaceAll(RegExp(r'^：'), ''),
        subtitle: '症状',
        recordId: rec.id,
      ));
    }

    // 身体状况（诊断/发现，含复查更新）。
    for (final rec in await s.records.byType(RecordType.condition)) {
      final rev = await s.records.currentRevisionOf(rec.id);
      final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
      events.add(_TimelineEvent(
        date: rec.localDate ?? '',
        icon: Icons.medical_services_outlined,
        title: data['name'] as String? ?? '身体状况',
        subtitle: [
          data['persistence'] == 'long_term' ? '长期状况' : '临时疾病',
          if (data['status'] == 'resolved') '已解除',
          if (data['last_checked_date'] != null)
            '最近复查 ${data['last_checked_date']}',
        ].join(' · '),
        recordId: rec.id,
      ));
    }

    // 医疗文件（按检查日期，缺了用上传日期）。
    for (final doc in await s.medicalDocuments.all()) {
      String date = '';
      if (doc.examDate != null) {
        date = TimeValue.decode(doc.examDate!).localDate ?? '';
      }
      if (date.isEmpty) {
        final t =
            DateTime.fromMillisecondsSinceEpoch(doc.uploadedAt, isUtc: true)
                .toLocal();
        date =
            '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      }
      events.add(_TimelineEvent(
        date: date,
        icon: Icons.description_outlined,
        title: medicalDocTypeLabels[doc.docType]!,
        subtitle: doc.institutionText ?? '检查/就诊资料',
        documentId: doc.id,
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    String? lastDate;
    final children = <Widget>[];
    for (final e in _events) {
      if (e.date != lastDate) {
        lastDate = e.date;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(e.date.isEmpty ? '日期未知' : e.date,
              style: Theme.of(context).textTheme.labelLarge),
        ));
      }
      children.add(ListTile(
        dense: true,
        leading: Icon(e.icon, size: 20),
        title: Text(e.title),
        subtitle: Text(e.subtitle),
        onTap: () {
          if (e.documentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalDocumentPage(
                    services: widget.services, documentId: e.documentId!),
              ),
            ).then((_) => _load());
          } else if (e.recordId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecordDetailPage(
                    services: widget.services, recordId: e.recordId!),
              ),
            ).then((_) => _load());
          }
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('就诊时间线')),
      body: _events.isEmpty
          ? const Center(
              child: Text(
                '还没有就诊相关的记录\n症状、诊断和检查报告会按时间排在这里',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(children: children),
    );
  }
}
