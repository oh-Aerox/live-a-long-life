import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/time_value.dart';
import '../services/health_service.dart';
import 'record_detail_page.dart';
import 'record_ui.dart';

/// 按日视图（product-spec §4）：日期切换，显示当天的记录。
/// 设备数据与缺口显示在 V2-M4 / V2-M5 加入。
class DayViewPage extends StatefulWidget {
  const DayViewPage(
      {super.key, required this.services, this.initialDate, this.readOnly = false});

  final AppServices services;
  final String? initialDate;

  /// Mac 副本只读（D-12：只有手机能修改记录）。
  final bool readOnly;

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  late DateTime _date;
  List<(RecordRow, RecordRevision)> _records = [];
  DeviceDayData? _device;

  /// 当天发出、还没整理成记录的消息（模型不可用时也能看到说过什么）。
  List<Message> _pending = [];

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate != null
        ? DateTime.parse(widget.initialDate!)
        : DateTime.now();
    _load();
  }

  String get _localDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final rows = await widget.services.records.byDate(_localDate);
    final result = <(RecordRow, RecordRevision)>[];
    for (final r in rows) {
      result.add((r, await widget.services.records.currentRevisionOf(r.id)));
    }
    // 按类型固定顺序：睡眠、三餐、运动、心情、不适、其他。
    const order = [
      RecordType.sleep,
      RecordType.meal,
      RecordType.exercise,
      RecordType.mood,
      RecordType.symptom,
      RecordType.note,
    ];
    result.sort((a, b) {
      final byType = order
          .indexOf(a.$1.recordType)
          .compareTo(order.indexOf(b.$1.recordType));
      if (byType != 0) return byType;
      return a.$1.createdAt.compareTo(b.$1.createdAt);
    });
    final device = await widget.services.healthService.dayData(_localDate);
    final dayStart = DateTime(_date.year, _date.month, _date.day);
    final pending = await widget.services.messages.pendingOrganizeBetween(
        dayStart.millisecondsSinceEpoch,
        dayStart.add(const Duration(days: 1)).millisecondsSinceEpoch);
    if (mounted) {
      setState(() {
        _records = result;
        _device = device;
        _pending = pending;
      });
    }
  }

  void _shift(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final title =
        '${_date.month}月${_date.day}日 周${weekdays[_date.weekday - 1]}';
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: _pickDate,
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        ),
        centerTitle: true,
        // 前后翻页都放右侧，把 leading 留给系统返回按钮（否则挡住返回）。
        actions: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: '前一天',
              onPressed: () => _shift(-1)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '后一天',
              onPressed: () => _shift(1)),
        ],
      ),
      body: ListView(
        children: [
          if (_records.isEmpty && _pending.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('这一天还没有记录')),
            )
          else
            for (final r in _records) _tile(r.$1, r.$2),
          if (_pending.isNotEmpty) ..._pendingSection(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child:
                Text('设备数据', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _deviceSection(),
        ],
      ),
    );
  }

  /// 待整理的消息：原文照列，整理成记录后自然从这里消失。
  List<Widget> _pendingSection() {
    String hm(int ms) {
      final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('待整理',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Text('模型可用时会自动整理成记录',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
      for (final m in _pending)
        ListTile(
          dense: true,
          leading: const Icon(Icons.schedule_outlined, size: 20),
          title: Text(m.body ?? '',
              maxLines: 3, overflow: TextOverflow.ellipsis),
          subtitle: Text(hm(m.sentAt)),
        ),
    ];
  }

  /// 设备数据区（D-11：没有行 = "暂未读取到"，不是 0；A-12 措辞）。
  Widget _deviceSection() {
    final d = _device;
    if (d == null || d.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('暂未读取到记录，可手动补充',
            style: TextStyle(color: Colors.grey)),
      );
    }
    String hm(int ms) {
      final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    final sleep = d.sleep;
    return Column(
      children: [
        if (sleep != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.bedtime_outlined, size: 20),
            title: Text(sleep.sleepDurationMin != null
                ? '睡眠 ${sleep.sleepDurationMin! ~/ 60} 小时 '
                    '${sleep.sleepDurationMin! % 60} 分钟'
                : '在床 ${(sleep.inBedDurationMin ?? 0) ~/ 60} 小时 '
                    '${(sleep.inBedDurationMin ?? 0) % 60} 分钟，睡眠时长未知'),
            subtitle: Text([
              if (sleep.sleepOnsetMs != null)
                '入睡 ${hm(sleep.sleepOnsetMs!)} · 醒来 ${hm(sleep.wakeMs!)}',
              '来源 ${sleep.sourceName}',
            ].join(' · ')),
          ),
        for (final w in d.workouts)
          ListTile(
            dense: true,
            leading: const Icon(Icons.directions_run_outlined, size: 20),
            title: Text([
              w.workoutType ?? '体能训练',
              '${((w.endUtc - w.startUtc) / 60000).round()} 分钟',
              if (w.energyKcal != null) '${w.energyKcal!.round()} 千卡',
            ].join(' · ')),
            subtitle: Text('${hm(w.startUtc)}—${hm(w.endUtc)} · ${w.sourceName}'),
          ),
        if (d.steps != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.directions_walk_outlined, size: 20),
            title: Text('步数 ${d.steps!.round()}'),
          ),
        if (d.activeEnergyKcal != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.local_fire_department_outlined, size: 20),
            title: Text('活动能量 ${d.activeEnergyKcal!.round()} 千卡'),
          ),
      ],
    );
  }

  Widget _tile(RecordRow record, RecordRevision rev) {
    final data = decodeData(rev);
    final occurred = TimeValue.decode(rev.occurred);
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    final edited = meta.fields.values
        .any((f) => f.reviewStatus == ReviewStatus.edited ||
            f.reviewStatus == ReviewStatus.confirmed);
    return ListTile(
      leading: Icon(recordTypeIcons[record.recordType]),
      title: Text(recordSummary(record.recordType, data),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        recordTypeLabels[record.recordType]!,
        timeValueText(occurred),
        if (occurred.dateAmbiguous) '日期待确认',
        if (edited) '已核对/修改' else '未核对',
      ].join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RecordDetailPage(
                  services: widget.services,
                  recordId: record.id,
                  readOnly: widget.readOnly)),
        );
        await _load();
      },
    );
  }
}
