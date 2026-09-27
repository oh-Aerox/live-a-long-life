import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// 数据库（docs/plan-v0.1.md §3、plan-v0.2.md V2-M0）。
/// 迁移从 schemaVersion 1 开始编号，之后只追加迁移，不改旧迁移。
@DriftDatabase(tables: [
  Messages,
  MessageRevisions,
  Attachments,
  AttachmentCopies,
  MessageAttachments,
  ProfileFields,
  Settings,
  HealthSamples,
  HealthAnchors,
  HealthDaily,
  OrganizeRuns,
  OrganizeRunItems,
  ModelCalls,
  Records,
  RecordRevisions,
  RecordSources,
  ModelConfigs,
  ReviewPrompts,
  CorrectionSuggestions,
  ChangeLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v0.2 整理层、健康数据与模型配置（schema §2.5/§2.6/§3/§4.3/§4.4）。
            await m.createTable(healthSamples);
            await m.createTable(healthAnchors);
            await m.createTable(healthDaily);
            await m.createTable(organizeRuns);
            await m.createTable(organizeRunItems);
            await m.createTable(modelCalls);
            await m.createTable(records);
            await m.createTable(recordRevisions);
            await m.createTable(recordSources);
            await m.createTable(modelConfigs);
            await m.createTable(reviewPrompts);
          }
          if (from < 3) {
            // 修正建议提前到 v0.2：手机整理的受保护字段冲突要用（A-25）。
            await m.createTable(correctionSuggestions);
          }
          if (from < 4) {
            // v0.3 同步的变更日志（schema §7.2）。
            await m.createTable(changeLogs);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
