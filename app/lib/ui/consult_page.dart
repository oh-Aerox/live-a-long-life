import 'dart:io';

import 'package:flutter/material.dart';

import 'desktop_text.dart';
import 'markdown_text.dart';
import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../services/app_log.dart';
import '../services/consult_service.dart';
import '../services/consult_suggestions.dart';

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
  final _focus = FocusNode();
  String _sessionId = const IdGenerator().newId();
  List<ConsultMessage> _messages = [];
  bool _allowLookup = true;
  bool _sending = false;

  /// 生成中的回答（流式）；没在生成时为 null。
  ConsultProgress? _progress;

  /// 示例问题（D-45）：新对话时展开，发出第一问后收起，可用灯泡按钮再打开。
  List<SuggestionGroup> _groups = [];
  String? _openGroup;
  bool _showSuggestions = true;

  static const _groupIcons = {
    'sleep': Icons.bedtime_outlined,
    'exercise': Icons.directions_run_outlined,
    'vitals': Icons.monitor_heart_outlined,
    'labs': Icons.science_outlined,
    'reports': Icons.description_outlined,
    'conditions': Icons.health_and_safety_outlined,
    'daily': Icons.restaurant_outlined,
    'general': Icons.lightbulb_outline,
  };

  @override
  void initState() {
    super.initState();
    _restore();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final groups = await widget.services.consult.suggestions();
      if (mounted) setState(() => _groups = groups);
    } catch (e, st) {
      // 示例问题只是辅助，生成失败不影响提问。
      AppLog.I.e('consult', '示例问题生成失败', e, st);
    }
  }

  /// 点示例问题：填进输入框，可以改了再发。
  void _useQuestion(String q) {
    _input.text = q;
    _input.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _openGroup = null);
    _focus.requestFocus();
  }

  Future<void> _restore() async {
    final allow = await widget.services.settings
        .get(ConsultService.allowLookupKey) as bool?;
    if (allow != null && mounted) setState(() => _allowLookup = allow);
    final latest = await widget.services.consult.latestSessionId();
    if (latest != null) {
      _sessionId = latest;
      await _reload();
      if (_messages.isNotEmpty && mounted) {
        setState(() => _showSuggestions = false);
      }
    }
  }

  Future<void> _reload() async {
    final msgs = await widget.services.consult.messagesOf(_sessionId);
    if (mounted) {
      setState(() => _messages = msgs);
      _scrollToEnd();
    }
  }

  /// 滚到底。[onlyIfNear] 为真时只在本来就停在底部附近才跟随，
  /// 用户往上翻着看时不打扰。
  void _scrollToEnd({bool onlyIfNear = false}) {
    if (onlyIfNear &&
        _scroll.hasClients &&
        _scroll.position.maxScrollExtent - _scroll.offset > 80) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _onProgress(ConsultProgress p) {
    if (!mounted) return;
    // 第一次回调时问题已存好：刷新出自己的提问。
    if (_progress == null) _reload();
    setState(() => _progress = p);
    _scrollToEnd(onlyIfNear: true);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _showSuggestions = false;
      _openGroup = null;
    });
    try {
      await widget.services.consult.ask(
        _sessionId,
        text,
        allowLookup: _allowLookup,
        onProgress: _onProgress,
      );
      await _reload();
    } catch (e) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('咨询失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _progress = null;
        });
      }
    }
  }

  void _newSession() {
    setState(() {
      _sessionId = const IdGenerator().newId();
      _messages = [];
      _showSuggestions = true;
    });
    _loadSuggestions();
  }

  Widget _suggestionPanel(ColorScheme scheme) {
    final open = _groups.where((g) => g.key == _openGroup).firstOrNull;
    final locked = open != null && open.needsLookup && !_allowLookup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (open != null) ...[
          for (final q in open.questions)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.chevron_right, size: 18),
              minLeadingWidth: 0,
              title: Text(q),
              enabled: !locked,
              onTap: () => _useQuestion(q),
            ),
          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text('打开下面的"允许模型查阅我的记录"后可问',
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ),
        ],
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final g in _groups)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(_groupIcons[g.key], size: 16),
                    label: Text(g.label),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selected: g.key == _openGroup,
                    onSelected: (on) =>
                        setState(() => _openGroup = on ? g.key : null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 生成中的回答：文字边到边显示；还没出字时显示在想或查了什么。
  Widget _draftBubble(ConsultProgress p, ColorScheme scheme) {
    final status = p.draft.isNotEmpty
        ? '回答中…'
        : p.lookups.isEmpty
            ? '思考中…'
            : '已查阅：${p.lookups.join('、')}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.draft.isNotEmpty) MarkdownText(p.draft),
            Padding(
              padding: EdgeInsets.only(top: p.draft.isEmpty ? 0 : 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator.adaptive(
                          strokeWidth: 1.5)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            child: _messages.isEmpty && _progress == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '有什么想问的？可以直接问，也可以从下面的问题开始。\n'
                        '我会结合你的资料和记录来回答，查了什么列在问题下方。\n\n'
                        '这里聊的不会变成健康记录；发送了什么在"模型调用记录"里可查。'
                        // 电脑端（D-29）：用电脑的模型，咨询历史不同步。
                        '${Platform.isMacOS || Platform.isWindows ? desktopText('\n\n电脑端的咨询用电脑端配置的模型；咨询记录只存在电脑端，和手机上的咨询互不相通。') : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, height: 1.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_progress == null ? 0 : 1),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return _draftBubble(_progress!, scheme);
                      }
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                children: [
                  if (_showSuggestions && _groups.isNotEmpty)
                    _suggestionPanel(scheme),
                  Row(
                    children: [
                      Checkbox(
                        value: _allowLookup,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) {
                          setState(() => _allowLookup = v ?? false);
                          widget.services.settings.set(
                              ConsultService.allowLookupKey, _allowLookup);
                        },
                      ),
                      // D-43：模型按需查记录、健康数据、检验和报告结论，
                      // 查了什么列在问题下方。
                      const Expanded(
                        child: Text('允许模型查阅我的记录（查了什么会列在问题下方）',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_showSuggestions
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline),
                        tooltip: '示例问题',
                        onPressed: _groups.isEmpty
                            ? null
                            : () => setState(() {
                                  _showSuggestions = !_showSuggestions;
                                  _openGroup = null;
                                }),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _focus,
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
