import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/app_context.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';
import 'package:live_a_long_life/services/export_service.dart';
import 'package:live_a_long_life/services/restore_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppDatabase sourceDb;
  late AppContext ctx;
  late Directory sourceFiles;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('export_test');
    sourceDb = AppDatabase(NativeDatabase.memory());
    ctx = AppContext(userId: 'u1', deviceId: 'phone-1');
    sourceFiles = Directory(p.join(tempDir.path, 'source_files'));
  });

  tearDown(() async {
    await sourceDb.close();
    await tempDir.delete(recursive: true);
  });

  /// 造一份有代表性的数据：文字消息（编辑过）、删除的消息、
  /// 附件消息、资料、设置。返回附件 sha256。
  Future<String> seedData() async {
    final messages = MessageRepository(sourceDb, ctx);
    final attachments =
        AttachmentRepository(sourceDb, ctx, filesDir: sourceFiles);
    final profile = ProfileRepository(sourceDb, ctx);
    final settings = SettingsRepository(sourceDb);

    final m1 = await messages.send(
        clientMsgId: 'c1',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: '早饭吃了鸡蛋',
        sentTz: 'Asia/Shanghai');
    await messages.edit(m1.id, '早饭吃了鸡蛋和牛奶');

    final m2 = await messages.send(
        clientMsgId: 'c2',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: '误发',
        sentTz: 'Asia/Shanghai');
    await messages.markDeleted(m2.id);

    final srcFile = File(p.join(tempDir.path, 'photo.jpg'));
    await srcFile.writeAsBytes(List.generate(500, (i) => i % 251));
    final imported =
        await attachments.importFile(srcFile, mimeType: 'image/jpeg');
    final m3 = await messages.send(
        clientMsgId: 'c3',
        role: MessageRole.user,
        kind: MessageKind.attachments,
        sentTz: 'Asia/Shanghai');
    await attachments.linkToMessage(
        messageId: m3.id, attachmentId: imported.attachment.id, position: 0);

    await profile.setField('height_cm', value: 175);
    await settings.set('review_times', ['08:00', '21:30']);
    await settings.set('device_id', 'phone-1');
    return imported.attachment.sha256;
  }

  group('导出（product-spec §3）', () {
    test('data.json、files/、manifest.json 齐全且校验通过', () async {
      final sha = await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      final result = await ExportService(sourceDb).export(out);

      expect(result.messageCount, 3);
      expect(result.fileCount, 1);
      expect(result.missingFiles, isEmpty);
      expect(await File(p.join(out.path, 'files', sha)).exists(), isTrue);

      final manifest = jsonDecode(
              await File(p.join(out.path, 'manifest.json')).readAsString())
          as Map<String, dynamic>;
      expect(manifest['format_version'], exportFormatVersion);
      expect(manifest['message_count'], 3);
      expect((manifest['files'] as Map).length, 2); // data.json + 1 附件

      final data = jsonDecode(
              await File(p.join(out.path, 'data.json')).readAsString())
          as Map<String, dynamic>;
      // 设备标识不随内容导出
      final keys =
          (data['settings'] as List).map((s) => (s as Map)['key']).toList();
      expect(keys, isNot(contains('device_id')));
      expect(keys, contains('review_times'));
      expect((data['message_revisions'] as List).length, 1);
    });
  });

  group('恢复（A-29、Codex 7_reply 替换语义）', () {
    Future<RestoreResult> doRestore(Directory exportDir, Directory targetRoot,
        {bool hasExistingData = false, bool replaceExisting = false}) {
      final service = RestoreService(
        dbFile: File(p.join(targetRoot.path, 'db', 'app.sqlite')),
        filesDir: Directory(p.join(targetRoot.path, 'files')),
      );
      return service.restore(exportDir,
          hasExistingData: hasExistingData,
          replaceExisting: replaceExisting,
          newDeviceId: 'phone-2');
    }

    test('恢复到空资料库：内容一致，附件可用', () async {
      final sha = await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb).export(out);

      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      final result = await doRestore(out, targetRoot);
      expect(result.messageCount, 3);
      expect(result.restoredFiles, 1);
      expect(result.partial, isFalse);

      final restored = AppDatabase(
          NativeDatabase(File(p.join(targetRoot.path, 'db', 'app.sqlite'))));
      try {
        final messages = await restored.select(restored.messages).get();
        expect(messages.length, 3);
        final edited = messages.firstWhere((m) => m.clientMsgId == 'c1');
        expect(edited.body, '早饭吃了鸡蛋和牛奶');
        expect(edited.revisionNo, 1);
        final deleted = messages.firstWhere((m) => m.clientMsgId == 'c2');
        expect(deleted.deletedAt, isNotNull);

        final revisions =
            await restored.select(restored.messageRevisions).get();
        expect(revisions.single.textBefore, '早饭吃了鸡蛋');

        final copies =
            await restored.select(restored.attachmentCopies).get();
        expect(copies.single.state, CopyState.present);
        final file = File(copies.single.localPath!);
        expect(await file.exists(), isTrue);
        expect(await AttachmentRepository.hashFile(file), sha);

        final profile = await restored.select(restored.profileFields).get();
        expect(profile.single.fieldKey, 'height_cm');

        final settings = await restored.select(restored.settings).get();
        final byKey = {for (final s in settings) s.key: s.value};
        expect(jsonDecode(byKey['review_times']!), ['08:00', '21:30']);
        expect(jsonDecode(byKey['device_id']!), 'phone-2');
      } finally {
        await restored.close();
      }
    });

    test('缺附件文件：其余照常导入，结果为部分恢复', () async {
      final sha = await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb).export(out);
      await File(p.join(out.path, 'files', sha)).delete();

      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      final result = await doRestore(out, targetRoot);
      expect(result.messageCount, 3);
      expect(result.partial, isTrue);
      expect(result.missingFiles, [sha]);

      final restored = AppDatabase(
          NativeDatabase(File(p.join(targetRoot.path, 'db', 'app.sqlite'))));
      try {
        final copies =
            await restored.select(restored.attachmentCopies).get();
        expect(copies.single.state, CopyState.missing);
      } finally {
        await restored.close();
      }
    });

    test('已有数据未确认替换：拒绝恢复', () async {
      await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb).export(out);
      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      expect(doRestore(out, targetRoot, hasExistingData: true),
          throwsA(isA<NeedsReplaceConfirmation>()));
    });

    test('data.json 损坏：恢复失败，原资料库不动', () async {
      await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb).export(out);
      // 篡改 data.json，让哈希对不上
      final dataFile = File(p.join(out.path, 'data.json'));
      await dataFile.writeAsString('${await dataFile.readAsString()} ');

      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      final oldDb = File(p.join(targetRoot.path, 'db', 'app.sqlite'));
      await oldDb.parent.create(recursive: true);
      await oldDb.writeAsString('原来的资料库');

      await expectLater(
          doRestore(out, targetRoot,
              hasExistingData: true, replaceExisting: true),
          throwsStateError);
      // 原文件原样保留
      expect(await oldDb.readAsString(), '原来的资料库');
    });
  });
}
