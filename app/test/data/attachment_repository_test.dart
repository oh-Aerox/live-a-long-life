import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:path/path.dart' as p;

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late Directory tempDir;
  late AttachmentRepository repo;

  setUp(() async {
    env = await TestEnv.create();
    tempDir = await Directory.systemTemp.createTemp('attach_test');
    repo = AttachmentRepository(env.db, env.ctx,
        filesDir: Directory(p.join(tempDir.path, 'files')));
  });

  tearDown(() async {
    await env.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<File> writeSource(String name, List<int> bytes) async {
    final f = File(p.join(tempDir.path, name));
    await f.writeAsBytes(bytes);
    return f;
  }

  group('导入与校验状态机（schema §2.3a）', () {
    test('新文件：落盘校验通过后登记为 present', () async {
      final source = await writeSource('a.jpg', List.filled(1024, 7));
      final result = await repo.importFile(source,
          mimeType: 'image/jpeg', originalFilename: 'a.jpg');

      expect(result.isDuplicate, isFalse);
      expect(result.attachment.byteSize, 1024);

      final copies = await env.db.select(env.db.attachmentCopies).get();
      expect(copies.single.state, CopyState.present);
      expect(copies.single.verifiedAt, isNotNull);
      // 文件按哈希命名存放
      expect(
          await File(copies.single.localPath!).exists(), isTrue);
      expect(p.basename(copies.single.localPath!), result.attachment.sha256);
    });

    test('同一内容再次导入：命中同一附件身份，不新建行（D-10）', () async {
      final bytes = List.filled(2048, 3);
      final first =
          await repo.importFile(await writeSource('x.pdf', bytes),
              mimeType: 'application/pdf');
      final second =
          await repo.importFile(await writeSource('改名后.pdf', bytes),
              mimeType: 'application/pdf');

      expect(second.isDuplicate, isTrue);
      expect(second.attachment.id, first.attachment.id);
      expect((await env.db.select(env.db.attachments).get()).length, 1);
      expect((await env.db.select(env.db.attachmentCopies).get()).length, 1);
    });

    test('副本文件损坏：校验后转 missing，附件身份保留', () async {
      final result = await repo.importFile(
          await writeSource('a.jpg', List.filled(100, 1)),
          mimeType: 'image/jpeg');
      final copy =
          (await env.db.select(env.db.attachmentCopies).get()).single;

      await File(copy.localPath!).writeAsBytes(List.filled(100, 2));

      expect(await repo.verifyCopy(result.attachment.id), CopyState.missing);
      final after =
          (await env.db.select(env.db.attachmentCopies).get()).single;
      expect(after.state, CopyState.missing);
      expect(after.copyVersion, copy.copyVersion + 1);
      // 附件身份不受影响
      expect((await env.db.select(env.db.attachments).get()).length, 1);
    });

    test('副本完好：校验通过仍为 present，刷新校验时间', () async {
      final result = await repo.importFile(
          await writeSource('a.jpg', List.filled(100, 1)),
          mimeType: 'image/jpeg');
      expect(await repo.verifyCopy(result.attachment.id), CopyState.present);
    });

    test('丢失后重新导入同一内容：副本转回 present（取回，schema §2.3a）',
        () async {
      final bytes = List.filled(100, 9);
      final result = await repo.importFile(await writeSource('a.jpg', bytes),
          mimeType: 'image/jpeg');
      final copy =
          (await env.db.select(env.db.attachmentCopies).get()).single;
      await File(copy.localPath!).delete();
      expect(await repo.verifyCopy(result.attachment.id), CopyState.missing);

      final again = await repo.importFile(await writeSource('b.jpg', bytes),
          mimeType: 'image/jpeg');
      expect(again.isDuplicate, isTrue);
      final restored =
          (await env.db.select(env.db.attachmentCopies).get()).single;
      expect(restored.state, CopyState.present);
      expect(await repo.verifyCopy(result.attachment.id), CopyState.present);
    });
  });

  group('消息关联（schema §2.4）', () {
    test('删除消息：引用被标记删除，共享附件的文件保留（product-spec §3）', () async {
      final bytes = List.filled(64, 8);
      final result = await repo.importFile(await writeSource('a.jpg', bytes),
          mimeType: 'image/jpeg');
      final messages = MessageRepository(env.db, env.ctx);
      final m1 = await messages.send(
          clientMsgId: 'c1',
          role: MessageRole.user,
          kind: MessageKind.attachments,
          sentTz: 'Asia/Shanghai');
      final m2 = await messages.send(
          clientMsgId: 'c2',
          role: MessageRole.user,
          kind: MessageKind.attachments,
          sentTz: 'Asia/Shanghai');
      await repo.linkToMessage(
          messageId: m1.id, attachmentId: result.attachment.id, position: 0);
      await repo.linkToMessage(
          messageId: m2.id, attachmentId: result.attachment.id, position: 0);

      await messages.markDeleted(m1.id);

      expect(await repo.attachmentsOf(m1.id), isEmpty);
      expect((await repo.attachmentsOf(m2.id)).length, 1);
      // 文件与副本状态不受影响
      expect(await repo.verifyCopy(result.attachment.id), CopyState.present);
      expect(await repo.messageIdsReferencing(result.attachment.id), [m2.id]);
    });

    test('同一 (消息, 附件) 只挂一次，position 与确认标记保留', () async {
      final result = await repo.importFile(
          await writeSource('a.jpg', List.filled(64, 5)),
          mimeType: 'image/jpeg');

      await repo.linkToMessage(
          messageId: 'm1', attachmentId: result.attachment.id, position: 0);
      await repo.linkToMessage(
          messageId: 'm1',
          attachmentId: result.attachment.id,
          position: 1,
          duplicateAcknowledged: true);

      final links = await repo.attachmentsOf('m1');
      expect(links.length, 1);
      expect(links.single.$1.position, 0);
      expect(links.single.$1.duplicateAcknowledged, isFalse);
    });
  });
}
