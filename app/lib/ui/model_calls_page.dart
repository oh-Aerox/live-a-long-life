import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';

const _callerLabels = {
  ModelCaller.phoneOrganize: '手机整理',
  ModelCaller.macAnalysis: 'Mac 分析',
  ModelCaller.externalAgent: '外部 agent',
  ModelCaller.phoneMedicalExtract: '医疗文件提取',
  ModelCaller.userConsult: '主动咨询',
};

const _statusLabels = {
  ModelCallStatus.succeeded: '成功',
  ModelCallStatus.failed: '失败',
  ModelCallStatus.timeout: '超时',
};

/// 模型调用记录（D-16 透明度：每次调用发送了什么可以查看）。
class ModelCallsPage extends StatelessWidget {
  const ModelCallsPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型调用记录')),
      body: FutureBuilder<List<ModelCall>>(
        future: services.organize.recentModelCalls(),
        builder: (context, snapshot) {
          final calls = snapshot.data;
          if (calls == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (calls.isEmpty) {
            return const Center(child: Text('还没有调用过模型'));
          }
          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, i) => _CallTile(call: calls[i]),
          );
        },
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final ModelCall call;

  int get _sentMessageCount =>
      (jsonDecode(call.sentMessageIds) as List).length;
  int get _sentAttachmentCount =>
      (jsonDecode(call.sentAttachmentIds) as List).length;

  @override
  Widget build(BuildContext context) {
    final t = DateTime.fromMillisecondsSinceEpoch(call.requestAt).toLocal();
    final time =
        '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final boundary = switch (call.dataBoundary) {
      DataBoundary.device => '本机',
      DataBoundary.lan => '局域网',
      DataBoundary.cloud => '云端',
    };
    return ExpansionTile(
      title: Text('$time · ${_statusLabels[call.status]}'),
      subtitle: Text('${_callerLabels[call.caller]} · $boundary · '
          '发送 $_sentMessageCount 条消息、$_sentAttachmentCount 个附件'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (call.tokensIn != null || call.tokensOut != null)
                Text('token：输入 ${call.tokensIn ?? "—"}，'
                    '输出 ${call.tokensOut ?? "—"}'),
              if (call.redactedCount != null)
                Text('发送前自动遮蔽：${call.redactedCount} 处'),
              if (call.sentSummary != null) Text('发送范围：${call.sentSummary}'),
              const SizedBox(height: 4),
              if (_sentMessageCount > 0)
                Text('发送的消息 ID：${call.sentMessageIds}'),
              if (_sentAttachmentCount > 0)
                Text('发送的附件 ID：${call.sentAttachmentIds}'),
              _Payload(
                title: '发送的内容',
                text: call.requestText,
                note: '另附固定的系统提示词（规则说明，不含个人数据）',
                missing: '这条调用发生在保存发送内容之前，只能看到上面的发送范围',
              ),
              _Payload(title: '返回的内容', text: call.responseText),
            ],
          ),
        ),
      ],
    );
  }
}

/// 一段可展开查看、可选中复制的内容；JSON 缩进排版便于阅读。
class _Payload extends StatelessWidget {
  const _Payload(
      {required this.title, required this.text, this.note, this.missing});

  final String title;
  final String? text;
  final String? note;
  final String? missing;

  static String _pretty(String raw) {
    final t = raw.trim();
    if (!(t.startsWith('{') || t.startsWith('['))) return raw;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(t));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(
        fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant);
    if (text == null) {
      return missing == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$title：$missing', style: grey),
            );
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      title: Text('$title（${text!.length} 字）'),
      subtitle: note == null ? null : Text(note!, style: grey),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SelectableText(_pretty(text!),
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ),
      ],
    );
  }
}
