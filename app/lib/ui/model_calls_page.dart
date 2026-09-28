import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';

const _callerLabels = {
  ModelCaller.phoneOrganize: '手机整理',
  ModelCaller.macAnalysis: 'Mac 分析',
  ModelCaller.externalAgent: '外部 agent',
  ModelCaller.phoneMedicalExtract: '检验单提取',
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
            return const Center(child: CircularProgressIndicator());
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
              const SizedBox(height: 4),
              Text('发送的消息 ID：${call.sentMessageIds}'),
              if (_sentAttachmentCount > 0)
                Text('发送的附件 ID：${call.sentAttachmentIds}'),
              if (call.responseText != null) ...[
                const SizedBox(height: 4),
                Text('返回内容：${call.responseText}'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
