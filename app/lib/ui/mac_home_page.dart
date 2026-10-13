import 'dart:io';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/backup_service.dart';
import '../services/menu_bar.dart';
import '../services/sync/lan_discovery.dart';
import '../services/sync/sync_server.dart';
import 'conditions_page.dart';
import 'consult_page.dart';
import 'day_view_page.dart';
import 'desktop_text.dart';
import 'lab_trends_page.dart';
import 'mac_messages_page.dart';
import 'mac_settings_page.dart';
import 'markdown_text.dart';
import 'medical_folder_page.dart';
import 'visit_timeline_page.dart';
import 'weekly_report_page.dart';

/// Mac 端主页（plan-v0.3 V3-M0）：副本概览骨架。
/// Mac 只保存手机同步来的副本，不能编辑（D-12）；
/// 同步、浏览、周报在 V3-M3 至 V3-M5 逐步补齐。
class MacHomePage extends StatefulWidget {
  const MacHomePage({super.key, required this.services});

  final AppServices services;

  @override
  State<MacHomePage> createState() => _MacHomePageState();
}

class _MacHomePageState extends State<MacHomePage> {
  int _messageCount = 0;
  int _recordCount = 0;
  List<Peer> _peers = [];
  SyncServer? _server;

  /// 配对成功事件，设置页据此收起二维码。
  final _pairedEvents = ValueNotifier<int>(0);

  late final PeerRepository _peerRepo =
      PeerRepository(widget.services.db);

  SyncState? _pullState;
  List<PendingRebuild> _pendingRebuilds = [];
  AnalysisArtifact? _latestReport;
  bool _generating = false;
  BackupRun? _latestBackup;
  bool _backingUp = false;
  final _passphrase = TextEditingController();
  String? _drillResult;

  Future<void> _runBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final pass = await _backupPassphrase();
    if (pass == null) return;
    setState(() => _backingUp = true);
    try {
      final target = await BackupService.backupRoot();
      await target.create(recursive: true);
      final run = await widget.services.backupService
          .backup(targetRoot: target, passphrase: pass);
      messenger.showSnackBar(
          SnackBar(content: Text('备份完成并校验通过：${run.targetPath}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('备份失败：$e')));
    } finally {
      if (mounted) setState(() => _backingUp = false);
      await _load();
    }
  }

  Future<void> _runDrill() async {
    final backup = _latestBackup;
    if (backup == null || backup.status != BackupStatus.published) return;
    final pass = await _backupPassphrase();
    if (pass == null) return;
    setState(() => _backingUp = true);
    try {
      final tmp = await Directory.systemTemp.createTemp('restore_drill');
      final result = await widget.services.backupService.restoreDrill(
        backupDir: Directory(backup.targetPath),
        passphrase: pass,
        restoreTo: tmp,
      );
      setState(() => _drillResult = result.ok
          ? '演练成功：${result.tableRows.values.fold(0, (a, b) => a + b)} 行数据、'
              '${result.filesRestored} 个附件全部解密校验通过'
              '${result.missingFiles.isEmpty ? '' : '；备份时已缺原件 ${result.missingFiles.length} 个'}'
          : '演练失败：${result.error}');
      await tmp.delete(recursive: true);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  /// 备份密码：首次输入后存 Keychain（D-15），之后直接用。
  Future<String?> _backupPassphrase() async {
    final stored = await widget.services.keyStore.read('backup_passphrase');
    if (stored != null && stored.isNotEmpty) return stored;
    if (!mounted) return null;
    final pass = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置备份密码'),
        content: TextField(
          controller: _passphrase,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
              helperText:
                  desktopText('密码存在电脑端的钥匙串里；忘记密码备份无法解开')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, _passphrase.text.trim()),
              child: const Text('确定')),
        ],
      ),
    );
    if (pass == null || pass.isEmpty) return null;
    await widget.services.keyStore.saveRaw('backup_passphrase', pass);
    return pass;
  }

