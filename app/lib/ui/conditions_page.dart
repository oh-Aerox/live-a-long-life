import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/condition_entry.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/time_value.dart';
import 'source_viewer_page.dart';

/// 长期状况档案（D-25，R-36）：长期状况全部列出，临时疾病单独一节。
/// 提取建议的状况带"未核对"标记，确认后才参与分析；复查进展追加
/// 新版本，既往诊断不改写（R-34）。不同年份报告里的同一问题各有一条
/// 记录，这里归成一行，按最新那份报告显示，既往写法列在下面（D-32）。
class ConditionsPage extends StatefulWidget {
  const ConditionsPage(
      {super.key, required this.services, this.readOnly = false});

  final AppServices services;
  final bool readOnly;

  @override
  State<ConditionsPage> createState() => _ConditionsPageState();
}

class _ConditionsPageState extends State<ConditionsPage> {
  List<ConditionEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final recs = await s.records.byType(RecordType.condition);
    final entries = <ConditionEntry>[];
    for (final rec in recs) {
      final rev = await s.records.currentRevisionOf(rec.id);
      entries.add(ConditionEntry(
        rec,
        rev,
        (jsonDecode(rev.data) as Map).cast<String, Object?>(),
        FieldMetaMap.decode(rev.fieldMeta),
      ));
    }
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _writeRevision(ConditionEntry e, Map<String, Object?> data,
      {FieldMeta? conditionMeta}) async {
    final fields = Map<String, FieldMeta>.from(e.meta.fields);
    if (conditionMeta != null) fields['condition'] = conditionMeta;
    await widget.services.records.addRevision(
      recordId: e.record.id,
      baseVersion: e.record.version,
      occurred: TimeValue.decode(e.rev.occurred),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap(fields),
      producedBy: ProducedBy.userEdit(),
    );
    await _load();
  }

  Future<void> _confirm(ConditionEntry e) => _writeRevision(e, e.data,
      conditionMeta: FieldMeta(
          origin: e.meta['condition']?.origin ?? FieldOrigin.modelInferred,
          reviewStatus: ReviewStatus.confirmed));

