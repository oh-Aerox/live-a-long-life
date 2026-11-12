import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/lab_abnormal.dart';
import '../data/record_summary.dart';
import '../data/repositories/medical_document_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/same_item.dart';
import '../data/workout_names.dart';
import 'health_live.dart';
import 'health_service.dart';
import 'tool_chat.dart';

/// 一次工具调用的结果：[content] 发回模型，[note] 是给用户看的一句话
/// （列在问题下方"查阅了什么"，并写进调用记录）。
class ToolOutcome {
  const ToolOutcome(this.content, this.note, {this.ephemeral = false});

  final String content;
  final String note;

  /// 实时读取的健康数据（D-44）：只发给模型，调用记录里只写 [note]。
  final bool ephemeral;
}

/// 咨询 agent 的只读工具（D-43）。只读、不写库；医疗类只给已核对的内容
/// （D-04：未核对的不算事实）。日期范围单次最多 [maxDays] 天，防止一次把
/// 全部数据发出去。
class ConsultTools {
  ConsultTools({
    required AppDatabase db,
    required RecordRepository records,
    required MedicalDocumentRepository documents,
    required Future<DeviceDayData> Function(String localDate) deviceData,
    HealthLiveReader? live,
    Future<bool> Function()? liveEnabled,
  })  : _db = db,
        _records = records,
        _documents = documents,
        _deviceData = deviceData,
        _live = live,
        _liveEnabled = liveEnabled;

  final AppDatabase _db;
  final RecordRepository _records;
  final MedicalDocumentRepository _documents;
  final Future<DeviceDayData> Function(String localDate) _deviceData;

  /// 已同步的某天设备数据（咨询页示例问题也用它判断有没有数据）。
  Future<DeviceDayData> deviceData(String localDate) => _deviceData(localDate);

  /// 实时读取（D-44）：只在 iPhone 上有；用户关掉健康数据同步时不提供。
  final HealthLiveReader? _live;
  final Future<bool> Function()? _liveEnabled;

  /// 这台设备现在能否实时读取健康数据。
  Future<bool> liveAvailable() async =>
      _live != null && (await _liveEnabled?.call() ?? true);

  /// 本次可用的工具：基础五个，能实时读取时再加 [liveSpec]。
  Future<List<ToolSpec>> availableSpecs() async =>
      [...specs, if (await liveAvailable()) liveSpec];

  static final liveSpec = ToolSpec(
    name: 'read_health_live',
    description: '实时读取手机"健康"App 里的数据（不经本应用保存，比 get_device_data '
        '更全更细）。一次读一个指标，时间范围单次最多 31 天。可读指标：'
        '${HealthLiveReader.metricGuide}。'
        '问某次运动的心率：先读 workouts 拿到起止时间，再读 heart_rate。'
        '问昨晚睡眠：读 sleep_stages，范围设为昨天 18:00 到今天 12:00。',
    parameters: {
      'type': 'object',
      'properties': {
        'metric': {'type': 'string', 'enum': HealthLiveReader.metricKeys},
        'start': {
          'type': 'string',
          'description': '开始时间 YYYY-MM-DD HH:MM（只写日期表示当天 00:00）',
        },
        'end': {
          'type': 'string',
          'description': '结束时间 YYYY-MM-DD HH:MM（只写日期表示到当天结束）',
        },
      },
      'required': ['metric', 'start', 'end'],
    },
  );

  static const maxDays = 31;
  static const _maxDocuments = 15;
  static const _maxLabItems = 5;

  static const _dateRange = {
    'start_date': {'type': 'string', 'description': '开始日期 YYYY-MM-DD'},
    'end_date': {'type': 'string', 'description': '结束日期 YYYY-MM-DD（含）'},
  };

