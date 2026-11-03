
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/export_location.dart';
import '../services/export_service.dart';
import '../services/medical_space_service.dart';
import 'adaptive.dart';
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

  /// 已上传到 iCloud 备份的附件（sha256）；没开 iCloud 备份或读不到时为 null，
  /// 不显示 iCloud 状态（D-51）。
  Set<String>? _inCloud;

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
    // 列 iCloud 文件夹可能慢一点，列表先出来，再补上 iCloud 状态。
    final inCloud = await widget.services.cloudBackup.uploadedShas();
    if (mounted) setState(() => _inCloud = inCloud);
  }

  bool? _cloudHas(MedicalFile f) => _inCloud?.contains(f.attachment.sha256);

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
    final noRemote = chosen
        .where((f) => !f.archivedOnMac && _cloudHas(f) != true)
        .length;
    // 只在 iCloud 有：清理后看不到原件，目前不能从 iCloud 单独取回。
    final cloudOnly = chosen
        .where((f) => !f.archivedOnMac && _cloudHas(f) == true)
        .length;
    // 只在电脑有：换手机从 iCloud 恢复时缺这些原件，只能再从电脑取回。
    final macOnly = chosen
        .where((f) => f.archivedOnMac && _cloudHas(f) == false)
        .length;
    // 导出的副本清理不动（它们是给用户带走的），但要说清楚，免得以为空间全释放了。
    var exported = 0;
    var exportWhere = '';
    try {
      final location = await ExportLocation.resolve();
      exportWhere = location.describe();
      exported = (await ExportService.exportedCopies(location.dir,
              {for (final f in chosen) f.attachment.sha256}))
          .length;
    } catch (_) {}
    if (!mounted) return;
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('清理手机原件'),
        content: Text(
          '将清理手机上的 ${chosen.length} 份医疗文件，释放约 ${_size(_selectedBytes)}。'
          '历史医疗记录保留，电脑上的已归档原件不受影响。'
          '${noRemote > 0 ? '\n\n注意：其中 $noRemote 份没有确认过的其他副本，清理后可能无法再查看原件（数据保留，未核对的仍是未核对）。' : ''}'
          '${cloudOnly > 0 ? '\n\n其中 $cloudOnly 份电脑还没确认收到，只在 iCloud 备份里有；清理后手机上看不到原件，目前不能从 iCloud 单独取回。' : ''}'
          '${macOnly > 0 ? '\n\n其中 $macOnly 份还没备份到 iCloud，只在电脑上有。换手机从 iCloud 恢复时会缺这些原件，要再从电脑取回；建议先在"iCloud 备份"里立即备份。' : ''}'
          '${exported > 0 ? '\n\n其中 $exported 份在你导出的数据里还有副本（$exportWhere），清理不会删除它们，需要时可自行删除。' : ''}',
        ),
        actions: [
          DialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          DialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDestructiveAction: true,
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
            ? '已从电脑取回，原件可以查看了'
            : '电脑不可达或没有这份文件；提取过的数据不受影响，也可以重新上传同一文件补回'),
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
      f.archivedOnMac ? '电脑已归档' : '电脑未确认收到',
      switch (_cloudHas(f)) {
        true => 'iCloud 已备份',
        false => 'iCloud 未备份',
        null => '',
      },
      if (!f.archivedOnMac && _cloudHas(f) != true) '无确认的其他副本',
    ].where((s) => s.isNotEmpty).join(' · ');

    if (cleanable) {
      return CheckboxListTile.adaptive(
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
      subtitle: Text('已清理 · ${f.archivedOnMac ? '可从电脑取回' : '电脑副本未确认，可重新上传同一文件补回'}'
          '${_cloudHas(f) == true ? ' · iCloud 备份里有' : ''}'),
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
                    '都不变，电脑与备份中的原件继续保留。正在提取或发送中的文件请稍后再清。'
                    '开了 iCloud 备份时，建议清理前先备份一次，换手机恢复时原件才齐全。',
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
