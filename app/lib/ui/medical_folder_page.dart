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
import '../data/time_value.dart';
import '../services/medical_duplicate.dart';
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
/// Mac 端 [readOnly]：只浏览，不添加（D-12）。
class MedicalFolderPage extends StatefulWidget {
  const MedicalFolderPage(
      {super.key,
      required this.services,
      required this.physicalExam,
      this.readOnly = false});

  final AppServices services;

  /// true = 我的体检（doc_type 为体检报告）；false = 我的病例夹（其余类型）。
  final bool physicalExam;
  final bool readOnly;

  @override
  State<MedicalFolderPage> createState() => _MedicalFolderPageState();
}

class _MedicalFolderPageState extends State<MedicalFolderPage> {
  final _picker = ImagePicker();
  final _ids = const IdGenerator();
  List<MedicalDocument> _docs = [];
  bool _busy = false;

  String get _title => widget.physicalExam ? '我的体检' : '我的病例夹';

  String get _emptyHint =>
      widget.readOnly ? '在手机上添加后同步过来' : '点右下角添加拍照或 PDF';

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
  /// D-27），再组成一份医疗文件。重复文件走 D-10 提示：内容完全相同
  /// （SHA-256）或识别文字相似（重拍、相册重新导出，[MedicalDuplicateService]）。
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
        final mime = _mimeOf(path);
        // 内容级重复：字节不同但文字相同（同一张纸重拍 / 相册重新导出）。
        // 导入前查，选"取消"就不留下孤立附件；识别结果按 SHA 缓存，提取复用。
        try {
          final file = File(path);
          final sha = await AttachmentRepository.hashFile(file);
          if (await s.attachments.bySha(sha) == null) {
            final hit = await s.medicalDuplicates
                .findSimilar(sha256: sha, file: file, mimeType: mime);
            if (hit != null) {
              if (!mounted) return;
              final action = await _askSimilar(hit, name);
              if (action == 'view') {
                if (!mounted) return;
                await _open(hit.document.id);
                return;
              }
              if (action != 'add') continue;
            }
          }
        } catch (_) {
          // 本地识别失败不挡导入，只是没有相似提示。
        }
        final ImportResult result;
        try {
          result = await s.attachments.importFile(
            File(path),
            mimeType: mime,
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
        if (action == 'view') {
          final existingDoc = await _documentOfAttachment(result.attachment.id);
          if (existingDoc != null && mounted) {
            await _open(existingDoc.id);
            return;
          }
        }
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
      await _open(doc.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String documentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MedicalDocumentPage(
              services: widget.services,
              documentId: documentId,
              readOnly: widget.readOnly)),
    );
    await _load();
  }

  Future<MedicalDocument?> _documentOfAttachment(String attachmentId) async {
    for (final d in await widget.services.medicalDocuments.all()) {
      if (MedicalPageRef.decodeList(d.pages)
          .any((r) => r.attachmentId == attachmentId)) {
        return d;
      }
    }
    return null;
  }

  static String _docLabel(MedicalDocument d) {
    final date = d.examDate == null
        ? null
        : TimeValue.decode(d.examDate!).localDate;
    final uploaded =
        DateTime.fromMillisecondsSinceEpoch(d.uploadedAt, isUtc: true).toLocal();
    return [
      medicalDocTypeLabels[d.docType]!,
      if (d.institutionText != null) d.institutionText!,
      date != null
          ? '检查日期 $date'
          : '${uploaded.month} 月 ${uploaded.day} 日添加',
    ].join(' · ');
  }

  Future<String?> _askSimilar(SimilarDocumentHit hit, String filename) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('可能已经上传过'),
        content: Text('这份文件识别出的文字与已有的「${_docLabel(hit.document)}」'
            '${(hit.textScore * 100).round()}% 相同，数字（日期、编号、结果）'
            '${(hit.numberScore * 100).round()}% 对得上，可能是同一张纸重拍或重新导出。'
            '\n\n确定是另一份报告（比如复查）可以仍然添加。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'view'),
              child: const Text('查看已有')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'add'),
              child: const Text('仍然添加')),
        ],
      ),
    );
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
              onPressed: () => Navigator.pop(context, 'view'),
              child: const Text('查看已有')),
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
                    ? '还没有体检报告\n$_emptyHint'
                    : '还没有病历或检查报告\n$_emptyHint',
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
                              services: widget.services,
                              documentId: d.id,
                              readOnly: widget.readOnly)),
                    );
                    await _load();
                  },
                );
              },
            ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
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