  static final specs = [
    const ToolSpec(
      name: 'get_records',
      description: '按日期范围查用户记下的日常记录摘要（睡眠、饮食、运动、心情、'
          '身体不适、其他，以及已核对的身体状况和报告要点）。单次最多 31 天。',
      parameters: {
        'type': 'object',
        'properties': {
          ..._dateRange,
          'types': {
            'type': 'array',
            'description': '只查这些类型，不填查全部',
            'items': {
              'type': 'string',
              'enum': [
                'sleep', 'meal', 'exercise', 'mood', 'symptom', 'note', //
                'condition', 'lab_panel',
              ],
            },
          },
        },
        'required': ['start_date', 'end_date'],
      },
    ),
    const ToolSpec(
      name: 'get_device_data',
      description: '按日期范围查手机/手表健康数据：睡眠时长与入睡醒来时间、步数、'
          '活动能量、体能训练。单次最多 31 天。',
      parameters: {
        'type': 'object',
        'properties': _dateRange,
        'required': ['start_date', 'end_date'],
      },
    ),
    const ToolSpec(
      name: 'list_lab_items',
      description: '列出做过的检验项目（只含已核对的），每项给最近一次的数值、'
          '日期、是否异常和测过几次。先用它找项目名，再用 get_lab_history 查历史。',
      parameters: {
        'type': 'object',
        'properties': {
          'keyword': {'type': 'string', 'description': '项目名或分组包含的字'},
          'abnormal_only': {
            'type': 'boolean',
            'description': '只列最近一次异常的项目',
          },
        },
      },
    ),
    const ToolSpec(
      name: 'get_lab_history',
      description: '查某个检验项目历次的数值、单位、参考范围和是否异常（只含已核对的），'
          '按日期升序。同名项目分属不同标本（如血、尿白细胞）时分别列出。',
      parameters: {
        'type': 'object',
        'properties': {
          'item': {'type': 'string', 'description': '项目名，如 血红蛋白、ALT'},
        },
        'required': ['item'],
      },
    ),
    const ToolSpec(
      name: 'search_medical_documents',
      description: '查病历、检验/影像报告、体检、处方里已核对的文字内容（诊断、所见、'
          '结论等）、异常指标和开药。可按关键词和日期范围筛选，最多返回 15 份，新的在前。',
      parameters: {
        'type': 'object',
        'properties': {
          'keyword': {'type': 'string', 'description': '在文字、标题、机构里查找'},
          ..._dateRange,
        },
      },
    ),
  ];

  /// 执行一次工具调用。参数有误时把错误发回模型，让它改参数重试。
  Future<ToolOutcome> run(ToolCall call) async {
    if (call.argumentsError != null) {
      return _error(call.name, call.argumentsError!);
    }
    final a = call.arguments;
    try {
      return switch (call.name) {
        'get_records' => await _getRecords(a),
        'get_device_data' => await _getDeviceData(a),
        'list_lab_items' => await _listLabItems(a),
        'get_lab_history' => await _getLabHistory(a),
        'search_medical_documents' => await _searchDocuments(a),
        'read_health_live' => await _readLive(a),
        _ => _error(call.name, '没有这个工具'),
      };
    } on FormatException catch (e) {
      return _error(call.name, e.message);
    }
  }

  Future<ToolOutcome> _readLive(Map<String, Object?> a) async {
    if (!await liveAvailable()) {
      return _error('read_health_live', '这台设备不能实时读取健康数据，请改用 get_device_data');
    }
    final start = _time(a['start'], endOfDay: false);
    final end = _time(a['end'], endOfDay: true);
    if (!end.isAfter(start)) throw const FormatException('结束时间早于开始时间');
    if (end.difference(start).inDays > maxDays) {
      throw const FormatException('单次最多读 $maxDays 天，请缩小范围');
    }
    final (content, note) = await _live!.read('${a['metric']}', start, end);
    return ToolOutcome(content, '实时读取：$note', ephemeral: true);
  }

  /// "YYYY-MM-DD HH:MM" 或 "YYYY-MM-DD"；只有日期时按当天开始/结束。
  static DateTime _time(Object? v, {required bool endOfDay}) {
    final s = '${v ?? ''}'.trim();
    final m = RegExp(r'^(\d{4}-\d{2}-\d{2})(?:[ T](\d{2}):(\d{2}))?$')
        .firstMatch(s);
    final day = m == null ? null : DateTime.tryParse(m[1]!);
    if (day == null) {
      throw FormatException('时间要写成 YYYY-MM-DD HH:MM：$s');
    }
    if (m![2] == null) {
      return endOfDay ? day.add(const Duration(days: 1)) : day;
    }
    return day.add(
        Duration(hours: int.parse(m[2]!), minutes: int.parse(m[3]!)));
  }

  ToolOutcome _error(String name, String message) =>
      ToolOutcome(jsonEncode({'error': message}), '$name 参数有误');

