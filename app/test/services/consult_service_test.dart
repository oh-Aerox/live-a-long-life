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

  test('近 7 天摘要（联调修订）：睡眠带时间；未核对状况与报告要点不发；已核对报告发诊断/异常/药名', () async {
    await addConfig();
    final occurred = TimeValue(
        localDate: today(),
        precision: TimePrecision.dateOnly,
        source: TimeValueSource.userStated);
    Future<void> add(RecordType type, Map<String, Object?> data,
            Map<String, FieldMeta> meta) =>
        records.create(
          recordType: type,
          occurred: occurred,
          dataJson: jsonEncode(data),
          fieldMeta: FieldMetaMap(meta),
          producedBy: ProducedBy.userEdit(),
        );
    const unreviewed = FieldMeta(
        origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.unreviewed);
    const confirmed = FieldMeta(
        origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.confirmed);

    await add(RecordType.sleep, {
      'sleep_onset': {'local_date': today(), 'local_time': '23:40'},
      'wake_time': {'local_date': today(), 'local_time': '07:05'},
      'quality_text': '睡得还行',
    }, {});
    await add(RecordType.condition,
        {'name': '胆囊息肉', 'persistence': 'long_term', 'status': 'active'},
        {'condition': unreviewed});
    // 全部未核对的报告：不发。
    await add(RecordType.labPanel, {
      'medical_document_id': 'd1',
      'results': [],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '未核对的诊断'}
      ],
    }, {'findings.0': unreviewed});
    // 已核对的报告：诊断、异常值、药名；正常值、现病史、未核对的药不发。
    await add(RecordType.labPanel, {
      'medical_document_id': 'd2',
      'results': [
        {'item_name_raw': '白细胞', 'value_raw': '11.2', 'value_num': 11.2,
         'unit_raw': '10^9/L', 'ref_range_raw': '3.5-9.5', 'ref_low': 3.5,
         'ref_high': 9.5, 'flag_raw': null},
        {'item_name_raw': '血红蛋白', 'value_raw': '145', 'value_num': 145,
         'ref_low': 130, 'ref_high': 175, 'flag_raw': null},
      ],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '1.咽喉炎 2.上呼吸道感染'},
        {'section_raw': '现病史', 'text_raw': '患者5天前出现不适'},
      ],
      'medications': [
        {'name': '头孢呋辛酯片'},
        {'name': '未核对的药'},
      ],
    }, {
      'results.0': confirmed,
      'results.1': confirmed,
      'findings.0': confirmed,
      'findings.1': confirmed,
      'medications.0': confirmed,
      'medications.1': unreviewed,
    });

    model.reply('好的');
    await consult.ask('s1', '最近要注意什么', includeRecentRecords: true);
    final sent = jsonDecode(model.calls.single) as Map;
    final summaries = [
      for (final r in sent['recent_records'] as List) (r as Map)['summary'] as String
    ];
    final all = summaries.join('\n');
    expect(all, contains('入睡 23:40'));
    expect(all, contains('醒来 07:05'));
    expect(all, isNot(contains('胆囊息肉')));
    expect(all, isNot(contains('未核对')));
    expect(all, contains('诊断：1.咽喉炎 2.上呼吸道感染'));
    expect(all, contains('白细胞 11.210^9/L'));
    expect(all, isNot(contains('血红蛋白')));
    expect(all, isNot(contains('现病史')));
    expect(all, contains('开药：头孢呋辛酯片'));
    expect(summaries, hasLength(2)); // 睡眠 + 已核对的报告

    // 调用记录保存了实际发送的内容。
    final call = (await organize.recentModelCalls()).single;
    expect(call.requestText, model.calls.single);
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
