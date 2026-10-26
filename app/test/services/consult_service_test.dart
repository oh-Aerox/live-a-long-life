import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/consult_service.dart';
import 'package:live_a_long_life/services/consult_tools.dart';
import 'package:live_a_long_life/services/health_service.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/tool_chat.dart';

import '../data/test_helpers.dart';
import 'organize_service_test.dart' show FakeModel;

/// 带工具的假模型：按脚本逐轮返回，记下每轮收到的消息和是否允许调用工具。
class FakeToolModel {
  final _script = <Object>[];
  final calls = <({List<ToolChatMessage> messages, bool allowTools})>[];

  void reply(Object turnOrError) => _script.add(turnOrError);

  Future<ToolChatResponse> call({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required List<ToolChatMessage> messages,
    required List<ToolSpec> tools,
    required bool allowTools,
    required int maxTokens,
  }) async {
    calls.add((messages: List.of(messages), allowTools: allowTools));
    if (_script.isEmpty) {
      throw StateError('FakeToolModel 没有预置应答（第 ${calls.length} 次调用）');
    }
    final next = _script.removeAt(0);
    if (next is Exception) throw next;
    return next as ToolChatResponse;
  }
}

ToolChatResponse textTurn(String text) => ToolChatResponse(
    text: text,
    toolCalls: const [],
    assistant: const AssistantTurn([]),
    tokensIn: 10,
    tokensOut: 20);

