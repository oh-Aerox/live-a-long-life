import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/change_log.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/peer_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/analysis_service.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/suggestion_service.dart';
import 'package:live_a_long_life/services/sync/secure_channel.dart';
import 'package:live_a_long_life/services/sync/sync_client.dart';
import 'package:live_a_long_life/services/sync/sync_server.dart';
import 'package:live_a_long_life/services/sync/sync_service.dart';
import 'package:path/path.dart' as p;

import '../data/test_helpers.dart';

String today([int daysAgo = 0]) {
  final t = DateTime.now().subtract(Duration(days: daysAgo));
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalysisService（V3-M5）', () {
    late TestEnv env;
    late RecordRepository records;
    late AnalysisService analysis;
    String? lastPrompt;
    Object? nextReply;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      env = await TestEnv.create();
      records = RecordRepository(env.db, env.ctx);
      final configs = ModelConfigRepository(env.db, env.ctx);
      await configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.example.com',
        model: 'm',
        dataBoundary: DataBoundary.cloud,
        keychainRef: '',
      );
      analysis = AnalysisService(
        db: env.db,
        modelConfigs: configs,
        organize: OrganizeRepository(env.db, env.ctx),
        keyStore: KeyStore(),
        deviceId: 'mac-1',
        modelCall: ({
          required config,
          required apiKey,
          system,
          required userText,
          required maxTokens,
        }) async {
          lastPrompt = userText;
          if (nextReply is Exception) throw nextReply as Exception;
          return ModelResponse(text: nextReply as String);
        },
      );
    });

    tearDown(() => env.dispose());

    test('生成周报：输入含记录版本，产物带引用与数据截止点；失败时旧周报保留',
        () async {
      final rec = await records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
            localDate: today(),
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: '{"status":"eaten","description":"面"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r1'),
      );
      final rev = await records.currentRevisionOf(rec.id);

      nextReply = jsonEncode({
        'content_md': '# 周报\n本周吃了面 [C1]',
        'citations': [
          {'claim_id': 'C1', 'record_revision_ids': [rev.id]},
        ],
      });
      final artifact = await analysis.generateWeeklyReview();
      expect(artifact.contentMd, contains('吃了面'));
      expect(lastPrompt, contains(rev.id)); // 输入里给了修订 ID
      expect(jsonDecode(artifact.citations), hasLength(1));
      expect(artifact.kind, AnalysisKind.weeklyReview);

      // 模型调用有记录（D-20），caller = mac_analysis。
      final calls = await env.db.select(env.db.modelCalls).get();
      expect(calls.single.caller, ModelCaller.macAnalysis);

      // 失败：响应完全为空 → 抛异常，旧周报保留（降级后只有空响应才算失败）。
      nextReply = '   ';
      await expectLater(
          analysis.generateWeeklyReview(), throwsA(isA<StateError>()));
      expect(await analysis.latest(AnalysisKind.weeklyReview), isNotNull);
      expect(
          (await analysis.latest(AnalysisKind.weeklyReview))!.id, artifact.id);
    });

    test('周报输入含状况档案（D-25/R-35）：已确认的长期状况进入，未核对的不进',
        () async {
      TimeValue day(String d) => TimeValue(
          localDate: d,
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated);
      Future<void> addCondition(String name, String persistence,
          ReviewStatus status, String date,
          {String state = 'active'}) async {
        await records.create(
          recordType: RecordType.condition,
          occurred: day(date),
          dataJson: jsonEncode({
            'name': name,
            'persistence': persistence,
            'status': state,
            'source_kind': 'report',
            'development_text': null,
          }),
          fieldMeta: FieldMetaMap({
            'condition': FieldMeta(
                origin: FieldOrigin.modelInferred, reviewStatus: status),
          }),
          producedBy: ProducedBy.medicalExtract('c1'),
        );
      }

      // 已确认的长期状况：进档案（发现日期多久远都进）。
      await addCondition('胆囊结石', 'long_term', ReviewStatus.confirmed,
          '2024-01-15');
      // 已痊愈的长期状况：单列为既往病史，不进长期档案（D-41）。
      await addCondition('肾结石', 'long_term', ReviewStatus.edited,
          '2023-05-01', state: 'resolved');
      // 已痊愈的临时疾病：不进。
      await addCondition('咽炎', 'temporary', ReviewStatus.edited, today(),
          state: 'resolved');
      // 未核对的长期状况：不进（D-04）。
      await addCondition('甲状腺结节', 'long_term', ReviewStatus.unreviewed,
          '2026-09-01');
      // 近 30 天内已确认的临时疾病：进近期清单。
      await addCondition('感冒', 'temporary', ReviewStatus.edited, today());
      // 很久以前的临时疾病：不进。
      await addCondition('急性肠胃炎', 'temporary', ReviewStatus.confirmed,
          '2024-06-01');

      nextReply = jsonEncode({'content_md': '# 周报', 'citations': []});
      await analysis.generateWeeklyReview();
      final input = jsonDecode(lastPrompt!) as Map;
      final longTerm = (input['long_term_conditions'] as List)
          .map((e) => (e as Map)['name'])
          .toList();
      final temporary = (input['recent_temporary_conditions'] as List)
          .map((e) => (e as Map)['name'])
          .toList();
      expect(longTerm, ['胆囊结石']);
      expect(temporary, ['感冒']);
      expect([for (final e in input['past_conditions'] as List) e['name']],
          ['肾结石']);
      expect(weeklyReviewSystemPrompt, contains('past_conditions'));
    });

    test('解析降级：JSON 前后带解释文字仍能取出正文与引用', () async {
      nextReply = '好的，这是你的周报：\n'
          '```json\n{"content_md":"# 周报\\n本周不错","citations":[]}\n```\n希望有帮助！';
      final a = await analysis.generateWeeklyReview();
      expect(a.contentMd, contains('本周不错'));
    });

    test('解析降级：模型直接返回 Markdown（非 JSON），整段当正文，不失败', () async {
      nextReply = '# 本周健康周报\n- 饮食：规律\n- 睡眠：偏少';
      final a = await analysis.generateWeeklyReview();
      expect(a.contentMd, contains('本周健康周报'));
      expect(jsonDecode(a.citations), isEmpty);
    });

    test('过期判断（D-14）：代次一致且没有新变更时不过期，有新变更即提示', () async {
      nextReply = jsonEncode({'content_md': '周报', 'citations': []});
      // 手机侧场景：本机既是数据源（测试里直接用同一库）。
      final generation = await env.db.currentGeneration();
      final messages = MessageRepository(env.db, env.ctx);
      final m = await messages.send(
        clientMsgId: 'c1',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: 'x',
        sentTz: 'Asia/Shanghai',
      );
      // 人工造一个"截止点 = 当前最大序号"的周报。
      final artifact = await analysis.generateWeeklyReview();
      final maxSeq = (await env.db.select(env.db.changeLogs).get())
          .map((c) => c.changeSeq)
          .fold(0, (a, b) => a > b ? a : b);
      await (env.db.update(env.db.analysisArtifacts)
            ..where((t) => t.id.equals(artifact.id)))
          .write(AnalysisArtifactsCompanion(
        dataGeneration: Value(generation),
        dataCutoffSeq: Value(maxSeq),
      ));
      final fresh = await analysis.latest(AnalysisKind.weeklyReview);
      expect(await analysis.isStale(fresh!), isFalse);

      // 新变更 → 过期。
      await messages.edit(m.id, 'y');
      expect(await analysis.isStale(fresh), isTrue);
    });
  });

  test('端到端：Mac 生成周报，手机经同步端点拉取保存', () async {
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
    final macEnv = await TestEnv.create();
    final phoneEnv = await TestEnv.create();
    final tempDir = await Directory.systemTemp.createTemp('analysis_sync');
    addTearDown(() async {
      await macEnv.dispose();
      await phoneEnv.dispose();
      await tempDir.delete(recursive: true);
    });

    // Mac 上放一份现成的周报。
    await macEnv.db.into(macEnv.db.analysisArtifacts).insert(
          AnalysisArtifactsCompanion.insert(
            id: 'a1',
            userId: 'u',
            createdAt: 1,
            createdOnDevice: 'mac-1',
            kind: AnalysisKind.weeklyReview,
            periodStart: today(6),
            periodEnd: today(),
            dataGeneration: 'g',
            dataCutoffSeq: 5,
            dependsOn: '{}',
            generatedAt: 1,
            generator: '{}',
            modelCallIds: '[]',
            contentMd: '# 周报正文',
            citations: '[]',
          ),
        );

    final server = SyncServer(
      deviceId: 'mac-1',
      displayName: 'Mac',
      db: macEnv.db,
      filesDir: Directory(p.join(tempDir.path, 'mac_files')),
      peers: PeerRepository(macEnv.db),
      keyStore: KeyStore(),
    );
    addTearDown(server.stop);
    final info = await server.startPairing();
    await SyncClient(
      deviceId: 'test-device',
      displayName: 'iPhone',
      peers: PeerRepository(phoneEnv.db),
      keyStore: KeyStore(),
    ).pairWith(PairingInfo(
      macDeviceId: info.macDeviceId,
      displayName: info.displayName,
      hosts: ['127.0.0.1'],
      port: info.port,
      key: info.key,
    ));

    final sync = SyncService(
      deviceId: 'test-device',
      db: phoneEnv.db,
      peers: PeerRepository(phoneEnv.db),
      keyStore: KeyStore(),
      filesDir: Directory(p.join(tempDir.path, 'phone_files')),
    );
    final row = await sync.fetchLatestAnalysis();
    expect(row, isNotNull);

    final phoneAnalysis = AnalysisService(
      db: phoneEnv.db,
      modelConfigs: ModelConfigRepository(phoneEnv.db, phoneEnv.ctx),
      organize: OrganizeRepository(phoneEnv.db, phoneEnv.ctx),
      keyStore: KeyStore(),
      deviceId: 'test-device',
    );
    await phoneAnalysis.saveFetched(row!);
    final saved = await phoneAnalysis.latest(AnalysisKind.weeklyReview);
    expect(saved!.contentMd, '# 周报正文');
    // 拉取保存不产生手机的变更日志。
    expect(await phoneEnv.db.select(phoneEnv.db.changeLogs).get(), isEmpty);
  });

  group('SuggestionService（schema §6.2）', () {
    late TestEnv env;
    late RecordRepository records;
    late SuggestionService suggestions;

    setUp(() async {
      env = await TestEnv.create();
      records = RecordRepository(env.db, env.ctx);
      suggestions = SuggestionService(
          db: env.db, records: records, deviceId: 'test-device');
    });

    tearDown(() => env.dispose());

    Future<(RecordRow, CorrectionSuggestion)> seed() async {
      final rec = await records.create(
        recordType: RecordType.sleep,
        occurred: TimeValue(
            localDate: '2026-09-26',
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: '{"sleep_onset_text":"01:00"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r1'),
      );
      final s = await env.db.into(env.db.correctionSuggestions).insertReturning(
            CorrectionSuggestionsCompanion.insert(
              id: 's1',
              userId: 'u',
              createdAt: 1,
              createdOnDevice: 'test-device',
              proposedBy: SuggestionProposedBy.organizeRun,
              targetRecordId: rec.id,
              targetVersion: rec.version,
              proposedData: '{"sleep_onset_text":"01:50"}',
              reason: '新消息得出不同的值',
              status: SuggestionStatus.pending,
            ),
          );
      return (rec, s);
    }

    test('接受：生成 confirmed 新版本，produced_by 指向建议', () async {
      final (rec, s) = await seed();
      expect(await suggestions.accept(s), SuggestionStatus.accepted);

      final rev = await records.currentRevisionOf(rec.id);
      expect(jsonDecode(rev.data)['sleep_onset_text'], '01:50');
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      expect(meta['sleep_onset_text']!.reviewStatus, ReviewStatus.confirmed);
      expect(ProducedBy.decode(rev.producedBy).kind, 'accepted_suggestion');
      expect((await suggestions.pending()), isEmpty);
    });

    test('目标已更新：建议转 obsolete，不套用', () async {
      final (rec, s) = await seed();
      final rev = await records.currentRevisionOf(rec.id);
      await records.addRevision(
        recordId: rec.id,
        baseVersion: rec.version,
        occurred: TimeValue.decode(rev.occurred),
        dataJson: '{"sleep_onset_text":"02:10"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.userEdit(),
      );
      expect(await suggestions.accept(s), SuggestionStatus.obsolete);
      final after = await records.currentRevisionOf(rec.id);
      expect(jsonDecode(after.data)['sleep_onset_text'], '02:10');
    });

    test('拒绝：状态改变，处理状态入变更日志（同步给 Mac）', () async {
      final (_, s) = await seed();
      await suggestions.reject(s);
      expect(await suggestions.pending(), isEmpty);
      final changes = await env.db.select(env.db.changeLogs).get();
      expect(
          changes.where((c) => c.entityType == 'correction_suggestions'),
          isNotEmpty);
    });

    test('记录被删除：待处理建议转 obsolete，处理状态入变更日志', () async {
      final (rec, _) = await seed();
      await records.markDeleted(rec.id);
      await suggestions.obsoletePendingFor(rec.id);
      expect(await suggestions.pending(), isEmpty);
      final row = await env.db.select(env.db.correctionSuggestions).getSingle();
      expect(row.status, SuggestionStatus.obsolete);
      final changes = await env.db.select(env.db.changeLogs).get();
      expect(
          changes.where((c) => c.entityType == 'correction_suggestions'),
          isNotEmpty);
    });
  });
}
