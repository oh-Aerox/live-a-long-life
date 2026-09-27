import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/data_boundary.dart';
import '../services/model_client.dart';
import 'model_calls_page.dart';

const _boundaryLabels = {
  DataBoundary.device: '本机',
  DataBoundary.lan: '局域网',
  DataBoundary.cloud: '云端',
};

/// 已探测的能力标签（schema §4.3，由测试连接写入）。
String _capabilityLabel(ModelConfig c) {
  final caps = (jsonDecode(c.capabilities) as List).cast<String>();
  if (caps.isEmpty) return '能力未探测';
  return caps.contains('image') ? '文本+图片' : '仅文本';
}

/// 模型配置列表（product-spec §4、D-16）。
class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key, required this.services});

  final AppServices services;

  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  List<ModelConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final configs = await widget.services.modelConfigs.all();
    if (mounted) setState(() => _configs = configs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型'), actions: [
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          tooltip: '调用记录',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ModelCallsPage(services: widget.services)),
          ),
        ),
      ]),
      body: ListView(
        children: [
          if (_configs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('还没有配置模型。没有模型时录入照常可用，'
                  '消息会显示"待整理"，配置后可以补整理。'),
            ),
          for (final c in _configs)
            ListTile(
              title: Text(
                  '${ModelPresetDefaults.byPreset[c.preset]?.label ?? c.preset.name} · ${c.model}'),
              subtitle: Text(
                  '${_boundaryLabels[c.dataBoundary]} · ${_capabilityLabel(c)} · ${c.lastTestResult ?? "未测试"}'),
              leading: c.isDefault
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.circle_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ModelConfigEditPage(
                          services: widget.services, existing: c)),
                );
                await _load();
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ModelConfigEditPage(services: widget.services)),
          );
          await _load();
        },
      ),
    );
  }
}

/// 新增 / 编辑一个模型配置：预设 → base_url、key、模型名 → 测试连接 → 设默认。
class ModelConfigEditPage extends StatefulWidget {
  const ModelConfigEditPage(
      {super.key, required this.services, this.existing});

  final AppServices services;
  final ModelConfig? existing;

  @override
  State<ModelConfigEditPage> createState() => _ModelConfigEditPageState();
}

class _ModelConfigEditPageState extends State<ModelConfigEditPage> {
  ModelPreset _preset = ModelPreset.anthropic;
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  bool _makeDefault = false;
  bool _busy = false;
  String? _testResult;

  ModelPresetDefaults get _defaults => ModelPresetDefaults.byPreset[_preset]!;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _preset = existing.preset;
      _baseUrl.text = existing.baseUrl;
      _model.text = existing.model;
      _makeDefault = existing.isDefault;
      _testResult = existing.lastTestResult;
      // key 不回显：留空表示沿用 Keychain 里已存的。
    } else {
      _applyPresetDefaults();
    }
  }

  void _applyPresetDefaults() {
    _baseUrl.text = _defaults.baseUrl;
    _model.clear();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save({required bool testAfter}) async {
    final baseUrl = _baseUrl.text.trim();
    final model = _model.text.trim();
    final key = _apiKey.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (baseUrl.isEmpty || model.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请填写地址和模型名')));
      return;
    }
    if (widget.existing == null && key.isEmpty && _defaults.needsKey) {
      messenger.showSnackBar(const SnackBar(content: Text('请填写 API key')));
      return;
    }
    setState(() => _busy = true);
    try {
      final s = widget.services;
      ModelConfig config;
      if (widget.existing == null) {
        config = await s.modelConfigs.add(
          preset: _preset,
          protocol: _defaults.protocol,
          baseUrl: baseUrl,
          model: model,
          dataBoundary: inferDataBoundary(baseUrl),
          keychainRef: '',
          makeDefault: _makeDefault,
        );
        final ref = await s.keyStore.save(config.id, key);
        config = await s.modelConfigs.setKeychainRef(config.id, ref);
      } else {
        config = await s.modelConfigs.updateEndpoint(
          widget.existing!.id,
          baseUrl: baseUrl,
          model: model,
          dataBoundary: inferDataBoundary(baseUrl),
        );
        if (key.isNotEmpty) {
          await s.keyStore.save(config.id, key);
        }
        if (_makeDefault && !widget.existing!.isDefault) {
          await s.modelConfigs.setDefault(config.id);
        }
      }
      if (testAfter) {
        final apiKey = await s.keyStore.read(config.keychainRef) ?? '';
        final result = await ModelClient()
            .testConnection(config: config, apiKey: apiKey);
        await s.modelConfigs.updateTestResult(
          config.id,
          result: result.message,
          capabilities: result.ok ? result.capabilities : null,
        );
        if (mounted) setState(() => _testResult = result.message);
        if (!result.ok) {
          messenger.showSnackBar(SnackBar(content: Text(result.message)));
          return; // 测试失败留在本页修改
        }
      }
      // 配好模型后补整理积压的"待整理"消息（A-10）。
      unawaited(s.organizeService.catchUp());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个模型配置？'),
        content: const Text('key 会一并从系统安全存储中移除。'
            '删除默认配置后整理会暂停在"待整理"，不会自动改用其他配置。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.services.keyStore.delete(existing.keychainRef);
    await widget.services.modelConfigs.markDeleted(existing.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final boundary = inferDataBoundary(_baseUrl.text.trim());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '添加模型' : '编辑模型'),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy ? null : _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ModelPreset>(
            initialValue: _preset,
            decoration: const InputDecoration(labelText: '服务'),
            items: [
              for (final e in ModelPresetDefaults.byPreset.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value.label)),
            ],
            onChanged: widget.existing != null
                ? null // 服务类型不可改，删了重建
                : (v) => setState(() {
                      _preset = v!;
                      _applyPresetDefaults();
                    }),
          ),
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(labelText: '服务地址（base URL）'),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _model,
            decoration: InputDecoration(
                labelText: '模型名', hintText: _defaults.modelHint),
            autocorrect: false,
          ),
          TextField(
            controller: _apiKey,
            decoration: InputDecoration(
              labelText: 'API key',
              hintText: widget.existing != null
                  ? '留空则沿用已保存的 key'
                  : (_defaults.needsKey ? '' : 'Ollama 通常不需要'),
              helperText: 'key 只存在系统安全存储里，不进数据库、导出和备份',
            ),
            obscureText: true,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('数据边界'),
            subtitle: const Text('整理时消息会发给这个服务'),
            trailing: Text(_boundaryLabels[boundary]!,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('设为默认模型'),
            value: _makeDefault,
            onChanged: (v) => setState(() => _makeDefault = v),
          ),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('最近测试：$_testResult'),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _save(testAfter: true),
            child: Text(_busy ? '测试中…' : '测试连接并保存'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _save(testAfter: false),
            child: const Text('直接保存'),
          ),
        ],
      ),
    );
  }
}