  Future<void> _generateReport() async {
    setState(() => _generating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.services.analysisService.generateWeeklyReview();
      messenger.showSnackBar(const SnackBar(content: Text('周报已生成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _generating = false);
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _ensureServer();
  }

  @override
  void dispose() {
    _server?.stop();
    _pairedEvents.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = widget.services.db;
    final messages = await db.select(db.messages).get();
    final records = await db.select(db.records).get();
    final peers = await _peerRepo.all();
    final pull = await (db.select(db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull))
          ..limit(1))
        .getSingleOrNull();
    final latestReport =
        await widget.services.analysisService.latest(AnalysisKind.weeklyReview);
    final latestBackup = await widget.services.backupService.latest();
    final pendingRebuilds = await _server?.pendingRebuilds() ?? const [];
    await const MacMenuBar().setStatus(await _menuBarStatus(pendingRebuilds));
    if (mounted) {
      setState(() {
        _messageCount = messages.where((m) => m.deletedAt == null).length;
        _recordCount = records.where((r) => r.deletedAt == null).length;
        _peers = peers;
        _pullState = pull;
        _latestReport = latestReport;
        _latestBackup = latestBackup;
        _pendingRebuilds = pendingRebuilds;
      });
    }
  }

  String get _syncText {
    final s = _pullState;
    if (s == null) return '还没有收到过同步';
    final t =
        DateTime.fromMillisecondsSinceEpoch(s.lastSuccessAt ?? 0).toLocal();
    return '已确认到第 ${s.ackedContiguousSeq} 条 · '
        '最近 ${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// 常驻服务：应用打开即监听，配对过的手机随时可以推送。
  Future<void> _ensureServer() async {
    if (_server != null) return;
    _server = SyncServer(
      deviceId: widget.services.ctx.deviceId,
      // 手机上显示的已连接设备名（手机端仍称 Mac，D-30 发版前统一）。
      displayName: Platform.isWindows ? '电脑' : 'Mac',
      db: widget.services.db,
      filesDir: widget.services.filesDir,
      peers: _peerRepo,
      keyStore: widget.services.keyStore,
      records: widget.services.records,
    )
      ..onReplicaChanged = () {
        if (mounted) _load();
      }
      ..onPaired = () {
        // 配对成功：通知设置页收起二维码，并刷新设备列表。
        _pairedEvents.value++;
        _load();
      };
    await _server!.start();
    await _load(); // 服务就绪后才能读到待重建的手机
    // 局域网广播，手机在 Mac 换 IP 后能自己找回来（V4-M5 mDNS）。
    final port = _server!.port;
    if (port != null) {
      await const LanDiscovery().publish(widget.services.ctx.deviceId, port,
          await SyncServer.lanAddresses());
    }
    if (mounted) setState(() {});
  }

  /// 手机从导出恢复后数据代次变了（schema §7.3、D-34）：用户确认后先备份，
  /// 备份成功才清掉旧副本，手机下次同步从新代次第 1 条重新发送。
  Future<void> _confirmRebuild(PendingRebuild pending) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重建手机数据副本'),
        content: SizedBox(
          width: 480,
          child: Text(desktopText(
            '「${pending.displayName}」的数据代次变了（从导出恢复过，或换了手机），'
            '电脑端从 ${_formatTime(pending.detectedAt.toLocal())} 起暂停接收它的同步。\n\n'
            '重建会以手机现在的数据为准：先清掉电脑端的手机数据副本，'
            '手机再把现有数据全部重新发一遍。手机上已经没有的内容'
            '（比如导出之后才记的、恢复时没带回来的）会从电脑端清掉。\n\n'
            '清掉之前先自动备份一次，备份不成功就不动数据；需要时可以从这份备份里找回。'
            '电脑端自己生成的周报、修正建议，其他手机的数据和已收到的原件文件都保留。',
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('备份并重建'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pass = await _backupPassphrase();
    if (pass == null) return;
    setState(() => _backingUp = true);
    try {
      final target = await BackupService.backupRoot();
      await target.create(recursive: true);
      final run = await widget.services.backupService.backup(
        targetRoot: target,
        passphrase: pass,
      );
      await _server!.rebuildReplica(pending.peerDeviceId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '已备份到 ${run.targetPath} 并清掉旧副本，'
            '请在手机上点一次同步',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('备份失败，没有重建：$e')));
    } finally {
      if (mounted) setState(() => _backingUp = false);
      await _load();
    }
  }

  /// 菜单栏第一行（P-34）：待重建优先，否则是最近一次收到同步的手机与时间。
  Future<String> _menuBarStatus(List<PendingRebuild> pending) async {
    if (pending.isNotEmpty) {
      return '「${pending.first.displayName}」需要重建副本，打开窗口处理';
    }
    final db = widget.services.db;
    final pulls = await (db.select(db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull)))
        .get();
    final received = pulls.where((s) => s.lastSuccessAt != null).toList()
      ..sort((a, b) => b.lastSuccessAt!.compareTo(a.lastSuccessAt!));
    if (received.isEmpty) return '同步：还没有收到过';
    final latest = received.first;
    final peer = await _peerRepo.active(latest.peerDeviceId);
    final t = DateTime.fromMillisecondsSinceEpoch(latest.lastSuccessAt!);
    return '最近同步：${peer?.displayName ?? '手机'} ${_formatTime(t)}';
  }

  static String _formatTime(DateTime t) =>
      '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _openSettings() async {
    await _ensureServer();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MacSettingsPage(
          services: widget.services,
          server: _server,
          pairedEvents: _pairedEvents,
        ),
      ),
    );
    await _load();
  }

  /// 病例与健康档案（2026-09-29 联调补，D-29）：手机上那一套医疗视图的
  /// 只读版——看提取结果、核对状态、原件位置、趋势与时间线；添加、提取、
  /// 核对、修改都只在手机上（D-12）。
  Widget _medicalCard(BuildContext context) {
    Widget entry(IconData icon, String label, Widget Function() page) =>
        OutlinedButton.icon(
          icon: Icon(icon, size: 18),
          label: Text(label),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page())),
        );
    final s = widget.services;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('病例与健康档案',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('手机同步来的医疗文件与提取结果，只读查看；添加、提取与核对在手机上进行。',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                entry(Icons.folder_shared_outlined, '我的病例夹',
                    () => MedicalFolderPage(
                        services: s, physicalExam: false, readOnly: true)),
                entry(Icons.assignment_outlined, '我的体检',
                    () => MedicalFolderPage(
                        services: s, physicalExam: true, readOnly: true)),
                entry(Icons.health_and_safety_outlined, '长期状况档案',
                    () => ConditionsPage(services: s, readOnly: true)),
                entry(Icons.show_chart, '指标趋势',
                    () => LabTrendsPage(services: s)),
                entry(Icons.timeline_outlined, '就诊时间线',
                    () => VisitTimelinePage(services: s, readOnly: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长命百岁'), actions: [
        // 顶部快捷入口（2026-09-29）：咨询与设置不属于某张卡片。
        TextButton.icon(
          icon: const Icon(Icons.forum_outlined, size: 18),
          label: const Text('咨询'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ConsultPage(services: widget.services)),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('设置'),
          onPressed: _openSettings,
        ),
        const SizedBox(width: 8),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(desktopText('电脑端保存手机同步来的完整副本，只读不改；'
              '记录的新建与修改只在手机上进行。')),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('副本概览', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('消息：$_messageCount 条'),
                  Text('记录：$_recordCount 条'),
                  Text('同步：$_syncText'),
                  for (final pending in _pendingRebuilds)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '「${pending.displayName}」从导出恢复过，'
                              '需要重建副本后才能继续同步',
                            ),
                          ),
                          TextButton(
                            onPressed: _backingUp
                                ? null
                                : () => _confirmRebuild(pending),
                            child: const Text('处理'),
                          ),
                        ],
                      ),
                    ),
                  if (_peers.isEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text('还没有配对手机，去设置里配对'),
                      onPressed: _openSettings,
                    ),
                  if (_server?.running ?? false)
                    Text('接收服务：端口 ${_server!.port}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('浏览消息'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MacMessagesPage(services: widget.services)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined,
                            size: 18),
                        label: const Text('按日查看'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DayViewPage(
                                  services: widget.services, readOnly: true)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _medicalCard(context),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('周报分析',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_latestReport != null) ...[
                    Text(
                        '最新：${_latestReport!.periodStart} 至 ${_latestReport!.periodEnd}'),
                    const SizedBox(height: 4),
                    Text(
                      MarkdownText.plain(_latestReport!.contentMd),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const Text('还没有生成过周报。生成失败时旧周报保留。'),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _generating ? null : _generateReport,
                        child: Text(_generating ? '生成中…' : '生成周报'),
                      ),
                      const SizedBox(width: 8),
                      if (_latestReport != null) ...[
                        OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WeeklyReportPage(
                                    services: widget.services, readOnly: true)),
                          ),
                          child: const Text('查看全文'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      desktopText('周报用电脑端配置的模型'
                          '（设置 → 模型配置，不与手机同步），手机在"周报"页拉取查看。'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('加密备份',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_latestBackup == null
                      ? '还没有备份。备份是加密整包，可以放进 iCloud 云盘目录。'
                      : '最近备份：${_backupStatusText(_latestBackup!)}'),
                  if (_drillResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_drillResult!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _backingUp ? null : _runBackup,
                        child: Text(_backingUp ? '进行中…' : '立即备份'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _backingUp ||
                                _latestBackup?.status != BackupStatus.published
                            ? null
                            : _runDrill,
                        child: const Text('恢复演练'),
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

  String _backupStatusText(BackupRun run) {
    final t = DateTime.fromMillisecondsSinceEpoch(run.createdAt).toLocal();
    final status = switch (run.status) {
      BackupStatus.published => '可用',
      BackupStatus.failed => '失败（${run.error ?? "未知"}）',
      BackupStatus.building => '生成中',
      BackupStatus.verifying => '校验中',
    };
    return '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} · $status';
  }
}
