import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/app_context.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';
import 'package:live_a_long_life/services/cloud_backup_service.dart';
import 'package:live_a_long_life/services/cloud_folder.dart';
import 'package:live_a_long_life/services/cloud_vault.dart';
import 'package:live_a_long_life/services/export_service.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/restore_service.dart';
import 'package:path/path.dart' as p;

/// 书签就是路径，读写直接走本机目录。
class FakeFolder extends LocalFolderIO implements CloudFolderAccess {
  FakeFolder(this.root);

  final Directory root;

  @override
  Future<PickedFolder?> pick() async => PickedFolder(
    bookmark: root.path,
    name: p.basename(root.path),
    inICloud: true,
  );

  @override
  Future<OpenedFolder> open(String bookmark) async =>
      OpenedFolder(path: bookmark);

  @override
  Future<void> close(String path) async {}

  @override
  Future<List<String>> notUploaded(List<String> paths) async => [
    for (final path in paths)
      if (pending.contains(path)) path,
  ];

  /// 模拟还没上传完的文件。
  final pending = <String>{};

  @override
  Future<void> beginBackground() async {}

  @override
  Future<void> endBackground() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  late Directory temp;
  late AppDatabase db;
  late Directory filesDir;
  late Directory cloudRoot;
  late AttachmentRepository attachments;
  late MessageRepository messages;
  final ctx = AppContext(userId: 'u1', deviceId: 'phone-1');

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cloud_test');
    db = AppDatabase(NativeDatabase.memory());
    filesDir = Directory(p.join(temp.path, 'files'));
    cloudRoot = Directory(p.join(temp.path, 'iCloud Drive'));
    await cloudRoot.create();
    attachments = AttachmentRepository(db, ctx, filesDir: filesDir);
    messages = MessageRepository(db, ctx);
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  var n = 0;
  Future<String> addPhoto(int seed) async {
    final src = File(p.join(temp.path, 'photo_${n++}.jpg'));
    await src.writeAsBytes(List.generate(300, (i) => (i * seed) % 251));
    final imported = await attachments.importFile(src, mimeType: 'image/jpeg');
    final m = await messages.send(
      clientMsgId: 'c${n++}',
      role: MessageRole.user,
      kind: MessageKind.attachments,
      sentTz: 'Asia/Shanghai',
    );
    await attachments.linkToMessage(
      messageId: m.id,
      attachmentId: imported.attachment.id,
      position: 0,
    );
    return imported.attachment.sha256;
  }

  Future<void> addText(String text) => messages.send(
    clientMsgId: 'c${n++}',
    role: MessageRole.user,
    kind: MessageKind.text,
    text: text,
    sentTz: 'Asia/Shanghai',
  );

  CloudVault vault() =>
      CloudVault(Directory(p.join(cloudRoot.path, CloudVault.dirName)));

  ExportService exporter() => ExportService(db, filesDir: filesDir);

  Future<AppDatabase> restoreInto(Directory staged) async {
    final target = Directory(p.join(temp.path, 'restored'));
    final dbFile = File(p.join(target.path, 'db', 'app.sqlite'));
    final result =
        await RestoreService(
          dbFile: dbFile,
          filesDir: Directory(p.join(target.path, 'files')),
        ).restore(
          staged,
          hasExistingData: false,
          newDeviceId: 'phone-2',
          deviceSettings: {CloudBackupService.kAuto: true},
        );
    expect(result.partial, isFalse);
    return AppDatabase(NativeDatabase(dbFile));
  }

