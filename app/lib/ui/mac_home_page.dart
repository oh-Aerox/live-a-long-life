import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/peer_repository.dart';
import '../services/sync/secure_channel.dart';
import '../services/sync/sync_server.dart';
import 'conditions_page.dart';
import 'consult_page.dart';
import 'day_view_page.dart';
import 'lab_trends_page.dart';
import 'mac_messages_page.dart';
import 'log_page.dart';
import 'markdown_text.dart';
import 'medical_folder_page.dart';
import 'model_config_page.dart';
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
  PairingInfo? _pairing;

  late final PeerRepository _peerRepo =
      PeerRepository(widget.services.db);

  SyncState? _pullState;
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
      final home = Platform.environment['HOME'] ?? '.';
      final target = Directory(p.join(home, 'Documents', '长寿记备份'));
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
          decoration: const InputDecoration(
              helperText: '密码存在这台 Mac 的钥匙串里；忘记密码备份无法解开'),
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
    if (mounted) {
      setState(() {
        _messageCount = messages.where((m) => m.deletedAt == null).length;
        _recordCount = records.where((r) => r.deletedAt == null).length;
        _peers = peers;
        _pullState = pull;
        _latestReport = latestReport;
        _latestBackup = latestBackup;
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
      displayName: 'Mac',
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
        // 配对成功：收起二维码并刷新设备列表。
        if (mounted) setState(() => _pairing = null);
        _load();
      };
    await _server!.start();
    if (mounted) setState(() {});
  }

  Future<void> _startPairing() async {
    await _ensureServer();
    final info = await _server!.startPairing();
    if (mounted) setState(() => _pairing = info);
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
      appBar: AppBar(title: const Text('长寿记（Mac 副本）'), actions: [
        IconButton(
          icon: const Icon(Icons.article_outlined),
          tooltip: '运行日志',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogPage()),
          ),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('这台 Mac 保存手机同步来的完整副本，只读不改；'
              '记录的新建与修改只在手机上进行。'),
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
                  Text('配对', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final peer in _peers)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone_iphone),
                      title: Text(peer.displayName),
                      subtitle: Text(
                          '指纹 ${peer.certFingerprint.substring(0, 16)}… · '
                          '最近地址 ${peer.lastSeenAddr ?? "—"}'),
                    ),
                  if (_pairing != null) ...[
                    const Text('用手机打开 长寿记 → 设置 → 连接 Mac，扫这个码：'),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: _pairing!.encode(),
                          size: 240,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '地址 ${_pairing!.hosts.join(" / ")} 端口 ${_pairing!.port}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ] else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: _startPairing,
                        child: Text(_peers.isEmpty ? '开始配对' : '重新配对'),
                      ),
                    ),
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
                      // 咨询只读副本、不写记录（D-12/D-26）；历史只存本机，
                      // 与手机上的咨询各自独立（consult_messages 不同步）。
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ConsultPage(services: widget.services)),
                        ),
                        child: const Text('咨询'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ModelConfigPage(services: widget.services)),
                        ),
                        child: const Text('模型配置'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('周报和咨询用这台 Mac 上配置的模型（配置不与手机同步），'
                      '手机在"周报"页拉取周报；Mac 上的咨询记录只存在这台 Mac。',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
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
