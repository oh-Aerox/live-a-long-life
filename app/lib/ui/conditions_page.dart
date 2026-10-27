import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/condition_entry.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/same_item.dart';
import '../data/time_value.dart';
import '../services/condition_category.dart';
import 'source_viewer_page.dart';

/// 长期状况档案（D-25，R-36）：长期状况全部列出，临时疾病单独一节。
/// 提取建议的状况带"未核对"标记，确认后才参与分析；复查进展追加
/// 新版本，既往诊断不改写（R-34）。不同年份报告里的同一问题各有一条
/// 记录，这里归成一行，按最新那份报告显示，既往写法列在下面（D-32）。
/// 按身体系统分组；已痊愈的、临时疾病收在下面；规则不敢自动合并的
/// 疑似重复提示用户确认，也可以手动合并（D-46）。
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

  /// 用户点过"不是同一个"的疑似重复（两组分组名的核心，排序后用 | 连接）。
  Set<String> _dismissed = {};
  static const _dismissedKey = 'condition_merge_dismissed';

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
    final dismissed =
        (await s.settings.get(_dismissedKey) as List?)?.cast<String>() ?? [];
    if (mounted) {
      setState(() {
        _entries = entries;
        _dismissed = dismissed.toSet();
      });
    }
  }

  static String _pairKey(List<ConditionEntry> a, List<ConditionEntry> b) =>
      ([SameItem.core(a.first.groupKey), SameItem.core(b.first.groupKey)]
            ..sort())
          .join('|');

  /// 疑似重复：同一节（长期/临时）、同一系统，两组里有名字可能说的是同一
  /// 问题，且用户没点过"不是"。
  List<(List<ConditionEntry>, List<ConditionEntry>)> _suspects(
      List<List<ConditionEntry>> groups) {
    final out = <(List<ConditionEntry>, List<ConditionEntry>)>[];
    for (var i = 0; i < groups.length; i++) {
      for (var j = i + 1; j < groups.length; j++) {
        final a = groups[i], b = groups[j];
        if (a.first.longTerm != b.first.longTerm) continue;
        if (conditionCategory(a.first.name) != conditionCategory(b.first.name)) {
          continue;
        }
        if (_dismissed.contains(_pairKey(a, b))) continue;
        if (a.any((x) => b.any((y) => SameItem.maybeSameProblem(x.name, y.name)))) {
          out.add((a, b));
        }
      }
    }
    return out;
  }

  /// 把 [source] 组并进 [target] 组：每条写一个新版本，记下合并到的名字
  /// （D-46）。核对状态不变；走变更日志同步到 Mac。
  Future<void> _merge(
      List<ConditionEntry> source, List<ConditionEntry> target) async {
    for (final e in source) {
      final data = Map<String, Object?>.from(e.data)
        ..['group_name'] = target.first.groupKey;
      await _writeRevision(e, data, reload: false);
    }
    await _load();
  }

  Future<void> _unmerge(List<ConditionEntry> group) async {
    for (final e in group) {
      if (e.mergedInto == null) continue;
      await _writeRevision(e, Map<String, Object?>.from(e.data)..remove('group_name'),
          reload: false);
    }
    await _load();
  }

  Future<void> _dismiss(List<ConditionEntry> a, List<ConditionEntry> b) async {
    final next = {..._dismissed, _pairKey(a, b)};
    await widget.services.settings.set(_dismissedKey, next.toList());
    setState(() => _dismissed = next);
  }

  Future<void> _reviewSuspects(List<List<ConditionEntry>> groups) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheet) {
        final pairs = _suspects(groups);
        if (pairs.isEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => Navigator.maybePop(context));
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('可能是同一问题',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('合并后显示为一行，按最新那份报告的写法；原记录都保留，可以取消合并。',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              for (final (a, b) in pairs)
                ListTile(
                  title: Text('${b.first.name}  ↔  ${a.first.name}'),
                  subtitle: Text(
                      '${b.first.date ?? ''} · ${a.first.date ?? ''}'),
                  trailing: Wrap(spacing: 4, children: [
                    TextButton(
                      onPressed: () async {
                        await _dismiss(a, b);
                        setSheet(() {});
                      },
                      child: const Text('不是'),
                    ),
                    FilledButton.tonal(
                      // 并进较新的那组，显示最新的写法。
                      onPressed: () async {
                        await _merge(b, a);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('合并'),
                    ),
                  ]),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// 手动合并：选同一节里的另一组，同一系统的排前面。
  Future<void> _pickMergeTarget(List<ConditionEntry> group) async {
    final category = conditionCategory(group.first.name);
    final candidates = [
      for (final g in ConditionEntry.groups(_entries))
        if (!identical(g.first, group.first) &&
            g.first.longTerm == group.first.longTerm)
          g
    ]..sort((a, b) {
        final ca = conditionCategory(a.first.name) == category ? 0 : 1;
        final cb = conditionCategory(b.first.name) == category ? 0 : 1;
        return ca != cb ? ca - cb : a.first.name.compareTo(b.first.name);
      });
    final target = await showDialog<List<ConditionEntry>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('把「${group.first.name}」合并到'),
        children: [
          for (final g in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, g),
              child: Text('${g.first.name}'
                  '（${conditionCategory(g.first.name)}）'),
            ),
        ],
      ),
    );
    if (target != null) await _merge(group, target);
  }

  Future<void> _writeRevision(ConditionEntry e, Map<String, Object?> data,
      {FieldMeta? conditionMeta, bool reload = true}) async {
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
    if (reload) await _load();
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
              ListTile(
                leading: const Icon(Icons.merge),
                title: const Text('与其他条目合并…'),
                onTap: () => Navigator.pop(context, 'merge'),
              ),
              if (group.any((c) => c.mergedInto != null))
                ListTile(
                  leading: const Icon(Icons.call_split),
                  title: const Text('取消合并'),
                  onTap: () => Navigator.pop(context, 'unmerge'),
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
      case 'merge':
        await _pickMergeTarget(group);
      case 'unmerge':
        await _unmerge(group);
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

  /// 按系统分组的一串条目：系统标题 + 组内按最新日期。
  List<Widget> _byCategory(List<List<ConditionEntry>> groups) {
    final byCat = <String, List<List<ConditionEntry>>>{};
    for (final g in groups) {
      (byCat[conditionCategory(g.first.name)] ??= []).add(g);
    }
    return [
      for (final cat in conditionCategories)
        if (byCat[cat] != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Text('$cat · ${byCat[cat]!.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          for (final g in byCat[cat]!) _tile(g),
        ],
    ];
  }

  Widget _section(String title, String hint, List<List<ConditionEntry>> groups,
          {required bool expanded}) =>
      ExpansionTile(
        initiallyExpanded: expanded,
        title: Text('$title（${groups.length}）'),
        subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
        children: _byCategory(groups),
      );

  @override
  Widget build(BuildContext context) {
    final groups = ConditionEntry.groups(_entries);
    final active =
        groups.where((g) => g.first.longTerm && !g.first.resolved).toList();
    final past =
        groups.where((g) => g.first.longTerm && g.first.resolved).toList();
    final temporary = groups.where((g) => !g.first.longTerm).toList()
      ..sort((a, b) =>
          (a.first.resolved ? 1 : 0).compareTo(b.first.resolved ? 1 : 0));
    final suspects = widget.readOnly ? const [] : _suspects(groups);

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
                if (suspects.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: ListTile(
                      leading: const Icon(Icons.merge),
                      title: Text('有 ${suspects.length} 组可能是同一问题'),
                      subtitle: const Text('确认后合并成一行'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _reviewSuspects(groups),
                    ),
                  ),
                if (active.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text('长期状况（参与分析）',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._byCategory(active),
                ],
                if (past.isNotEmpty)
                  _section('既往病史', '已痊愈或已解除，只作背景参考', past,
                      expanded: false),
                if (temporary.isNotEmpty)
                  _section('临时疾病', '只影响近期建议；已痊愈的不再参与', temporary,
                      expanded: temporary.any((g) => !g.first.resolved)),
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
