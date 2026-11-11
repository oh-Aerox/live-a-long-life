import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/organize_service.dart';
import 'package:path/path.dart' as p;

import '../data/test_helpers.dart';

/// 按脚本逐次返回的假模型：每次调用弹出一个应答（文本或异常）。
class FakeModel {
  final _script = <Object>[];
  final calls = <String>[]; // 每次调用的 userText

  /// 文字、异常，或调用时才求值的函数（模拟调用途中发生的事）。
  void reply(Object textOrError) => _script.add(textOrError);

  Future<ModelResponse> call({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    required int maxTokens,
    void Function(String delta)? onText,
  }) async {
    calls.add(userText);
    if (_script.isEmpty) {
      throw StateError('FakeModel 没有预置应答（第 ${calls.length} 次调用）');
    }
    var next = _script.removeAt(0);
    if (next is Object Function()) next = next();
    if (next is ModelClientException) throw next;
    return ModelResponse(text: next as String, tokensIn: 10, tokensOut: 20);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late MessageRepository messages;
  late RecordRepository records;
  late OrganizeRepository runs;
  late ModelConfigRepository configs;
  late FakeModel model;
  late OrganizeService service;

  setUp(() async {
    env = await TestEnv.create();
    messages = MessageRepository(env.db, env.ctx);
    records = RecordRepository(env.db, env.ctx);
    runs = OrganizeRepository(env.db, env.ctx);
    configs = ModelConfigRepository(env.db, env.ctx);
    model = FakeModel();
    FlutterSecureStorage.setMockInitialValues({});
    service = OrganizeService(
      db: env.db,
      messages: messages,
      records: records,
      runs: runs,
      modelConfigs: configs,
      keyStore: KeyStore(),
      modelCall: model.call,
    );
  });

  tearDown(() async {
    service.dispose();
    await env.dispose();
  });

  Future<Message> say(String text, {String? clientMsgId}) => messages.send(
        clientMsgId: clientMsgId ?? 'c-${text.hashCode}',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: text,
        sentTz: 'Asia/Shanghai',
      );

  Future<ModelConfig> addConfig(
          {DataBoundary boundary = DataBoundary.cloud}) =>
      configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.example.com',
        model: 'm',
        dataBoundary: boundary,
        keychainRef: '',
      );

  String mealJson(List<String> sourceIds,
          {String date = '2026-09-26', String? recordId}) =>
      jsonEncode([
        {
          'record_id': recordId,
          'record_type': 'meal',
          'occurred': {'local_date': date, 'precision': 'date_only'},
          'data': {
            'status': 'eaten',
            'meal_slot': 'dinner',
            'description': '面',
          },
          'source_message_ids': sourceIds,
          'inferred_fields': ['meal_slot'],
        },
      ]);

  test('A-10：没有配置模型时不建批次，消息保持待整理', () async {
    final m = await say('晚饭吃了面');
    expect(await service.enqueue(OrganizeTrigger.doneMarker), isNull);
    expect((await messages.byId(m.id))!.organizeState, OrganizeState.pending);
    expect(model.calls, isEmpty);
  });

  test('成功整理：记录落盘、来源链接、字段来源标注、消息转已整理（A-08 补记昨天）',
      () async {
    await addConfig();
    final m = await say('昨天晚饭吃了面');
    model.reply(mealJson([m.id], date: '2026-09-25'));

    final run = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.succeeded);
    expect(finished.modelConfigId, isNotNull);

    // 记录归到昨天，记录时间是现在（A-08）。
    final day = await records.byDate('2026-09-25');
    expect(day, hasLength(1));
    final rev = await records.currentRevisionOf(day.single.id);
    expect(jsonDecode(rev.data)['description'], '面');
    // meal_slot 是模型推断，description 来自原话。
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    expect(meta['meal_slot']!.origin, FieldOrigin.modelInferred);
    expect(meta['description']!.origin, FieldOrigin.userStated);

    final sources = await records.sourcesOf(rev.id);
    expect(sources.single.sourceId, m.id);
    expect(sources.single.messageRevisionNo, 0);

    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);

