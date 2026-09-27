import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/change_log.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:path/path.dart' as p;

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late MessageRepository messages;

  setUp(() async {
    env = await TestEnv.create();
    messages = MessageRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  Future<List<ChangeLog>> allChanges() => (env.db.select(env.db.changeLogs)
        ..orderBy([(t) => OrderingTerm.asc(t.changeSeq)]))
      .get();

  Future<Message> say(String text) => messages.send(
        clientMsgId: 'c-${text.hashCode}',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: text,
        sentTz: 'Asia/Shanghai',
      );

  test('change_seq 本代次内单调递增无空洞，代次只生成一次', () async {
    final profile = ProfileRepository(env.db, env.ctx);
    await say('第一条');
    await say('第二条');
    await profile.setField('height_cm', value: 175);

    final changes = await allChanges();
    expect(changes.map((c) => c.changeSeq).toList(), [1, 2, 3]);
    expect(changes.map((c) => c.generation).toSet(), hasLength(1));
    expect(changes.map((c) => c.sourceDeviceId).toSet(), {'test-device'});
    expect(changes.last.entityType, 'profile_fields');

    // 实体的通用 change_seq 已回写（schema §1.1）。
    final field = (await env.db.select(env.db.profileFields).get()).single;
    expect(field.changeSeq, 3);
  });

  test('负载与 entity_version 一致：先发的旧序号带旧文字（Codex 7_reply）', () async {
    final m = await say('早饭吃了鸡蛋');
    await messages.edit(m.id, '早饭吃了鸡蛋和牛奶');

    final changes = (await allChanges())
        .where((c) => c.entityType == 'messages')
        .toList();
    expect(changes, hasLength(2));
    final v1 = jsonDecode(changes[0].payload) as Map;
    final v2 = jsonDecode(changes[1].payload) as Map;
    expect(changes[0].entityVersion, 1);
    expect(v1['text'], '早饭吃了鸡蛋'); // 快照，不是当前行
    expect(changes[1].entityVersion, 2);
    expect(v2['text'], '早饭吃了鸡蛋和牛奶');

    // 编辑同时产生了修改历史行的变更。
    final revisionChanges = (await allChanges())
        .where((c) => c.entityType == 'message_revisions');
    expect(revisionChanges, hasLength(1));
  });

  test('删除是 delete 操作；附件变更带 depends_on_blob', () async {
    final tempDir = await Directory.systemTemp.createTemp('changelog');
    addTearDown(() => tempDir.delete(recursive: true));
    final attachments = AttachmentRepository(env.db, env.ctx,
        filesDir: Directory(p.join(tempDir.path, 'files')));
    final f = File(p.join(tempDir.path, 'a.jpg'));
    await f.writeAsBytes(List.filled(64, 7));
    final imported = await attachments.importFile(f, mimeType: 'image/jpeg');

    final m = await say('误发');
    await attachments.linkToMessage(
        messageId: m.id, attachmentId: imported.attachment.id, position: 0);
    await messages.markDeleted(m.id);

    final changes = await allChanges();
    final attachmentChange =
        changes.singleWhere((c) => c.entityType == 'attachments');
    expect(attachmentChange.dependsOnBlob, imported.attachment.sha256);

    final deletes =
        changes.where((c) => c.op == ChangeOp.delete).toList();
    // 消息 + 它的附件关联都标记 delete。
    expect(deletes.map((c) => c.entityType).toSet(),
        {'messages', 'message_attachments'});
    final messageDelete =
        deletes.singleWhere((c) => c.entityType == 'messages');
    expect(jsonDecode(messageDelete.payload)['deleted_at'], isNotNull);
    expect(messageDelete.entityVersion, 2);
  });

  test('记录写入产生 records + 版本 + 来源三类变更，records 快照是最终状态',
      () async {
    final records = RecordRepository(env.db, env.ctx);
    final rec = await records.create(
      recordType: RecordType.meal,
      occurred: TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('r1'),
      sources: const [
        SourceLink(sourceKind: RecordSourceKind.message, sourceId: 'm1'),
      ],
    );
    await records.addRevision(
      recordId: rec.id,
      baseVersion: 1,
      occurred: TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten","notes":"半碗"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );

    final changes = await allChanges();
    expect(changes.where((c) => c.entityType == 'record_revisions'),
        hasLength(2));
    expect(changes.where((c) => c.entityType == 'record_sources'),
        hasLength(1));
    final recordChanges =
        changes.where((c) => c.entityType == 'records').toList();
    expect(recordChanges, hasLength(2));
    // addRevision 的 records 快照拍在行更新之后：版本 2。
    expect(recordChanges.last.entityVersion, 2);
    expect(
        jsonDecode(recordChanges.last.payload)['version'], 2);
  });

  test('代次不随导出走：恢复后的新库首次写入生成全新代次', () async {
    await say('一条消息');
    final generation = await env.db.currentGeneration();

    // 模拟"另一个环境"：新库（备份恢复后 settings 里没有 data_generation）。
    final other = await TestEnv.create();
    addTearDown(() => other.dispose());
    final otherMessages = MessageRepository(other.db, other.ctx);
    await otherMessages.send(
      clientMsgId: 'c-x',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '恢复后的新消息',
      sentTz: 'Asia/Shanghai',
    );
    final otherGeneration = await other.db.currentGeneration();
    expect(otherGeneration, isNot(generation));
    // 新代次的序号从 1 重新开始。
    final otherChanges = await other.db.select(other.db.changeLogs).get();
    expect(otherChanges.single.changeSeq, 1);
  });
}