  Future<ToolOutcome> _getRecords(Map<String, Object?> a) async {
    final (from, to) = _range(a);
    final types = (a['types'] as List?)?.map((e) => '$e').toSet();
    final out = <Map<String, Object?>>[];
    for (final rec in await _records.since(from)) {
      final date = rec.localDate;
      if (date == null || date.compareTo(to) > 0) continue;
      if (rec.currentRevisionId == null) continue;
      if (types != null && !types.contains(enumToDb(rec.recordType))) continue;
      final rev = await _records.currentRevisionOf(rec.id);
      final summary = consultRecordSummary(rec.recordType, rev);
      if (summary == null) continue;
      out.add({
        'date': date,
        'type': enumToDb(rec.recordType),
        'summary': summary,
      });
    }
    out.sort((x, y) => '${x['date']}'.compareTo('${y['date']}'));
    return ToolOutcome(
      jsonEncode({'start_date': from, 'end_date': to, 'records': out}),
      '记录 ${_short(from)}~${_short(to)}（${out.length} 条）',
    );
  }

  Future<ToolOutcome> _getDeviceData(Map<String, Object?> a) async {
    final (from, to) = _range(a);
    final days = <Map<String, Object?>>[];
    final empty = <String>[];
    for (var d = DateTime.parse(from);
        !d.isAfter(DateTime.parse(to));
        d = d.add(const Duration(days: 1))) {
      final date = _fmt(d);
      final data = await _deviceData(date);
      if (data.isEmpty) {
        empty.add(date);
        continue;
      }
      final sleep = data.sleep;
      days.add({
        'date': date,
        if (sleep != null)
          'sleep': [
            if (sleep.sleepDurationMin != null)
              '睡眠 ${_hm(sleep.sleepDurationMin!)}'
            else if (sleep.inBedDurationMin != null)
              '在床 ${_hm(sleep.inBedDurationMin!)}（睡眠时长未知）',
            if (sleep.sleepOnsetMs != null) '入睡 ${_clock(sleep.sleepOnsetMs!)}',
            if (sleep.wakeMs != null) '醒来 ${_clock(sleep.wakeMs!)}',
          ].join('，'),
        if (data.steps != null) 'steps': data.steps!.round(),
        if (data.activeEnergyKcal != null)
          'active_energy_kcal': data.activeEnergyKcal!.round(),
        if (data.workouts.isNotEmpty)
          'workouts': [
            for (final w in data.workouts)
              [
                workoutLabel(w.workoutType),
                '${_clock(w.startUtc)} 起 ${((w.endUtc - w.startUtc) / 60000).round()} 分钟',
                if (w.energyKcal != null) '${w.energyKcal!.round()} 千卡',
              ].join('，'),
          ],
      });
    }
    return ToolOutcome(
      jsonEncode({
        'days': days,
        // 没有数据 ≠ 0（D-11）：可能没戴设备或还没同步。
        'days_without_data': empty,
      }),
      '健康数据 ${_short(from)}~${_short(to)}（${days.length} 天有数据）',
    );
  }

  /// 已核对、不是占位值的检验结果（D-04）。
  Future<List<LabResult>> _reviewedLabs() async => [
        for (final r in await _db.select(_db.labResults).get())
          if (r.reviewStatus != ReviewStatus.unreviewed &&
              !SameItem.isPlaceholderValue(r.valueRaw))
            r,
      ];

  bool _abnormal(LabResult r) => isAbnormalLab(
        flagRaw: r.flagRaw,
        valueRaw: r.valueRaw,
        valueNum: r.valueNum,
        refLow: r.refLow,
        refHigh: r.refHigh,
        refRangeRaw: r.refRangeRaw,
      );

