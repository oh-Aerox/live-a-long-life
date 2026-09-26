import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/attachment_repository.dart';

/// 对话页（product-spec §3 v0.1 页面）。
/// 消息按 seq 排列、按天分组；发送即保存并显示"已保存"；
/// 附件复制进应用存储并校验后才出现在对话流（即"已保存"）。
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.services, required this.tz});

  final AppServices services;

  /// 当前 IANA 时区名，启动时检测。
  final String tz;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ids = const IdGenerator();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  /// 正在保存的附件批次数（>0 时输入栏显示进度）。
  int _savingBatches = 0;

  /// 消息 ID → 列表内 key，用于"查看已有"跳转。
  final _messageKeys = <String, GlobalKey>{};

  AppServices get _s => widget.services;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _s.messages.send(
      clientMsgId: _ids.newId(),
      role: MessageRole.user,
      kind: MessageKind.text,
      text: text,
      sentTz: widget.tz,
    );
  }

  Future<void> _sendDoneMarker() async {
    await _s.messages.send(
      clientMsgId: _ids.newId(),
      role: MessageRole.user,
      kind: MessageKind.doneMarker,
      sentTz: widget.tz,
    );
  }

  // ---- 附件导入 ----

  static String _mimeOf(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _showAttachSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('选照片（可多选）'),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('导入文件（PDF 或图片）'),
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
    await _importPaths(paths);
  }

  /// 导入一批文件：逐个落盘校验，重复内容给三选项提示（D-10、A-03），
  /// 保留下来的附件合成一条消息，顺序即选择顺序（A-01）。
  Future<void> _importPaths(List<String> paths) async {
    setState(() => _savingBatches++);
    try {
      final kept = <({Attachment attachment, bool duplicateAcknowledged})>[];
      for (final path in paths) {
        final name = p.basename(path);
        final ImportResult result;
        try {
          result = await _s.attachments.importFile(
            File(path),
            mimeType: _mimeOf(path),
            originalFilename: name,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「$name」保存失败：$e')));
          }
          continue;
        }
        if (!result.isDuplicate) {
          kept.add((attachment: result.attachment, duplicateAcknowledged: false));
          continue;
        }
        if (!mounted) return;
        final action = await _askDuplicate(result.attachment, name);
        switch (action) {
          case 'add':
            kept.add(
                (attachment: result.attachment, duplicateAcknowledged: true));
          case 'view':
            await _revealExisting(result.attachment);
          default:
            break; // 取消：跳过这个文件
        }
      }
      if (kept.isEmpty) return;

      final message = await _s.messages.send(
        clientMsgId: _ids.newId(),
        role: MessageRole.user,
        kind: MessageKind.attachments,
        sentTz: widget.tz,
      );
      for (var i = 0; i < kept.length; i++) {
        await _s.attachments.linkToMessage(
          messageId: message.id,
          attachmentId: kept[i].attachment.id,
          position: i,
          duplicateAcknowledged: kept[i].duplicateAcknowledged,
        );
      }
    } finally {
      if (mounted) setState(() => _savingBatches--);
    }
  }

  Future<String?> _askDuplicate(Attachment existing, String filename) {
    final imported = DateTime.fromMillisecondsSinceEpoch(
        existing.firstImportedAt,
        isUtc: true).toLocal();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('这个文件已经记录过'),
        content: Text(
            '「$filename」与 ${imported.month}月${imported.day}日 导入的文件内容完全相同。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'view'),
            child: const Text('查看已有'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'add'),
            child: const Text('仍然添加'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _revealExisting(Attachment attachment) async {
    final ids = await _s.attachments.messageIdsReferencing(attachment.id);
    if (ids.isEmpty || !mounted) return;
    final key = _messageKeys[ids.first];
    final targetContext = key?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(targetContext,
          duration: const Duration(milliseconds: 400), alignment: 0.3);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已有记录在更早的历史里，往上翻可以看到')));
    }
  }

  // ---- 显示 ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长寿记')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _s.messages.watchThread(),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <Message>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('想到什么，随手记下来',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return _buildList(messages);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildList(List<Message> messages) {
    // 组装为（日期头 + 消息）的条目列表，倒序显示（最新在底部）。
    final items = <Widget>[];
    String? lastDate;
    String? lastUserMessageId;
    for (final m in messages) {
      if (m.role == MessageRole.user) lastUserMessageId = m.id;
    }
    for (final m in messages) {
      final local = DateTime.fromMillisecondsSinceEpoch(m.sentAt, isUtc: true)
          .toLocal();
      final dateLabel = local.year == DateTime.now().year
          ? '${local.month}月${local.day}日'
          : '${local.year}年${local.month}月${local.day}日';
      if (dateLabel != lastDate) {
        lastDate = dateLabel;
        items.add(Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(dateLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ));
      }
      final key = _messageKeys.putIfAbsent(m.id, GlobalKey.new);
      items.add(KeyedSubtree(key: key, child: _buildMessage(m)));
      if (m.id == lastUserMessageId) {
        items.add(Padding(
          padding: EdgeInsets.only(
              top: 2,
              bottom: 4,
              right: m.role == MessageRole.user ? 12 : 0),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Text('✓ 已保存',
                style: TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ));
      }
    }
    final reversed = items.reversed.toList();
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reversed.length,
      itemBuilder: (context, index) => reversed[index],
    );
  }

  Widget _buildMessage(Message m) {
    if (m.kind == MessageKind.doneMarker) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('— 记好了 —',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }
    final isUser = m.role == MessageRole.user;
    final Widget content;
    if (m.kind == MessageKind.attachments) {
      content = _AttachmentTiles(services: _s, messageId: m.id);
    } else {
      content = Text(m.body ?? '',
          style: TextStyle(color: isUser ? Colors.white : null));
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_savingBatches > 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('正在保存附件…', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '添加照片或文件',
                  onPressed: _savingBatches > 0 ? null : _showAttachSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '说点什么…',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) =>
                      value.text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: '发送',
                              onPressed: _sendText,
                            )
                          : TextButton(
                              onPressed: _sendDoneMarker,
                              child: const Text('记好了'),
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 一条附件消息里的缩略图或文件卡片，按 position 排列（A-01）。
class _AttachmentTiles extends StatelessWidget {
  const _AttachmentTiles({required this.services, required this.messageId});

  final AppServices services;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(MessageAttachment, Attachment)>>(
      future: services.attachments.attachmentsOf(messageId),
      builder: (context, snapshot) {
        final rows = snapshot.data;
        if (rows == null) {
          return const SizedBox(
              width: 60,
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [for (final (_, a) in rows) _tile(context, a)],
        );
      },
    );
  }

  Widget _tile(BuildContext context, Attachment a) {
    if (a.mimeType.startsWith('image/')) {
      return FutureBuilder<String?>(
        future: services.attachments.localPathOf(a.id),
        builder: (context, snapshot) {
          final path = snapshot.data;
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: path != null
                ? Image.file(File(path),
                    width: 84, height: 84, fit: BoxFit.cover)
                : Container(
                    width: 84,
                    height: 84,
                    color: Colors.black12,
                    child: const Icon(Icons.image_not_supported_outlined)),
          );
        },
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 18),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              a.originalFilename ?? 'PDF',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