ToolChatResponse toolTurn(String name, Map<String, Object?> args,
        {String id = 'call-1'}) =>
    ToolChatResponse(
      text: '',
      toolCalls: [ToolCall(id: id, name: name, arguments: args)],
      assistant: AssistantTurn([
        {'type': 'tool_use', 'id': id, 'name': name, 'input': args},
      ]),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late RecordRepository records;
  late ProfileRepository profile;
  late ModelConfigRepository configs;
  late OrganizeRepository organize;
  late FakeModel model;
  late FakeToolModel toolModel;
  late ConsultService consult;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
    profile = ProfileRepository(env.db, env.ctx);
    configs = ModelConfigRepository(env.db, env.ctx);
    organize = OrganizeRepository(env.db, env.ctx);
    model = FakeModel();
    toolModel = FakeToolModel();
    consult = ConsultService(
      db: env.db,
      records: records,
      profile: profile,
      organize: organize,
      modelConfigs: configs,
      keyStore: KeyStore(),
      tools: ConsultTools(
        db: env.db,
        records: records,
        documents: MedicalDocumentRepository(env.db, env.ctx),
        deviceData: (_) async => const DeviceDayData(
            sleep: null, workouts: [], steps: null, activeEnergyKcal: null),
      ),
      modelCall: model.call,
      toolCall: toolModel.call,
    );
  });

  tearDown(() => env.dispose());

  Future<void> addConfig() => configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.example.com',
        model: 'm',
        dataBoundary: DataBoundary.cloud,
        keychainRef: '',
      );

  String today() {
    final t = DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  Future<void> addCondition(String name, ReviewStatus status,
      {String state = 'active'}) async {
    await records.create(
      recordType: RecordType.condition,
      occurred: TimeValue(
          localDate: '2025-01-01',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: jsonEncode({
        'name': name,
        'persistence': 'long_term',
        'status': state,
        'development_text': null,
      }),
      fieldMeta: FieldMetaMap({
        'condition':
            FieldMeta(origin: FieldOrigin.modelInferred, reviewStatus: status),
      }),
      producedBy: ProducedBy.medicalExtract('c1'),
    );
  }

  test('不允许查阅：一问一答，基本资料 + 已确认状况进入，未核对不进（D-26）',
      () async {
    await addConfig();
    await profile.setField('sex_at_birth', value: 'male');
    await addCondition('胆囊结石', ReviewStatus.confirmed);
    await addCondition('甲状腺结节', ReviewStatus.unreviewed);
    await addCondition('肾结石', ReviewStatus.edited, state: 'resolved');
    await records.create(
      recordType: RecordType.meal,
      occurred: TimeValue(
          localDate: today(),
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten","description":"牛肉面"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('r1'),
    );

    model.reply('结石患者注意多喝水，少吃油腻。');
    final reply = await consult.ask('s1', '晚饭吃什么好？');
    expect(reply.role, 'assistant');
    expect(reply.body, contains('结石'));

    final sent = jsonDecode(model.calls.single) as Map;
    expect((sent['profile'] as Map)['sex_at_birth'], 'male');
    final names = (sent['long_term_conditions'] as List)
        .map((e) => (e as Map)['name'])
        .toList();
    expect(names, ['胆囊结石']); // 未核对的不进（D-04），已痊愈的单列
    expect([for (final e in sent['past_conditions'] as List) e['name']],
        ['肾结石']);
    expect(sent['today'], today());
    expect((sent['conversation'] as List).length, 1);

    // 调用记录：caller 与发送范围描述（A-38）。
    final call = (await organize.recentModelCalls()).single;
    expect(call.caller, ModelCaller.userConsult);
    expect(call.sentSummary, contains('基本资料'));
    expect(call.sentSummary, contains('状况档案 1 条'));
    expect(call.sentSummary, isNot(contains('最近 7 天')));

    // 咨询不进消息流、不生成记录（D-26）。
    expect(await env.db.select(env.db.messages).get(), isEmpty);
    final recs = await env.db.select(env.db.records).get();
    expect(recs.where((r) => r.recordType == RecordType.note), isEmpty);
    // 不入变更日志（本地问答不同步）。
    final changes = await env.db.select(env.db.changeLogs).get();
    expect(changes.where((c) => c.entityType == 'consult_messages'), isEmpty);
  });

  test('多轮追问带会话历史', () async {
    await addConfig();
    model.reply('第一轮回答');
    await consult.ask('s1', '最近想加强锻炼');
    model.reply('第二轮回答');
    await consult.ask('s1', '那强度怎么定？');

    final sent = jsonDecode(model.calls[1]) as Map;
    final convo = sent['conversation'] as List;
    expect(convo, hasLength(3)); // 首问 + 首答 + 当前问题
    expect((convo[1] as Map)['role'], 'assistant');

    final msgs = await consult.messagesOf('s1');
    expect(msgs, hasLength(4));
    expect(msgs.last.modelCallId, isNotNull);
  });

  test('允许查阅（D-43）：模型调工具、结果发回、再作答；每轮一条调用记录，问题下方列出查了什么',
      () async {
    await addConfig();
    await records.create(
      recordType: RecordType.exercise,
      occurred: TimeValue(
          localDate: today(),
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"done","activity":"跑步","duration_text":"30 分钟"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('r1'),
    );

    toolModel.reply(toolTurn(
        'get_records', {'start_date': today(), 'end_date': today()}));
    toolModel.reply(textTurn('今天跑了 30 分钟，强度合适。'));
    final reply = await consult.ask('s1', '我今天运动够吗？', allowLookup: true);

    expect(reply.body, contains('30 分钟'));
    expect(model.calls, isEmpty); // 不走一问一答
    expect(toolModel.calls, hasLength(2));
    // 第二轮带上了模型的工具调用和工具结果。
    final second = toolModel.calls[1].messages;
    expect(second, hasLength(3));
    expect(second[1], isA<AssistantTurn>());
    final result = (second[2] as ToolResults).results.single;
    expect(result.callId, 'call-1');
    expect(result.content, contains('跑步'));

    final question = (await consult.messagesOf('s1')).first;
    expect(question.contextNote, contains('查阅：记录'));
    expect(question.contextNote, contains('（1 条）'));

    final calls = await organize.recentModelCalls();
    expect(calls, hasLength(2));
    expect(calls.every((c) => c.caller == ModelCaller.userConsult), isTrue);
    // 第二轮的发送内容是工具结果，可在调用记录里查到；回答出自这一轮。
    final toolRound =
        calls.firstWhere((c) => c.sentSummary!.startsWith('查阅结果'));
    expect(toolRound.requestText, contains('跑步'));
    expect(reply.modelCallId, toolRound.id);
    // 第一轮的返回内容记的是模型要调的工具。
    final first = calls.firstWhere((c) => c.id != toolRound.id);
    expect(first.responseText, contains('get_records'));
  });

  test('允许查阅：到轮数上限时禁止再调工具，逼模型作答', () async {
    await addConfig();
    for (var i = 1; i < ConsultService.maxLookupRounds; i++) {
      toolModel.reply(toolTurn('list_lab_items', {}, id: 'c$i'));
    }
    toolModel.reply(textTurn('根据现有数据……'));
    await consult.ask('s1', '我的指标怎么样', allowLookup: true);
    expect(toolModel.calls, hasLength(ConsultService.maxLookupRounds));
    expect(toolModel.calls.last.allowTools, isFalse);
    expect(toolModel.calls[ConsultService.maxLookupRounds - 2].allowTools,
        isTrue);
  });

  test('允许查阅：第一轮被拒（模型不支持工具）时按一问一答回答并注明', () async {
    await addConfig();
    toolModel.reply(ModelClientException('tools not supported', statusCode: 400));
    model.reply('普通回答');
    final reply = await consult.ask('s1', '问一下', allowLookup: true);
    expect(reply.body, '普通回答');
    final question = (await consult.messagesOf('s1')).first;
    expect(question.contextNote, contains('模型不支持查阅'));
    // 失败的一轮和兜底的一问一答各有记录。
    final calls = await organize.recentModelCalls();
    expect(calls.map((c) => c.status).toSet(),
        {ModelCallStatus.failed, ModelCallStatus.succeeded});
  });

  test('允许查阅：网络错误不兜底，照常报错', () async {
    await addConfig();
    toolModel.reply(ModelClientException('网络断了', retriable: true));
    await expectLater(
        consult.ask('s1', '问一下', allowLookup: true), throwsException);
    expect(model.calls, isEmpty);
  });

  test('模型失败：问题保留在会话里，失败调用有记录', () async {
    await addConfig();
    model.reply(ModelClientException('网络断了'));
    await expectLater(consult.ask('s1', '问一下'), throwsException);
    final msgs = await consult.messagesOf('s1');
    expect(msgs.single.role, 'user');
    final call = (await organize.recentModelCalls()).single;
    expect(call.status, ModelCallStatus.failed);
    expect(call.caller, ModelCaller.userConsult);
  });
}
