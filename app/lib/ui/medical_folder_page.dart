import 'dart:io';

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/medical_document_repository.dart';
import 'medical_document_page.dart';

const medicalDocTypeLabels = {
  MedicalDocType.labReport: '检验报告',
  MedicalDocType.imagingReport: '影像报告',
  MedicalDocType.visitRecord: '门诊病历',
  MedicalDocType.prescription: '处方',
  MedicalDocType.dischargeSummary: '出院小结',
  MedicalDocType.physicalExam: '体检报告',
  MedicalDocType.other: '医疗文件',
};

/// 病例夹 / 体检两个入口，一套实现（D-27）：doc_type 过滤的医疗文件
/// 列表，可添加（仍写入消息流）、查看、进详情提取与核对。
class MedicalFolderPage extends StatefulWidget {
  const MedicalFolderPage(
      {super.key, required this.services, required this.physicalExam});

  final AppServices services;

  /// true = 我的体检（doc_type 为体检报告）；false = 我的病例夹（其余类型）。
  final bool physicalExam;

  @override
  State<MedicalFolderPage> createState() => _MedicalFolderPageState();
}

class _MedicalFolderPageState extends State<MedicalFolderPage> {
  final _picker = ImagePicker();
  final _ids = const IdGenerator();
  List<MedicalDocument> _docs = [];
  bool _busy = false;

  String get _title => widget.physicalExam ? '我的体检' : '我的病例夹';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.services.medicalDocuments.all();
    final docs = [
      for (final d in all)
        if ((d.docType == MedicalDocType.physicalExam) == widget.physicalExam)
          d,
    ];
    if (mounted) setState(() => _docs = docs);
  }

  static String _mimeOf(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// 添加文件：与对话流导入同一套机制——附件先进消息流（原始层不变，
  /// D-27），再组成一份医疗文件。重复文件走 D-10 三选项提示。
  Future<void> _add() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('选择文件（PDF 等）'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    List<String> paths;
    switch (choice) {
      case 'camera':
        final shot = await _picker.pickImage(source: ImageSource.camera);
        paths = [if (shot != null) shot.path];
      case 'photos':
        final picked = await _picker.pickMultiImage();
        paths = picked.map((x) => x.path).toList();
      default:
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
        );
        paths = result.map((f) => f.path).whereType<String>().toList();
    }
    if (paths.isEmpty) return;

    setState(() => _busy = true);
    try {
      final s = widget.services;
      final kept = <({Attachment attachment, bool duplicateAcknowledged})>[];
      for (final path in paths) {
        final name = p.basename(path);
        final ImportResult result;
        try {
          result = await s.attachments.importFile(
            File(path),
            mimeType: _mimeOf(path),
            originalFilename: name,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('「$name」保存失败：$e')));
          }
          continue;
        }
        if (!result.isDuplicate) {
          kept.add(
              (attachment: result.attachment, duplicateAcknowledged: false));
          continue;
        }
        if (!mounted) return;
        final action = await _askDuplicate(result.attachment, name);
        if (action == 'add') {
          kept.add(
              (attachment: result.attachment, duplicateAcknowledged: true));
        }
      }
      if (kept.isEmpty) return;

      final message = await s.messages.send(
        clientMsgId: _ids.newId(),
        role: MessageRole.user,
        kind: MessageKind.attachments,
        sentTz: DateTime.now().timeZoneName,
      );
      for (var i = 0; i < kept.length; i++) {
        await s.attachments.linkToMessage(
          messageId: message.id,
          attachmentId: kept[i].attachment.id,
          position: i,
          duplicateAcknowledged: kept[i].duplicateAcknowledged,
        );
      }
      final doc = await s.medicalDocuments.create(
        pages: [
          for (var i = 0; i < kept.length; i++)
            MedicalPageRef(
              attachmentId: kept[i].attachment.id,
              messageId: message.id,
              pageNo: i + 1,
            ),
        ],
        docType: widget.physicalExam
            ? MedicalDocType.physicalExam
            : MedicalDocType.other,
      );
      await _load();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MedicalDocumentPage(
                services: widget.services, documentId: doc.id)),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askDuplicate(Attachment existing, String filename) {
    final imported = DateTime.fromMillisecondsSinceEpoch(
            existing.firstImportedAt,
            isUtc: true)
        .toLocal();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('这个文件已经记录过'),
        content: Text('「$filename」与 ${imported.year}-${imported.month} 月导入的'
            '文件内容相同。仍要加进这份医疗文件吗？（不会重复占用空间）'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'add'),
              child: const Text('仍然添加')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _docs.isEmpty
          ? Center(
              child: Text(
                widget.physicalExam
                    ? '还没有体检报告\n点右下角添加拍照或 PDF'
                    : '还没有病历或检查报告\n点右下角添加拍照或 PDF',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: _docs.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = _docs[i];
                final pages = MedicalPageRef.decodeList(d.pages);
                final uploaded = DateTime.fromMillisecondsSinceEpoch(
                        d.uploadedAt,
                        isUtc: true)
                    .toLocal();
                final subtitle = [
                  if (d.institutionText != null) d.institutionText!,
                  '${pages.length} 页',
                  '上传于 ${uploaded.year}-${uploaded.month.toString().padLeft(2, '0')}-${uploaded.day.toString().padLeft(2, '0')}',
                ].join(' · ');
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(medicalDocTypeLabels[d.docType]!),
                  subtitle: Text(subtitle),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MedicalDocumentPage(
                              services: widget.services, documentId: d.id)),
                    );
                    await _load();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _add,
        tooltip: '添加',
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
      ),
    );
  }
}
