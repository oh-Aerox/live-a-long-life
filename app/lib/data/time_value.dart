import 'dart:convert';

/// 时间精度（schema §1.2）。
enum TimePrecision { exact, approx, partOfDay, dateOnly, unknown }

/// 时段（schema §1.2）。
enum PartOfDay { earlyMorning, morning, noon, afternoon, evening, night }

/// 时间值的来源（schema §1.2）。
enum TimeValueSource { userStated, inferredFromSentAt, device }

String _enumToDb(Enum e) => e.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );

T _enumFromDb<T extends Enum>(List<T> values, String db) =>
    values.firstWhere((v) => _enumToDb(v) == db);

/// 发生时间（schema §1.2，D-06）。
///
/// 不变式（构造时校验，不编造时刻）：
/// - `instantUtcMs` 只在 exact / approx 有值；
/// - `partOfDay` 只在 precision = partOfDay 有值；
/// - exact / approx / partOfDay / dateOnly 必有 `localDate`；
///   unknown 的 `localDate` 可空（能按发送时间推断时有）。
class TimeValue {
  TimeValue({
    this.instantUtcMs,
    this.tz,
    this.tzInferred = false,
    this.localDate,
    required this.precision,
    this.partOfDay,
    required this.source,
    this.dateAmbiguous = false,
    this.rawText,
  }) {
    final hasInstant = instantUtcMs != null;
    final exactish =
        precision == TimePrecision.exact || precision == TimePrecision.approx;
    if (hasInstant != exactish) {
      throw ArgumentError(
          'instantUtcMs 只在 exact/approx 精度下有值（当前 $precision）');
    }
    if ((partOfDay != null) != (precision == TimePrecision.partOfDay)) {
      throw ArgumentError('partOfDay 只在 part_of_day 精度下有值（当前 $precision）');
    }
    if (localDate == null && precision != TimePrecision.unknown) {
      throw ArgumentError('精度 $precision 必须有 localDate');
    }
  }

  /// UTC 毫秒时刻，只在 exact / approx 有值。
  final int? instantUtcMs;

  /// IANA 时区名，比如 Asia/Shanghai。
  final String? tz;

  /// 时区是推断的（取自发送时或读取时的时区）时为真。
  final bool tzInferred;

  /// 事件的自然日期，格式 yyyy-MM-dd。
  final String? localDate;

  final TimePrecision precision;
  final PartOfDay? partOfDay;
  final TimeValueSource source;

  /// 日期理解有歧义（比如凌晨说的"今天晚饭"）时为真，界面提示核对。
  final bool dateAmbiguous;

  /// 用户原话中表示时间的片段。
  final String? rawText;

  Map<String, Object?> toJson() => {
        'instant_utc': instantUtcMs,
        'tz': tz,
        'tz_inferred': tzInferred,
        'local_date': localDate,
        'precision': _enumToDb(precision),
        'part_of_day': partOfDay == null ? null : _enumToDb(partOfDay!),
        'source': _enumToDb(source),
        'date_ambiguous': dateAmbiguous,
        'raw_text': rawText,
      };

  factory TimeValue.fromJson(Map<String, Object?> json) => TimeValue(
        instantUtcMs: json['instant_utc'] as int?,
        tz: json['tz'] as String?,
        tzInferred: json['tz_inferred'] as bool? ?? false,
        localDate: json['local_date'] as String?,
        precision:
            _enumFromDb(TimePrecision.values, json['precision'] as String),
        partOfDay: json['part_of_day'] == null
            ? null
            : _enumFromDb(PartOfDay.values, json['part_of_day'] as String),
        source: _enumFromDb(TimeValueSource.values, json['source'] as String),
        dateAmbiguous: json['date_ambiguous'] as bool? ?? false,
        rawText: json['raw_text'] as String?,
      );

  String encode() => jsonEncode(toJson());

  static TimeValue decode(String s) =>
      TimeValue.fromJson(jsonDecode(s) as Map<String, Object?>);
}
