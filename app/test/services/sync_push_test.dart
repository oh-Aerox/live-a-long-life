import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/peer_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/sync/secure_channel.dart';
import 'package:live_a_long_life/services/sync/sync_client.dart';
import 'package:live_a_long_life/services/sync/lan_discovery.dart';
import 'package:live_a_long_life/services/sync/sync_server.dart';
import 'package:live_a_long_life/services/sync/sync_service.dart';
import 'package:path/path.dart' as p;

import '../data/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv macEnv;
  late TestEnv phoneEnv;
  late Directory tempDir;
  late SyncServer server;
  late SyncService sync;
  late MessageRepository phoneMessages;

  setUp(() async {
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
    macEnv = await TestEnv.create();
    phoneEnv = await TestEnv.create();
    tempDir = await Directory.systemTemp.createTemp('sync_push');

    server = SyncServer(
      deviceId: 'mac-1',
      displayName: 'Mac',
      db: macEnv.db,
      filesDir: Directory(p.join(tempDir.path, 'mac_files')),
      peers: PeerRepository(macEnv.db),
      keyStore: KeyStore(),
      records: RecordRepository(macEnv.db, macEnv.ctx),
    );
    final info = await server.startPairing();
    final client = SyncClient(
      deviceId: 'test-device', // 与 TestEnv 的 ctx.deviceId 一致
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

    phoneMessages = MessageRepository(phoneEnv.db, phoneEnv.ctx);
    sync = SyncService(
      deviceId: 'test-device',
      db: phoneEnv.db,
      peers: PeerRepository(phoneEnv.db),
      keyStore: KeyStore(),
      filesDir: Directory(p.join(tempDir.path, 'phone_files')),
    );
  });

  tearDown(() async {
    await server.stop();
    await macEnv.dispose();
    await phoneEnv.dispose();
    await tempDir.delete(recursive: true);
  });

  test('消息与记录逐条推送到 Mac，游标推进，重复同步不重发（断点续传基础）',
      () async {
    final m = await phoneMessages.send(
      clientMsgId: 'c1',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '晚饭吃了面',
      sentTz: 'Asia/Shanghai',
    );
    await phoneMessages.edit(m.id, '晚饭吃了一碗面');
    await RecordRepository(phoneEnv.db, phoneEnv.ctx).create(
      recordType: RecordType.meal,
      occurred: TimeValue(
          localDate: '2026-09-27',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten","description":"面"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('r1'),
      sources: [
        SourceLink(sourceKind: RecordSourceKind.message, sourceId: m.id),
      ],
    );

    final result = await sync.syncNow();
    expect(result.error, isNull);
    expect(result.sent, greaterThanOrEqualTo(6));
    expect(result.pending, 0);

    // Mac 副本内容一致（编辑后的文字 + 修改历史 + 记录）。
    final macMessages = await macEnv.db.select(macEnv.db.messages).get();
    expect(macMessages.single.body, '晚饭吃了一碗面');
    expect(macMessages.single.revisionNo, 1);
    expect(await macEnv.db.select(macEnv.db.messageRevisions).get(),
        hasLength(1));
    final macRecords = await macEnv.db.select(macEnv.db.records).get();
    expect(macRecords, hasLength(1));
    expect(await macEnv.db.select(macEnv.db.recordRevisions).get(),
        hasLength(1));

    // Mac 不为接收产生自己的变更日志（schema §7.2）。
    expect(await macEnv.db.select(macEnv.db.changeLogs).get(), isEmpty);

    // 双端游标一致。
    final phonePush = await (phoneEnv.db.select(phoneEnv.db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.push)))
        .getSingle();
    final macPull = await (macEnv.db.select(macEnv.db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.pull)))
        .getSingle();
    expect(phonePush.ackedContiguousSeq, macPull.ackedContiguousSeq);

    // 再同步：没有新变更，不重发。
    final again = await sync.syncNow();
    expect(again.sent, 0);

    // 增量：新写一条只发新增的。
    await phoneMessages.send(
      clientMsgId: 'c2',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '又一条',
      sentTz: 'Asia/Shanghai',
    );
    final incremental = await sync.syncNow();
    expect(incremental.sent, 1);
    expect(await macEnv.db.select(macEnv.db.messages).get(), hasLength(2));
  });

  test('附件：先 need_blob 再传文件，Mac 校验落盘并记自己的副本状态', () async {
    final phoneFiles = Directory(p.join(tempDir.path, 'phone_files'));
    final attachments = AttachmentRepository(phoneEnv.db, phoneEnv.ctx,
        filesDir: phoneFiles);
    final src = File(p.join(tempDir.path, 'photo.jpg'));
    await src.writeAsBytes(List.generate(300, (i) => i % 250));
    final imported = await attachments.importFile(src,
        mimeType: 'image/jpeg', originalFilename: 'photo.jpg');
    final m = await phoneMessages.send(
      clientMsgId: 'c1',
      role: MessageRole.user,
      kind: MessageKind.attachments,
      sentTz: 'Asia/Shanghai',
    );
    await attachments.linkToMessage(
        messageId: m.id, attachmentId: imported.attachment.id, position: 0);

    final result = await sync.syncNow();
    expect(result.error, isNull);

    final sha = imported.attachment.sha256;
    final macFile = File(p.join(tempDir.path, 'mac_files', sha));
    expect(await macFile.exists(), isTrue);
    expect((await macFile.readAsBytes()).length, 300);

    // Mac 给自己记了副本状态（deviceId = mac-1，不入变更日志）。
    final macCopies =
        await macEnv.db.select(macEnv.db.attachmentCopies).get();
    final macCopy = macCopies.singleWhere((c) => c.deviceId == 'mac-1');
    expect(macCopy.state, CopyState.present);
    expect(macCopy.localPath, sha);
  });

  test('代次变化：Mac 拒收并提示重建，不静默混用旧序号（schema §7.3）', () async {
    await phoneMessages.send(
      clientMsgId: 'c1',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '第一代的数据',
      sentTz: 'Asia/Shanghai',
    );
    expect((await sync.syncNow()).error, isNull);

    // 模拟恢复换代次：清掉 generation，写入新变更。
    await (phoneEnv.db.delete(phoneEnv.db.settings)
          ..where((t) => t.key.equals('data_generation')))
        .go();
    await phoneMessages.send(
      clientMsgId: 'c2',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '新代次的数据',
      sentTz: 'Asia/Shanghai',
    );

    final result = await sync.syncNow();
    expect(result.error, contains('代次已变化'));
    // Mac 上没有第二条消息。
    expect(await macEnv.db.select(macEnv.db.messages).get(), hasLength(1));
  });

  test('检验结果同步到 Mac 后建索引，新版本到达后索引跟上（D-27，2026-09-29 联调）',
      () async {
    final phoneRecords = RecordRepository(phoneEnv.db, phoneEnv.ctx);
    final occurred = TimeValue(
        localDate: '2026-01-27',
        precision: TimePrecision.dateOnly,
        source: TimeValueSource.userStated);
    String panel(String value) => jsonEncode({
          'medical_document_id': 'doc-1',
          'results': [
            {'item_name_raw': '牛肉', 'value_raw': value, 'value_num': num.parse(value)},
            {'item_name_raw': '鸡肉', 'value_raw': '5', 'value_num': 5},
          ],
        });
    final rec = await phoneRecords.create(
      recordType: RecordType.labPanel,
      occurred: occurred,
      dataJson: panel('0'),
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );
    expect((await sync.syncNow()).error, isNull);

    final macIndex = await macEnv.db.select(macEnv.db.labResults).get();
    expect(macIndex.map((r) => r.itemNameRaw), unorderedEquals(['牛肉', '鸡肉']));
    expect(macIndex.first.medicalDocumentId, 'doc-1');

    // 手机上修改（新版本）→ Mac 索引跟着换成新值。
    await phoneRecords.addRevision(
      recordId: rec.id,
      baseVersion: rec.version,
      occurred: occurred,
      dataJson: panel('9'),
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );
    expect((await sync.syncNow()).error, isNull);
    final beef = await (macEnv.db.select(macEnv.db.labResults)
          ..where((t) => t.itemNameRaw.equals('牛肉')))
        .getSingle();
    expect(beef.valueRaw, '9');
    expect(await macEnv.db.select(macEnv.db.labResults).get(), hasLength(2));

    // 手机删除 → Mac 索引清空。
    await phoneRecords.markDeleted(rec.id);
    expect((await sync.syncNow()).error, isNull);
    expect(await macEnv.db.select(macEnv.db.labResults).get(), isEmpty);
  });

  test('Mac 换了地址：按设备 ID 在局域网找回新地址，同步照常并更新记录（V4-M5）',
      () async {
    final phonePeers = PeerRepository(phoneEnv.db);
    final mac = (await phonePeers.all()).single;
    final goodAddr = mac.lastSeenAddr!;
    // 模拟 Mac 换 IP：记录里的旧地址已连不上。
    await phonePeers.updateLastSeen(mac.peerDeviceId, '127.0.0.1:1');
    await phoneMessages.send(
      clientMsgId: 'c-mdns',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '换了网络之后的一条',
      sentTz: 'Asia/Shanghai',
    );

    // 没有发现能力：和以前一样连不上。
    final withoutDiscovery = await sync.syncNow();
    expect(withoutDiscovery.error, isNotNull);

    final asked = <String>[];
    final withDiscovery = SyncService(
      deviceId: 'test-device',
      db: phoneEnv.db,
      peers: phonePeers,
      keyStore: KeyStore(),
      filesDir: Directory(p.join(tempDir.path, 'phone_files')),
      discover: (id) async {
        asked.add(id);
        // 第一个候选连不上（比如已拔线的直连地址），应接着试下一个。
        return ['127.0.0.1:2', goodAddr];
      },
    );
    final result = await withDiscovery.syncNow();
    expect(result.error, isNull);
    expect(asked, [mac.peerDeviceId]); // 按 Mac 的设备 ID 找
    expect((await phonePeers.all()).single.lastSeenAddr, goodAddr);
    expect(await macEnv.db.select(macEnv.db.messages).get(), hasLength(1));

    // 地址已更新：下次直接连上，不再查找。
    await withDiscovery.syncNow();
    expect(asked, hasLength(1));
  });

  test('候选地址排序：局域网地址优先，169.254 链路本地地址放最后', () {
    expect(
        LanDiscovery.preferOrder(
            ['169.254.140.85:47857', '10.0.0.26:47857', '10.0.0.26:47857']),
        ['10.0.0.26:47857', '169.254.140.85:47857']);
  });
}
