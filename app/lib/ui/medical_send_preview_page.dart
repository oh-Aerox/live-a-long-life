import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/medical_extraction_service.dart';
import '../services/redaction.dart';
import '../services/text_extraction.dart' show PageTextSource;

/// 发送前预览（D-28）：本地识别 + 脱敏的结果逐行展示，这里看到的就是
/// 将要发给模型的全部文字。用户可改写或删除任意行、切换每页是否发送，
/// 确认后才调用模型。返回提取结果；用户返回则什么都不发。
class MedicalSendPreviewPage extends StatefulWidget {
  const MedicalSendPreviewPage(
      {super.key, required this.services, required this.documentId});

  final AppServices services;
  final String documentId;

  @override
  State<MedicalSendPreviewPage> createState() => _MedicalSendPreviewPageState();
}

class _MedicalSendPreviewPageState extends State<MedicalSendPreviewPage> {
  SendDraft? _draft;
  ModelConfig? _config;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// 本地准备草稿；切换页后重新准备，但保留用户已做的行修改。
  Future<void> _prepare() async {
    try {
      final old = _draft;
      final draft = await widget.services.medicalExtraction
          .prepareSend(widget.documentId);
      if (old != null) draft.edits.addAll(old.edits);
      final config = await widget.services.modelConfigs.defaultConfig();
      if (mounted) {
        setState(() {
          _draft = draft;
          _config = config;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _togglePage(DraftPage page) async {
    await widget.services.medicalDocuments
        .setPageOverride(widget.documentId, page.pageNo, !page.included);
    await _prepare();
  }

  Future<void> _editLine(DraftPage page, int index) async {
    final draft = _draft!;
    final ctl = TextEditingController(text: draft.lineText(page, index));
    final original = page.lines[index].text;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('第 ${page.pageNo} 页第 ${index + 1} 行'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
              helperText: '改掉不想发送的内容；清空 = 这行不发送'),
        ),
        actions: [
          if (draft.isEdited(page, index))
            TextButton(
                onPressed: () => Navigator.pop(context, '\u0000reset'),
                child: const Text('恢复')),
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('删掉这行')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctl.text),
              child: const Text('保存')),
        ],
      ),
    );
    if (result == null) return;
    final key = SendDraft.lineKey(page.pageNo, index);
    setState(() {
      if (result == '\u0000reset' || result == original) {
        draft.edits.remove(key);
      } else {
        draft.edits[key] = result;
      }
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final outcome =
          await widget.services.medicalExtraction.sendDraft(_draft!);
      if (mounted) Navigator.pop(context, outcome);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('提取失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// 占位符高亮，让用户一眼看到哪些已被遮蔽。
  Widget _lineText(String text, {required bool edited, required bool deleted}) {
    if (deleted) {
      return const Text('（已删掉，不发送）',
          style: TextStyle(fontSize: 13, color: Colors.grey));
    }
    final spans = <TextSpan>[];
    final pattern = RegExp(
        '${RegExp.escape(RedactionService.namePlaceholder)}|'
        '${RegExp.escape(RedactionService.idPlaceholder)}|'
        '${RegExp.escape(RedactionService.cardPlaceholder)}');
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(
            backgroundColor: Color(0x3300A000), fontWeight: FontWeight.bold),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface,
          decoration: edited ? TextDecoration.underline : null,
          decorationStyle: TextDecorationStyle.dotted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('发送前确认')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('本地识别失败：$_error'),
        ),
      );
    }
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('发送前确认')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('正在本机识别文字…'),
            ],
          ),
        ),
      );
    }

    // 平铺成列表项：页头 + （发送的页）逐行。
    final items = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          '下面就是将要发给模型'
          '${_config == null ? '' : '（${_config!.model}）'}的全部文字，'
          '原图不发送。已自动遮蔽姓名、证件号、门诊卡号 ${draft.redactedCount} 处（绿色）。'
          '请检查有没有漏掉的个人信息：点任意一行可以修改或删掉。',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ];
    for (final page in draft.pages) {
      items.add(SwitchListTile(
        value: page.included,
        onChanged: _sending ? null : (_) => _togglePage(page),
        title: Text('第 ${page.pageNo} 页'
            '${page.source == PageTextSource.pdfText ? ' · 文字层' : ''}'
            '${page.included ? '' : ' · 不发送'}'),
        subtitle: Text(page.reason, style: const TextStyle(fontSize: 11)),
      ));
      if (!page.included) continue;
      for (var i = 0; i < page.lines.length; i++) {
        final text = draft.lineText(page, i);
        items.add(InkWell(
          onTap: _sending ? null : () => _editLine(page, i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                Expanded(
                  child: _lineText(text,
                      edited: draft.isEdited(page, i),
                      deleted: text.trim().isEmpty),
                ),
                if (draft.isEdited(page, i))
                  const Text(' 已改',
                      style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ),
          ),
        ));
      }
      items.add(const Divider());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('发送前确认')),
      body: ListView(children: items),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _sending || draft.includedPages.isEmpty || _config == null
                ? null
                : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            label: Text(_config == null
                ? '还没有配置模型'
                : _sending
                    ? '模型整理中（最长 3 分钟）…'
                    : '确认发送 ${draft.includedPages.length} 页、'
                        '${draft.sentLineCount} 行'),
          ),
        ),
      ),
    );
  }
}
