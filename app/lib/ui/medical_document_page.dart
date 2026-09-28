import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/time_value.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;

/// 医疗文件详情（V4-M2 第一版）：文件信息、页数、提取入口、提取结果
/// 列表。逐项核对、定位回原件高亮、页排除标记在本里程碑后续补。
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
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await widget.services.medicalDocuments.byId(widget.documentId);
    final results =
        await widget.services.records.labResultsOfDocument(widget.documentId);
    if (mounted) {
      setState(() {
        _doc = doc;
        _results = results;
      });
    }
  }

  /// 提取：本地 OCR → 页筛选 → 脱敏（只删姓名证件号，D-24）→ 模型
  /// 结构化 → 检验项目入库（全部未核对）。
  Future<void> _extract() async {
    setState(() => _extracting = true);
    try {
      final outcome = await widget.services.medicalExtraction
          .extractDocument(widget.documentId);
      if (!mounted) return;
      final skipped =
          outcome.pageDecisions.where((d) => !d.included).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('提取完成，已遮蔽 ${outcome.redactedCount} 处隐私信息'
            '${skipped > 0 ? '，跳过 $skipped 页无关内容' : ''}。'
            '结果未核对，确认后才参与分析'),
      ));
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
    final pages = MedicalPageRef.decodeList(doc.pages);

    return Scaffold(
      appBar: AppBar(title: Text(medicalDocTypeLabels[doc.docType]!)),
      body: ListView(
        children: [
          ListTile(
            title: const Text('页数'),
            subtitle: Text('${pages.length} 页（原件在对话流中可查看）'),
          ),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('检验结果（未核对的不参与分析）'),
            ),
            for (final r in _results)
              ListTile(
                dense: true,
                title: Text(r.itemNameRaw),
                subtitle: Text([
                  r.valueRaw,
                  if (r.unitRaw != null) r.unitRaw!,
                  if (r.refRangeRaw != null) '参考 ${r.refRangeRaw}',
                ].join(' ')),
                trailing: Text(
                  r.flagRaw ??
                      (r.reviewStatus == ReviewStatus.unreviewed ? '未核对' : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: r.flagRaw != null ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
