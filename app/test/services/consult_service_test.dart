import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/consult_service.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/model_client.dart';

import '../data/test_helpers.dart';
import 'organize_service_test.dart' show FakeModel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late RecordRepository records;
  late ProfileRepository profile;
  late ModelConfigRepository configs;
  late OrganizeRepository organize;
  late FakeModel model;
  late ConsultService consult;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
    profile = ProfileRepository(env.db, env.ctx);
    configs = ModelConfigRepository(env.db, env.ctx);
    organize = OrganizeRepository(env.db, env.ctx);
    model = FakeModel();
    consult = ConsultService(
      db: env.db,
      records: records,
      profile: profile,
      organize: organize,
      modelConfigs: configs,
      keyStore: KeyStore(),
      modelCall: model.call,
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

  Future<void> addCondition(String name, ReviewStatus status) async {
    await records.create(
      recordType: RecordType.condition,
      occurred: TimeValue(
          localDate: '2025-01-01',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: jsonEncode({
        'name': name,
        'persistence': 'long_term',
        'status': 'active',
        'development_text': null,
      }),
      fieldMeta: FieldMetaMap({
        'condition':
            FieldMeta(origin: FieldOrigin.modelInferred, reviewStatus: status),
      }),
      producedBy: ProducedBy.medicalExtract('c1'),
    );
  }

  test('咨询上下文：基本资料 + 已确认状况进入，未核对不进；默认不带近期记录（D-26）',
      () async {
    await addConfig();
    await profile.setField('sex_at_birth', value: 'male');
    await addCondition('胆囊结石', ReviewStatus.confirmed);
    await addCondition('甲状腺结节', ReviewStatus.unreviewed);
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
    expect(names, ['胆囊结石']); // 未核对的不进（D-04）
    expect(sent.containsKey('recent_records'), isFalse); // 默认不带
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

  test('多轮追问带会话历史；勾选后附带近 7 天记录摘要', () async {
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

    model.reply('第一轮回答');
    await consult.ask('s1', '最近想加强锻炼');
    model.reply('第二轮回答');
    await consult.ask('s1', '那强度怎么定？', includeRecentRecords: true);

    final sent = jsonDecode(model.calls[1]) as Map;
    final convo = sent['conversation'] as List;
    expect(convo, hasLength(3)); // 首问 + 首答 + 当前问题
    expect((convo[1] as Map)['role'], 'assistant');
    final recent = sent['recent_records'] as List;
    expect((recent.single as Map)['summary'], contains('跑步'));

    final msgs = await consult.messagesOf('s1');
    expect(msgs, hasLength(4));
    expect(msgs.last.modelCallId, isNotNull);
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