  Future<ToolOutcome> _listLabItems(Map<String, Object?> a) async {
    final keyword = (a['keyword'] as String?)?.trim() ?? '';
    final abnormalOnly = a['abnormal_only'] == true;
    final byKey = <String, List<LabResult>>{};
    for (final r in await _reviewedLabs()) {
      (byKey[r.itemKey] ??= []).add(r);
    }
    final items = <Map<String, Object?>>[];
    for (final MapEntry(key: key, value: rows) in byKey.entries) {
      rows.sort((x, y) => (x.examDate ?? '').compareTo(y.examDate ?? ''));
      final latest = rows.last;
      final group = SameItem.trendGroup(latest.panelRaw, key);
      if (keyword.isNotEmpty &&
          !key.contains(keyword) &&
          !group.contains(keyword) &&
          !rows.any((r) => r.itemNameRaw.contains(keyword))) {
        continue;
      }
      final abnormal = _abnormal(latest);
      if (abnormalOnly && !abnormal) continue;
      items.add({
        'item': key,
        'group': group,
        'latest': '${latest.valueRaw}${latest.unitRaw ?? ''}',
        'date': latest.examDate,
        'abnormal': abnormal,
        'times': rows.length,
      });
    }
    items.sort((x, y) => '${x['group']}${x['item']}'
        .compareTo('${y['group']}${y['item']}'));
    return ToolOutcome(
      jsonEncode({'items': items}),
      [
        '检验项目列表',
        if (keyword.isNotEmpty) '"$keyword"',
        if (abnormalOnly) '只看异常',
        '（${items.length} 项）',
      ].join(' '),
    );
  }

  Future<ToolOutcome> _getLabHistory(Map<String, Object?> a) async {
    final item = (a['item'] as String?)?.trim() ?? '';
    if (item.isEmpty) throw const FormatException('item 不能为空');
    final key = SameItem.labKey(item);
    final byKey = <String, List<LabResult>>{};
    for (final r in await _reviewedLabs()) {
      if (r.itemKey == key ||
          r.itemKey.contains(item) ||
          r.itemNameRaw.contains(item)) {
        (byKey[r.itemKey] ??= []).add(r);
      }
    }
    // 完全同名的排前面，其余按项目名。
    final keys = byKey.keys.toList()
      ..sort((x, y) => x == key ? -1 : (y == key ? 1 : x.compareTo(y)));
    final out = <Map<String, Object?>>[];
    var points = 0;
    for (final k in keys.take(_maxLabItems)) {
      final rows = byKey[k]!
        ..sort((x, y) => (x.examDate ?? '').compareTo(y.examDate ?? ''));
      points += rows.length;
      out.add({
        'item': k,
        'group': SameItem.trendGroup(rows.last.panelRaw, k),
        'history': [
          for (final r in rows)
            {
              'date': r.examDate,
              'value': r.valueRaw,
              if (r.unitRaw != null) 'unit': r.unitRaw,
              if (r.refRangeRaw != null) 'reference': r.refRangeRaw,
              if (r.flagRaw != null) 'flag': r.flagRaw,
              'abnormal': _abnormal(r),
            },
        ],
      });
    }
    return ToolOutcome(
      jsonEncode({
        'items': out,
        if (keys.length > _maxLabItems)
          'more_items': keys.skip(_maxLabItems).toList(),
      }),
      '检验历史"$item"（${out.length} 项 $points 次）',
    );
  }

  Future<ToolOutcome> _searchDocuments(Map<String, Object?> a) async {
    final keyword = (a['keyword'] as String?)?.trim() ?? '';
    final from = a['start_date'] == null ? null : _date(a['start_date']);
    final to = a['end_date'] == null ? null : _date(a['end_date']);
    final out = <Map<String, Object?>>[];
    var matched = 0;
    // byType 按日期降序：新的在前。
    for (final rec in await _records.byType(RecordType.labPanel)) {
      if (rec.currentRevisionId == null) continue;
      final date = rec.localDate ?? '';
      if (from != null && date.compareTo(from) < 0) continue;
      if (to != null && date.compareTo(to) > 0) continue;
      final rev = await _records.currentRevisionOf(rec.id);
      final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      final docId = data['medical_document_id'] as String?;
      final doc = docId == null ? null : await _documents.byId(docId);
      if (doc != null && doc.deletedAt != null) continue;
      final entry = _documentEntry(date, doc, data, meta);
      if (entry == null) continue;
      if (keyword.isNotEmpty && !jsonEncode(entry).contains(keyword)) continue;
      matched++;
      if (out.length < _maxDocuments) out.add(entry);
    }
    return ToolOutcome(
      jsonEncode({
        'documents': out,
        if (matched > out.length) 'more_documents': matched - out.length,
      }),
      [
        '报告内容',
        if (keyword.isNotEmpty) '"$keyword"',
        if (from != null || to != null)
          '${from == null ? '' : _short(from)}~${to == null ? '' : _short(to)}',
        '（$matched 份）',
      ].join(' '),
    );
  }

