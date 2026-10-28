import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../services/export_location.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/restore_service.dart';
import '../services/signing_info.dart';
import 'adaptive.dart';
import 'android_background_page.dart';
import 'log_page.dart';
import 'medical_space_page.dart';
import 'model_config_page.dart';
import 'pair_mac_page.dart';
import 'profile_page.dart';
import 'review_times_page.dart';

/// 设置页（product-spec §3）。
class SettingsPage extends StatefulWidget {
  const SettingsPage(
      {super.key, required this.services, required this.notifications});

  final AppServices services;
  final NotificationService notifications;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _reviewSummary = '';
  DateTime? _signingExpiry;
  String _version = '';
  bool _busy = false;
  bool _healthEnabled = false;
  String? _pairedMacName;
  String _syncSummary = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final times = (await widget.services.settings.get('review_times') as List)
        .cast<String>();
    final enabled =
        await widget.services.settings.get('review_enabled') as bool;
    final expiry = await SigningInfo.provisioningExpiry();
    final info = await PackageInfo.fromPlatform();
    final healthEnabled =
        await widget.services.settings.get('healthkit_sync_enabled') as bool? ??
            false;
    final peers = await widget.services.peerRepo.all();
    final push = await (widget.services.db.select(widget.services.db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.push))
          ..limit(1))
        .getSingleOrNull();
    final syncSummary = push == null
        ? '还没同步过'
        : (push.pendingCount > 0
            ? '待传 ${push.pendingCount} 条'
            : '已同步到第 ${push.ackedContiguousSeq} 条');
    if (mounted) {
      setState(() {
        _reviewSummary = enabled ? times.join('、') : '已关闭';
        _signingExpiry = expiry;
        _version = '${info.version} (${info.buildNumber})';
        _healthEnabled = healthEnabled;
        _pairedMacName =
            peers.isEmpty ? null : peers.map((p) => p.displayName).join('、');
        _syncSummary = syncSummary;
      });
    }
  }

  /// 开启时申请权限并立即同步一次。iOS 不会告诉应用权限被拒，
  /// 读不到只显示"暂未读取到"（D-11、A-12）。
  Future<void> _toggleHealth(bool enable) async {
    setState(() {
      _healthEnabled = enable;
      _busy = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.services.settings.set('healthkit_sync_enabled', enable);
      if (enable) {
        await widget.services.healthService.requestAuthorization();
        final n = await widget.services.healthService.syncNow();
        messenger.showSnackBar(SnackBar(
            content: Text(n > 0 ? '已读取 $n 条新样本' : '暂未读取到记录，可手动补充')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('读取失败：$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _signingText {
    final expiry = _signingExpiry;
    if (expiry == null) return '—';
    final days = expiry.difference(DateTime.now()).inDays;
    final local = expiry.toLocal();
    final date = '${local.month}月${local.day}日';
    if (days < 0) return '已过期（$date）';
    if (days == 0) return '今天到期';
    return '$days 天后（$date）';
  }

  @override
  Widget build(BuildContext context) {
    final cupertino = useCupertino(context);
    final chevron = cupertino
        ? const CupertinoListTileChevron()
        : const Icon(Icons.chevron_right);
    Future<void> open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: cupertino
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : null,
      appBar: adaptiveAppBar(context, title: const Text('设置')),
      body: ListView(
        children: [
          AdaptiveSection(header: '记录与提醒', children: [
            AdaptiveTile(
              title: const Text('每日回顾'),
              subtitle: Text(_reviewSummary),
              trailing: chevron,
              onTap: () async {
                await open(ReviewTimesPage(
                    services: widget.services,
                    notifications: widget.notifications));
                await _load();
              },
            ),
            if (Platform.isAndroid)
              AdaptiveTile(
                title: const Text('后台与提醒'),
                subtitle: const Text('通知、闹钟和提醒、省电策略、自启动'),
                trailing: chevron,
                onTap: () => open(AndroidBackgroundPage(
                    services: widget.services,
                    notifications: widget.notifications)),
              ),
            AdaptiveTile(
              title: const Text('基本资料'),
              subtitle: const Text('出生年月、生理性别、身高、过敏、长期用药等'),
              trailing: chevron,
              onTap: () => open(ProfilePage(services: widget.services)),
            ),
            AdaptiveTile(
              title: const Text('读取健康数据'),
              subtitle: const Text('睡眠、步数、体能训练、活动能量。只读取，不写入'),
              trailing: Switch.adaptive(
                value: _healthEnabled,
                onChanged: _busy ? null : (v) => _toggleHealth(v),
              ),
            ),
          ]),
          AdaptiveSection(header: '模型', children: [
            AdaptiveTile(
              title: const Text('模型'),
              subtitle: const Text('配置整理消息用的模型，查看调用记录'),
              trailing: chevron,
              onTap: () => open(ModelConfigPage(services: widget.services)),
            ),
          ]),
          AdaptiveSection(header: '数据与同步', children: [
            AdaptiveTile(
              title: Text(_pairedMacName == null ? '连接 Mac' : '已连接 Mac'),
              subtitle: Text(_pairedMacName == null
                  ? '扫 Mac 上的二维码配对，数据同步到 Mac 保存副本'
                  : '$_pairedMacName · $_syncSummary'),
              trailing: chevron,
              onTap: () async {
                await open(PairMacPage(services: widget.services));
                await _load();
              },
            ),
            AdaptiveTile(
              title: const Text('医疗文件空间'),
              subtitle: const Text('清理手机原件，保留记录；已清理的可取回'),
              trailing: chevron,
              onTap: () => open(MedicalSpacePage(services: widget.services)),
            ),
            AdaptiveTile(
              title: const Text('导出数据'),
              subtitle: const Text('导出到"文件"应用可见的文件夹'),
              trailing: chevron,
              onTap: _busy ? null : () => _export(),
            ),
            AdaptiveTile(
              title: const Text('从导出恢复'),
              trailing: chevron,
              onTap: _busy ? null : () => _restore(),
            ),
            AdaptiveTile(
              title: const Text('数据存储位置'),
              subtitle: const Text('保存在本机；配对后 Mac 上有一份副本'),
              onTap: () => showAdaptiveDialog<void>(
                context: context,
                builder: (context) => AlertDialog.adaptive(
                  title: const Text('数据存储位置'),
                  content: const Text('消息、照片、PDF 和资料保存在本机应用'
                      '沙盒里。配对 Mac 后，数据通过局域网同步到 Mac 保存副本，'
                      '不经过云端。整理消息、识别病历时，相关内容会发给你配置的'
                      '模型服务，发了什么可以在"模型 → 调用记录"里查看。'
                      '删除应用会一并删除本机数据，重要内容请先用"导出数据"备份。'),
                  actions: [
                    DialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('知道了')),
                  ],
                ),
              ),
            ),
          ]),
          AdaptiveSection(header: '关于', children: [
            // 只有 iOS 免费签名才有到期日；安卓、正式签名读不到，不显示。
            if (_signingExpiry != null)
              AdaptiveTile(
                title: const Text('签名到期'),
                subtitle: const Text('免费签名 7 天有效，到期前连接 Mac 重签'),
                trailing: Text(_signingText),
              ),
            AdaptiveTile(
              title: const Text('版本'),
              trailing: Text(_version),
            ),
          ]),
          AdaptiveSection(
            header: '开发者',
            footer: '排查问题用。周报和修正建议移到了首页的"健康档案"。',
            children: [
              AdaptiveTile(
                title: const Text('运行日志'),
                subtitle: const Text('可复制给开发'),
                trailing: chevron,
                onTap: () => open(const LogPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 导出与恢复（product-spec §13）----

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final location = await ExportLocation.resolve();
      final now = DateTime.now();
      final name = '导出-${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
      final target = Directory(p.join(location.dir.path, name));
      final result = await ExportService(widget.services.db, filesDir: widget.services.filesDir).export(target);
      if (!mounted) return;
      final missingNote = result.missingFiles.isEmpty
          ? ''
          : '\n\n注意：${result.missingFiles.length} 个附件本机没有文件，'
              '未包含在导出里。';
      await showAdaptiveDialog<void>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('导出完成'),
          content: Text('已导出 ${result.messageCount} 条消息、'
              '${result.fileCount} 个文件，校验通过。\n\n'
              '位置：${location.describe(name)}\n\n'
              '导出的内容未加密，请保存在安全的位置。$missingNote'),
          actions: [
            DialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 选要恢复的导出。安卓从别的设备拿来的导出要选压缩包：别的应用解压出的
  /// 文件本应用无权读取（分区存储），只有系统选择器选中的文件读得到
  /// （2026-09-30 小米 12 联调）。本机自己导出的文件夹两端都能直接选。
  Future<Directory?> _pickRestoreSource() async {
    var zip = false;
    if (Platform.isAndroid) {
      final choice = await showActionSheet<bool>(context,
          title: '从导出恢复',
          actions: const [
            SheetAction(
                value: true,
                label: '选择压缩包（.zip）',
                subtitle: '从别的设备传来的导出，先压缩成 zip 再传到这台手机',
                icon: Icons.folder_zip_outlined),
            SheetAction(
                value: false,
                label: '选择导出文件夹',
                subtitle: '这台手机自己导出的（下载 → 长命百岁 → exports）',
                icon: Icons.folder_outlined),
          ]);
      if (choice == null) return null;
      zip = choice;
    }
    if (!zip) {
      final path =
          await FilePicker.getDirectoryPath(dialogTitle: '选择导出文件夹');
      return path == null ? null : Directory(path);
    }
    final picked = await FilePicker.pickFiles(
        dialogTitle: '选择导出压缩包',
        type: FileType.custom,
        allowedExtensions: ['zip']);
    final zipPath = picked.firstOrNull?.path;
    if (zipPath == null) return null;
    final tmp = await Directory.systemTemp.createTemp('restore_zip');
    return RestoreService.unpackZip(File(zipPath), tmp);
  }

  Future<void> _restore() async {
    final Directory? source;
    try {
      source = await _pickRestoreSource();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('打不开这个导出：$e')));
      }
      return;
    }
    if (source == null || !mounted) return;

    final hasData = await widget.services.hasExistingData();
    if (!mounted) return;
    if (hasData) {
      final confirmed = await showAdaptiveDialog<bool>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('替换全部数据？'),
          content: const Text('应用里已有数据。恢复会用导出的内容替换现有'
              '全部数据，且无法撤销。\n\n建议先用"导出数据"备份现有内容，'
              '再进行恢复。'),
          actions: [
            DialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            DialogAction(
                onPressed: () => Navigator.pop(context, true),
                isDestructiveAction: true,
                child: const Text('替换全部数据')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final service = RestoreService(
        dbFile: widget.services.dbFile,
        filesDir: widget.services.filesDir,
      );
      // 关数据库前先确认导出读得出来：读不出时应用照常可用，不必重开。
      try {
        await service.readManifest(source);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('无法读取这个导出：$e'
                  '${Platform.isAndroid ? '。从别的设备传来的导出请压缩成 zip 后选"选择压缩包"' : ''}')));
        }
        return;
      }
      // 替换会移走当前资料库文件，先关掉数据库连接。
      await widget.services.db.close();
      final result = await service.restore(
        source,
        hasExistingData: hasData,
        replaceExisting: true,
        newDeviceId: widget.services.ctx.deviceId,
      );
      if (!mounted) return;
      final title = result.partial ? '部分恢复' : '恢复完成';
      final missingNote = result.partial
          ? '\n\n${result.missingFiles.length} 个附件文件缺失或损坏，'
              '对应内容以"文件缺失"显示，其余已照常导入。'
          : '';
      await showAdaptiveDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog.adaptive(
          title: Text(title),
          content: Text('已恢复 ${result.messageCount} 条消息、'
              '${result.restoredFiles} 个文件。$missingNote\n\n'
              '请关闭应用后重新打开，加载恢复的数据。'),
          actions: [
            DialogAction(
                onPressed: () => exit(0), child: const Text('关闭应用')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('恢复失败，原有数据未受影响：$e。请重新打开应用。')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
