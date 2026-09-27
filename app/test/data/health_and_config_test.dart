import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/display_value.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/health_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/review_prompt_repository.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() => env.dispose());

  group('HealthRepository', () {
    late HealthRepository health;

    setUp(() => health = HealthRepository(env.db, env.ctx));

    HealthSampleInput sleepSample(String uuid, int start, int end) =>
        HealthSampleInput(
          platformUuid: uuid,
          sampleType: HealthSampleType.sleep,
          startUtcMs: start,
          endUtcMs: end,
          tz: 'Asia/Shanghai',
          sleepStage: SleepStage.core,
          sourceName: 'Apple Watch',
        );

    test('样本按 platform_uuid 幂等写入', () async {
      final first = await health.upsertSamples([
        sleepSample('u1', 100, 200),
        sleepSample('u2', 200, 300),
      ]);
      expect(first, 2);

      // 锚点重建后重读同一批样本：不重复建行。
      final second = await health.upsertSamples([sleepSample('u1', 100, 200)]);
      expect(second, 0);

      final rows = await health.samplesBetween(
        sampleType: HealthSampleType.sleep,
        startUtcMs: 0,
        endUtcMs: 1000,
      );
      expect(rows, hasLength(2));
    });

    test('来源删除的样本不再返回；重新读到时恢复（A-31）', () async {
      await health.upsertSamples([sleepSample('u1', 100, 200)]);
      await health.markRemovedInSource(['u1']);

      var rows = await health.samplesBetween(
        sampleType: HealthSampleType.sleep,
        startUtcMs: 0,
        endUtcMs: 1000,
      );
      expect(rows, isEmpty);

      // anchored query 再次返回同一样本，说明仍在，清除删除标记。
      await health.upsertSamples([sleepSample('u1', 100, 200)]);
      rows = await health.samplesBetween(
        sampleType: HealthSampleType.sleep,
        startUtcMs: 0,
        endUtcMs: 1000,
      );
      expect(rows, hasLength(1));
    });

    test('按天聚合同一天同指标覆盖写入；没有行不等于 0（D-11）', () async {
      expect(
          await health.dailyValue('2026-09-26', HealthMetric.steps), isNull);

      await health.upsertDaily(
        localDate: '2026-09-26',
        aggTz: 'Asia/Shanghai',
        intervalStartUtcMs: 0,
        intervalEndUtcMs: 86400000,
        metric: HealthMetric.steps,
        value: 5000,
      );
      await health.upsertDaily(
        localDate: '2026-09-26',
        aggTz: 'Asia/Shanghai',
        intervalStartUtcMs: 0,
        intervalEndUtcMs: 86400000,
        metric: HealthMetric.steps,
        value: 8000,
      );

      final row =
          await health.dailyValue('2026-09-26', HealthMetric.steps);
      expect(row!.value, 8000);
      // 覆盖而不是新增。
      final all = await env.db.select(env.db.healthDaily).get();
      expect(all, hasLength(1));
    });

    test('锚点保存与读取', () async {
      expect(await health.anchorOf(HealthSampleType.sleep), isNull);
      await health.saveAnchor(HealthSampleType.sleep, [1, 2, 3]);
      await health.saveAnchor(HealthSampleType.sleep, [4, 5]);
      final anchor = await health.anchorOf(HealthSampleType.sleep);
      expect(anchor!.anchor, [4, 5]);
    });
  });

  group('ModelConfigRepository', () {
    late ModelConfigRepository configs;

    setUp(() => configs = ModelConfigRepository(env.db, env.ctx));

    Future<ModelConfig> addOllama({bool makeDefault = false}) => configs.add(
          preset: ModelPreset.ollama,
          protocol: ModelProtocol.openaiCompatible,
          baseUrl: 'http://mac.local:11434/v1',
          model: 'qwen3',
          dataBoundary: DataBoundary.lan,
          keychainRef: 'model-key-1',
          makeDefault: makeDefault,
        );

    test('第一个配置自动成为默认；默认配置唯一', () async {
      final first = await addOllama();
      expect(first.isDefault, isTrue);

      final second = await configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.anthropic.com',
        model: 'claude-sonnet-5',
        dataBoundary: DataBoundary.cloud,
        keychainRef: 'model-key-2',
        makeDefault: true,
      );
      expect(second.isDefault, isTrue);

      final all = await configs.all();
      expect(all.where((c) => c.isDefault).single.id, second.id);

      await configs.setDefault(first.id);
      final def = await configs.defaultConfig();
      expect(def!.id, first.id);
    });

    test('测试连接结果写入 capabilities', () async {
      final cfg = await addOllama();
      final updated = await configs.updateTestResult(
        cfg.id,
        result: 'ok',
        capabilities: ['text', 'image'],
      );
      expect(updated.lastTestResult, 'ok');
      expect(updated.lastTestAt, isNotNull);
      expect(updated.capabilities, '["text","image"]');
    });

    test('删除默认配置后没有默认配置，不自动切换（A-11 边界原则）', () async {
      final a = await addOllama(makeDefault: true);
      await configs.add(
        preset: ModelPreset.deepseek,
        protocol: ModelProtocol.openaiCompatible,
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        dataBoundary: DataBoundary.cloud,
        keychainRef: 'model-key-3',
      );
      await configs.markDeleted(a.id);

      expect(await configs.defaultConfig(), isNull);
      final all = await configs.all();
      expect(all, hasLength(1));
    });
  });

  group('ReviewPromptRepository', () {
    late ReviewPromptRepository prompts;

    setUp(() => prompts = ReviewPromptRepository(env.db, env.ctx));

    test('记账：当天同一缺口只问一次，可记录回答结果（A-32）', () async {
      final p = await prompts.add(
        reviewDate: '2026-09-26',
        promptMessageId: 'msg-p1',
        gapKey: 'meal.breakfast',
        templateId: 'tpl-1',
      );
      expect(p.outcome, isNull);
      expect(await prompts.askedToday('2026-09-26', 'meal.breakfast'), isTrue);
      expect(await prompts.askedToday('2026-09-26', 'meal.lunch'), isFalse);
      expect(await prompts.askedToday('2026-09-27', 'meal.breakfast'), isFalse);

      final answered = await prompts.markOutcome(
        p.id,
        ReviewOutcome.answered,
        answeredMessageId: 'msg-a1',
      );
      expect(answered.outcome, ReviewOutcome.answered);
      expect(answered.answeredMessageId, 'msg-a1');

      expect(await prompts.byReviewDate('2026-09-26'), hasLength(1));
    });
  });

  group('默认显示值排序（D-07，schema §3.7）', () {
    FieldCandidate<String> c(String v, FieldOrigin o, ReviewStatus r, int t) =>
        FieldCandidate(value: v, origin: o, reviewStatus: r, effectiveAtMs: t);

    test('edited/confirmed > user_stated 未核对 > device > model_inferred', () {
      final candidates = [
        c('模型值', FieldOrigin.modelInferred, ReviewStatus.unreviewed, 400),
        c('设备值', FieldOrigin.device, ReviewStatus.unreviewed, 300),
        c('用户说的', FieldOrigin.userStated, ReviewStatus.unreviewed, 200),
        c('用户改的', FieldOrigin.userEdited, ReviewStatus.edited, 100),
      ];
      final ranked = rankCandidates(candidates);
      expect(ranked.map((x) => x.value),
          ['用户改的', '用户说的', '设备值', '模型值']);
      expect(defaultDisplayValue(candidates)!.value, '用户改的');
    });

    test('用户修正不被设备数据覆盖：设备值更新后默认值仍是用户值（A-13）', () {
      final candidates = [
        c('01:00', FieldOrigin.userStated, ReviewStatus.unreviewed, 100),
        // 设备数据刷新，fetched_at 更晚。
        c('00:40', FieldOrigin.device, ReviewStatus.unreviewed, 999),
      ];
      expect(defaultDisplayValue(candidates)!.value, '01:00');
    });

    test('同一级别取生效时间最新的', () {
      final candidates = [
        c('旧话', FieldOrigin.userStated, ReviewStatus.unreviewed, 100),
        c('新话', FieldOrigin.userStated, ReviewStatus.unreviewed, 200),
      ];
      expect(defaultDisplayValue(candidates)!.value, '新话');
    });

    test('没有候选时为空', () {
      expect(defaultDisplayValue(<FieldCandidate<String>>[]), isNull);
    });
  });
}
