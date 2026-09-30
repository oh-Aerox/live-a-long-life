import 'dart:io';

import 'package:flutter/material.dart';

import 'desktop_text.dart';
import 'markdown_text.dart';
import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';

/// 主动咨询（D-26）：临时问模型一些建议。问答不进消息流、不参与整理、
/// 不生成记录；要记录咨询里提到的事，回消息流正常录入。
class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key, required this.services});

  final AppServices services;

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String _sessionId = const IdGenerator().newId();
  List<ConsultMessage> _messages = [];
  bool _includeRecent = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final latest = await widget.services.consult.latestSessionId();
    if (latest != null) {
      _sessionId = latest;
      await _reload();
    }
  }

  Future<void> _reload() async {
    final msgs = await widget.services.consult.messagesOf(_sessionId);
    if (mounted) {
      setState(() => _messages = msgs);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() => _sending = true);
    try {
      final future = widget.services.consult.ask(
        _sessionId,
        text,
        includeRecentRecords: _includeRecent,
      );
      await _reload(); // 先显示自己的提问
      await future;
      await _reload();
    } catch (e) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('咨询失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _newSession() {
    setState(() {
      _sessionId = const IdGenerator().newId();
      _messages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('咨询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: '新对话',
            onPressed: _messages.isEmpty ? null : _newSession,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '临时想问点什么就在这里问。\n\n'
                        '提问会附带基本资料和已确认的状况档案，让建议贴合你；'
                        '发送了什么在"模型调用记录"里可查。\n\n'
                        '咨询是问答不是录入：这里聊的不会变成健康记录，'
                        '要记录的事请回消息流正常发。'
                        // 电脑端（D-29）：用电脑的模型，咨询历史不同步。
                        '${Platform.isMacOS || Platform.isWindows ? desktopText('\n\n在 Mac 上用这台 Mac 配置的模型；这里的咨询记录只存在这台 Mac，和手机上的咨询互不相通。') : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, height: 1.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 模型回复是 Markdown；用户原话按原样显示。
                              isUser
                                  ? SelectableText(m.body)
                                  : MarkdownText(m.body),
                              if (isUser && m.contextNote != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '发送了：${m.contextNote}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: scheme.onSurfaceVariant),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _includeRecent,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) =>
                            setState(() => _includeRecent = v ?? false),
                      ),
                      const Expanded(
                        child: Text('附带最近 7 天记录摘要（默认不带）',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: '想问点什么…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : _send,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
