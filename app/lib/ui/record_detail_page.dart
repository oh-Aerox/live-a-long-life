import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/time_value.dart';
import '../services/medical_space_service.dart' show MedicalFile;
import 'adaptive.dart';
import 'medical_folder_page.dart' show medicalDocTypeLabels;
import 'record_ui.dart';
import 'source_viewer_page.dart';

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

  /// 附件来源（医疗原件）的本机状态：原件在不在本机、已清理时能否取回
  /// （A-17：不能伪称原件仍在本机）。
  Map<String, _AttachmentSource> _attachments = {};

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
    final attachments = <String, _AttachmentSource>{};
    Map<String, MedicalFile>? medicalFiles;
    for (final src in sourceRows) {
      Message? msg;
      if (src.sourceKind == RecordSourceKind.message) {
        msg = await s.messages.byId(src.sourceId);
      } else if (src.sourceKind == RecordSourceKind.attachment) {
        final att = await s.attachments.byId(src.sourceId);
        if (att != null) {
          medicalFiles ??= {
            for (final f in await s.medicalSpace.list()) f.attachment.id: f
          };
          final f = medicalFiles[att.id];
          attachments[att.id] = _AttachmentSource(
            attachment: att,
            state: await s.attachments.copyStateOf(att.id),
            archivedOnMac: f?.archivedOnMac ?? false,
            label: medicalDocTypeLabels.entries
                    .where((e) => e.key.name == f?.docLabel)
                    .map((e) => e.value)
                    .firstOrNull ??
                att.originalFilename ??
                '附件',
          );
        }
      }
      sources.add((src, msg));
    }
    if (mounted) {
      setState(() {
        _record = record;
        _rev = rev;
        _history = history;
        _sources = sources;
        _attachments = attachments;
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

  /// 重新整理这条记录（D-05 触发时机 4）：来源消息重新排队，批次异步执行。
  Future<void> _reorganize() async {
    final run =
        await widget.services.organizeService.reorganizeRecord(widget.recordId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(run == null
          ? '无法重新整理：没有配置模型，或这条记录没有可重排的来源消息'
          : '已加入整理队列，稍后自动更新'),
    ));
  }

  /// 删除这条记录（只在手机上，Mac 只读）：标记删除，走变更日志同步到
  /// Mac；指向它的待处理修正建议一起作废。原消息由用户选是否一起删。
  /// 医疗文件提取出的记录在医疗文件页整份删除，这里不提供。
  Future<void> _delete() async {
    final s = widget.services;
    final messageIds = {
      for (final (src, msg) in _sources)
        if (msg != null && msg.deletedAt == null) src.sourceId,
    };
    final others = (await s.records.recordsCitingMessages(messageIds))
      ..remove(widget.recordId);
    if (!mounted) return;
    final choice = await showAdaptiveDialog<String>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('删除这条记录？'),
        content: Text([
          '记录从日视图移除，不再参与周报和分析；同步后 Mac 上也会移除。',
          if (messageIds.isNotEmpty)
            '原消息（${messageIds.length} 条）还在对话里，可以一起删掉。'
                '${others.isEmpty ? '' : '这些消息还整理出了另外 ${others.length} 条记录，删消息不影响那些记录。'}',
        ].join('\n\n')),
        actions: [
          if (messageIds.isNotEmpty)
            DialogAction(
                onPressed: () => Navigator.pop(context, 'with_messages'),
                isDestructiveAction: true,
                child: const Text('连同原消息一起删除')),
          DialogAction(
              onPressed: () => Navigator.pop(context, 'record'),
              isDestructiveAction: true,
              child: Text(messageIds.isEmpty ? '删除' : '只删除记录')),
          DialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
        ],
      ),
    );
    if (choice == null) return;
    await s.db.transaction(() async {
      await s.records.markDeleted(widget.recordId);
      await s.suggestionService.obsoletePendingFor(widget.recordId);
      if (choice == 'with_messages') {
        for (final id in messageIds) {
          await s.messages.markDeleted(id);
        }
      }
    });
    if (mounted) Navigator.pop(context);
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
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator.adaptive()));
    }
    final data = decodeData(rev);
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    final occurred = TimeValue.decode(rev.occurred);
    final photoCount = (data['photo_attachment_ids'] as List?)?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(recordTypeLabels[record.recordType]!),
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新整理',
              onPressed: _reorganize,
            ),
          if (!widget.readOnly && _attachments.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除这条记录',
              onPressed: _delete,
            ),
        ],
      ),
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
            if (_attachments[src.sourceId] case final a?
                when src.sourceKind == RecordSourceKind.attachment)
              _attachmentTile(a)
            else
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

  /// 医疗原件来源：在本机可打开（带记录里的原件定位）；已清理时说明
  /// 记录保留、给出取回入口，Mac 端副本只读不取回（D-22、A-17）。
  Widget _attachmentTile(_AttachmentSource a) {
    final present = a.state == CopyState.present;
    final subtitle = present
        ? '在本机 · 点开查看原件'
        : a.state == CopyState.offloaded
            ? '手机上已清理，记录保留 · '
                '${a.archivedOnMac ? 'Mac 已归档，可取回（需 Mac 在线）' : '没有确认的其他副本，可重新上传同一文件补回'}'
            : '本机没有这份文件，记录保留';
    return ListTile(
      dense: true,
      leading: const Icon(Icons.description_outlined, size: 18),
      title: Text('原件：${a.label}'),
      subtitle: Text(subtitle),
      trailing: !present &&
              a.state == CopyState.offloaded &&
              a.archivedOnMac &&
              !widget.readOnly
          ? TextButton(onPressed: () => _retrieve(a), child: const Text('取回'))
          : null,
      onTap: present ? () => _openAttachment(a) : null,
    );
  }

  Future<void> _openAttachment(_AttachmentSource a) async {
    // 状况记录带原件定位（框出诊断那一行）；其余打开第一页。
    final data = _rev == null ? null : jsonDecode(_rev!.data);
    final loc = data is Map ? data['locator'] : null;
    final locator = loc is Map && loc['attachment_id'] == a.attachment.id
        ? loc.cast<String, Object?>()
        : {'attachment_id': a.attachment.id, 'page_no': 1, 'attachment_page': 1};
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SourceViewerPage(
            services: widget.services, locator: locator, title: a.label),
      ),
    );
  }

  Future<void> _retrieve(_AttachmentSource a) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.services.medicalSpace.retrieve(a.attachment.id);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? '已从 Mac 取回，原件可以查看了'
          : 'Mac 不可达或没有这份文件；记录不受影响，也可以重新上传同一文件补回'),
    ));
    await _load();
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

class _AttachmentSource {
  const _AttachmentSource({
    required this.attachment,
    required this.state,
    required this.archivedOnMac,
    required this.label,
  });

  final Attachment attachment;
  final CopyState state;
  final bool archivedOnMac;
  final String label;
}