    // 模型调用有记录（D-16）。
    final calls = await runs.recentModelCalls();
    expect(calls.single.status, ModelCallStatus.succeeded);
    expect(jsonDecode(calls.single.sentMessageIds), [m.id]);

    // 归属日期不是今天：对话流出现"已记到 9月25日"提示，指向这条记录（A-23）。
    final thread = await messages.thread();
    final notice =
        thread.where((t) => t.kind == MessageKind.appNotice).single;
    expect(notice.body, contains('已记到 9月25日'));
    expect(jsonDecode(notice.promptMeta!)['record_id'], day.single.id);
    expect(notice.inReplyTo, m.id);
  });

  test('记录上点"重新整理"：来源消息重排，模型带 record_id 更新原记录（D-05 触发 4）',
      () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    model.reply(mealJson([m.id]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    final record = (await records.byDate('2026-09-26')).single;
    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);

    // 重新整理：模型这次把描述改了，带 record_id 更新。
    model.reply(jsonEncode([
      {
        'record_id': record.id,
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten', 'meal_slot': 'dinner', 'description': '牛肉面'},
        'source_message_ids': [m.id],
        'inferred_fields': ['meal_slot'],
      },
    ]));
    final run = await service.reorganizeRecord(record.id);
    expect(run, isNotNull);
    expect(run!.trigger, OrganizeTrigger.userReorganize);
    await service.pump();

    // 同一条记录出了新版本，不是新建。
    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(1));
    final rev = await records.currentRevisionOf(record.id);
    expect(jsonDecode(rev.data)['description'], '牛肉面');
    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);
  });

  test('重新整理：没有默认模型或来源消息已删除时返回 null', () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    model.reply(mealJson([m.id]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    final record = (await records.byDate('2026-09-26')).single;

    // 来源消息删除后没有可重排的输入。
    await messages.markDeleted(m.id);
    expect(await service.reorganizeRecord(record.id), isNull);
  });

  test('A-30：同一天两次运动生成两条独立记录', () async {
    await addConfig();
    final m = await say('早上跑步 30 分钟，晚上游泳 1 小时');
    model.reply(jsonEncode([
      {
        'record_type': 'exercise',
        'occurred': {
          'local_date': '2026-09-26',
          'precision': 'part_of_day',
          'part_of_day': 'morning',
        },
        'data': {'status': 'done', 'activity': '跑步', 'duration_text': '30 分钟'},
        'source_message_ids': [m.id],
      },
      {
        'record_type': 'exercise',
        'occurred': {
          'local_date': '2026-09-26',
          'precision': 'part_of_day',
          'part_of_day': 'evening',
        },
        'data': {'status': 'done', 'activity': '游泳', 'duration_text': '1 小时'},
        'source_message_ids': [m.id],
      },
    ]));

    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(2));
    expect(day.first.id, isNot(day.last.id));
  });

  test('无效项被丢弃、有效项照常写入，批次记 partial（不猜默认值）', () async {
    await addConfig();
    final m = await say('晚饭吃了面，另外某些乱七八糟的');
    model.reply(jsonEncode([
      jsonDecode(mealJson([m.id])).first,
      {'record_type': '不存在的类型', 'data': {}},
      {'record_type': 'mood'}, // 缺 occurred 和 source
    ]));

    final run = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.partial);
    expect(finished.error, contains('被丢弃'));
    expect(await records.byDate('2026-09-26'), hasLength(1));
  });

  test('返回不是 JSON：批次 failed，消息保持待整理，可下次补整理', () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    model.reply('抱歉，我不能……');

    final run = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.failed);
    expect((await messages.byId(m.id))!.organizeState, OrganizeState.pending);
  });

  test('A-11：局域网模型不可达时批次 blocked_boundary，不再调用任何模型', () async {
    await addConfig(boundary: DataBoundary.lan);
    final m = await say('晚饭吃了面');
    model.reply(ModelClientException('网络错误', retriable: true));

    final run = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.blockedBoundary);
    expect((await messages.byId(m.id))!.organizeState, OrganizeState.pending);
    expect(model.calls, hasLength(1)); // 只试了这一个配置，没有别的请求
  });

  test('A-24：整理中修改输入 → 本批作废重排，最终记录基于修改后的文字', () async {
    await addConfig();
    final m = await say('晚饭吃了两碗饭');

    // 第一次应答返回前修改消息（模型调用瞬间篡改，模拟"整理进行中修改"）。
    var edited = false;
    Future<ModelResponse> tamperedCall({
      required ModelConfig config,
      required String apiKey,
      String? system,
      required String userText,
      required int maxTokens,
    }) async {
      final resp = await model.call(
          config: config,
          apiKey: apiKey,
          system: system,
          userText: userText,
          maxTokens: maxTokens);
      if (!edited) {
        edited = true;
        await messages.edit(m.id, '晚饭吃了一碗饭');
      }
      return resp;
    }

    service = OrganizeService(
      db: env.db,
      messages: messages,
      records: records,
      runs: runs,
      modelConfigs: configs,
      keyStore: KeyStore(),
      modelCall: tamperedCall,
    );

    model.reply(jsonEncode([
      {
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten', 'description': '两碗饭'},
        'source_message_ids': [m.id],
      },
    ]));
    // 重排批次基于修改后的文字。
    model.reply(jsonEncode([
      {
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten', 'description': '一碗饭'},
        'source_message_ids': [m.id],
      },
    ]));

    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    // 旧结果作废：没有"两碗饭"的记录。
    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(1));
    final rev = await records.currentRevisionOf(day.single.id);
    expect(jsonDecode(rev.data)['description'], '一碗饭');
    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);
    // 第二次调用的输入里是修改后的文字。
    expect(model.calls, hasLength(2));
    expect(model.calls.last, contains('一碗饭'));

    // 第一批的项标了 stale_input。
    final items = await env.db.select(env.db.organizeRunItems).get();
    expect(items.map((i) => i.status),
        containsAll([OrganizeItemStatus.staleInput, OrganizeItemStatus.committed]));
  });

  test('A-25：用户修改过的字段不被整理覆盖，生成修正建议', () async {
    await addConfig();
    // 整理只把最近 7 天的记录放进快照，记录日期要跟着今天走，写死的日期
    // 过几天就出了窗口，模型给的 record_id 会被当成编造的拒掉。
    final t = DateTime.now();
    final day =
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final m = await say('一点睡的');
    model.reply(jsonEncode([
      {
        'record_type': 'sleep',
        'occurred': {'local_date': day, 'precision': 'date_only'},
        'data': {'quality_text': '还行', 'sleep_onset_text': '01:00'},
        'source_message_ids': [m.id],
      },
    ]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    // 用户手动把 sleep_onset_text 改为 00:30（字段级 edited）。
    final rec = (await records.byDate(day)).single;
    final rev = await records.currentRevisionOf(rec.id);
    final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
    data['sleep_onset_text'] = '00:30';
    final meta = FieldMetaMap.decode(rev.fieldMeta).fields;
    meta['sleep_onset_text'] = const FieldMeta(
        origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited);
    await records.addRevision(
      recordId: rec.id,
      baseVersion: (await records.byId(rec.id))!.version,
      occurred: TimeValue.decode(rev.occurred),
      dataJson: jsonEncode(data),
      fieldMeta: FieldMetaMap(meta),
      producedBy: ProducedBy.userEdit(),
    );

    // 又发一条消息，模型得出不同的入睡时间，更新同一条记录。
    final m2 = await say('想起来了，是快两点才睡着');
    model.reply(jsonEncode([
      {
        'record_id': rec.id,
        'record_type': 'sleep',
        'occurred': {'local_date': day, 'precision': 'date_only'},
        'data': {'quality_text': '不太好', 'sleep_onset_text': '01:50'},
        'source_message_ids': [m2.id],
      },
    ]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    // 受保护字段保持用户值；其他字段正常更新。
    final after = await records.currentRevisionOf(rec.id);
    final afterData = (jsonDecode(after.data) as Map).cast<String, Object?>();
    expect(afterData['sleep_onset_text'], '00:30');
    expect(afterData['quality_text'], '不太好');
    final afterMeta = FieldMetaMap.decode(after.fieldMeta);
    expect(afterMeta['sleep_onset_text']!.reviewStatus, ReviewStatus.edited);

    // 生成了修正建议，绑定提交后的版本。
    final suggestions =
        await env.db.select(env.db.correctionSuggestions).get();
    expect(suggestions, hasLength(1));
    expect(suggestions.single.targetRecordId, rec.id);
    expect(jsonDecode(suggestions.single.proposedData),
        {'sleep_onset_text': '01:50'});
    expect(suggestions.single.status, SuggestionStatus.pending);
    expect(suggestions.single.targetVersion,
        (await records.byId(rec.id))!.version);

    // 项状态 protected_suggested，且没有为冲突重调模型（共 2 次调用）。
    final items = await env.db.select(env.db.organizeRunItems).get();
    expect(items.map((i) => i.status),
        contains(OrganizeItemStatus.protectedSuggested));
    expect(model.calls, hasLength(2));
  });

  test('空数组：批次成功，闲聊消息也算整理过', () async {
    await addConfig();
    final m = await say('哈哈哈');
    model.reply('[]');
    final run = await service.enqueue(OrganizeTrigger.idle);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.succeeded);
    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);
  });

  test('照片消息被模型关联到记录：照片挂上、消息转已整理；没被引用的纯图片保持待整理',
      () async {
    await addConfig();
    final tempDir = await Directory.systemTemp.createTemp('organize_photo');
    addTearDown(() => tempDir.delete(recursive: true));
    final attachments = AttachmentRepository(env.db, env.ctx,
        filesDir: Directory(p.join(tempDir.path, 'files')));

    Future<(Message, String)> photoMessage(String name, int seed) async {
      final f = File(p.join(tempDir.path, name));
      await f.writeAsBytes(List.filled(64, seed));
      final imported = await attachments.importFile(f, mimeType: 'image/jpeg');
      final m = await messages.send(
        clientMsgId: 'photo-$name',
        role: MessageRole.user,
        kind: MessageKind.attachments,
        sentTz: 'Asia/Shanghai',
      );
      await attachments.linkToMessage(
          messageId: m.id, attachmentId: imported.attachment.id, position: 0);
      return (m, imported.attachment.id);
    }

    final (photoMsg, attachmentId) = await photoMessage('dinner.jpg', 1);
    final (lonePhoto, _) = await photoMessage('random.jpg', 2);
    final textMsg = await say('晚饭吃了面，拍了张照片');

    model.reply(jsonEncode([
      {
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten', 'description': '面'},
        'source_message_ids': [textMsg.id, photoMsg.id],
      },
    ]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    // 模型看到的输入里包含两条照片消息（attachment_count）。
    expect(model.calls.single, contains('attachment_count'));

    final rec = (await records.byDate('2026-09-26')).single;
    final rev = await records.currentRevisionOf(rec.id);
    expect(jsonDecode(rev.data)['photo_attachment_ids'], [attachmentId]);
    final sourceIds =
        (await records.sourcesOf(rev.id)).map((s) => s.sourceId).toSet();
    expect(sourceIds, {textMsg.id, photoMsg.id});

    expect((await messages.byId(photoMsg.id))!.organizeState,
        OrganizeState.organized);
    // 没被引用的纯图片不算整理过，等图片输入能力。
    expect((await messages.byId(lonePhoto.id))!.organizeState,
        OrganizeState.pending);
  });

  test('失败重试后成功不重复：网络失败→成功→再点，只建一条（复现并防回归）',
      () async {
    await addConfig();
    final m = await say('晚饭吃了面');

    // 前两次"记好了"网络失败：不建记录，消息保持 pending。
    model.reply(ModelClientException('网络错误', retriable: true));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    model.reply(ModelClientException('网络错误', retriable: true));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    expect(await records.byDate('2026-09-26'), isEmpty);
    expect((await messages.byId(m.id))!.organizeState, OrganizeState.pending);

    // 换模型后成功一次。
    model.reply(mealJson([m.id]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    expect(await records.byDate('2026-09-26'), hasLength(1));
    expect(
        (await messages.byId(m.id))!.organizeState, OrganizeState.organized);

    // 再点"记好了"：消息已整理，pendingOrganize 为空，enqueue 不建批次。
    final again = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    expect(again, isNull);
    expect(await records.byDate('2026-09-26'), hasLength(1));
  });

  test('模型不可用：对话流提示一次，恢复后提示已恢复并整理', () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    List<Message> notices(List<Message> t) =>
        t.where((x) => x.kind == MessageKind.appNotice).toList();

    model.reply(ModelClientException('网络错误', retriable: true));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    model.reply(ModelClientException('网络错误', retriable: true));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    var n = notices(await messages.thread());
    expect(n, hasLength(1)); // 连续失败只提示一次
    expect(n.single.body, contains('当前模型不可用'));
    expect(n.single.body, contains('自动整理'));

    // 日视图能看到这条待整理的原文。
    final pending = await messages.pendingOrganizeBetween(
        m.sentAt - 1000, m.sentAt + 1000);
    expect(pending.single.id, m.id);

    model.reply(mealJson([m.id]));
    await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();
    n = notices(await messages.thread());
    expect(n.where((x) => x.body!.contains('模型已恢复')), hasLength(1));
    expect((await messages.byId(m.id))!.organizeState,
        OrganizeState.organized);
  });

  test('请求期间切到后台而失败：不提示模型不可用，回前台补整理照常', () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    // 只看模型状态提示（"已记到 X月X日"之类的照常出现）。
    List<Message> notices(List<Message> t) => t
        .where((x) => x.promptMeta?.contains('"kind":"model_') ?? false)
        .toList();

    // 锁屏后应用被挂起，请求断开，回前台时才报超时（2026-11-11 真机）。
    model.reply(() {
      service.noteHidden();
      return ModelClientException('网络错误：超时', retriable: true);
    });
    await service.enqueue(OrganizeTrigger.idle);
    await service.pump();
    expect(notices(await messages.thread()), isEmpty);

    model.reply(mealJson([m.id]));
    await service.catchUp();
    await service.pump();
    expect(notices(await messages.thread()), isEmpty);
    expect((await messages.byId(m.id))!.organizeState,
        OrganizeState.organized);
  });

  test('dedupeExactDuplicates：内容与来源全同的重复只留一条', () async {
    // 手动造 3 条 data/来源相同、但 occurred 来源标记不同的记录
    // （模拟不同批次整理同一句话时时间片段有无的差异）——仍应判为重复。
    final occurreds = [
      TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.inferredFromSentAt),
      TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated,
          rawText: '昨天'),
    ];
    for (var i = 0; i < 3; i++) {
      await records.create(
        recordType: RecordType.meal,
        occurred: occurreds[i],
        dataJson: '{"status":"eaten","description":"面"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('run-$i'),
        sources: const [
          SourceLink(sourceKind: RecordSourceKind.message, sourceId: 'msg-1'),
        ],
      );
    }
    // 一条内容不同的：不该被删。
    await records.create(
      recordType: RecordType.meal,
      occurred: TimeValue(
          localDate: '2026-09-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten","description":"米饭"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('run-x'),
      sources: const [
        SourceLink(sourceKind: RecordSourceKind.message, sourceId: 'msg-1'),
      ],
    );

    final removed = await records.dedupeExactDuplicates();
    expect(removed, 2);
    final day = await records.byDate('2026-09-26');
    expect(day, hasLength(2)); // 一条"面" + 一条"米饭"
  });

  test('模型编造来源消息或目标记录的项被拒绝', () async {
    await addConfig();
    final m = await say('晚饭吃了面');
    model.reply(jsonEncode([
      {
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten'},
        'source_message_ids': ['不存在的消息'],
      },
      {
        'record_id': '不存在的记录',
        'record_type': 'meal',
        'occurred': {'local_date': '2026-09-26', 'precision': 'date_only'},
        'data': {'status': 'eaten'},
        'source_message_ids': [m.id],
      },
    ]));
    final run = await service.enqueue(OrganizeTrigger.doneMarker);
    await service.pump();

    final finished = await (env.db.select(env.db.organizeRuns)
          ..where((t) => t.id.equals(run!.id)))
        .getSingle();
    expect(finished.status, OrganizeRunStatus.failed);
    expect(await records.byDate('2026-09-26'), isEmpty);
  });
}
