import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';

/// 迁移回归（2026-09-29 Mac 从 v8 升级报 duplicate column 卡死启动）。
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('migration_test');
    file = File('${dir.path}/app.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<List<String>> columnsOf(AppDatabase db, String table) async =>
      (await db.customSelect('PRAGMA table_info($table)').get())
          .map((r) => r.read<String>('name'))
          .toList();

  Future<int> userVersion(AppDatabase db) async =>
      (await db.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version');

  /// 建一个当前版本的库，再用 [downgrade] 改成旧结构并把 user_version 置 8。
  Future<void> prepareV8(Future<void> Function(AppDatabase db) downgrade) async {
    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await downgrade(db);
    await db.customStatement('PRAGMA user_version = 8');
    await db.close();
  }

  Future<void> expectUpgradesToCurrent() async {
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await userVersion(db), db.schemaVersion);
    expect(await columnsOf(db, 'model_calls'),
        containsAll(['redacted_count', 'sent_summary', 'request_text']));
    expect(await columnsOf(db, 'medical_documents'),
        containsAll(['page_overrides', 'line_edits']));
    expect(await columnsOf(db, 'lab_results'), isNotEmpty);
    expect(await columnsOf(db, 'consult_messages'), isNotEmpty);
  }

  test('v8 → 当前：v9 建表已含 v12 的列，不重复加列', () async {
    await prepareV8((db) async {
      for (final t in ['medical_documents', 'lab_results', 'consult_messages']) {
        await db.customStatement('DROP TABLE $t');
      }
      await db.customStatement('ALTER TABLE model_calls DROP COLUMN redacted_count');
      await db.customStatement('ALTER TABLE model_calls DROP COLUMN sent_summary');
      await db.customStatement('ALTER TABLE model_calls DROP COLUMN request_text');
    });
    await expectUpgradesToCurrent();
  });

  test('上次升级中途失败（表列已在、user_version 仍是 8）：可重跑', () async {
    await prepareV8((db) async {
      await db.customStatement('DROP TABLE consult_messages');
      await db.customStatement('ALTER TABLE model_calls DROP COLUMN sent_summary');
    });
    await expectUpgradesToCurrent();
  });

  test('v14 → 当前：医疗文件加行修改列', () async {
    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('ALTER TABLE medical_documents DROP COLUMN line_edits');
    await db.customStatement('PRAGMA user_version = 14');
    await db.close();
    await expectUpgradesToCurrent();
  });
}