  Future<void> _addDevelopment(ConditionEntry e) async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「${e.name}」复查进展'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: '比如：复查 B 超，结石大小无变化'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (ok != true || ctl.text.trim().isEmpty) return;
    final t = DateTime.now();
    final data = Map<String, Object?>.from(e.data);
    data['development_text'] = ctl.text.trim();
    data['last_checked_date'] =
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    await _writeRevision(e, data,
        conditionMeta: const FieldMeta(
            origin: FieldOrigin.userEdited,
            reviewStatus: ReviewStatus.edited));
  }

  Future<void> _toggleResolved(ConditionEntry e) async {
    final data = Map<String, Object?>.from(e.data);
    data['status'] = e.resolved ? 'active' : 'resolved';
    await _writeRevision(e, data,
        conditionMeta: const FieldMeta(
            origin: FieldOrigin.userEdited,
            reviewStatus: ReviewStatus.edited));
  }

  Future<void> _viewSource(ConditionEntry e) async {
    final locator = e.data['locator'];
    if (locator is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('这条状况没有原件定位信息')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SourceViewerPage(
          services: widget.services,
          locator: locator.cast<String, Object?>(),
          title: e.name,
        ),
      ),
    );
  }

  /// 组里比最新那条早的报告（同一天的重复不算）。
  static List<ConditionEntry> _earlier(List<ConditionEntry> group) => [
        for (final c in group.skip(1))
          if (c.date != group.first.date) c,
      ];

  Future<void> _actions(List<ConditionEntry> group) async {
    final e = group.first;
    final earlier = [
      for (final c in _earlier(group))
        if (c.data['locator'] != null) c,
    ];
    // 只读（Mac，D-12）：不确认、不追加、不标痊愈，有原件位置就直接看。
    if (widget.readOnly && e.data['locator'] == null && earlier.isEmpty) {
      return;
    }
    final action = widget.readOnly && earlier.isEmpty
        ? 'source'
        : await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!widget.readOnly && !e.reviewed)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('确认（确认后参与分析）'),
                onTap: () => Navigator.pop(context, 'confirm'),
              ),
            if (!widget.readOnly) ...[
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('添加复查进展'),
                onTap: () => Navigator.pop(context, 'develop'),
              ),
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(e.resolved ? '恢复为进行中' : '标记已痊愈/解除'),
                onTap: () => Navigator.pop(context, 'resolve'),
              ),
            ],
            if (e.data['locator'] != null)
              ListTile(
                leading: const Icon(Icons.image_search_outlined),
                title: Text(earlier.isEmpty
                    ? '查看原件位置'
                    : '查看原件位置（${e.date ?? '最新'}）'),
                onTap: () => Navigator.pop(context, 'source'),
              ),
            for (var i = 0; i < earlier.length; i++)
              ListTile(
                leading: const Icon(Icons.history),
                title: Text('查看 ${earlier[i].date ?? ''} 的原件'),
                subtitle: Text(earlier[i].name),
                onTap: () => Navigator.pop(context, 'earlier:$i'),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'confirm':
        await _confirm(e);
      case 'develop':
        await _addDevelopment(e);
      case 'resolve':
        await _toggleResolved(e);
      case 'source':
        await _viewSource(e);
      case final String a when a.startsWith('earlier:'):
        await _viewSource(earlier[int.parse(a.substring(8))]);
    }
  }

  /// 手动添加（user_stated：用户亲述直接算已修改，D-04）。
  Future<void> _addManually() async {
    final nameCtl = TextEditingController();
    var longTerm = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加身体状况'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtl,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: '名称', hintText: '比如 胆囊结石、青霉素过敏')),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('长期状况')),
                  ButtonSegment(value: false, label: Text('临时疾病')),
                ],
                selected: {longTerm},
                onSelectionChanged: (s) =>
                    setDialogState(() => longTerm = s.single),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存')),
          ],
        ),
      ),
    );
    if (ok != true || nameCtl.text.trim().isEmpty) return;
    final t = DateTime.now();
    await widget.services.records.create(
      recordType: RecordType.condition,
      occurred: TimeValue(
        localDate:
            '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}',
        precision: TimePrecision.dateOnly,
        source: TimeValueSource.userStated,
      ),
      dataJson: jsonEncode({
        'name': nameCtl.text.trim(),
        'persistence': longTerm ? 'long_term' : 'temporary',
        'status': 'active',
        'source_kind': 'user_stated',
        'evidence_text': null,
        'development_text': null,
        'last_checked_date': null,
        'medical_document_id': null,
        'locator': null,
      }),
      fieldMeta: FieldMetaMap({
        'condition': const FieldMeta(
            origin: FieldOrigin.userStated,
            reviewStatus: ReviewStatus.edited),
      }),
      producedBy: ProducedBy.userEdit(),
    );
    await _load();
  }

  Widget _tile(List<ConditionEntry> group) {
    final e = group.first;
    final earlier = _earlier(group);
    final subtitle = [
      if (group.last.date != null) '发现于 ${group.last.date}',
      if (earlier.isNotEmpty && e.date != null) '最近报告 ${e.date}',
      if (e.data['last_checked_date'] != null)
        '复查 ${e.data['last_checked_date']}',
      if (e.data['development_text'] != null)
        '${e.data['development_text']}',
      if (earlier.isNotEmpty)
        '此前：${[for (final c in earlier) '${c.date ?? ''} ${c.name}'].join('；')}',
    ].join(' · ');
    return ListTile(
      dense: true,
      title: Text(
        e.name,
        style: e.resolved
            ? const TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 3),
      trailing: Text(
        e.resolved ? '已解除' : (e.reviewed ? '已确认' : '未核对'),
        style: TextStyle(
          fontSize: 11,
          color: e.resolved
              ? Colors.grey
              : (e.reviewed ? Colors.green : Colors.orange),
        ),
      ),
      onTap: () => _actions(group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ConditionEntry.groups(_entries);
    final longTerm = groups.where((g) => g.first.longTerm).toList()
      ..sort((a, b) =>
          (a.first.resolved ? 1 : 0).compareTo(b.first.resolved ? 1 : 0));
    final temporary = groups.where((g) => !g.first.longTerm).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('长期状况档案')),
      body: _entries.isEmpty
          ? const Center(
              child: Text(
                '还没有记录的身体状况\n提取检查报告时会自动建议，也可以手动添加',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              children: [
                if (longTerm.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('长期状况（参与分析；已痊愈的只作既往病史参考）'),
                  ),
                  for (final e in longTerm) _tile(e),
                ],
                if (temporary.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('临时疾病（只影响近期建议；已痊愈的不再参与）'),
                  ),
                  for (final e in temporary) _tile(e),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '康复、复查都以追加方式记录，既往诊断和当时的指标不会被改写。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
        onPressed: _addManually,
        tooltip: '添加状况',
        child: const Icon(Icons.add),
      ),
    );
  }
}
