import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 模型配置的读写（schema §4.3，D-16）。
/// key 本身不进数据库，只存 Keychain 引用名；本表不同步、不进备份。
class ModelConfigRepository {
  ModelConfigRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  /// 新增配置。`makeDefault` 为真或当前没有默认配置时设为默认。
  Future<ModelConfig> add({
    required ModelPreset preset,
    required ModelProtocol protocol,
    required String baseUrl,
    required String model,
    required DataBoundary dataBoundary,
    required String keychainRef,
    bool makeDefault = false,
  }) {
    return _db.transaction(() async {
      final hasDefault = await _defaultConfig() != null;
      final beDefault = makeDefault || !hasDefault;
      if (beDefault) await _clearDefault();
      return _db.into(_db.modelConfigs).insertReturning(
            ModelConfigsCompanion.insert(
              id: ids.newId(),
              userId: _ctx.userId,
              createdAt: ids.nowMs(),
              createdOnDevice: _ctx.deviceId,
              preset: preset,
              protocol: protocol,
              baseUrl: baseUrl,
              model: model,
              dataBoundary: dataBoundary,
              keychainRef: keychainRef,
              isDefault: Value(beDefault),
            ),
          );
    });
  }

  /// 设为默认，同时取消其他配置的默认标记（默认配置唯一）。
  Future<void> setDefault(String configId) {
    return _db.transaction(() async {
      await _clearDefault();
      await (_db.update(_db.modelConfigs)..where((t) => t.id.equals(configId)))
          .write(const ModelConfigsCompanion(isDefault: Value(true)));
    });
  }

  Future<void> _clearDefault() => (_db.update(_db.modelConfigs)
        ..where((t) => t.isDefault.equals(true)))
      .write(const ModelConfigsCompanion(isDefault: Value(false)));

  Future<ModelConfig?> _defaultConfig() => (_db.select(_db.modelConfigs)
        ..where((t) => t.isDefault.equals(true) & t.deletedAt.isNull()))
      .getSingleOrNull();

  /// 当前默认配置；没有配置时为空，消息保持"待整理"（A-10）。
  Future<ModelConfig?> defaultConfig() => _defaultConfig();

  /// 写入测试连接结果，capabilities 由测试结果得出（schema §4.3）。
  Future<ModelConfig> updateTestResult(
    String configId, {
    required String result,
    List<String>? capabilities,
  }) async {
    final updated = await (_db.update(_db.modelConfigs)
          ..where((t) => t.id.equals(configId)))
        .writeReturning(ModelConfigsCompanion(
      lastTestAt: Value(ids.nowMs()),
      lastTestResult: Value(result),
      capabilities: capabilities == null
          ? const Value.absent()
          : Value(jsonEncode(capabilities)),
    ));
    return updated.single;
  }

  /// 标记删除。被删的若是默认配置，之后没有默认配置——
  /// 整理会停在"待整理"，不自动改走其他配置（A-11 的边界原则）。
  Future<void> markDeleted(String configId) {
    return _db.transaction(() async {
      final cfg = await (_db.select(_db.modelConfigs)
            ..where((t) => t.id.equals(configId)))
          .getSingle();
      await (_db.update(_db.modelConfigs)..where((t) => t.id.equals(configId)))
          .write(ModelConfigsCompanion(
        deletedAt: Value(ids.nowMs()),
        isDefault: const Value(false),
        version: Value(cfg.version + 1),
      ));
    });
  }

  Future<List<ModelConfig>> all() => (_db.select(_db.modelConfigs)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<ModelConfig?> byId(String id) => (_db.select(_db.modelConfigs)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();
}
