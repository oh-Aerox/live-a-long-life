import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// v0.1 数据库（docs/plan-v0.1.md §3）。
/// 迁移从 schemaVersion 1 开始编号，之后只追加迁移，不改旧迁移。
@DriftDatabase(tables: [
  Messages,
  MessageRevisions,
  Attachments,
  AttachmentCopies,
  MessageAttachments,
  ProfileFields,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
