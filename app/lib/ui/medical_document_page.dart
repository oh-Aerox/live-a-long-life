import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/time_value.dart';
import '../services/lab_review.dart';
import '../services/medical_extraction_service.dart';
import 'adaptive.dart';
import 'medical_crop_page.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;
import 'medical_send_preview_page.dart';
import 'source_viewer_page.dart';

/// 医疗文件详情（V4-M2）：文件信息、提取（先本地识别预览、确认后发送，
/// D-28）、检验数值与文字内容逐项核对（D-04）、定位回原件（A-19）。
/// Mac 端 [readOnly]：只看提取结果、核对状态和原件位置，不提取、不核对、
/// 不修改、不删除（D-12 只有手机写入）。
class MedicalDocumentPage extends StatefulWidget {
  const MedicalDocumentPage(
      {super.key,
      required this.services,
      required this.documentId,
      this.readOnly = false});

  final AppServices services;
  final String documentId;
  final bool readOnly;

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
  bool _imageSending = false;
  bool _tidying = false;

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
        duration: outcome.failedPages.isEmpty
            ? const Duration(seconds: 4)
            : const Duration(seconds: 10),
        content: Text('提取完成，已遮蔽 ${outcome.redactedCount} 处隐私信息'
            '${skipped > 0 ? '，$skipped 页未发送' : ''}'
            '${outcome.failedPages.isEmpty ? '' : '。第 ${outcome.failedPages.join('、')} 页没有提取成功（其余已保存），可以稍后重新提取'}'
            '${outcome.conditionRecords.isNotEmpty ? '，发现 ${outcome.conditionRecords.length} 条身体状况建议（在长期状况档案里核对）' : ''}。'
            '结果未核对，确认后才参与分析'),
      ));
      if (outcome.possibleDuplicateRecordIds.isNotEmpty) {
        await showAdaptiveDialog<void>(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('可能重复'),
            content: Text('同一检查日期已有 '
                '${outcome.possibleDuplicateRecordIds.length} 条包含相同项目的'
                '检验记录（可能是同一份报告拍了两次）。两份都会保留，'
                '核对时注意别重复确认。'),
            actions: [
              DialogAction(
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

  /// 模型识图兜底（V4-M3，D-24）：本机识别不准时显式发起。先看默认模型能否
  /// 识图（不能就提示换模型，不算失败）→ 选页 → 裁剪 → 发送。
  Future<void> _extractByImage() async {
    final ex = widget.services.medicalExtraction;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ex.defaultModelSupportsImage()) {
      if (!mounted) return;
      await showAdaptiveDialog<void>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('当前模型不能识图'),
          content: const Text('默认模型在测试连接时没有检测到图片能力。可以在'
              '"设置 → 模型配置"里换一个支持图片的模型设为默认，或对它重新测试连接。'
              '\n\n也可以继续用"识别并预览"，在本机识别文字后发送。'),
          actions: [
            DialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了')),
          ],
        ),
      );
      return;
    }
    final List<ImagePageChoice> pages;
    try {
      pages = await ex.imagePages(widget.documentId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (pages.isEmpty || !mounted) return;
    var page = pages.first;
    if (pages.length > 1) {
      final picked = await showActionSheet<ImagePageChoice>(context,
          title: '识别哪一页？',
          actions: [
            for (final p in pages)
              SheetAction(value: p, label: '第 ${p.pageNo} 页'),
          ]);
      if (picked == null) return;
      page = picked;
    }
    final Uint8List bytes;
    try {
      bytes = await ex.pageImage(page);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!mounted) return;
    final crop = await Navigator.push<CropResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicalCropPage(bytes: bytes, title: '第 ${page.pageNo} 页'),
      ),
    );
    if (crop == null || !mounted) return;
    setState(() => _imageSending = true);
    try {
      final outcome = await ex.extractFromImage(
        widget.documentId,
        ImageSend(
          attachmentId: page.attachmentId,
          pageNo: page.pageNo,
          attachmentPage: page.attachmentPage,
          png: crop.png,
          width: crop.width,
          height: crop.height,
          cropBox: crop.cropBox,
        ),
      );
      messenger.showSnackBar(SnackBar(
        content: Text('识图完成'
            '${outcome.conditionRecords.isNotEmpty ? '，发现 ${outcome.conditionRecords.length} 条身体状况建议' : ''}。'
            '结果未核对，确认后才参与分析；点一条可看它在原件上的区域'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('识图失败：$e')));
    } finally {
      if (mounted) setState(() => _imageSending = false);
      await _load();
    }
  }

  /// 用模型整理文字内容（D-35）：同一部位的所见与结论合并、重复的去掉。
  /// 只发已提取的文字；写成新版本，提示条上可以撤销。
  Future<void> _tidyFindings() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('用模型整理文字？'),
        content: Text('把下面 ${_entryList('findings').length} 段诊断与检查文字发给默认模型，'
            '同一部位的所见和结论合并成一条，重复的去掉，原文不改写。'
            '\n\n只发这些已提取的文字，不发图片。合并出来的条目要重新核对，'
            '整理前的版本保留在修改历史里。'),
        actions: [
          DialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          DialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('整理')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _tidying = true);
    try {
      final outcome = await widget.services.medicalExtraction
          .tidyFindings(widget.documentId);
      if (!outcome.changed) {
        messenger.showSnackBar(
            const SnackBar(content: Text('没有需要合并的条目，未改动')));
        return;
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('已整理：${outcome.before} 段合并为 ${outcome.after} 段，'
            '合并的条目需要重新核对'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            // 整理后又改过就不撤，免得把后来的核对一起退回去。
            if (_record?.version != outcome.record.version) return;
            await _writeRevision(outcome.previousData!,
                FieldMetaMap.decode(outcome.previousFieldMeta!));
          },
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('整理失败：$e')));
    } finally {
      if (mounted) setState(() => _tidying = false);
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
    final values = await showFieldsDialog(context, title: '修改这一项', fields: [
      DialogField(label: '项目', initial: row.itemNameRaw),
      DialogField(label: '数值', initial: row.valueRaw),
      DialogField(label: '单位', initial: row.unitRaw ?? ''),
      DialogField(label: '参考范围', initial: row.refRangeRaw ?? ''),
    ]);
    if (values == null) return;
    final rev = _rev!;
    final (data, meta) = LabReview.editResult(
      rev.data,
      FieldMetaMap.decode(rev.fieldMeta),
      index,
      itemNameRaw: values[0].trim(),
      valueRaw: values[1].trim(),
      unitRaw: values[2].trim(),
      refRangeRaw: values[3].trim(),
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
    // 只读：点一项直接看原件位置。
    final action = widget.readOnly
        ? 'source'
        : await showActionSheet<String>(context, actions: _reviewActions);
    switch (action) {
      case 'confirm':
        await _confirmResult(index);
      case 'edit':
        await _editResult(index, row);
      case 'source':
        await _viewSource(index, row);
    }
  }

  /// 点一条检验结果或文字内容时的操作菜单。
  static const _reviewActions = [
    SheetAction(
        value: 'confirm', label: '确认无误', icon: Icons.check_circle_outline),
    SheetAction(value: 'edit', label: '修改', icon: Icons.edit_outlined),
    SheetAction(
        value: 'source',
        label: '查看原件位置',
        icon: Icons.image_search_outlined),
  ];

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
    final action = widget.readOnly
        ? 'source'
        : await showActionSheet<String>(context, actions: [
            ..._reviewActions,
            const SheetAction(
                value: 'delete',
                label: '删除这一条',
                icon: Icons.delete_outline,
                isDestructiveAction: true),
          ]);
    final rev = _rev;
    if (action == null || rev == null || !mounted) return;
    switch (action) {
      case 'confirm':
        final (data, meta) = LabReview.confirmEntry(
            rev.data, FieldMetaMap.decode(rev.fieldMeta), list, index);
        await _writeRevision(data, meta);
      case 'edit':
        final labels = _entryFields[list]!;
        final values = await showFieldsDialog(context, title: '修改', fields: [
          for (final e in labels.entries)
            DialogField(
                label: e.value,
                initial: entry[e.key] as String? ?? '',
                maxLines: null),
        ]);
        if (values == null || !mounted) return;
        final edited = {
          for (final (i, k) in labels.keys.indexed) k: values[i].trim()
        };
        // 主字段（文字内容 / 药品名）不能改空。
        final mainKey = list == 'findings' ? 'text_raw' : 'name';
        if (edited[mainKey]!.isEmpty) return;
        final (data, meta) = LabReview.editEntry(
          rev.data,
          FieldMetaMap.decode(rev.fieldMeta),
          list,
          index,
          edited,
        );
        await _writeRevision(data, meta);
      case 'delete':
        final (data, meta) = LabReview.deleteEntry(
            rev.data, FieldMetaMap.decode(rev.fieldMeta), list, index);
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
      AdaptiveSection(header: title, children: [
        for (var i = 0; i < entries.length; i++)
          AdaptiveTile(
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
      ]),
    ];
  }

  Future<void> _delete() async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('删除这份医疗文件？'),
        content: const Text('从病例夹移除，提取出的检验数值、文字和药品一起删除，'
            '不再参与分析；还没核对的身体状况建议也一起删掉，已确认的状况档案保留。'
            '\n\n原始照片或 PDF 仍在对话记录里。'),
        actions: [
          DialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          DialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDestructiveAction: true,
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.services.medicalExtraction.deleteDocument(widget.documentId);
    if (mounted) Navigator.pop(context);
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
    final cupertino = useCupertino(context);
    // iOS 分组列表的灰色底。
    final background = cupertino
        ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
        : null;
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
          backgroundColor: background,
          appBar: adaptiveAppBar(context),
          body: const Center(child: CircularProgressIndicator.adaptive()));
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
    const hintStyle = TextStyle(fontSize: 12, color: Colors.grey);

    return Scaffold(
      backgroundColor: background,
      appBar: adaptiveAppBar(
        context,
        title: Text(medicalDocTypeLabels[doc.docType]!),
        actions: [
          if (pageRefs.length > 1 && !widget.readOnly)
            NavAction(
              icon: Icons.swap_vert,
              cupertinoIcon: CupertinoIcons.arrow_up_arrow_down,
              tooltip: '调整页序',
              onPressed: _reorderPages,
            ),
          if (!widget.readOnly)
            NavAction(
              icon: Icons.delete_outline,
              cupertinoIcon: CupertinoIcons.delete,
              tooltip: '删除这份文件',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        children: [
          AdaptiveSection(children: [
            if (doc.institutionText != null)
              AdaptiveTile(
                  title: const Text('医疗机构'),
                  subtitle: Text(doc.institutionText!)),
            AdaptiveTile(
                title: const Text('检查日期'),
                subtitle: Text(_dateText(doc.examDate))),
          ]),
          if (!cupertino) const Divider(),
          if (widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                _record == null
                    ? '这份文件还没有提取，在手机上提取与核对。'
                    : '只读：提取与核对在手机上进行。点一条可查看原件位置。',
                style: hintStyle,
              ),
            ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: cupertino
                  ? CupertinoButton.filled(
                      onPressed: _extract,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.doc_text_viewfinder,
                              size: 20),
                          const SizedBox(width: 6),
                          Text(_record == null ? '识别并预览' : '重新提取'),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _extract,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(_record == null ? '识别并预览' : '重新提取'),
                    ),
            ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: cupertino
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CupertinoButton.tinted(
                          onPressed: _imageSending ? null : _extractByImage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _imageSending
                                  ? const CupertinoActivityIndicator()
                                  : const Icon(CupertinoIcons.photo, size: 20),
                              const SizedBox(width: 6),
                              Text(_imageSending
                                  ? '模型识图中（最长 3 分钟）…'
                                  : '用模型识图'),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                              '本机识别不准时用（手写、拍歪、版式复杂）：裁剪后把图片发给模型',
                              style: hintStyle),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _imageSending ? null : _extractByImage,
                          icon: _imageSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2))
                              : const Icon(Icons.image_search_outlined),
                          label: Text(_imageSending
                              ? '模型识图中（最长 3 分钟）…'
                              : '用模型识图'),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                              '本机识别不准时用（手写、拍歪、版式复杂）：裁剪后把图片发给模型',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
            ),
          if (!widget.readOnly && _entryList('findings').length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: cupertino
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CupertinoButton.tinted(
                          onPressed: _tidying ? null : _tidyFindings,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _tidying
                                  ? const CupertinoActivityIndicator()
                                  : const Icon(CupertinoIcons.wand_stars,
                                      size: 20),
                              const SizedBox(width: 6),
                              Text(_tidying ? '模型整理中…' : '用模型整理'),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                              '诊断与检查文字拆得太碎时用：同一部位的所见和结论合并，重复的去掉',
                              style: hintStyle),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _tidying ? null : _tidyFindings,
                          icon: _tidying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2))
                              : const Icon(Icons.auto_fix_high_outlined),
                          label: Text(_tidying ? '模型整理中…' : '用模型整理'),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                              '诊断与检查文字拆得太碎时用：同一部位的所见和结论合并，重复的去掉',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
            ),
          if (_record == null && !widget.readOnly)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '先在本机识别文字并自动遮蔽姓名、证件号和门诊卡号，展示给你检查、修改，'
                '确认后才发给模型。原图不发送；体检册的导读、宣教等无关页默认不发。',
                style: hintStyle,
              ),
            ),
          if (_record != null &&
              _results.isEmpty &&
              !hasEntries &&
              !widget.readOnly)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('这份文件没有提取到检验数值或文字内容，可以重新提取。',
                  style: hintStyle),
            ),
          if (_record != null && hasUnreviewed && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('点一条可核对；未核对的内容不参与分析',
                        style: hintStyle),
                  ),
                  cupertino
                      ? CupertinoButton(
                          sizeStyle: CupertinoButtonSize.small,
                          onPressed: _confirmAll,
                          child: const Text('全部确认'))
                      : TextButton(
                          onPressed: _confirmAll, child: const Text('全部确认')),
                ],
              ),
            ),
          ..._entrySection('findings', '诊断与检查文字'),
          ..._entrySection('medications', '处方药品'),
          if (_results.isNotEmpty)
            AdaptiveSection(
              header: '检验结果',
              footer: '项目、数值、单位、参考范围、检查日期确认后，这条结果才参与分析。',
              children: [
                for (var i = 0; i < _results.length; i++)
                  AdaptiveTile(
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
                            : (_results[i].reviewStatus ==
                                    ReviewStatus.unreviewed
                                ? Colors.grey
                                : Colors.green),
                      ),
                    ),
                    onTap: () =>
                        _resultActions(_results[i].resultIndex, _results[i]),
                  ),
              ],
            ),
          if (cupertino) const SizedBox(height: 24),
        ],
      ),
    );
  }
}
