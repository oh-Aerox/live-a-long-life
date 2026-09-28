import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/medical_space_service.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;

/// 医疗文件空间（D-22/schema §8）：清理手机原件，保留记录。
/// 默认勾选已提取、已核对、Mac 已归档的；清理只删本机文件，
/// 历史医疗数据、核对状态、来源索引不变，Mac 与备份不联动删除。
class MedicalSpacePage extends StatefulWidget {
  const MedicalSpacePage({super.key, required this.services});

  final AppServices services;

  @override
  State<MedicalSpacePage> createState() => _MedicalSpacePageState();
}

class _MedicalSpacePageState extends State<MedicalSpacePage> {
  List<MedicalFile> _files = [];
  final _selected = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await widget.services.medicalSpace.list();
    if (!mounted) return;
    setState(() {
      _files = files;
      _selected
        ..clear()
        ..addAll([
          for (final f in files)
            if (f.defaultSelected) f.attachment.id,
        ]);
    });
  }

  String _size(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  List<MedicalFile> get _present =>
      _files.where((f) => f.state == CopyState.present).toList();
  List<MedicalFile> get _offloaded =>
      _files.where((f) => f.state != CopyState.present).toList();

  int get _selectedBytes => _present
      .where((f) => _selected.contains(f.attachment.id))
      .fold(0, (s, f) => s + f.byteSize);

  Future<void> _cleanup() async {
    final chosen = _present
        .where((f) => _selected.contains(f.attachment.id))
        .toList();
    if (chosen.isEmpty) return;
    final noRemote = chosen.where((f) => !f.archivedOnMac).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理手机原件'),
        content: Text(
          '将清理手机上的 ${chosen.length} 份医疗文件，释放约 ${_size(_selectedBytes)}。'
          '历史医疗记录保留，Mac 上的已归档原件不受影响。'
          '${noRemote > 0 ? '\n\n注意：其中 $noRemote 份没有确认过的其他副本，清理后可能无法再查看原件（数据保留，未核对的仍是未核对）。' : ''}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清理手机原件')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final result = await widget.services.medicalSpace.cleanup(chosen);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('已释放 ${_size(result.freedBytes)}'
            '${result.failures.isEmpty ? '' : '，${result.failures.length} 份清理失败（未计入）'}'),
      ));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retrieve(MedicalFile f) async {
    setState(() => _busy = true);
    try {
      final ok = await widget.services.medicalSpace.retrieve(f.attachment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '已从 Mac 取回，原件可以查看了'
            : 'Mac 不可达或没有这份文件；提取过的数据不受影响，也可以重新上传同一文件补回'),
      ));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _fileTile(MedicalFile f, {required bool cleanable}) {
    final att = f.attachment;
    final docType = f.documentIds.isEmpty
        ? ''
        : (medicalDocTypeLabels.entries
                .where((e) => e.key.name == f.docLabel)
                .map((e) => e.value)
                .firstOrNull ??
            '医疗文件');
    final status = [
      _size(f.byteSize),
      docType,
      '引用 ${f.referenceCount} 处',
      if (f.extracted) f.reviewed ? '已核对' : '有未核对项' else '未提取',
      f.archivedOnMac ? 'Mac 已归档' : '无确认的其他副本',
    ].where((s) => s.isNotEmpty).join(' · ');

    if (cleanable) {
      return CheckboxListTile(
        dense: true,
        value: _selected.contains(att.id),
        title: Text(att.originalFilename ?? att.sha256.substring(0, 12)),
        subtitle: Text(status, maxLines: 2),
        onChanged: (v) => setState(() {
          if (v == true) {
            _selected.add(att.id);
          } else {
            _selected.remove(att.id);
          }
        }),
      );
    }
    return ListTile(
      dense: true,
      title: Text(att.originalFilename ?? att.sha256.substring(0, 12)),
      subtitle: Text('已清理 · ${f.archivedOnMac ? '可从 Mac 取回' : 'Mac 副本未确认，可重新上传同一文件补回'}'),
      trailing: TextButton(
        onPressed: _busy ? null : () => _retrieve(f),
        child: const Text('取回'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('医疗文件空间')),
      body: _files.isEmpty
          ? const Center(
              child: Text('还没有医疗文件占用空间',
                  style: TextStyle(color: Colors.grey)))
          : ListView(
              children: [
                if (_present.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('在手机上的原件（按文件去重计占用）'),
                  ),
                  for (final f in _present) _fileTile(f, cleanable: true),
                ],
                if (_offloaded.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('已清理（记录与索引保留）'),
                  ),
                  for (final f in _offloaded) _fileTile(f, cleanable: false),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '清理只释放手机上的文件和缓存；诊断、指标、日期、来源索引和核对状态'
                    '都不变，Mac 与备份中的原件继续保留。正在提取或发送中的文件请稍后再清。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _present.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _busy || _selected.isEmpty ? null : _cleanup,
                  child: Text(_selected.isEmpty
                      ? '选择要清理的文件'
                      : '清理手机原件（约 ${_size(_selectedBytes)}）'),
                ),
              ),
            ),
    );
  }
}
