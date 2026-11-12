import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/change_log.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/analysis_service.dart';
import 'package:live_a_long_life/services/health_service.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/sleep_merge.dart';
import 'package:live_a_long_life/services/suggestion_service.dart';

import '../data/test_helpers.dart';

String today([int daysAgo = 0]) {
  final t = DateTime.now().subtract(Duration(days: daysAgo));
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalysisService', () {
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

      // 模型调用有记录（D-20）。
      final calls = await env.db.select(env.db.modelCalls).get();
      expect(calls.single.caller, ModelCaller.weeklyReview);

      // 截止点取本机的代次和变更序号；周报入变更日志，同步给电脑。
      expect(artifact.dataGeneration, await env.db.currentGeneration());
      expect(artifact.dataCutoffSeq, greaterThan(0));
      final logged = await env.db.select(env.db.changeLogs).get();
      expect(
          logged.where((c) =>
              c.entityType == 'analysis_artifacts' &&
              c.entityId == artifact.id),
          hasLength(1));
      // 自己入日志、调用记录入日志都不让周报一生成就过期。
      expect(await analysis.isStale(artifact), isFalse);

      // 失败：响应完全为空 → 抛异常，旧周报保留（降级后只有空响应才算失败）。
      nextReply = '   ';
      await expectLater(
          analysis.generateWeeklyReview(), throwsA(isA<StateError>()));
      expect(await analysis.latest(AnalysisKind.weeklyReview), isNotNull);
      expect(
          (await analysis.latest(AnalysisKind.weeklyReview))!.id, artifact.id);
    });

    test('周报输入含设备睡眠（按夜合并，与日视图同口径）：没有用户睡眠记录也能写睡眠',
        () async {
      final wake = DateTime.now().copyWith(hour: 7, minute: 10);
      final withDevice = AnalysisService(
        db: env.db,
        modelConfigs: ModelConfigRepository(env.db, env.ctx),
        organize: OrganizeRepository(env.db, env.ctx),
        keyStore: KeyStore(),
        deviceId: 'mac-1',
        deviceData: (date) async => DeviceDayData(
          sleep: date == today()
              ? SleepSegment(
                  sleepOnsetMs: wake
                      .subtract(const Duration(hours: 7, minutes: 40))
                      .millisecondsSinceEpoch,
                  wakeMs: wake.millisecondsSinceEpoch,
                  sleepDurationMin: 412,
                  inBedDurationMin: 460,
                  sourceName: 'Apple Watch')
              : null,
          workouts: const [],
          steps: null,
          activeEnergyKcal: null,
        ),
        modelCall: ({
          required config,
          required apiKey,
          system,
          required userText,
          required maxTokens,
        }) async {
          lastPrompt = userText;
          return ModelResponse(
              text: jsonEncode({'content_md': '# 周报', 'citations': []}));
        },
      );
      await withDevice.generateWeeklyReview();
      final device =
          (jsonDecode(lastPrompt!) as Map)['health_device'] as List;
      expect(device, hasLength(1)); // 没数据的日子不列，不当成 0（D-11）
      final night = device.single as Map;
      expect(night['date'], today());
      expect(night['sleep'],
          {'sleep_minutes': 412, 'in_bed_minutes': 460, 'onset': '23:30',
           'wake': '07:10'});
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

    test('过期判断（D-14）：截止点之后周期内的记录有变更才过期，消息和周期外的不算',
        () async {
      nextReply = jsonEncode({'content_md': '周报', 'citations': []});
      final messages = MessageRepository(env.db, env.ctx);
      final m = await messages.send(
        clientMsgId: 'c1',
        role: MessageRole.user,
        kind: MessageKind.text,
        text: 'x',
        sentTz: 'Asia/Shanghai',
      );
      final artifact = await analysis.generateWeeklyReview();
      expect(await analysis.isStale(artifact), isFalse);

      // 消息还没整理成记录，不改变周报的依据。
      await messages.edit(m.id, 'y');
      expect(await analysis.isStale(artifact), isFalse);

      // 周期外的新记录不影响这份周报。
      await records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
            localDate: today(20),
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: '{"status":"eaten","description":"饺子"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r2'),
      );
      expect(await analysis.isStale(artifact), isFalse);

      // 周期内的新记录 → 过期。
      await records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
            localDate: today(),
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: '{"status":"eaten","description":"粥"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r2'),
      );
      expect(await analysis.isStale(artifact), isTrue);

      // 电脑端只看，不判断过期。
      final desktop = AnalysisService(
        db: env.db,
        modelConfigs: ModelConfigRepository(env.db, env.ctx),
        organize: OrganizeRepository(env.db, env.ctx),
        keyStore: KeyStore(),
        deviceId: 'mac-1',
        isPhone: false,
      );
      expect(await desktop.isStale(artifact), isFalse);
    });

    test('上一个完整周：周一到周日', () {
      // 2026-11-12 是周四。
      final (start, end) =
          AnalysisService.lastFullWeek(DateTime(2026, 11, 12, 9));
      expect(start, DateTime(2026, 11, 2));
      expect(end, DateTime(2026, 11, 8));
      // 周一当天：上周仍是上一个完整周。
      final (s2, e2) = AnalysisService.lastFullWeek(DateTime(2026, 11, 9));
      expect(s2, DateTime(2026, 11, 2));
      expect(e2, DateTime(2026, 11, 8));
      // 周日当天：本周还没过完，取再上一周。
      final (s3, e3) = AnalysisService.lastFullWeek(DateTime(2026, 11, 8, 23));
      expect(s3, DateTime(2026, 10, 26));
      expect(e3, DateTime(2026, 11, 1));
    });

    test('自动生成：开关关着不生成；打开后补上周，已有就不重复；失败一小时内不重试',
        () async {
      final settings = SettingsRepository(env.db);
      var generated = 0;
      final auto = AnalysisService(
        db: env.db,
        modelConfigs: ModelConfigRepository(env.db, env.ctx),
        organize: OrganizeRepository(env.db, env.ctx),
        keyStore: KeyStore(),
        deviceId: 'test-device',
        settings: settings,
        onGenerated: () => generated++,
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
      final now = DateTime(2026, 11, 12, 9);
      lastPrompt = null;
      nextReply = jsonEncode({'content_md': '# 上周', 'citations': []});

      expect(await auto.autoGenerateIfDue(now: now), isNull);
      expect(lastPrompt, isNull);

      await settings.set(AnalysisService.autoSettingKey, true);
      final a = await auto.autoGenerateIfDue(now: now);
      expect(a, isNotNull);
      expect((a!.periodStart, a.periodEnd), ('2026-11-02', '2026-11-08'));
      expect((jsonDecode(lastPrompt!) as Map)['period'],
          ['2026-11-02', '2026-11-08']);
      expect(generated, 1);

      // 同一周再触发：已有覆盖到上周日的周报，不再生成。
      expect(await auto.autoGenerateIfDue(now: now), isNull);
      expect(generated, 1);

      // 下一周：模型连不上 → 不抛异常，记下原因；一小时内不重试。
      final nextWeek = now.add(const Duration(days: 7));
      nextReply = ModelClientException('网络错误：连不上', retriable: true);
      lastPrompt = null;
      expect(await auto.autoGenerateIfDue(now: nextWeek), isNull);
      expect(lastPrompt, isNotNull);
      expect(auto.lastAutoError, '网络错误：连不上');
      lastPrompt = null;
      expect(
          await auto.autoGenerateIfDue(
              now: nextWeek.add(const Duration(minutes: 30))),
          isNull);
      expect(lastPrompt, isNull);

      // 一小时后再试，成功后清掉失败原因。
      nextReply = jsonEncode({'content_md': '# 又一周', 'citations': []});
      final b = await auto.autoGenerateIfDue(
          now: nextWeek.add(const Duration(hours: 2)));
      expect(b!.periodEnd, '2026-11-15');
      expect(auto.lastAutoError, isNull);
    });
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
