import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/time_value.dart';
import '../services/lab_review.dart';
import '../services/medical_extraction_service.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;
import 'medical_send_preview_page.dart';
import 'source_viewer_page.dart';

/// 医疗文件详情（V4-M2）：文件信息、提取（先本地识别预览、确认后发送，
/// D-28）、检验数值与文字内容逐项核对（D-04）、定位回原件（A-19）。
class MedicalDocumentPage extends StatefulWidget {
  const MedicalDocumentPage(
      {super.key, required this.services, required this.documentId});

  final AppServices services;
  final String documentId;

  @override
  State<MedicalDocumentPage> createState() => _MedicalDocumentPageState();
}

class _MedicalDocumentPageState extends State<MedicalDocumentPage> {
  MedicalDocument? _doc;
  List<LabResult> _results = [];
  RecordRow? _record;
  RecordRevision? _rev;
  /// 逐条核对的列表（D-28）：findings 文字内容、medications 处方药品。
  Map<String, List<Map<String, Object?>>> _entries = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final doc = await s.medicalDocuments.byId(widget.documentId);
    // 按记录查而不是走检验索引：只有文字的报告索引里没有行（D-28）。
    final record = await s.records.labPanelOfDocument(widget.documentId);
    RecordRevision? rev;
    var results = <LabResult>[];
    final entries = <String, List<Map<String, Object?>>>{};
    if (record != null) {
      rev = await s.records.currentRevisionOf(record.id);
      results = [
        for (final r in await s.records.labResultsOfDocument(widget.documentId))
          if (r.recordId == record.id) r
      ];
      final data = jsonDecode(rev.data) as Map;
      for (final list in LabReview.entryLists) {
        entries[list] = [
          for (final e in data[list] as List? ?? const [])
            (e as Map).cast<String, Object?>()
        ];
      }
    }
    if (mounted) {
      setState(() {
        _doc = doc;
        _results = results;
        _entries = entries;
        _record = record;
        _rev = rev;
      });
    }
  }

  /// 提取两步走（D-28）：预览页本地识别、展示将要发送的文字并可修改，
  /// 用户确认后才发给模型；从预览页返回则什么都不发。
  Future<void> _extract() async {
    final outcome = await Navigator.push<MedicalExtractOutcome>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalSendPreviewPage(
            services: widget.services, documentId: widget.documentId),
      ),
    );
    if (outcome == null || !mounted) return;
    try {
      final skipped = outcome.pageDecisions.where((d) => !d.included).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('提取完成，已遮蔽 ${outcome.redactedCount} 处隐私信息'
            '${skipped > 0 ? '，$skipped 页未发送' : ''}'
            '${outcome.conditionRecords.isNotEmpty ? '，发现 ${outcome.conditionRecords.length} 条身体状况建议（在长期状况档案里核对）' : ''}。'
            '结果未核对，确认后才参与分析'),
      ));
      if (outcome.possibleDuplicateRecordIds.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('可能重复'),
            content: Text('同一检查日期已有 '
                '${outcome.possibleDuplicateRecordIds.length} 条包含相同项目的'
                '检验记录（可能是同一份报告拍了两次）。两份都会保留，'
                '核对时注意别重复确认。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('知道了')),
            ],
          ),
        );
      }
    } finally {
      await _load();
    }
  }

  /// 写一版新记录（核对/修改都走这里，索引随版本自动重建 D-27）。
  Future<void> _writeRevision(String dataJson, FieldMetaMap meta) async {
    final record = _record!;
    final rev = _rev!;
    await widget.services.records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: TimeValue.decode(rev.occurred),
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: dataJson,
      fieldMeta: meta,
      producedBy: ProducedBy.userEdit(),
    );
    await _load();
  }

  Future<void> _confirmResult(int index) async {
    final rev = _rev!;
    final (data, meta) = LabReview.confirmResult(
        rev.data, FieldMetaMap.decode(rev.fieldMeta), index);
    await _writeRevision(data, meta);
  }

  Future<void> _confirmAll() async {
    final rev = _rev!;
    final (data, meta) =
        LabReview.confirmAll(rev.data, FieldMetaMap.decode(rev.fieldMeta));
    await _writeRevision(data, meta);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已全部确认，这份报告的数据开始参与分析')));
    }
  }

  Future<void> _editResult(int index, LabResult row) async {
    final nameCtl = TextEditingController(text: row.itemNameRaw);
    final valueCtl = TextEditingController(text: row.valueRaw);
    final unitCtl = TextEditingController(text: row.unitRaw ?? '');
    final refCtl = TextEditingController(text: row.refRangeRaw ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改这一项'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: '项目')),
            TextField(
                controller: valueCtl,
                decoration: const InputDecoration(labelText: '数值')),
            TextField(
                controller: unitCtl,
                decoration: const InputDecoration(labelText: '单位')),
            TextField(
                controller: refCtl,
                decoration: const InputDecoration(labelText: '参考范围')),
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
    );
    if (ok != true) return;
    final rev = _rev!;
    final (data, meta) = LabReview.editResult(
      rev.data,
      FieldMetaMap.decode(rev.fieldMeta),
      index,
      itemNameRaw: nameCtl.text.trim(),
      valueRaw: valueCtl.text.trim(),
      unitRaw: unitCtl.text.trim(),
      refRangeRaw: refCtl.text.trim(),
    );
    await _writeRevision(data, meta);
  }

  /// 定位回原件（A-19）：取该项 locator 的第一处。
  Future<void> _viewSource(int index, LabResult row) async {
    final rev = _rev;
    if (rev == null) return;
    final data = jsonDecode(rev.data) as Map;
    final results = data['results'] as List;
    if (index >= results.length) return;
    final locators = (results[index] as Map)['locator'] as List? ?? const [];
    if (locators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('这一项没有原件定位信息')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SourceViewerPage(
          services: widget.services,
          locator: (locators.first as Map).cast<String, Object?>(),
          title: row.itemNameRaw,
        ),
      ),
    );
  }

  Future<void> _resultActions(int index, LabResult row) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('确认无误'),
              onTap: () => Navigator.pop(context, 'confirm'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('修改'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.image_search_outlined),
              title: const Text('查看原件位置'),
              onTap: () => Navigator.pop(context, 'source'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'confirm':
        await _confirmResult(index);
      case 'edit':
        await _editResult(index, row);
      case 'source':
        await _viewSource(index, row);
    }
  }

  /// 各列表修改对话框里的字段（键 → 标签）。
  static const _entryFields = {
    'findings': {'section_raw': '栏目', 'text_raw': '内容'},
    'medications': {
      'name': '药品',
      'spec': '规格',
      'dose': '单次用量',
      'route': '用法',
      'frequency': '频次',
      'duration': '疗程',
      'quantity': '数量',
    },
  };

  List<Map<String, Object?>> _entryList(String list) => _entries[list] ?? const [];

  ReviewStatus _entryStatus(String list, int index) =>
      FieldMetaMap.decode(_rev!.fieldMeta)['$list.$index']?.reviewStatus ??
      ReviewStatus.unreviewed;

  Future<void> _entryActions(String list, int index) async {
    final entry = _entryList(list)[index];
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('确认无误'),
              onTap: () => Navigator.pop(context, 'confirm'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('修改'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.image_search_outlined),
              title: const Text('查看原件位置'),
              onTap: () => Navigator.pop(context, 'source'),
            ),
          ],
        ),
      ),
    );
    final rev = _rev;
    if (action == null || rev == null || !mounted) return;
    switch (action) {
      case 'confirm':
        final (data, meta) = LabReview.confirmEntry(
            rev.data, FieldMetaMap.decode(rev.fieldMeta), list, index);
        await _writeRevision(data, meta);
      case 'edit':
        final labels = _entryFields[list]!;
        final ctls = {
          for (final k in labels.keys)
            k: TextEditingController(text: entry[k] as String? ?? ''),
        };
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('修改'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in labels.entries)
                    TextField(
                        controller: ctls[e.key],
                        maxLines: null,
                        decoration: InputDecoration(labelText: e.value)),
                ],
              ),
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
        // 主字段（文字内容 / 药品名）不能改空。
        final mainKey = list == 'findings' ? 'text_raw' : 'name';
        if (ok != true || ctls[mainKey]!.text.trim().isEmpty || !mounted) {
          return;
        }
        final (data, meta) = LabReview.editEntry(
          rev.data,
          FieldMetaMap.decode(rev.fieldMeta),
          list,
          index,
          {for (final e in ctls.entries) e.key: e.value.text.trim()},
        );
        await _writeRevision(data, meta);
      case 'source':
        final locators = entry['locator'] as List? ?? const [];
        if (locators.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('这一条没有原件定位信息')));
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SourceViewerPage(
              services: widget.services,
              locator: (locators.first as Map).cast<String, Object?>(),
              title: (entry['section_raw'] ?? entry['name'] ?? '原件') as String,
            ),
          ),
        );
    }
  }

  static Widget _statusText(ReviewStatus status, {bool warn = false}) => Text(
        switch (status) {
          ReviewStatus.unreviewed => '未核对',
          ReviewStatus.confirmed => '已确认',
          ReviewStatus.edited => '已修改',
        },
        style: TextStyle(
          fontSize: 11,
          color: warn
              ? Colors.orange
              : (status == ReviewStatus.unreviewed ? Colors.grey : Colors.green),
        ),
      );

  /// 模型对识别错误的修正，核对时对照原件看（D-28）。
  static Widget? _fixesText(Object? fixes) {
    final list = [
      for (final f in fixes as List? ?? const [])
        if (f is String) f
    ];
    if (list.isEmpty) return null;
    return Text('已修正识别错误：${list.join('；')}',
        style: const TextStyle(fontSize: 11, color: Colors.orange));
  }

  /// 检验数值的修正记录不进索引表，从记录数据取。
  Object? _resultFixes(int index) {
    final results = (jsonDecode(_rev!.data) as Map)['results'] as List?;
    if (results == null || index >= results.length) return null;
    return (results[index] as Map)['ocr_fixes'];
  }

  List<Widget> _entrySection(String list, String title) {
    final entries = _entryList(list);
    if (entries.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (var i = 0; i < entries.length; i++)
        ListTile(
          dense: true,
          title: Text(list == 'findings'
              ? (entries[i]['section_raw'] as String? ?? '文字内容')
              : entries[i]['name'] as String),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list == 'findings'
                  ? entries[i]['text_raw'] as String
                  : [
                      for (final k in const [
                        'dose',
                        'route',
                        'frequency',
                        'duration',
                        'spec',
                        'quantity'
                      ])
                        if (entries[i][k] is String) entries[i][k] as String
                    ].join('  ')),
              ?_fixesText(entries[i]['ocr_fixes']),
            ],
          ),
          trailing: _statusText(_entryStatus(list, i)),
          onTap: () => _entryActions(list, i),
        ),
    ];
  }

  /// 附件级页序调整（一份多页报告可由不同消息的照片组成，页序可调）。
  Future<void> _reorderPages() async {
    final doc = _doc!;
    var refs = MedicalPageRef.decodeList(doc.pages);
    final changed = await showDialog<List<MedicalPageRef>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('调整页序（长按拖动）'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setDialogState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = refs.removeAt(oldIndex);
                  refs.insert(newIndex, item);
                });
              },
              children: [
                for (var i = 0; i < refs.length; i++)
                  ListTile(
                    key: ValueKey(refs[i].attachmentId),
                    leading: const Icon(Icons.drag_handle),
                    title: Text('第 ${i + 1} 页'),
                    subtitle: Text('附件 ${refs[i].attachmentId.substring(0, 8)}…'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            TextButton(
                onPressed: () => Navigator.pop(context, refs),
                child: const Text('保存')),
          ],
        ),
      ),
    );
    if (changed == null) return;
    await widget.services.medicalDocuments.updatePages(doc.id, [
      for (var i = 0; i < changed.length; i++)
        MedicalPageRef(
          attachmentId: changed[i].attachmentId,
          messageId: changed[i].messageId,
          pageNo: i + 1,
        ),
    ]);
    await _load();
  }

  String _dateText(String? encoded) {
    if (encoded == null) return '未知';
    return TimeValue.decode(encoded).localDate ?? '未知';
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }
    final pageRefs = MedicalPageRef.decodeList(doc.pages);
    final hasUnreviewed =
        _results.any((r) => r.reviewStatus == ReviewStatus.unreviewed) ||
            [
              for (final list in LabReview.entryLists)
                for (var i = 0; i < _entryList(list).length; i++)
                  _entryStatus(list, i)
            ].contains(ReviewStatus.unreviewed);
    final hasEntries =
        LabReview.entryLists.any((l) => _entryList(l).isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(medicalDocTypeLabels[doc.docType]!),
        actions: [
          if (pageRefs.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_vert),
              tooltip: '调整页序',
              onPressed: _reorderPages,
            ),
        ],
      ),
      body: ListView(
        children: [
          if (doc.institutionText != null)
            ListTile(
                title: const Text('医疗机构'),
                subtitle: Text(doc.institutionText!)),
          ListTile(
              title: const Text('检查日期'),
              subtitle: Text(_dateText(doc.examDate))),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: _extract,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(_record == null ? '识别并预览' : '重新提取'),
            ),
          ),
          if (_record == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '先在本机识别文字并自动遮蔽姓名和证件号，展示给你检查、修改，'
                '确认后才发给模型。原图不发送；体检册的导读、宣教等无关页默认不发。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          if (_record != null && _results.isEmpty && !hasEntries)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('这份文件没有提取到检验数值或文字内容，可以重新提取。',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (_record != null && hasUnreviewed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('点一条可核对；未核对的内容不参与分析',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  TextButton(
                      onPressed: _confirmAll, child: const Text('全部确认')),
                ],
              ),
            ),
          ..._entrySection('findings', '诊断与检查文字'),
          ..._entrySection('medications', '处方药品'),
          if (_results.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('检验结果',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (var i = 0; i < _results.length; i++)
              ListTile(
                dense: true,
                title: Text(_results[i].itemNameRaw),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text([
                      _results[i].valueRaw,
                      if (_results[i].unitRaw != null) _results[i].unitRaw!,
                      if (_results[i].refRangeRaw != null)
                        '参考 ${_results[i].refRangeRaw}',
                    ].join(' ')),
                    ?_fixesText(_resultFixes(_results[i].resultIndex)),
                  ],
                ),
                trailing: Text(
                  [
                    if (_results[i].flagRaw != null) _results[i].flagRaw!,
                    switch (_results[i].reviewStatus) {
                      ReviewStatus.unreviewed => '未核对',
                      ReviewStatus.confirmed => '已确认',
                      ReviewStatus.edited => '已修改',
                    },
                  ].join(' '),
                  style: TextStyle(
                    fontSize: 11,
                    color: _results[i].flagRaw != null
                        ? Colors.orange
                        : (_results[i].reviewStatus == ReviewStatus.unreviewed
                            ? Colors.grey
                            : Colors.green),
                  ),
                ),
                onTap: () => _resultActions(_results[i].resultIndex, _results[i]),
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '项目、数值、单位、参考范围、检查日期确认后，这条结果才参与分析。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
