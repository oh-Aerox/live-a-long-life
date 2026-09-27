import 'dart:io';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';

/// Mac 端消息流（V3-M4）：手机同步来的副本，只读（D-12）。
class MacMessagesPage extends StatelessWidget {
  const MacMessagesPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息（副本，只读）')),
      body: StreamBuilder<List<Message>>(
        stream: services.messages.watchThread(),
        builder: (context, snapshot) {
          final messages = snapshot.data ?? const <Message>[];
          if (messages.isEmpty) {
            return const Center(child: Text('还没有同步来的消息'));
          }
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              final showDay = i == 0 ||
                  _dayOf(messages[i - 1].sentAt) != _dayOf(m.sentAt);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDay)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(_dayOf(m.sentAt),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                  _bubble(context, m),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _dayOf(int sentAtMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(sentAtMs).toLocal();
    return '${t.year}年${t.month}月${t.day}日';
  }

  Widget _bubble(BuildContext context, Message m) {
    if (m.kind == MessageKind.doneMarker) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('— 记好了 —',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }
    final isUser = m.role == MessageRole.user;
    final Widget content = m.kind == MessageKind.attachments
        ? _MacAttachmentTiles(services: services, messageId: m.id)
        : Text(
            (m.body ?? '') + (m.revisionNo > 0 ? '（已编辑）' : ''),
            style: TextStyle(color: isUser ? Colors.white : null),
          );
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 480),
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
}

class _MacAttachmentTiles extends StatelessWidget {
  const _MacAttachmentTiles({required this.services, required this.messageId});

  final AppServices services;
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(MessageAttachment, Attachment)>>(
      future: services.attachments.attachmentsOf(messageId),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final (_, a) in rows)
              if (a.mimeType.startsWith('image/'))
                FutureBuilder<String?>(
                  future: services.attachments.localPathOf(a.id),
                  builder: (context, pathSnap) {
                    final path = pathSnap.data;
                    return path == null
                        ? const SizedBox(
                            width: 84,
                            height: 84,
                            child: Icon(Icons.image_outlined))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(File(path),
                                width: 84, height: 84, fit: BoxFit.cover),
                          );
                  },
                )
              else
                Chip(
                  avatar: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(a.originalFilename ?? 'PDF',
                      style: const TextStyle(fontSize: 12)),
                ),
          ],
        );
      },
    );
  }
}
