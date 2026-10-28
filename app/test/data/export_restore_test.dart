import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/app_context.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/health_repository.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
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

  group('导出（product-spec §13）', () {
    test('data.json、files/、manifest.json 齐全且校验通过', () async {
      final sha = await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      final result = await ExportService(sourceDb, filesDir: sourceFiles).export(out);

      expect(result.messageCount, 3);
      expect(result.fileCount, 1);
      expect(result.missingFiles, isEmpty);
      expect(await File(p.join(out.path, 'files', '$sha.jpg')).exists(), isTrue);

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

  group('恢复（A-29 替换语义）', () {
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
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);

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
        // local_path 存文件名，按恢复目标的 files/ 目录解析
        expect(copies.single.localPath, sha);
        final file =
            File(p.join(targetRoot.path, 'files', copies.single.localPath!));
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
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);
      await File(p.join(out.path, 'files', '$sha.jpg')).delete();

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

    test('v0.2 数据随导出恢复：记录、来源、健康数据都在（格式 v2）', () async {
      await seedData();
      final records = RecordRepository(sourceDb, ctx);
      final health = HealthRepository(sourceDb, ctx);
      final rec = await records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated,
        ),
        dataJson: '{"status":"eaten","description":"面"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('run-1'),
        sources: const [
          SourceLink(sourceKind: RecordSourceKind.message, sourceId: 'c1'),
        ],
      );
      await health.upsertDaily(
        localDate: '2026-09-26',
        aggTz: 'Asia/Shanghai',
        intervalStartUtcMs: 0,
        intervalEndUtcMs: 86400000,
        metric: HealthMetric.steps,
        value: 8000,
      );

      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);
      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      await doRestore(out, targetRoot);

      final restored = AppDatabase(
          NativeDatabase(File(p.join(targetRoot.path, 'db', 'app.sqlite'))));
      try {
        final restoredRecords = RecordRepository(
            restored, AppContext(userId: 'u1', deviceId: 'phone-2'));
        final day = await restoredRecords.byDate('2026-09-26');
        expect(day.single.id, rec.id);
        final rev = await restoredRecords.currentRevisionOf(rec.id);
        expect(rev.data, contains('面'));
        expect(await restoredRecords.sourcesOf(rev.id), hasLength(1));

        final daily = await (restored.select(restored.healthDaily)).get();
        expect(daily.single.value, 8000);
        // 模型配置不进备份（schema §4.3）。
        expect(await restored.select(restored.modelConfigs).get(), isEmpty);
      } finally {
        await restored.close();
      }
    });

    /// 病例夹里的一份文件 + 一条咨询记录（v0.4 的表）。
    Future<String> seedV4() async {
      final att = (await sourceDb.select(sourceDb.attachments).get()).single;
      final link = (await sourceDb.select(sourceDb.messageAttachments).get())
          .single;
      final doc = await MedicalDocumentRepository(sourceDb, ctx).create(
        pages: [
          MedicalPageRef(
              attachmentId: att.id, messageId: link.messageId, pageNo: 1),
        ],
        docType: MedicalDocType.labReport,
      );
      await sourceDb.into(sourceDb.consultMessages).insert(
          ConsultMessagesCompanion.insert(
              id: 'q1',
              sessionId: 's1',
              role: 'user',
              body: '尿酸高怎么办',
              contextNote: const Value('基本资料'),
              createdAt: 1));
      return doc.id;
    }

    test('v0.4 数据随导出恢复：病例夹文件、咨询记录都在（格式 v3，2026-09-30）',
        () async {
      await seedData();
      final docId = await seedV4();

      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);
      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      await doRestore(out, targetRoot);

      final restored = AppDatabase(
          NativeDatabase(File(p.join(targetRoot.path, 'db', 'app.sqlite'))));
      try {
        final docs = await MedicalDocumentRepository(
                restored, AppContext(userId: 'u1', deviceId: 'phone-2'))
            .all();
        expect(docs.single.id, docId);
        expect(docs.single.docType, MedicalDocType.labReport);
        final consult = await restored.select(restored.consultMessages).get();
        expect(consult.single.body, '尿酸高怎么办');
      } finally {
        await restored.close();
      }
    });

    test('从 Mac 压缩的 zip 恢复：嵌套目录、__MACOSX 不影响（安卓，2026-09-30）',
        () async {
      await seedData();
      final out = Directory(p.join(tempDir.path, '导出-20260930-0842'));
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);

      // 仿 Finder"压缩"：外层是导出文件夹，另带 __MACOSX 资源分叉。
      final archive = Archive();
      await for (final f in out.list(recursive: true)) {
        if (f is! File) continue;
        final rel = p.relative(f.path, from: tempDir.path);
        archive.add(ArchiveFile.bytes(rel, await f.readAsBytes()));
      }
      archive.add(ArchiveFile.bytes(
          '__MACOSX/导出-20260930-0842/._manifest.json', [0, 1, 2]));
      final zip = File(p.join(tempDir.path, 'export.zip'));
      await zip.writeAsBytes(ZipEncoder().encode(archive));

      final unpacked = await RestoreService.unpackZip(
          zip, Directory(p.join(tempDir.path, 'unpacked')));
      expect(File(p.join(unpacked.path, 'manifest.json')).existsSync(), isTrue);

      final result =
          await doRestore(unpacked, Directory(p.join(tempDir.path, 'target')));
      expect(result.messageCount, 3);
      expect(result.restoredFiles, 1);
      expect(result.partial, isFalse);
    });

    test('压缩包里没有导出数据：明确报错', () async {
      final archive = Archive()..add(ArchiveFile.bytes('随便.txt', [1, 2, 3]));
      final zip = File(p.join(tempDir.path, 'other.zip'));
      await zip.writeAsBytes(ZipEncoder().encode(archive));
      expect(
          () => RestoreService.unpackZip(
              zip, Directory(p.join(tempDir.path, 'unpacked'))),
          throwsA(isA<StateError>()));
    });

    test('已有数据未确认替换：拒绝恢复', () async {
      await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);
      final targetRoot = Directory(p.join(tempDir.path, 'target'));
      expect(doRestore(out, targetRoot, hasExistingData: true),
          throwsA(isA<NeedsReplaceConfirmation>()));
    });

    test('data.json 损坏：恢复失败，原资料库不动', () async {
      await seedData();
      final out = Directory(p.join(tempDir.path, 'export'));
      await ExportService(sourceDb, filesDir: sourceFiles).export(out);
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

  test('导出目录里的原件副本按内容哈希识别（清理确认提示用，2026-09-29）', () async {
    final root = await Directory.systemTemp.createTemp('exports');
    addTearDown(() => root.delete(recursive: true));
    final run1 = Directory(p.join(root.path, '导出-20260929-1437', 'files'))
      ..createSync(recursive: true);
    File(p.join(run1.path, 'aaa.png')).writeAsBytesSync([1]);
    File(p.join(run1.path, 'bbb.pdf')).writeAsBytesSync([1]);
    Directory(p.join(root.path, '导出-20260930-0900', 'files'))
        .createSync(recursive: true);
    File(p.join(root.path, '导出-20260930-0900', 'files', 'aaa.png'))
        .writeAsBytesSync([1]);

    expect(await ExportService.exportedCopies(root, {'aaa', 'ccc'}), {'aaa'});
    expect(await ExportService.exportedCopies(root, {'ccc'}), isEmpty);
    expect(
        await ExportService.exportedCopies(
            Directory(p.join(root.path, 'none')), {'aaa'}),
        isEmpty);
  });

  test('每张表都登记了是否随导出走（防新增表漏导出，2026-09-30 病例夹恢复后为空）',
      () {
    final all = {for (final t in sourceDb.allTables) t.actualTableName};
    final declared = {...v2ExportTables, ...exportExcludedTables.keys};
    expect(all.difference(declared), isEmpty,
        reason: '新表要加进 v2ExportTables，或在 exportExcludedTables 写明不导出的原因');
    expect(declared.difference(all), isEmpty, reason: '登记了不存在的表名');
  });
}
