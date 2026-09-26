import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 用户资料（schema.md §4.1）：每次修改追加新版本行，历史全部保留（D-18）。
class ProfileRepository {
  ProfileRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 第一版包含的资料项（schema.md §4.1）。
  static const fieldKeys = [
    'birth_year_month',
    'sex_at_birth',
    'gender_identity',
    'height_cm',
    'exercise_preferences',
    'chronic_conditions',
    'medications',
    'allergies',
    'family_history',
    'smoking',
    'alcohol',
  ];

  Future<ProfileField> setField(
    String fieldKey, {
    Object? value,
    ProfileFieldState state = ProfileFieldState.provided,
  }) {
    return _db.transaction(() async {
      final latest = await _latest(fieldKey);
      final now = ids.nowMs();
      return _db.into(_db.profileFields).insertReturning(
            ProfileFieldsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              version: Value((latest?.version ?? 0) + 1),
              fieldKey: fieldKey,
              value: jsonEncode(value),
              state: state,
              updatedAt: now,
            ),
          );
    });
  }

  Future<ProfileField?> _latest(String fieldKey) =>
      (_db.select(_db.profileFields)
            ..where((t) => t.fieldKey.equals(fieldKey))
            ..orderBy([(t) => OrderingTerm.desc(t.version)])
            ..limit(1))
          .getSingleOrNull();

  /// 某项资料的当前值；从未填写过时为 null。
  Future<(ProfileField, Object?)?> current(String fieldKey) async {
    final row = await _latest(fieldKey);
    if (row == null) return null;
    return (row, jsonDecode(row.value));
  }

  /// 某项资料的全部历史版本，从早到晚。
  Future<List<ProfileField>> history(String fieldKey) =>
      (_db.select(_db.profileFields)
            ..where((t) => t.fieldKey.equals(fieldKey))
            ..orderBy([(t) => OrderingTerm.asc(t.version)]))
          .get();
}
