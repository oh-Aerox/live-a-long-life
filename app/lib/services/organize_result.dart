import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/time_value.dart';

/// 模型产出的一条候选记录（已通过严格校验）。
class OrganizeCandidate {
  OrganizeCandidate({
    required this.existingRecordId,
    required this.recordType,
    required this.occurred,
    this.occurredEnd,
    required this.data,
    required this.sourceMessageIds,
    required this.inferredFields,
  });

  /// 更新已有记录时为其 ID；新建为 null。
  final String? existingRecordId;
  final RecordType recordType;
  final TimeValue occurred;
  final TimeValue? occurredEnd;
  final Map<String, Object?> data;
  final List<String> sourceMessageIds;
  final Set<String> inferredFields;
}

/// 解析结果：有效项 + 被丢弃项的原因（缺字段丢弃该条，
/// 不猜默认值；解析整体失败时一条记录都不写）。
class OrganizeParseResult {
  OrganizeParseResult({required this.candidates, required this.errors});

  final List<OrganizeCandidate> candidates;
  final List<String> errors;
}

/// 解析模型返回的 JSON 数组。`validMessageIds` / `validRecordIds` 用于
/// 拒绝模型编造的来源和目标。返回 null 表示整体不是合法 JSON 数组。
OrganizeParseResult? parseOrganizeResponse(
  String responseText, {
  required Set<String> validMessageIds,
  required Set<String> validRecordIds,
  required String fallbackTz,
}) {
  var text = responseText.trim();
  // 容忍 ```json 围栏，但不做更多修补。
  if (text.startsWith('```')) {
    final firstNewline = text.indexOf('\n');
    if (firstNewline > 0) text = text.substring(firstNewline + 1);
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
  }
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (decoded is! List) return null;

  final candidates = <OrganizeCandidate>[];
  final errors = <String>[];
  for (var i = 0; i < decoded.length; i++) {
    final raw = decoded[i];
    try {
      candidates.add(_parseItem(raw, validMessageIds, validRecordIds,
          fallbackTz: fallbackTz));
    } catch (e) {
      errors.add('第 ${i + 1} 项被丢弃：$e');
    }
  }
  return OrganizeParseResult(candidates: candidates, errors: errors);
}

OrganizeCandidate _parseItem(
  Object? raw,
  Set<String> validMessageIds,
  Set<String> validRecordIds, {
  required String fallbackTz,
}) {
  if (raw is! Map) throw const FormatException('不是对象');
  final typeName = raw['record_type'];
  if (typeName is! String) throw const FormatException('缺 record_type');
  final RecordType recordType;
  try {
    recordType = enumFromDb(RecordType.values, typeName);
  } on StateError {
    throw FormatException('未知类型 $typeName');
  }

  final recordId = raw['record_id'];
  if (recordId != null) {
    if (recordId is! String || !validRecordIds.contains(recordId)) {
      throw const FormatException('record_id 不在可更新的已有记录里');
    }
  }

  final sources = raw['source_message_ids'];
  if (sources is! List || sources.isEmpty) {
    throw const FormatException('缺 source_message_ids');
  }
  final sourceIds = sources.cast<Object?>().map((s) {
    if (s is! String || !validMessageIds.contains(s)) {
      throw const FormatException('来源消息不在本批输入里');
    }
    return s;
  }).toList();

  final occurredRaw = raw['occurred'];
  if (occurredRaw is! Map) throw const FormatException('缺 occurred');
  final occurred =
      buildTimeValueFromModel(occurredRaw.cast<String, Object?>(), fallbackTz);
  final occurredEndRaw = raw['occurred_end'];
  final occurredEnd = occurredEndRaw is Map
      ? buildTimeValueFromModel(
          occurredEndRaw.cast<String, Object?>(), fallbackTz)
      : null;

  final data = raw['data'];
  if (data is! Map) throw const FormatException('缺 data');

  final inferred = raw['inferred_fields'];

  return OrganizeCandidate(
    existingRecordId: recordId as String?,
    recordType: recordType,
    occurred: occurred,
    occurredEnd: occurredEnd,
    data: data.cast<String, Object?>(),
    sourceMessageIds: sourceIds,
    inferredFields: inferred is List
        ? inferred.whereType<String>().toSet()
        : const <String>{},
  );
}

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// 把模型输出的时间对象转成 TimeValue（schema §1.2 的不变式在这里兜底）：
/// - 模型给了 local_time 且日期合法 → approx（本实现不区分 exact，统一按大约）；
///   时刻按设备本地时区换算成 UTC——v0.2 只在手机上整理，消息也是本机发的；
/// - 只有日期 → date_only 或模型声明的 part_of_day；
/// - 都没有 → unknown。
/// 不合法的字段一律降级，不编造。
TimeValue buildTimeValueFromModel(Map<String, Object?> raw, String fallbackTz) {
  final localDate = raw['local_date'];
  final validDate = localDate is String && _dateRe.hasMatch(localDate);
  final localTime = raw['local_time'];
  final validTime = localTime is String && _timeRe.hasMatch(localTime);
  final rawText = raw['raw_text'] is String ? raw['raw_text'] as String : null;
  final ambiguous = raw['date_ambiguous'] == true;
  final source = rawText != null && rawText.isNotEmpty
      ? TimeValueSource.userStated
      : TimeValueSource.inferredFromSentAt;

  if (!validDate) {
    return TimeValue(
      precision: TimePrecision.unknown,
      source: source,
      tz: fallbackTz,
      tzInferred: true,
      dateAmbiguous: ambiguous,
      rawText: rawText,
    );
  }

  if (validTime) {
    final parts = (localTime).split(':');
    final d = DateTime.parse(localDate);
    final instant = DateTime(
            d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]))
        .toUtc()
        .millisecondsSinceEpoch;
    return TimeValue(
      instantUtcMs: instant,
      tz: fallbackTz,
      tzInferred: true,
      localDate: localDate,
      precision: TimePrecision.approx,
      source: source,
      dateAmbiguous: ambiguous,
      rawText: rawText,
    );
  }

  final partOfDayRaw = raw['part_of_day'];
  PartOfDay? partOfDay;
  if (partOfDayRaw is String) {
    try {
      partOfDay = enumFromDb(PartOfDay.values, partOfDayRaw);
    } on StateError {
      partOfDay = null;
    }
  }
  return TimeValue(
    tz: fallbackTz,
    tzInferred: true,
    localDate: localDate,
    precision:
        partOfDay != null ? TimePrecision.partOfDay : TimePrecision.dateOnly,
    partOfDay: partOfDay,
    source: source,
    dateAmbiguous: ambiguous,
    rawText: rawText,
  );
}
