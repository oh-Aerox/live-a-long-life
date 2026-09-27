import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 一条待写入的健康样本（HealthKit 读取结果）。
class HealthSampleInput {
  const HealthSampleInput({
    required this.platformUuid,
    required this.sampleType,
    required this.startUtcMs,
    required this.endUtcMs,
    required this.tz,
    this.tzInferred = false,
    this.sourceBundleId,
    this.sleepStage,
    this.workoutType,
    this.energyKcal,
    this.distanceM,
    required this.sourceName,
  });

  final String platformUuid;
  final HealthSampleType sampleType;
  final int startUtcMs;
  final int endUtcMs;
  final String tz;
  final bool tzInferred;
  final String? sourceBundleId;
  final SleepStage? sleepStage;
  final String? workoutType;
  final double? energyKcal;
  final double? distanceM;
  final String sourceName;
}

/// 设备健康数据的读写（schema §2.5、§2.6，D-11）。
class HealthRepository {
  HealthRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 按 `platform_uuid` 幂等写入样本：已存在的只刷新 `fetched_at` 并清除
  /// 删除标记（锚点重建后重新读到，说明样本仍在），不重复建行。
  Future<int> upsertSamples(List<HealthSampleInput> inputs) {
    return _db.transaction(() async {
      var inserted = 0;
      final now = ids.nowMs();
      for (final s in inputs) {
        final existing = await (_db.select(_db.healthSamples)
              ..where((t) => t.platformUuid.equals(s.platformUuid)))
            .getSingleOrNull();
        if (existing != null) {
          await (_db.update(_db.healthSamples)
                ..where((t) => t.id.equals(existing.id)))
              .write(HealthSamplesCompanion(
            fetchedAt: Value(now),
            removedInSourceAt: const Value(null),
          ));
          continue;
        }
        await _db.into(_db.healthSamples).insert(HealthSamplesCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: now,
              createdOnDevice: _ctx.deviceId,
              platformUuid: s.platformUuid,
              sampleType: s.sampleType,
              startUtc: s.startUtcMs,
              endUtc: s.endUtcMs,
              tz: s.tz,
              tzInferred: Value(s.tzInferred),
              sourceBundleId: Value(s.sourceBundleId),
              sleepStage: Value(s.sleepStage),
              workoutType: Value(s.workoutType),
              energyKcal: Value(s.energyKcal),
              distanceM: Value(s.distanceM),
              sourceName: s.sourceName,
              fetchedAt: now,
            ));
        inserted++;
      }
      return inserted;
    });
  }

  /// anchored query 报告某些样本已在苹果健康中删除（D-11）。
  /// 只按明确报告标记；重读时缺席不算删除。
  Future<void> markRemovedInSource(List<String> platformUuids) async {
    if (platformUuids.isEmpty) return;
    await (_db.update(_db.healthSamples)
          ..where((t) => t.platformUuid.isIn(platformUuids)))
        .write(HealthSamplesCompanion(removedInSourceAt: Value(ids.nowMs())));
  }

  /// 某时间范围内的样本，不含已在来源删除的。
  Future<List<HealthSample>> samplesBetween({
    required HealthSampleType sampleType,
    required int startUtcMs,
    required int endUtcMs,
  }) =>
      (_db.select(_db.healthSamples)
            ..where((t) =>
                t.sampleType.equalsValue(sampleType) &
                t.removedInSourceAt.isNull() &
                t.endUtc.isBiggerThanValue(startUtcMs) &
                t.startUtc.isSmallerThanValue(endUtcMs))
            ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
          .get();

  /// 写入按天聚合值：同一天同指标覆盖本行（schema §2.6，设备数据非用户数据）。
  Future<void> upsertDaily({
    required String localDate,
    required String aggTz,
    required int intervalStartUtcMs,
    required int intervalEndUtcMs,
    required HealthMetric metric,
    required double value,
  }) {
    return _db.transaction(() async {
      final now = ids.nowMs();
      final existing = await (_db.select(_db.healthDaily)
            ..where((t) =>
                t.localDate.equals(localDate) & t.metric.equalsValue(metric)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.healthDaily)
              ..where((t) => t.id.equals(existing.id)))
            .write(HealthDailyCompanion(
          aggTz: Value(aggTz),
          intervalStartUtc: Value(intervalStartUtcMs),
          intervalEndUtc: Value(intervalEndUtcMs),
          value: Value(value),
          fetchedAt: Value(now),
        ));
        return;
      }
      await _db.into(_db.healthDaily).insert(HealthDailyCompanion.insert(
            id: ids.newId(),
            userId: _ctx.userId,
            createdAt: now,
            createdOnDevice: _ctx.deviceId,
            localDate: localDate,
            aggTz: aggTz,
            intervalStartUtc: intervalStartUtcMs,
            intervalEndUtc: intervalEndUtcMs,
            metric: metric,
            value: value,
            fetchedAt: now,
          ));
    });
  }

  /// 某天的聚合值。没有行表示"暂未读取到"，不表示 0（D-11）。
  Future<HealthDailyData?> dailyValue(String localDate, HealthMetric metric) =>
      (_db.select(_db.healthDaily)
            ..where((t) =>
                t.localDate.equals(localDate) & t.metric.equalsValue(metric)))
          .getSingleOrNull();

  Future<void> saveAnchor(HealthSampleType sampleType, List<int> anchor) =>
      _db.into(_db.healthAnchors).insertOnConflictUpdate(
            HealthAnchorsCompanion.insert(
              sampleType: sampleType,
              anchor: Uint8List.fromList(anchor),
              updatedAt: ids.nowMs(),
            ),
          );

  Future<HealthAnchor?> anchorOf(HealthSampleType sampleType) =>
      (_db.select(_db.healthAnchors)
            ..where((t) => t.sampleType.equalsValue(sampleType)))
          .getSingleOrNull();
}
