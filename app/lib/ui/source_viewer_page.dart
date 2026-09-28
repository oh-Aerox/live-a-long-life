import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_services.dart';
import '../services/text_extraction.dart';

/// 定位回原件（A-19）：显示某个检验数值来自原件的哪一页哪个区域。
/// 图片直接显示；PDF 用本地渲染出对应页。有坐标画高亮框，
/// 文字层直取无坐标时显示原文行。
class SourceViewerPage extends StatefulWidget {
  const SourceViewerPage({
    super.key,
    required this.services,
    required this.locator,
    required this.title,
  });

  final AppServices services;

  /// 记录 data 里的 locator 项：attachment_id、page_no、attachment_page、
  /// box{x,y,w,h}（可空）、line_text。
  final Map<String, Object?> locator;
  final String title;

  @override
  State<SourceViewerPage> createState() => _SourceViewerPageState();
}

class _SourceViewerPageState extends State<SourceViewerPage> {
  ui.Image? _image;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final attachmentId = widget.locator['attachment_id'] as String;
      final att = await widget.services.attachments.byId(attachmentId);
      final path = await widget.services.attachments.localPathOf(attachmentId);
      if (att == null || path == null) {
        setState(() => _error = '原件当前不在本机（可能已清理），历史数据保留');
        return;
      }
      String imagePath = path;
      if (att.mimeType == 'application/pdf') {
        final page = (widget.locator['attachment_page'] as int? ?? 1) - 1;
        final out = p.join(Directory.systemTemp.path,
            'src_view_${att.sha256.substring(0, 12)}_$page.png');
        imagePath =
            await PlatformTextExtractor().renderPdfPage(path, page, out);
      }
      final bytes = await File(imagePath).readAsBytes();
      final image = await decodeImageFromList(bytes);
      if (mounted) setState(() => _image = image);
    } catch (e) {
      if (mounted) setState(() => _error = '无法打开原件：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.locator['box'] as Map?;
    final lineText = widget.locator['line_text'] as String?;
    final pageNo = widget.locator['page_no'];

    Widget body;
    if (_error != null) {
      body = Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!, textAlign: TextAlign.center),
      ));
    } else if (_image == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final image = _image!;
      body = InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: AspectRatio(
            aspectRatio: image.width / image.height,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                fit: StackFit.expand,
                children: [
                  RawImage(image: image, fit: BoxFit.fill),
                  if (box != null)
                    Positioned(
                      left: (box['x'] as num).toDouble() * c.maxWidth - 4,
                      top: (box['y'] as num).toDouble() * c.maxHeight - 4,
                      width: (box['w'] as num).toDouble() * c.maxWidth + 8,
                      height: (box['h'] as num).toDouble() * c.maxHeight + 8,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} · 第 $pageNo 页')),
      body: Column(
        children: [
          Expanded(child: body),
          if (box == null && lineText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text('原文（该页为 PDF 文字层，无区域坐标）：\n$lineText',
                  style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
