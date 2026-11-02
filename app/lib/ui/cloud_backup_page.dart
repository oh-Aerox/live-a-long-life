import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/cloud_backup_service.dart';
import '../services/cloud_folder.dart';
import '../services/cloud_vault.dart';
import '../services/restore_service.dart';
import 'adaptive.dart';

/// iCloud 备份（D-51）：选 iCloud 云盘里的一个文件夹，自动或手动备份；
/// 换手机、重装后选同一个文件夹恢复。只在 iPhone 上有。
class CloudBackupPage extends StatefulWidget {
  const CloudBackupPage({super.key, required this.services});

  final AppServices services;

  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage> {
  CloudBackupService get _cloud => widget.services.cloudBackup;
  CloudBackupState? _state;
  bool _busy = false;

  /// 恢复时下载附件的进度（备份进度在 [CloudBackupService.status] 里）。
  String? _restoreStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _cloud.state();
    if (mounted) setState(() => _state = s);
  }

  static String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final day = t.year == now.year && t.month == now.month && t.day == now.day
        ? '今天'
        : '${t.month}月${t.day}日';
    return '$day ${two(t.hour)}:${two(t.minute)}';
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _confirm(
    String title,
    String content,
    String ok, {
    bool destructive = false,
  }) async {
    final r = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title),
        content: Text(content),
        actions: [
          DialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          DialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: destructive,
            child: Text(ok),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _inform(String title, String content) =>
      showAdaptiveDialog<void>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: Text(title),
          content: Text(content),
          actions: [
            DialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  /// 选文件夹；不在 iCloud 云盘里的提醒一次。
  Future<PickedFolder?> _pickFolder() async {
    final picked = await _cloud.folder.pick();
    if (picked == null || !mounted) return null;
    if (!picked.inICloud &&
        !await _confirm(
          '这个文件夹不在 iCloud 云盘里',
          '"${picked.name}"在这台手机上，不会上传到 iCloud，换手机后无法从这里'
              '恢复。建议在"文件"里选 iCloud 云盘中的文件夹。',
          '仍然使用',
        )) {
      return null;
    }
    return picked;
  }

  /// 让用户输入备份密码解锁，存进钥匙串。取消返回 null。
  Future<List<int>?> _askPassword(VaultMeta meta) async {
    while (true) {
      if (!mounted) return null;
      final r = await showFieldsDialog(
        context,
        title: '输入备份密码',
        fields: const [DialogField(label: '备份密码', obscureText: true)],
        confirmLabel: '确定',
      );
      if (r == null) return null;
      try {
        final key = await CloudVault.unlock(meta, r.first);
        await _cloud.saveKey(meta, key);
        return key;
      } on WrongPassword {
        if (mounted) _toast('密码不对，再试一次');
      }
    }
  }

  /// 新建备份时设置密码；不加密返回 ''，取消返回 null。
  Future<String?> _choosePassword() async {
    final encrypt = await showActionSheet<bool>(
      context,
      title: '备份要不要加密？',
      actions: const [
        SheetAction(
          value: true,
          label: '加密（推荐）',
          subtitle: '设置备份密码。恢复时要输入，忘了就无法恢复',
          icon: Icons.lock_outline,
        ),
        SheetAction(
          value: false,
          label: '不加密',
          subtitle: '病历原件等内容以原样存在 iCloud 里',
          icon: Icons.lock_open_outlined,
        ),
      ],
    );
    if (encrypt == null) return null;
    if (!encrypt) return '';
    while (true) {
      if (!mounted) return null;
      final r = await showFieldsDialog(
        context,
        title: '设置备份密码',
        fields: const [
          DialogField(label: '备份密码（至少 6 位）', obscureText: true),
          DialogField(label: '再输入一次', obscureText: true),
        ],
        confirmLabel: '确定',
      );
      if (r == null) return null;
      if (r[0].length < 6) {
        _toast('密码至少 6 位');
      } else if (r[0] != r[1]) {
        _toast('两次输入不一致');
      } else {
        return r[0];
      }
    }
  }

  Future<void> _enable() => _run(() async {
    final picked = await _pickFolder();
    if (picked == null || !mounted) return;
    var meta = await _cloud.withVault(picked.bookmark, (v) => v.readMeta());
    if (!mounted) return;
    if (meta != null) {
      // 文件夹里已有备份（换手机后接着用、或重新选回原来的文件夹）。
      if (meta.encrypted && await _cloud.savedKey(meta) == null) {
        if (await _askPassword(meta) == null) return;
      }
    } else {
      final password = await _choosePassword();
      if (password == null) return;
      meta = await _cloud.createVault(
        picked.bookmark,
        password: password.isEmpty ? null : password,
      );
    }
    await _cloud.connect(picked, meta);
    await _load();
    await _backupNow(force: true);
  });

  Future<void> _backupNow({bool force = false}) async {
    try {
      final r = await _cloud.backupNow(force: force);
      if (!mounted) return;
      if (r.unchanged) {
        _toast('内容没有变化，最近一次备份就是最新的');
      } else {
        final s = r.snapshot!;
        final missing = s.missingFiles.isEmpty
            ? ''
            : '；${s.missingFiles.length} 个附件手机上没有，未备份';
        _toast(
          '备份完成：${s.messageCount} 条消息、${s.files.length} 个文件'
          '（新传 ${r.uploaded} 个）$missing',
        );
      }
    } on NeedsPassword {
      final bookmark = await _cloud.bookmark();
      if (bookmark == null || !mounted) return;
      final meta = await _cloud.withVault(bookmark, (v) => v.readMeta());
      if (meta == null || !mounted) return;
      if (await _askPassword(meta) != null) await _backupNow(force: force);
    } catch (e) {
      if (mounted) _toast('备份失败：$e');
    }
  }

  Future<void> _changeFolder() async {
    if (!await _confirm('更换文件夹', '以后备份到新选的文件夹。原文件夹里的备份不会删除。', '选择文件夹')) {
      return;
    }
    await _enable();
  }

  Future<void> _disable() async {
    if (!await _confirm(
      '停用 iCloud 备份',
      '不再备份到 iCloud。已经备份的内容留在原文件夹里，'
          '之后仍可以从那里恢复。',
      '停用',
      destructive: true,
    )) {
      return;
    }
    await _run(_cloud.disconnect);
  }

  // ---- 恢复 ----

  Future<void> _restore() async {
    final current = await _cloud.currentFolder();
    if (!mounted) return;
    PickedFolder? folder = current;
    if (current != null) {
      final other = await showActionSheet<bool>(
        context,
        title: '从哪个文件夹恢复？',
        actions: [
          SheetAction(value: false, label: '现在的备份文件夹（${current.name}）'),
          const SheetAction(value: true, label: '选择其他文件夹'),
        ],
      );
      if (other == null) return;
      if (other) folder = null;
    }
    folder ??= await _pickFolder();
    if (folder == null || !mounted) return;
    final picked = folder;

    setState(() => _busy = true);
    final VaultMeta? meta;
    final List<CloudSnapshot> snapshots;
    try {
      (meta, snapshots) = await _cloud.withVault(
        picked.bookmark,
        (v) async => (await v.readMeta(), await v.list()),
      );
    } catch (e) {
      if (mounted) _toast('读不出备份：$e');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (meta == null || snapshots.isEmpty) {
      await _inform(
        '没有找到备份',
        meta == null
            ? '这个文件夹里没有长命百岁的备份。请选"${CloudVault.dirName}"'
                  '或它所在的文件夹。'
            : '备份文件夹里还没有可用的备份，可能还没从 iCloud 下载完，'
                  '稍后再试。',
      );
      return;
    }

    final chosen = await showActionSheet<CloudSnapshot>(
      context,
      title: '选择要恢复的备份',
      actions: [
        for (final s in snapshots)
          SheetAction(
            value: s,
            label: _time(DateTime.fromMillisecondsSinceEpoch(s.createdAt)),
            subtitle: '${s.messageCount} 条消息、${s.files.length} 个文件',
          ),
      ],
    );
    if (chosen == null || !mounted) return;

    List<int>? key;
    if (meta.encrypted) {
      key = await _cloud.savedKey(meta) ?? await _askPassword(meta);
      if (key == null || !mounted) return;
    }

    final hasData = await widget.services.hasExistingData();
    if (!mounted) return;
    if (hasData &&
        !await _confirm(
          '替换全部数据？',
          '应用里已有数据。恢复会用这份备份替换现有全部数据，且无法撤销。',
          '替换全部数据',
          destructive: true,
        )) {
      return;
    }

    await _doRestore(picked, meta, chosen, key, hasData);
  }

  Future<void> _doRestore(
    PickedFolder picked,
    VaultMeta meta,
    CloudSnapshot snapshot,
    List<int>? key,
    bool hasData,
  ) async {
    setState(() {
      _busy = true;
      _restoreStatus = '正在下载备份';
    });
    _cloud.blocked = true;
    final tmp = await Directory.systemTemp.createTemp('cloud_restore');
    var dbClosed = false;
    try {
      final staged = await _cloud.withVault(
        picked.bookmark,
        (v) => v.stage(
          snapshot,
          into: tmp,
          key: key,
          onProgress: (done, total) {
            if (mounted) {
              setState(() => _restoreStatus = '正在下载附件 $done/$total');
            }
          },
        ),
      );
      if (mounted) setState(() => _restoreStatus = '正在恢复');
      final service = RestoreService(
        dbFile: widget.services.dbFile,
        filesDir: widget.services.filesDir,
      );
      await service.readManifest(staged);
      // 替换会移走当前资料库文件，先关掉数据库连接。
      await widget.services.db.close();
      dbClosed = true;
      final result = await service.restore(
        staged,
        hasExistingData: hasData,
        replaceExisting: true,
        newDeviceId: widget.services.ctx.deviceId,
        deviceSettings: CloudBackupService.deviceSettings(
          picked,
          meta,
          auto: true,
          restoredFrom: snapshot,
        ),
      );
      if (!mounted) return;
      final missingNote = result.partial
          ? '\n\n${result.missingFiles.length} 个附件文件缺失或损坏，'
                '对应内容以"文件缺失"显示，其余已照常导入。'
          : '';
      await showAdaptiveDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog.adaptive(
          title: Text(result.partial ? '部分恢复' : '恢复完成'),
          content: Text(
            '已恢复 ${result.messageCount} 条消息、'
            '${result.restoredFiles} 个文件。$missingNote\n\n'
            '之后会接着自动备份到这个文件夹。请关闭应用后重新打开，'
            '加载恢复的数据。',
          ),
          actions: [
            DialogAction(onPressed: () => exit(0), child: const Text('关闭应用')),
          ],
        ),
      );
    } catch (e) {
      if (!dbClosed) _cloud.blocked = false;
      if (mounted) {
        _toast(
          e is WrongPassword
              ? '密码不对'
              : dbClosed
              ? '恢复失败，原有数据未受影响：$e。请重新打开应用。'
              : '恢复失败：$e',
        );
      }
    } finally {
      await tmp.delete(recursive: true);
      if (mounted) {
        setState(() {
          _busy = false;
          _restoreStatus = null;
        });
      }
    }
  }

  // ---- 页面 ----

  @override
  Widget build(BuildContext context) {
    final cupertino = useCupertino(context);
    final s = _state;
    return Scaffold(
      backgroundColor: cupertino
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : null,
      appBar: adaptiveAppBar(context, title: const Text('iCloud 备份')),
      body: s == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: _cloud.status,
                  builder: (context, status, _) {
                    final text = _restoreStatus ?? status;
                    if (text == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(text),
                        ],
                      ),
                    );
                  },
                ),
                if (s.enabled) ..._enabledSections(s) else _intro(),
                AdaptiveSection(
                  header: '恢复',
                  footer:
                      '换手机或重装应用后，在这里选同一个 iCloud 文件夹，'
                      '挑一份备份恢复。恢复会替换手机上的全部数据。',
                  children: [
                    AdaptiveTile(
                      title: const Text('从 iCloud 备份恢复'),
                      onTap: _busy ? null : _restore,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _intro() => AdaptiveSection(
    footer:
        '备份到你在"文件"里选的 iCloud 云盘文件夹，包括消息、记录、'
        '病例夹和体检原件、资料与设置；不含模型配置和 key。'
        '每天保留最后一份，最多 ${CloudBackupService.keepDays} 天；附件只存一份，只上传新增的。',
    children: [
      AdaptiveTile(
        title: const Text('开启 iCloud 备份'),
        subtitle: const Text('选择一个 iCloud 云盘里的文件夹'),
        onTap: _busy ? null : _enable,
      ),
    ],
  );

  List<Widget> _enabledSections(CloudBackupState s) {
    final last = s.lastAt == null
        ? '还没有备份'
        : '上次 ${_time(s.lastAt!)} · ${s.lastMessages} 条消息、'
              '${s.lastFiles} 个文件'
              '${s.lastMissing > 0 ? '（${s.lastMissing} 个附件手机上没有）' : ''}';
    final failed =
        s.errorAt != null &&
        (s.lastAt == null || s.errorAt!.isAfter(s.lastAt!));
    return [
      AdaptiveSection(
        header: '备份位置',
        footer: s.inICloud ? null : '这个文件夹不在 iCloud 云盘里，换手机后无法从这里恢复。',
        children: [
          AdaptiveTile(
            title: Text(s.folderName!),
            subtitle: Text(
              [
                s.inICloud ? 'iCloud 云盘' : '本机',
                s.encrypted ? '已加密' : '未加密',
              ].join(' · '),
            ),
          ),
          AdaptiveTile(
            title: const Text('自动备份'),
            subtitle: const Text('打开和离开应用时，内容有变化就备份'),
            trailing: Switch.adaptive(
              value: s.auto,
              onChanged: _busy ? null : (v) => _run(() => _cloud.setAuto(v)),
            ),
          ),
        ],
      ),
      AdaptiveSection(
        children: [
          AdaptiveTile(
            title: const Text('立即备份'),
            subtitle: Text(
              failed ? '上次备份失败（${_time(s.errorAt!)}）：${s.error}' : last,
              style: failed
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
            onTap: _busy ? null : () => _run(_backupNow),
          ),
        ],
      ),
      AdaptiveSection(
        children: [
          AdaptiveTile(
            title: const Text('更换文件夹'),
            onTap: _busy ? null : _changeFolder,
          ),
          AdaptiveTile(
            title: Text(
              '停用 iCloud 备份',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _busy ? null : _disable,
          ),
        ],
      ),
    ];
  }
}
