import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// 设置键值对（schema.md §4.2），值统一存 JSON。
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// 默认值（schema.md §4.2）。`home_tz` 无默认，首次引导时写入。
  static const defaults = <String, Object?>{
    'review_times': ['21:30'],
    'review_enabled': true,
    'day_view_start': '00:00',
    'idle_preorganize_sec': 180,
    'healthkit_enabled_types': ['sleep', 'steps', 'workout', 'active_energy'],
  };

  Future<Object?> get(String key) async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return defaults[key];
    return jsonDecode(row.value);
  }

  Future<void> set(String key, Object? value, {int? nowMs}) async {
    await _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion(
          key: Value(key),
          value: Value(jsonEncode(value)),
          updatedAt:
              Value(nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch),
        ));
  }

  Future<Map<String, Object?>> getAll() async {
    final rows = await _db.select(_db.settings).get();
    final result = Map<String, Object?>.from(defaults);
    for (final row in rows) {
      result[row.key] = jsonDecode(row.value);
    }
    return result;
  }
}