  group('备份文件夹格式', () {
    for (final password in [null, 'secret123']) {
      test('写一份再恢复：内容一致（${password == null ? '不加密' : '加密'}）', () async {
        await addText('早饭吃了鸡蛋');
        final sha = await addPhoto(7);
        final v = vault();
        final (meta, key) = await v.create(
          vaultId: 'v1',
          nowMs: 1000,
          password: password,
        );
        expect(meta.encrypted, password != null);

        final snap = await v.write(
          await exporter().snapshot(),
          snapshotId: 'snap-0000-0001',
          nowMs: 2000,
          key: key,
        );
        expect(snap.files.keys, [sha]);
        expect(snap.missingFiles, isEmpty);

        final objects = Directory(p.join(v.dir.path, 'objects'));
        final stored = await objects
            .list()
            .map((e) => p.basename(e.path))
            .toList();
        expect(stored, [password == null ? sha : '$sha.enc']);

        // 换一台手机：只凭文件夹和密码。
        final again = (await vault().readMeta())!;
        final unlocked = password == null
            ? null
            : await CloudVault.unlock(again, password);
        final listed = await vault().list();
        expect(listed.single.name, snap.name);
        final staged = await vault().stage(
          listed.single,
          into: Directory(p.join(temp.path, 'staged')),
          key: unlocked,
        );
        final restored = await restoreInto(staged);
        final msgs = await restored.select(restored.messages).get();
        expect(msgs.map((m) => m.body), contains('早饭吃了鸡蛋'));
        expect(msgs, hasLength(2));
        final auto = await SettingsRepository(
          restored,
        ).get(CloudBackupService.kAuto);
        expect(auto, isTrue);
        await restored.close();
      });
    }

    test('密码不对：解不开', () async {
      final (meta, _) = await vault().create(
        vaultId: 'v1',
        nowMs: 1,
        password: 'right-one',
      );
      expect(
        () => CloudVault.unlock(meta, 'wrong-one'),
        throwsA(isA<WrongPassword>()),
      );
    });

    test('附件只传新的；手机清理过原件、云端已有的照样引用', () async {
      final first = await addPhoto(3);
      final v = vault();
      await v.create(vaultId: 'v1', nowMs: 1);
      await v.write(
        await exporter().snapshot(),
        snapshotId: 'aaaaaaaa-0001',
        nowMs: 1000,
      );
      final firstObject = File(p.join(v.dir.path, 'objects', first));
      final stat1 = await firstObject.stat();

      // 清理手机原件（D-22）后又加一张。
      await File(p.join(filesDir.path, first)).delete();
      final second = await addPhoto(5);
      final snap = await v.write(
        await exporter().snapshot(),
        snapshotId: 'aaaaaaaa-0002',
        nowMs: 2000,
      );
      expect(snap.files.keys.toSet(), {first, second});
      expect(snap.missingFiles, isEmpty);
      expect((await firstObject.stat()).modified, stat1.modified);
    });

    test('每天留最后一份，最多几天；没被引用的附件删掉', () async {
      final v = vault();
      await v.create(vaultId: 'v1', nowMs: 1);
      DateTime day(int d, int h) => DateTime(2026, 11, d, h);
      final old = await addPhoto(3);
      await v.write(
        await exporter().snapshot(),
        snapshotId: 'aaaaaaaa-0001',
        nowMs: day(1, 9).millisecondsSinceEpoch,
      );
      // 这张照片之后从应用里没了（换成只引用新照片的资料库）。
      await db.customStatement('DELETE FROM message_attachments');
      await db.customStatement('DELETE FROM attachments');
      final fresh = await addPhoto(9);
      final times = [day(2, 9), day(3, 9), day(3, 20), day(4, 9), day(4, 22)];
      for (var i = 0; i < times.length; i++) {
        await v.write(
          await exporter().snapshot(),
          snapshotId: 'aaaaaaaa-001$i',
          nowMs: times[i].millisecondsSinceEpoch,
        );
      }
      expect(await v.prune(days: 3), 3);
      expect((await v.list()).map((s) => s.createdAt), [
        day(4, 22).millisecondsSinceEpoch,
        day(3, 20).millisecondsSinceEpoch,
        day(2, 9).millisecondsSinceEpoch,
      ]);
      expect(await v.objectShas(), {fresh});
      expect(old, isNot(fresh));
    });

    test('iCloud 未下载的占位文件算已有；中断留下的 .part 清掉', () async {
      final sha = await addPhoto(3);
      final v = vault();
      await v.create(vaultId: 'v1', nowMs: 1);
      final objects = Directory(p.join(v.dir.path, 'objects'));
      await objects.create(recursive: true);
      await File(p.join(objects.path, '.$sha.icloud')).writeAsString('');
      await File(p.join(objects.path, 'deadbeef.part')).writeAsString('x');
      final snap = await v.write(
        await exporter().snapshot(),
        snapshotId: 'aaaaaaaa-0001',
        nowMs: 1000,
      );
      expect(snap.files.keys, [sha]);
      final names = await objects.list().map((e) => p.basename(e.path)).toSet();
      expect(names, {'.$sha.icloud'});
    });
  });

