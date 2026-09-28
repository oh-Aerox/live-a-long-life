import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/time_value.dart';
import '../services/lab_review.dart';
import '../services/medical_extraction_service.dart';
import '../services/text_extraction.dart' show PageTextSource;
import 'medical_folder_page.dart' show medicalDocTypeLabels;
import 'source_viewer_page.dart';

/// 医疗文件详情（V4-M2）：文件信息、页面发送范围（页筛选默认 + 用户
/// 覆盖）、提取、逐项核对（D-04）、定位回原件（A-19）。
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
  List<PagePreview>? _pages; // 懒加载：展开"页面"时才做本地 OCR
  bool _extracting = false;
  bool _pagesLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final doc = await s.medicalDocuments.byId(widget.documentId);
    final results = await s.records.labResultsOfDocument(widget.documentId);
    RecordRow? record;
    RecordRevision? rev;
    if (results.isNotEmpty) {
      record = await s.records.byId(results.first.recordId);
      if (record != null) {
        rev = await s.records.currentRevisionOf(record.id);
      }
    }
    if (mounted) {
      setState(() {
        _doc = doc;
        _results = results;
        _record = record;
        _rev = rev;
      });
    }
  }

  Future<void> _loadPages() async {
    if (_pagesLoading) return;
    setState(() => _pagesLoading = true);
    try {
      final pages =
          await widget.services.medicalExtraction.previewPages(widget.documentId);
      if (mounted) setState(() => _pages = pages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('页面预览失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _pagesLoading = false);
    }
  }

  Future<void> _togglePage(PagePreview page) async {
    await widget.services.medicalDocuments
        .setPageOverride(widget.documentId, page.pageNo, !page.included);
    await _load();
    await _loadPages();
  }

  Future<void> _clearPageOverride(PagePreview page) async {
    await widget.services.medicalDocuments
        .setPageOverride(widget.documentId, page.pageNo, null);
    await _load();
    await _loadPages();
  }

  Future<void> _extract() async {
    setState(() => _extracting = true);
    try {
      final outcome = await widget.services.medicalExtraction
          .extractDocument(widget.documentId);
      if (!mounted) return;
      final skipped = outcome.pageDecisions.where((d) => !d.included).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('提取完成，已遮蔽 ${outcome.redactedCount} 处隐私信息'
            '${skipped > 0 ? '，跳过 $skipped 页无关内容' : ''}'
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
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('提取失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
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
    setState(() => _pages = null);
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
        _results.any((r) => r.reviewStatus == ReviewStatus.unreviewed);

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
          ExpansionTile(
            title: Text('页面与发送范围（${pageRefs.length} 个附件）'),
            subtitle: const Text('排除的页不会发给模型，随时可点选恢复'),
            onExpansionChanged: (open) {
              if (open && _pages == null) _loadPages();
            },
            children: [
              if (_pages == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final page in _pages!)
                  GestureDetector(
                    onLongPress: page.overridden
                        ? () => _clearPageOverride(page)
                        : null,
                    child: SwitchListTile(
                      dense: true,
                      value: page.included,
                      title: Text('第 ${page.pageNo} 页'
                          '${page.source == PageTextSource.pdfText ? ' · 文字层' : ''}'),
                      subtitle: Text(
                        '${page.firstLine.length > 24 ? page.firstLine.substring(0, 24) : page.firstLine}'
                        '\n${page.reason}${page.overridden ? '（长按恢复默认）' : ''}',
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (_) => _togglePage(page),
                    ),
                  ),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: _extracting ? null : _extract,
              icon: _extracting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_results.isEmpty ? '提取检验数据' : '重新提取'),
            ),
          ),
          if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '提取在本机完成文字识别，发给模型前会自动删除姓名和证件号；'
                '体检册的导读、宣教等无关页不会发送。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          if (_results.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Expanded(child: Text('检验结果（点一项可核对）')),
                  if (hasUnreviewed)
                    TextButton(
                        onPressed: _confirmAll, child: const Text('全部确认')),
                ],
              ),
            ),
            for (var i = 0; i < _results.length; i++)
              ListTile(
                dense: true,
                title: Text(_results[i].itemNameRaw),
                subtitle: Text([
                  _results[i].valueRaw,
                  if (_results[i].unitRaw != null) _results[i].unitRaw!,
                  if (_results[i].refRangeRaw != null)
                    '参考 ${_results[i].refRangeRaw}',
                ].join(' ')),
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
