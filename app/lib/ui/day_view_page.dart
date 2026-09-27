import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/time_value.dart';
import 'record_detail_page.dart';
import 'record_ui.dart';

/// 按日视图（product-spec §4）：日期切换，显示当天的记录。
/// 设备数据与缺口显示在 V2-M4 / V2-M5 加入。
class DayViewPage extends StatefulWidget {
  const DayViewPage({super.key, required this.services, this.initialDate});

  final AppServices services;
  final String? initialDate;

  @override
  State<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends State<DayViewPage> {
  late DateTime _date;
  List<(RecordRow, RecordRevision)> _records = [];

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
    if (mounted) setState(() => _records = result);
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
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
        actions: [
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shift(1)),
        ],
      ),
      body: _records.isEmpty
          ? const Center(child: Text('这一天还没有记录'))
          : ListView(
              children: [for (final r in _records) _tile(r.$1, r.$2)],
            ),
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
                  services: widget.services, recordId: record.id)),
        );
        await _load();
      },
    );
  }
}