  group('CloudBackupService', () {
    late CloudBackupService service;
    late SettingsRepository settings;

    setUp(() {
      settings = SettingsRepository(db);
      service = CloudBackupService(
        db: db,
        filesDir: filesDir,
        settings: settings,
        keyStore: KeyStore(),
        folder: FakeFolder(cloudRoot),
      );
    });

    Future<void> enable({String? password}) async {
      final picked = (await service.folder.pick())!;
      final meta = await service.createVault(
        picked.bookmark,
        password: password,
      );
      await service.connect(picked, meta);
    }

    test('内容没变不新建备份；有变化再备份', () async {
      await enable();
      await addText('一');
      final r1 = await service.backupNow();
      expect(r1.unchanged, isFalse);
      expect((await service.backupNow()).unchanged, isTrue);
      // 回到前台读健康数据会改写上次读取时间，不算内容变化。
      await settings.set('health_last_sync_ms', 123);
      expect((await service.backupNow()).unchanged, isTrue);
      await addText('二');
      final r3 = await service.backupNow();
      expect(r3.unchanged, isFalse);
      expect(r3.snapshot!.messageCount, 2);
      final state = await service.state();
      expect(state.lastMessages, 2);
      expect(state.error, isNull);
    });

    test('从备份恢复后内容没变：不再新建备份', () async {
      await enable();
      await addText('一');
      await addPhoto(4);
      final first = (await service.backupNow()).snapshot!;
      final staged = await vault().stage(
        first,
        into: Directory(p.join(temp.path, 'staged')),
      );
      final dbFile = File(p.join(temp.path, 'restored', 'db', 'app.sqlite'));
      final restoredFiles = Directory(p.join(temp.path, 'restored', 'files'));
      final picked = (await service.folder.pick())!;
      final meta = (await vault().readMeta())!;
      await RestoreService(dbFile: dbFile, filesDir: restoredFiles).restore(
        staged,
        hasExistingData: false,
        newDeviceId: 'phone-2',
        deviceSettings: CloudBackupService.deviceSettings(
          picked,
          meta,
          restoredFrom: first,
        ),
      );
      final restored = AppDatabase(NativeDatabase(dbFile));
      addTearDown(restored.close);
      final after = CloudBackupService(
        db: restored,
        filesDir: restoredFiles,
        settings: SettingsRepository(restored),
        keyStore: KeyStore(),
        folder: FakeFolder(cloudRoot),
      );
      expect((await after.backupNow()).unchanged, isTrue);
    });

    test('加密：钥匙串里有密钥就直接备份，没有要密码', () async {
      await enable(password: 'secret123');
      await addText('一');
      expect((await service.backupNow()).unchanged, isFalse);

      FlutterSecureStorage.setMockInitialValues({});
      await addText('二');
      await expectLater(service.backupNow(), throwsA(isA<NeedsPassword>()));
      expect((await service.state()).error, '需要输入备份密码');
    });

    test('文件夹里的备份被换掉：报错，不往别的备份库里写', () async {
      await enable();
      await Directory(
        p.join(cloudRoot.path, CloudVault.dirName),
      ).delete(recursive: true);
      await vault().create(vaultId: 'other', nowMs: 1);
      await expectLater(service.backupNow(), throwsStateError);
    });

    test('医疗文件空间用：列出已上传到 iCloud 的附件，没传完的不算', () async {
      expect(await service.uploadedShas(), isNull); // 没开启
      await enable();
      final a = await addPhoto(3);
      final b = await addPhoto(5);
      await service.backupNow();
      final folder = service.folder as FakeFolder;
      folder.pending.add(
        p.join(cloudRoot.path, CloudVault.dirName, 'objects', b),
      );
      expect(await service.uploadedShas(), {a});
    });

    test('备份设置属于这台手机，不随导出走', () async {
      await enable();
      final snap = await exporter().snapshot();
      final keys = [
        for (final s in snap.data['settings'] as List) (s as Map)['key'],
      ];
      expect(keys.where((k) => '$k'.startsWith('cloud_backup_')), isEmpty);
    });
  });
}
