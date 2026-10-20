import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/time_value.dart';
import '../services/body_map.dart';
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
  bool _fillingPanels = false;

  /// 核对时的筛选：全部 / 只看未核对 / 只看异常。
  _ReviewFilter _filter = _ReviewFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _editInstitution() async {
    final doc = _doc;
    if (doc == null) return;
    final values = await showFieldsDialog(context, title: '医疗机构', fields: [
      DialogField(initial: doc.institutionText ?? '', hint: '如 某某市人民医院'),
    ]);
    if (values == null) return;
    final text = values.single.trim();
    final value = text.isEmpty ? null : text;
    if (value == doc.institutionText) return;
    await widget.services.medicalDocuments.updateInstitution(doc.id, value);
    await _load();
  }

  /// 改检查日期：文件、提取记录和身体状况一起改（[MedicalExtractionService.changeExamDate]）。
  Future<void> _editVisitTitle() async {
    final doc = _doc;
    if (doc == null) return;
    final values = await showFieldsDialog(context, title: '就诊标题', fields: [
      DialogField(initial: doc.visitTitle ?? '', hint: '如 甲状腺结节复查'),
    ]);
    if (values == null) return;
    final text = values.single.trim();
    final value = text.isEmpty ? null : text;
    if (value == doc.visitTitle) return;
    await widget.services.medicalDocuments.updateVisitTitle(doc.id, value);
    await _load();
  }

  Future<void> _editExamDate() async {
    final doc = _doc;
    if (doc == null) return;
    final current =
        doc.examDate == null ? null : TimeValue.decode(doc.examDate!).localDate;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null ? now : DateTime.parse(current),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '检查日期',
    );
    if (picked == null) return;
    final newDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (newDate == current) return;
    await widget.services.medicalExtraction.changeExamDate(doc.id, newDate);
    await _load();
  }

  /// 血压"122/86"在索引里拆成收缩压、舒张压两行（part 1、2，D-39）；
  /// 核对按报告原样显示一行，确认、修改、删除都作用于这一条原文。
  static List<LabResult> _asReported(List<LabResult> rows, List raw) => [
        for (final r in rows)
          if (r.part == 0)
            r
          else if (r.part == 1 && raw[r.resultIndex] is Map)
            r.copyWith(
              itemNameRaw: '${raw[r.resultIndex]['item_name_raw']}',
              valueRaw: '${raw[r.resultIndex]['value_raw']}',
              valueNum: const Value(null),
              unitRaw: Value(raw[r.resultIndex]['unit_raw'] as String?),
              refRangeRaw: Value(raw[r.resultIndex]['ref_range_raw'] as String?),
              flagRaw: Value(raw[r.resultIndex]['flag_raw'] as String?),
            ),
      ];

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
      final data = jsonDecode(rev.data) as Map;
      results = _asReported([
        for (final r in await s.records.labResultsOfDocument(widget.documentId))
          if (r.recordId == record.id) r
      ], data['results'] as List? ?? const []);
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

  /// 补检查大项（D-36）：旧报告的检验项目没有大项、分批提取时续表的项目
  /// 读不到标题，尿常规的"白细胞"和血常规混在一起。只发项目名称和已有的
  /// 大项；写成新版本，提示条上可以撤销。
  Future<void> _fillPanels() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _fillingPanels = true);
    try {
      final outcome = await widget.services.medicalExtraction
          .fillPanels(widget.documentId);
      if (outcome.previousData == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('模型没有认出所属大项，未改动')));
        return;
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('已给 ${outcome.filled} 项补上所属大项，'
            '在下面按大项分组显示，不对的可以点一项修改'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            if (_record?.version != outcome.record.version) return;
            await _writeRevision(outcome.previousData!,
                FieldMetaMap.decode(outcome.previousFieldMeta!));
          },
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('补大项失败：$e')));
    } finally {
      if (mounted) setState(() => _fillingPanels = false);
      await _load();
    }
  }

  /// 检验结果按大项分段（D-36）：连续同一大项的放一段，没有大项的单独一段。
  List<Widget> _resultSections() {
    final sections = <(String?, List<int>)>[];
    for (var i = 0; i < _results.length; i++) {
      if (!_resultVisible(_results[i])) continue;
      final panel = _results[i].panelRaw;
      if (sections.isEmpty || sections.last.$1 != panel) {
        sections.add((panel, []));
      }
      sections.last.$2.add(i);
    }
    final hasPanels = sections.any((s) => s.$1 != null);
    return [
      for (var k = 0; k < sections.length; k++)
        AdaptiveSection(
          header: !hasPanels
              ? '检验结果'
              : '检验结果 · ${sections[k].$1 ?? '未标大项'}',
          footer: k == sections.length - 1 && _filter == _ReviewFilter.all
              ? '项目、数值、单位、参考范围、检查日期确认后，这条结果才参与分析。'
              : null,
          children: [for (final i in sections[k].$2) _resultTile(i)],
        ),
    ];
  }

  /// 异常：有异常标记，或数值超出参考范围（与人体图同一口径）。
  static bool _abnormal(LabResult r) => BodyMapRules.isAbnormalLab(
        flagRaw: r.flagRaw,
        valueRaw: r.valueRaw,
        valueNum: r.valueNum,
        refLow: r.refLow,
        refHigh: r.refHigh,
        refRangeRaw: r.refRangeRaw,
      );

  bool _resultVisible(LabResult r) => switch (_filter) {
        _ReviewFilter.all => true,
        _ReviewFilter.unreviewed => r.reviewStatus == ReviewStatus.unreviewed,
        _ReviewFilter.abnormal => _abnormal(r),
      };

  Widget _resultTile(int i) => AdaptiveTile(
        dense: true,
        title: Text(_results[i].itemNameRaw),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              // 异常的数值加粗标红，一眼能扫到。
              TextSpan(
                text: [
                  _results[i].valueRaw,
                  if (_results[i].unitRaw != null) _results[i].unitRaw!,
                ].join(' '),
                style: _abnormal(_results[i])
                    ? const TextStyle(
                        fontWeight: FontWeight.bold, color: _abnormalColor)
                    : null,
              ),
              if (_results[i].refRangeRaw != null)
                TextSpan(text: '  参考 ${_results[i].refRangeRaw}'),
            ])),
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
                ? _abnormalColor
                : (_results[i].reviewStatus == ReviewStatus.unreviewed
                    ? Colors.grey
                    : Colors.green),
          ),
        ),
        onTap: () => _resultActions(_results[i].resultIndex, _results[i]),
      );

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

  /// 写新版本并在提示条上给"撤销"：删除、全部确认这类一步生效的操作用。
  /// 之后又改过（版本变了）就不撤，免得把后来的核对一起退回去。
  Future<void> _writeWithUndo(
      String dataJson, FieldMetaMap meta, String message) async {
    final previous = _rev!;
    final messenger = ScaffoldMessenger.of(context);
    await _writeRevision(dataJson, meta);
    final version = _record?.version;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(message),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            if (_record?.version != version) return;
            await _writeRevision(
                previous.data, FieldMetaMap.decode(previous.fieldMeta));
          },
        ),
      ));
  }

  Future<void> _confirmAll() async {
    final rev = _rev!;
    final (data, meta) =
        LabReview.confirmAll(rev.data, FieldMetaMap.decode(rev.fieldMeta));
    await _writeWithUndo(data, meta, '已全部确认，这份报告的数据开始参与分析');
  }

  Future<void> _editResult(int index, LabResult row) async {
    final values = await showFieldsDialog(context, title: '修改这一项', fields: [
      DialogField(
          label: '所属大项', initial: row.panelRaw ?? '', hint: '如 血常规、尿常规'),
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
      panelRaw: values[0].trim(),
      itemNameRaw: values[1].trim(),
      valueRaw: values[2].trim(),
      unitRaw: values[3].trim(),
      refRangeRaw: values[4].trim(),
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
        : await showActionSheet<String>(context, actions: [
            ..._reviewActions,
            const SheetAction(
                value: 'delete',
                label: '删除这一项',
                icon: Icons.delete_outline,
                isDestructiveAction: true),
          ]);
    switch (action) {
      case 'confirm':
        await _confirmResult(index);
      case 'edit':
        await _editResult(index, row);
      case 'delete':
        final rev = _rev!;
        final (data, meta) = LabReview.deleteResult(
            rev.data, FieldMetaMap.decode(rev.fieldMeta), index);
        await _writeWithUndo(data, meta, '已删除「${row.itemNameRaw}」');
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
        await _writeWithUndo(data, meta, '已删除这一条');
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
    // 文字和药品没有"异常"之分，只看异常时不显示。
    final shown = [
      for (var i = 0; i < entries.length; i++)
        if (switch (_filter) {
          _ReviewFilter.all => true,
          _ReviewFilter.unreviewed =>
            _entryStatus(list, i) == ReviewStatus.unreviewed,
          _ReviewFilter.abnormal => false,
        })
          i
    ];
    if (shown.isEmpty) return const [];
    return [
      AdaptiveSection(header: title, children: [
        for (final i in shown)
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

  /// 模型在跑时的进度说明，没有在跑为 null。
  String? get _busyText => _imageSending
      ? '模型识图中（最长 3 分钟）…'
      : _tidying
          ? '模型整理文字中…'
          : _fillingPanels
              ? '模型补大项中…'
              : null;

  /// 主操作随状态变：还没提取是"识别并预览"，有未核对的是"全部确认"；
  /// 用模型的几种做法收进"更多"（原来四个按钮并排，要读说明才分得清）。
  Widget _actionRow(bool cupertino, int unreviewed) {
    final (String? label, IconData icon, VoidCallback? onPressed) =
        _record == null
            ? ('识别并预览', Icons.document_scanner_outlined, _extract)
            : unreviewed > 0
                ? ('全部确认（$unreviewed 项）', Icons.done_all, _confirmAll)
                : (null, Icons.check_circle_outline, null);
    final busy = _busyText != null;
    final Widget primary = label == null
        ? const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            SizedBox(width: 6),
            Text('已全部核对'),
          ])
        : cupertino
            ? CupertinoButton.filled(
                onPressed: busy ? null : onPressed,
                child: Text(label),
              )
            : FilledButton.icon(
                onPressed: busy ? null : onPressed,
                icon: Icon(icon),
                label: Text(label),
              );
    final more = cupertino
        ? CupertinoButton.tinted(
            onPressed: busy ? null : _moreActions,
            child: const Text('更多'),
          )
        : OutlinedButton.icon(
            onPressed: busy ? null : _moreActions,
            icon: const Icon(Icons.more_horiz),
            label: const Text('更多'),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Expanded(child: primary),
        const SizedBox(width: 8),
        more,
      ]),
    );
  }

  /// "更多"：重新提取和三种用模型的做法，各带一句什么时候用。
  Future<void> _moreActions() async {
    final action = await showActionSheet<String>(context, actions: [
      if (_record != null)
        const SheetAction(
            value: 'extract',
            label: '重新提取',
            subtitle: '重新识别文字、发送前确认后交给模型；核对状态会清零',
            icon: Icons.document_scanner_outlined),
      const SheetAction(
          value: 'image',
          label: '用模型识图',
          subtitle: '本机识别不准时用（手写、拍歪、版式复杂）：裁剪后把图片发给模型',
          icon: Icons.image_search_outlined),
      if (_entryList('findings').length >= 2)
        const SheetAction(
            value: 'tidy',
            label: '用模型整理文字',
            subtitle: '诊断与检查文字拆得太碎时用：同一部位的所见和结论合并，重复的去掉',
            icon: Icons.auto_fix_high_outlined),
      if (_results.any((r) => r.panelRaw == null))
        const SheetAction(
            value: 'panels',
            label: '用模型补大项',
            subtitle: '检验项目没有标血常规、尿常规等大项时用：只发项目名称，不发数值',
            icon: Icons.category_outlined),
    ]);
    switch (action) {
      case 'extract':
        await _extract();
      case 'image':
        await _extractByImage();
      case 'tidy':
        await _tidyFindings();
      case 'panels':
        await _fillPanels();
    }
  }

  /// 核对进度与筛选：已核对 x/y · 异常 n。
  Widget _summaryBar(bool cupertino, int total, int unreviewed, int abnormal) {
    final reviewed = total - unreviewed;
    const labels = {
      _ReviewFilter.all: '全部',
      _ReviewFilter.unreviewed: '未核对',
      _ReviewFilter.abnormal: '异常',
    };
    void select(_ReviewFilter? f) {
      if (f != null) setState(() => _filter = f);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
              text: '已核对 $reviewed/$total',
              style: TextStyle(
                  color: unreviewed == 0 ? Colors.green : null,
                  fontWeight: FontWeight.w600),
            ),
            if (abnormal > 0)
              TextSpan(
                text: '  ·  异常 $abnormal',
                style: const TextStyle(
                    color: _abnormalColor, fontWeight: FontWeight.w600),
              ),
            if (unreviewed > 0 && !widget.readOnly)
              const TextSpan(
                text: '  点一条核对，未核对的不参与分析',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ])),
          const SizedBox(height: 8),
          cupertino
              ? CupertinoSlidingSegmentedControl<_ReviewFilter>(
                  groupValue: _filter,
                  onValueChanged: select,
                  children: {
                    for (final e in labels.entries) e.key: Text(e.value),
                  },
                )
              : SegmentedButton<_ReviewFilter>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in labels.entries)
                      ButtonSegment(value: e.key, label: Text(e.value)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (v) => select(v.first),
                ),
        ],
      ),
    );
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
    final hasEntries =
        LabReview.entryLists.any((l) => _entryList(l).isNotEmpty);
    const hintStyle = TextStyle(fontSize: 12, color: Colors.grey);
    // 核对进度：检验结果按列表显示的行数算（汇总与明细重复的只算一次）。
    final statuses = [
      for (final r in _results) r.reviewStatus,
      for (final list in LabReview.entryLists)
        for (var i = 0; i < _entryList(list).length; i++) _entryStatus(list, i),
    ];
    final total = statuses.length;
    final unreviewed =
        statuses.where((st) => st == ReviewStatus.unreviewed).length;
    final abnormal = _results.where(_abnormal).length;

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
            if (doc.visitTitle != null || !widget.readOnly)
              AdaptiveTile(
                title: const Text('就诊标题'),
                subtitle: Text(doc.visitTitle ?? '提取后自动生成，也可以点此填写'),
                trailing: widget.readOnly
                    ? null
                    : Icon(
                        cupertino ? CupertinoIcons.pencil : Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey),
                onTap: widget.readOnly ? null : _editVisitTitle,
              ),
            if (doc.institutionText != null || !widget.readOnly)
              AdaptiveTile(
                title: const Text('医疗机构'),
                subtitle: Text(doc.institutionText ?? '未识别，点此填写'),
                trailing: widget.readOnly
                    ? null
                    : Icon(
                        cupertino ? CupertinoIcons.pencil : Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey),
                onTap: widget.readOnly ? null : _editInstitution,
              ),
            AdaptiveTile(
              title: const Text('检查日期'),
              subtitle: Text(_dateText(doc.examDate)),
              trailing: widget.readOnly
                  ? null
                  : Icon(
                      cupertino ? CupertinoIcons.pencil : Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey),
              onTap: widget.readOnly ? null : _editExamDate,
            ),
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
          if (!widget.readOnly) _actionRow(cupertino, unreviewed),
          if (_busyText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2)),
                const SizedBox(width: 8),
                Expanded(child: Text(_busyText!, style: hintStyle)),
              ]),
            ),
          if (_record == null && !widget.readOnly)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                '先在本机识别文字并自动遮蔽姓名、证件号和门诊卡号，展示给你检查、修改，'
                '确认后才发给模型。原图不发送；体检册的导读、宣教等无关页默认不发。'
                '本机识别不准（手写、拍歪、版式复杂）时，在"更多"里用模型识图。',
                style: hintStyle,
              ),
            ),
          if (_record != null &&
              _results.isEmpty &&
              !hasEntries &&
              !widget.readOnly)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('这份文件没有提取到检验数值或文字内容，可以在"更多"里重新提取。',
                  style: hintStyle),
            ),
          if (_record != null && (_results.isNotEmpty || hasEntries))
            _summaryBar(cupertino, total, unreviewed, abnormal),
          ..._entrySection('findings', '诊断与检查文字'),
          ..._entrySection('medications', '处方药品'),
          // D-36 之前提取的全没有大项；分批提取时后一页续表的常读不到标题。
          if (!widget.readOnly &&
              _filter == _ReviewFilter.all &&
              _results.any((r) => r.panelRaw == null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                  '${_results.every((r) => r.panelRaw == null) ? '这份报告的检验项目' : '有 ${_results.where((r) => r.panelRaw == null).length} 项'}'
                  '没有标所属大项，尿常规的白细胞、葡萄糖等会和血液里的同名项目混在一起，'
                  '可以在"更多"里用模型补大项',
                  style: hintStyle),
            ),
          if (_results.isNotEmpty) ..._resultSections(),
          if (_filter != _ReviewFilter.all &&
              !_results.any(_resultVisible) &&
              (_filter == _ReviewFilter.abnormal ||
                  unreviewed == 0))
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                  _filter == _ReviewFilter.abnormal
                      ? '没有异常的检验结果'
                      : '没有未核对的内容',
                  textAlign: TextAlign.center,
                  style: hintStyle),
            ),
          if (cupertino) const SizedBox(height: 24),
        ],
      ),
    );
  }
}

enum _ReviewFilter { all, unreviewed, abnormal }

/// 异常数值的颜色，与人体图"需关注"一致。
const _abnormalColor = Color(0xFFD32F2F);