  static const _docTypeLabels = {
    MedicalDocType.labReport: '检验报告',
    MedicalDocType.imagingReport: '影像报告',
    MedicalDocType.visitRecord: '门诊病历',
    MedicalDocType.prescription: '处方',
    MedicalDocType.dischargeSummary: '出院小结',
    MedicalDocType.physicalExam: '体检报告',
    MedicalDocType.other: '其他',
  };

  /// 一份报告里已核对的文字、异常指标与开药；什么都没核对过返回 null。
  Map<String, Object?>? _documentEntry(String date, MedicalDocument? doc,
      Map<String, Object?> data, FieldMetaMap meta) {
    bool reviewed(String key) => meta[key]?.isProtected ?? false;
    final findings = data['findings'] as List? ?? const [];
    final texts = [
      for (var i = 0; i < findings.length; i++)
        if (reviewed('findings.$i'))
          '${(findings[i] as Map)['section_raw'] ?? ''}：'
              '${_clip('${(findings[i] as Map)['text_raw'] ?? ''}')}',
    ];
    final results = data['results'] as List? ?? const [];
    final abnormal = <String>[];
    for (var i = 0; i < results.length; i++) {
      final r = results[i] as Map;
      if (!reviewed('results.$i')) continue;
      if (!isAbnormalLab(
        flagRaw: r['flag_raw'] as String?,
        valueRaw: '${r['value_raw']}',
        valueNum: (r['value_num'] as num?)?.toDouble(),
        refLow: (r['ref_low'] as num?)?.toDouble(),
        refHigh: (r['ref_high'] as num?)?.toDouble(),
        refRangeRaw: r['ref_range_raw'] as String?,
      )) {
        continue;
      }
      abnormal.add([
        SameItem.itemName('${r['item_name_raw']}'),
        '${r['value_raw']}${r['unit_raw'] ?? ''}',
        if (r['ref_range_raw'] != null) '（参考 ${r['ref_range_raw']}）',
      ].join(' '));
    }
    final meds = data['medications'] as List? ?? const [];
    final medNames = [
      for (var i = 0; i < meds.length; i++)
        if (reviewed('medications.$i')) '${(meds[i] as Map)['name']}',
    ];
    if (texts.isEmpty && abnormal.isEmpty && medNames.isEmpty) return null;
    return {
      'date': date,
      if (doc != null) 'type': _docTypeLabels[doc.docType],
      if (doc?.institutionText != null) 'institution': doc!.institutionText,
      if (doc?.visitTitle != null) 'title': doc!.visitTitle,
      if (texts.isNotEmpty) 'findings': texts,
      if (abnormal.isNotEmpty) 'abnormal_results': abnormal,
      if (medNames.isNotEmpty) 'medications': medNames,
    };
  }

  static String _clip(String s) =>
      s.length > 1000 ? '${s.substring(0, 1000)}…' : s;

  static String _date(Object? v) {
    final s = '${v ?? ''}'.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
        DateTime.tryParse(s) == null) {
      throw FormatException('日期要写成 YYYY-MM-DD：$s');
    }
    return s;
  }

  static (String, String) _range(Map<String, Object?> a) {
    final from = _date(a['start_date']);
    final to = _date(a['end_date']);
    final days =
        DateTime.parse(to).difference(DateTime.parse(from)).inDays + 1;
    if (days < 1) throw const FormatException('结束日期早于开始日期');
    if (days > maxDays) {
      throw const FormatException('单次最多查 $maxDays 天，请分段查询');
    }
    return (from, to);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _short(String date) => date.substring(5);

  static String _hm(int min) => '${min ~/ 60} 小时 ${min % 60} 分钟';

  static String _clock(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

/// 咨询里一条记录的摘要；医疗类只发已核对的内容（D-04），
/// 没有可发内容时返回 null。
String? consultRecordSummary(RecordType type, RecordRevision rev) {
  final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
  final meta = FieldMetaMap.decode(rev.fieldMeta);
  switch (type) {
    case RecordType.condition:
      if (!(meta['condition']?.isProtected ?? false)) return null;
      return recordSummary(type, data);
    case RecordType.labPanel:
      return reviewedMedicalSummary(data, meta);
    default:
      return recordSummary(type, data);
  }
}
