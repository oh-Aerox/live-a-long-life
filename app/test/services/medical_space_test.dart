import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/peer_repository.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/medical_space_service.dart';
import 'package:live_a_long_life/services/sync/secure_channel.dart';
import 'package:live_a_long_life/services/sync/sync_client.dart';
import 'package:live_a_long_life/services/sync/sync_server.dart';
import 'package:live_a_long_life/services/sync/sync_service.dart';
import 'package:live_a_long_life/services/text_extraction.dart';
import 'package:path/path.dart' as p;

import '../data/test_helpers.dart';
import 'text_extraction_test.dart' show FakeExtractor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv macEnv;
  late TestEnv phoneEnv;
  late Directory tempDir;
  late SyncServer server;
  late SyncService sync;
  late AttachmentRepository attachments;
  late MedicalDocumentRepository documents;
  late MessageRepository messages;
  late MedicalSpaceService space;

  setUp(() async {
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
    macEnv = await TestEnv.create();
    phoneEnv = await TestEnv.create();
    tempDir = await Directory.systemTemp.createTemp('medical_space');

    server = SyncServer(
      deviceId: 'mac-1',
      displayName: 'Mac',
      db: macEnv.db,
      filesDir: Directory(p.join(tempDir.path, 'mac_files')),
      peers: PeerRepository(macEnv.db),
      keyStore: KeyStore(),
    );
    final info = await server.startPairing();
    final client = SyncClient(
      deviceId: 'test-device',
      displayName: 'iPhone',
      peers: PeerRepository(phoneEnv.db),
      keyStore: KeyStore(),
    );
    await client.pairWith(PairingInfo(
      macDeviceId: info.macDeviceId,
      displayName: info.displayName,
      hosts: ['127.0.0.1'],
      port: info.port,
      key: info.key,
    ));

    final phoneFiles = Directory(p.join(tempDir.path, 'phone_files'));
    attachments =
        AttachmentRepository(phoneEnv.db, phoneEnv.ctx, filesDir: phoneFiles);
    documents = MedicalDocumentRepository(phoneEnv.db, phoneEnv.ctx);
    messages = MessageRepository(phoneEnv.db, phoneEnv.ctx);
    sync = SyncService(
      deviceId: 'test-device',
      db: phoneEnv.db,
      peers: PeerRepository(phoneEnv.db),
      keyStore: KeyStore(),
      filesDir: phoneFiles,
    );
    space = MedicalSpaceService(
      db: phoneEnv.db,
      attachments: attachments,
      documents: documents,
      sync: sync,
      extraction: TextExtractionService(
          extractor: FakeExtractor(),
          cacheDir: Directory(p.join(tempDir.path, 'cache'))),
    );
  });

  tearDown(() async {
    await server.stop();
    await macEnv.dispose();
    await phoneEnv.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<Attachment> importMedicalFile(List<int> bytes) async {
    final src = File(p.join(tempDir.path, 'r_${bytes.hashCode}.jpg'))
      ..writeAsBytesSync(bytes);
    final att =
        (await attachments.importFile(src, mimeType: 'image/jpeg')).attachment;
    final msg = await messages.send(
      clientMsgId: 'c-${bytes.hashCode}',
      role: MessageRole.user,
      kind: MessageKind.attachments,
      sentTz: 'Asia/Shanghai',
    );
    await attachments.linkToMessage(
        messageId: msg.id, attachmentId: att.id, position: 0);
    await documents.create(
      pages: [
        MedicalPageRef(attachmentId: att.id, messageId: msg.id, pageNo: 1)
      ],
      docType: MedicalDocType.labReport,
    );
    return att;
  }

  test('清单：按文件去重、Mac 未归档不默认选；清理→offloaded 释放空间；'
      '记录与引用保留（A-33/A-34/A-36）', () async {
    final att = await importMedicalFile([1, 2, 3, 4, 5]);

    var files = await space.list();
    expect(files, hasLength(1));
    expect(files.single.state, CopyState.present);
    // 还没同步到 Mac：无确认副本，不默认勾选。
    expect(files.single.archivedOnMac, isFalse);
    expect(files.single.defaultSelected, isFalse);

    // 同步后 Mac 归档确认。
    final result = await sync.syncNow();
    expect(result.ok, isTrue);
    files = await space.list();
    expect(files.single.archivedOnMac, isTrue);

    // 清理：文件删了、状态 offloaded、字节数如实。
    final phonePath = (await attachments.localPathOf(att.id))!;
    final cleanup = await space.cleanup(files);
    expect(cleanup.freedBytes, 5);
    expect(cleanup.failures, isEmpty);
    expect(File(phonePath).existsSync(), isFalse);
    expect(await attachments.copyStateOf(att.id), CopyState.offloaded);
    expect(await attachments.localPathOf(att.id), isNull);

    // 附件身份、消息引用、医疗文件都还在（只删物理副本）。
    expect(await attachments.byId(att.id), isNotNull);
    expect(await attachments.messageIdsReferencing(att.id), hasLength(1));
    expect(await documents.all(), hasLength(1));
    // Mac 上的原件不受影响。
    expect(
        File(p.join(tempDir.path, 'mac_files', att.sha256)).existsSync(),
        isTrue);

    // 再清一次：没有 present 副本，释放 0，不谎报（A-36）。
    final again = await space.cleanup(await space.list());
    expect(again.freedBytes, 0);
  });

  test('取回（A-21）：从 Mac 拉回同一文件，哈希校验，沿用附件身份', () async {
    final att = await importMedicalFile([9, 8, 7, 6]);
    await sync.syncNow();
    await space.cleanup(await space.list());
    expect(await attachments.localPathOf(att.id), isNull);

    final ok = await space.retrieve(att.id);
    expect(ok, isTrue);
    expect(await attachments.copyStateOf(att.id), CopyState.present);
    final path = await attachments.localPathOf(att.id);
    expect(File(path!).readAsBytesSync(), [9, 8, 7, 6]);
    // 没有新建附件或医疗文件（不重复建档）。
    expect(await documents.all(), hasLength(1));
  });

  test('Mac 没有这份文件：取回失败返回 false，数据不受影响', () async {
    final att = await importMedicalFile([4, 4, 4]);
    // 不同步（Mac 没有文件），直接清理再取回。
    await space.cleanup(await space.list());
    expect(await space.retrieve(att.id), isFalse);
    expect(await attachments.copyStateOf(att.id), CopyState.offloaded);
    // 重新上传同一文件补回（D-10）：沿用同一附件。
    final src = File(p.join(tempDir.path, 'reupload.jpg'))
      ..writeAsBytesSync([4, 4, 4]);
    final result = await attachments.importFile(src, mimeType: 'image/jpeg');
    expect(result.isDuplicate, isTrue);
    expect(result.attachment.id, att.id);
    expect(await attachments.copyStateOf(att.id), CopyState.present);
  });
}
