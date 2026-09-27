import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/time_value.dart';
import 'record_ui.dart';

/// 记录详情（product-spec §4）：来源消息可查、字段可修正、历史保留。
/// 修正后字段状态变为"用户已修改"，整理不再覆盖它（D-05、A-25）。
class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage(
      {super.key,
      required this.services,
      required this.recordId,
      this.readOnly = false});

  final AppServices services;
  final String recordId;

  /// Mac 副本只读（D-12）。
  final bool readOnly;

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  RecordRow? _record;
  RecordRevision? _rev;
  List<RecordRevision> _history = [];
  List<(RecordSource, Message?)> _sources = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    final record = await s.records.byId(widget.recordId);
    if (record == null) return;
    final rev = await s.records.currentRevisionOf(record.id);
    final history = await s.records.revisionsOf(record.id);
    final sourceRows = await s.records.sourcesOf(rev.id);
    final sources = <(RecordSource, Message?)>[];
    for (final src in sourceRows) {
      Message? msg;
      if (src.sourceKind == RecordSourceKind.message) {
        msg = await s.messages.byId(src.sourceId);
      }
      sources.add((src, msg));
    }
    if (mounted) {
      setState(() {
        _record = record;
        _rev = rev;
        _history = history;
        _sources = sources;
      });
    }
  }

  /// 修正一个字段：新版本 + 字段级 edited（schema §1.3、§3.4）。
  Future<void> _editField(String field, Object? currentValue) async {
    final controller =
        TextEditingController(text: currentValue?.toString() ?? '');
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修正「${fieldLabels[field] ?? field}」'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (newValue == null || newValue == currentValue?.toString()) return;

    final record = _record!;
    final rev = _rev!;
    final data = decodeData(rev);
    // 数字字段维持数字类型。
    data[field] =
        currentValue is num ? (num.tryParse(newValue) ?? newValue) : newValue;
    final meta = FieldMetaMap.decode(rev.fieldMeta).fields;
    meta[field] = const FieldMeta(
        origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited);
    await widget.services.records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: TimeValue.decode(rev.occurred),
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap(meta),
      producedBy: ProducedBy.userEdit(),
    );
    await _load();
  }

  /// 确认或修改归属日期（A-23 歧义核对：点一下即可改）。
  Future<void> _confirmDate() async {
    final record = _record!;
    final rev = _rev!;
    final occurred = TimeValue.decode(rev.occurred);
    final current = DateTime.parse(occurred.localDate!);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: '这条记录属于哪一天？',
    );
    if (picked == null) return;
    final newDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    final confirmed = TimeValue(
      instantUtcMs: occurred.instantUtcMs,
      tz: occurred.tz,
      tzInferred: occurred.tzInferred,
      localDate: newDate,
      precision: occurred.precision,
      partOfDay: occurred.partOfDay,
      source: TimeValueSource.userStated,
      dateAmbiguous: false,
      rawText: occurred.rawText,
    );
    await widget.services.records.addRevision(
      recordId: record.id,
      baseVersion: record.version,
      occurred: confirmed,
      occurredEnd:
          rev.occurredEnd == null ? null : TimeValue.decode(rev.occurredEnd!),
      dataJson: rev.data,
      fieldMeta: FieldMetaMap(FieldMetaMap.decode(rev.fieldMeta).fields),
      producedBy: ProducedBy.userEdit(),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final rev = _rev;
    if (record == null || rev == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final data = decodeData(rev);
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    final occurred = TimeValue.decode(rev.occurred);
    final photoCount = (data['photo_attachment_ids'] as List?)?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(recordTypeLabels[record.recordType]!)),
      body: ListView(
        children: [
          ListTile(
            title: const Text('发生时间'),
            subtitle: Text(timeValueText(occurred) +
                (occurred.dateAmbiguous ? ' · 日期待确认' : '')),
            trailing: widget.readOnly
                ? null
                : TextButton(
                    onPressed: _confirmDate,
                    child: Text(occurred.dateAmbiguous ? '确认日期' : '改日期'),
                  ),
          ),
          const Divider(),
          for (final entry in data.entries)
            if (entry.key != 'photo_attachment_ids')
              ListTile(
                dense: true,
                title: Text(fieldLabels[entry.key] ?? entry.key),
                subtitle: Text(fieldValueText(entry.value)),
                trailing: Text(
                  _metaText(meta[entry.key]),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onTap: !widget.readOnly &&
                        (entry.value is String || entry.value is num)
                    ? () => _editField(entry.key, entry.value)
                    : null,
              ),
          if (photoCount > 0)
            ListTile(
                dense: true,
                title: const Text('照片'),
                subtitle: Text('$photoCount 张（在对话流里查看）')),
          // 睡眠记录附设备参考值：只作参考，排序永远让位于用户值（D-07、A-13）。
          if (record.recordType == RecordType.sleep &&
              occurred.localDate != null)
            FutureBuilder(
              future: widget.services.healthService.dayData(occurred.localDate!),
              builder: (context, snapshot) {
                final sleep = snapshot.data?.sleep;
                if (sleep == null) return const SizedBox.shrink();
                String hm(int ms) {
                  final t =
                      DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
                  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                }

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.watch_outlined, size: 18),
                  title: const Text('设备参考'),
                  subtitle: Text([
                    if (sleep.sleepOnsetMs != null)
                      '入睡 ${hm(sleep.sleepOnsetMs!)} · 醒来 ${hm(sleep.wakeMs!)}',
                    if (sleep.sleepDurationMin != null)
                      '睡眠 ${sleep.sleepDurationMin! ~/ 60} 小时 ${sleep.sleepDurationMin! % 60} 分钟',
                    '来源 ${sleep.sourceName}',
                  ].join(' · ')),
                );
              },
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('来源', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final (src, msg) in _sources)
            ListTile(
              dense: true,
              leading: const Icon(Icons.chat_bubble_outline, size: 18),
              title: Text(
                msg == null
                    ? '${enumToDb(src.sourceKind)} ${src.sourceId}'
                    : (msg.body ?? '[照片消息]'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: msg == null
                  ? null
                  : Text(_sentTime(msg) +
                      (src.messageRevisionNo != null && src.messageRevisionNo! < msg.revisionNo
                          ? ' · 引用的是修改前的版本'
                          : '')),
            ),
          if (_history.length > 1) ...[
            const Divider(),
            ExpansionTile(
              title: Text('历史版本（${_history.length}）'),
              children: [
                for (final h in _history.reversed)
                  ListTile(
                    dense: true,
                    title: Text('版本 ${h.recordVersion} · '
                        '${_producedByText(h.producedBy)}'),
                    subtitle: Text(
                        recordSummary(record.recordType, decodeData(h)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _metaText(FieldMeta? meta) {
    if (meta == null) return '';
    final origin = switch (meta.origin) {
      FieldOrigin.userStated => '你说的',
      FieldOrigin.userEdited => '你改的',
      FieldOrigin.device => '设备',
      FieldOrigin.modelInferred => '模型推断',
    };
    final review = switch (meta.reviewStatus) {
      ReviewStatus.unreviewed => '未核对',
      ReviewStatus.confirmed => '已确认',
      ReviewStatus.edited => '已修改',
    };
    return '$origin · $review';
  }

  String _sentTime(Message m) {
    final t = DateTime.fromMillisecondsSinceEpoch(m.sentAt).toLocal();
    return '${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _producedByText(String producedByJson) {
    final pb = ProducedBy.decode(producedByJson);
    return switch (pb.kind) {
      'organize_run' => '整理产生',
      'user_edit' => '你修改的',
      'accepted_suggestion' => '接受修正建议',
      _ => pb.kind,
    };
  }
}
