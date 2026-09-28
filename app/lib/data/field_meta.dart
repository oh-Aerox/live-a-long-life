import 'dart:convert';

/// 字段值的来源（schema §1.3 字段级）。
enum FieldOrigin { userStated, userEdited, device, modelInferred }

/// 字段的核对状态（D-04）。
enum ReviewStatus { unreviewed, confirmed, edited }

String _enumToDb(Enum e) => e.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );

T _enumFromDb<T extends Enum>(List<T> values, String db) =>
    values.firstWhere((v) => _enumToDb(v) == db);

/// 单个字段的来源与核对状态（schema §1.3）。
class FieldMeta {
  const FieldMeta({required this.origin, required this.reviewStatus});

  final FieldOrigin origin;
  final ReviewStatus reviewStatus;

  /// 受保护字段：整理不得覆盖，冲突转修正建议（D-05 提交规则第 3 条）。
  bool get isProtected =>
      reviewStatus == ReviewStatus.confirmed ||
      reviewStatus == ReviewStatus.edited;

  Map<String, Object?> toJson() => {
        'origin': _enumToDb(origin),
        'review_status': _enumToDb(reviewStatus),
      };

  factory FieldMeta.fromJson(Map<String, Object?> json) => FieldMeta(
        origin: _enumFromDb(FieldOrigin.values, json['origin'] as String),
        reviewStatus:
            _enumFromDb(ReviewStatus.values, json['review_status'] as String),
      );
}

/// 整条记录版本的字段级元数据：`field_path` → FieldMeta。
class FieldMetaMap {
  const FieldMetaMap(this.fields);

  final Map<String, FieldMeta> fields;

  FieldMeta? operator [](String fieldPath) => fields[fieldPath];

  String encode() =>
      jsonEncode(fields.map((k, v) => MapEntry(k, v.toJson())));

  static FieldMetaMap decode(String s) {
    final raw = jsonDecode(s) as Map<String, Object?>;
    return FieldMetaMap(raw.map((k, v) =>
        MapEntry(k, FieldMeta.fromJson(v as Map<String, Object?>))));
  }
}

/// 版本级来源：这一版由什么产生（schema §1.3 版本级）。
class ProducedBy {
  const ProducedBy._(this.kind, this.refId);

  /// `organize_run` 整理批次 / `user_edit` 用户编辑 /
  /// `accepted_suggestion` 接受了修正建议。
  final String kind;

  /// 批次 ID 或修正建议 ID；用户编辑时为空。
  final String? refId;

  factory ProducedBy.organizeRun(String runId) =>
      ProducedBy._('organize_run', runId);
  factory ProducedBy.userEdit() => const ProducedBy._('user_edit', null);
  factory ProducedBy.acceptedSuggestion(String suggestionId) =>
      ProducedBy._('accepted_suggestion', suggestionId);
  factory ProducedBy.medicalExtract(String modelCallId) =>
      ProducedBy._('medical_extract', modelCallId);

  Map<String, Object?> toJson() => {'kind': kind, 'ref_id': refId};

  factory ProducedBy.fromJson(Map<String, Object?> json) =>
      ProducedBy._(json['kind'] as String, json['ref_id'] as String?);

  String encode() => jsonEncode(toJson());

  static ProducedBy decode(String s) =>
      ProducedBy.fromJson(jsonDecode(s) as Map<String, Object?>);
}
