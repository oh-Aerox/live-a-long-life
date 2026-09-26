import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late MessageRepository repo;

  setUp(() async {
    env = await TestEnv.create();
    repo = MessageRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  Future<Message> sendText(String clientMsgId, String text) => repo.send(
        clientMsgId: clientMsgId,
        role: MessageRole.user,
        kind: MessageKind.text,
        text: text,
        sentTz: 'Asia/Shanghai',
      );

  group('幂等写入（D-10、A-04）', () {
    test('同一 client_msg_id 重复提交只落一行', () async {
      final first = await sendText('c1', '早饭吃了鸡蛋');
      final second = await sendText('c1', '早饭吃了鸡蛋');

      expect(second.id, first.id);
      expect(second.seq, first.seq);
      expect((await env.db.select(env.db.messages).get()).length, 1);
    });

    test('不同消息 seq 递增，对话流按 seq 排列', () async {
      final a = await sendText('c1', '第一条');
      final b = await sendText('c2', '第二条');
      expect(b.seq, a.seq + 1);

      final thread = await repo.thread();
      expect(thread.map((m) => m.body).toList(), ['第一条', '第二条']);
    });

    test('用户消息默认待整理，应用消息默认不需要整理', () async {
      final user = await sendText('c1', '你好');
      final app = await repo.send(
        clientMsgId: 'c2',
        role: MessageRole.app,
        kind: MessageKind.appNotice,
        text: '已保存',
        sentTz: 'Asia/Shanghai',
      );
      expect(user.organizeState, OrganizeState.pending);
      expect(app.organizeState, OrganizeState.notApplicable);
    });
  });

  group('修改历史（A-06，schema §2.2）', () {
    test('被替换文字按原修订号保存，从 0 开始', () async {
      final msg = await sendText('c1', '原文');
      expect(msg.revisionNo, 0);

      final edited = await repo.edit(msg.id, '第一次修改');
      expect(edited.revisionNo, 1);
      expect(edited.version, msg.version + 1);
      expect(edited.organizeState, OrganizeState.needsReorganize);

      final edited2 = await repo.edit(msg.id, '第二次修改');
      expect(edited2.revisionNo, 2);

      final revisions = await repo.revisionsOf(msg.id);
      expect(revisions.length, 2);
      expect(revisions[0].revisionNo, 0);
      expect(revisions[0].textBefore, '原文');
      expect(revisions[1].revisionNo, 1);
      expect(revisions[1].textBefore, '第一次修改');
    });

    test('已删除消息不能修改', () async {
      final msg = await sendText('c1', '误发');
      await repo.markDeleted(msg.id);
      expect(() => repo.edit(msg.id, '改一下'), throwsStateError);
    });
  });

  group('删除标记（schema §2.1）', () {
    test('删除写入 deleted_at 且 version 加 1，对话流不再显示', () async {
      final msg = await sendText('c1', '误发');
      await sendText('c2', '正常消息');

      final deleted = await repo.markDeleted(msg.id);
      expect(deleted.deletedAt, isNotNull);
      expect(deleted.version, msg.version + 1);

      final thread = await repo.thread();
      expect(thread.map((m) => m.body), ['正常消息']);

      // 数据仍在，只是被标记。
      expect(await repo.byId(msg.id), isNotNull);
    });

    test('重复删除幂等，version 不再变', () async {
      final msg = await sendText('c1', '误发');
      final once = await repo.markDeleted(msg.id);
      final twice = await repo.markDeleted(msg.id);
      expect(twice.version, once.version);
      expect(twice.deletedAt, once.deletedAt);
    });
  });
}
