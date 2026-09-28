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

  /// 删除一个配置：确认后清 Keychain 里的 key 并标记删除。
  /// 删的是默认配置时，剩下的第一个自动补为默认，避免没有默认可用。
  Future<void> _delete(ModelConfig c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个模型配置？'),
        content: Text(
            '${ModelPresetDefaults.byPreset[c.preset]?.label ?? c.preset.name} · ${c.model}\n'
            'key 会一并从系统安全存储中移除。'),
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
    if (confirmed != true) return;
    final s = widget.services;
    if (c.keychainRef.isNotEmpty) await s.keyStore.delete(c.keychainRef);
    await s.modelConfigs.markDeleted(c.id);
    // 删掉的是默认、还有其他配置时，补一个默认。
    if (c.isDefault) {
      final rest = await s.modelConfigs.all();
      if (rest.isNotEmpty) await s.modelConfigs.setDefault(rest.first.id);
    }
    await _load();
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
          if (_configs.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('点左侧圆圈设为默认（整理和周报用默认模型）',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          for (final c in _configs)
            ListTile(
              title: Text(
                  '${ModelPresetDefaults.byPreset[c.preset]?.label ?? c.preset.name} · ${c.model}'),
              subtitle: Text(
                  '${_boundaryLabels[c.dataBoundary]} · ${_capabilityLabel(c)} · ${c.lastTestResult ?? "未测试"}'),
              // 点圆圈直接设默认，不进配置页。
              leading: IconButton(
                icon: Icon(
                  c.isDefault ? Icons.check_circle : Icons.circle_outlined,
                  color: c.isDefault ? Colors.green : null,
                ),
                tooltip: c.isDefault ? '当前默认' : '设为默认',
                onPressed: c.isDefault
                    ? null
                    : () async {
                        await widget.services.modelConfigs.setDefault(c.id);
                        await _load();
                      },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '编辑',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ModelConfigEditPage(
                                services: widget.services, existing: c)),
                      );
                      await _load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除',
                    onPressed: () => _delete(c),
                  ),
                ],
              ),
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

  /// 正在编辑的配置 id：进来时是 existing?.id；新增页首次保存后记下来，
  /// 之后重试测试都是更新同一条，不再重复新增（修复失败重试堆积）。
  String? _editingId;

  ModelPresetDefaults get _defaults => ModelPresetDefaults.byPreset[_preset]!;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _editingId = existing.id;
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
    if (_editingId == null && key.isEmpty && _defaults.needsKey) {
      messenger.showSnackBar(const SnackBar(content: Text('请填写 API key')));
      return;
    }
    setState(() => _busy = true);
    try {
      final s = widget.services;
      ModelConfig config;
      if (_editingId == null) {
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
        _editingId = config.id; // 记下：后续重试是更新，不再新增
      } else {
        config = await s.modelConfigs.updateEndpoint(
          _editingId!,
          baseUrl: baseUrl,
          model: model,
          dataBoundary: inferDataBoundary(baseUrl),
        );
        if (key.isNotEmpty) {
          await s.keyStore.save(config.id, key);
        }
        if (_makeDefault && !config.isDefault) {
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
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('最近测试结果',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  // 可选中复制：中转站的原始返回片段会显示在这里，便于排查。
                  SelectableText(_testResult!,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
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
