import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/repositories/review_prompt_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/health_service.dart';
import 'package:live_a_long_life/services/record_gaps.dart';
import 'package:live_a_long_life/services/review_service.dart';
import 'package:live_a_long_life/services/sleep_merge.dart';

import '../data/test_helpers.dart';

const emptyDevice = DeviceDayData(
    sleep: null, workouts: [], steps: null, activeEnergyKcal: null);

(RecordType, Map<String, Object?>) rec(RecordType t, Map<String, Object?> d) =>
    (t, d);

void main() {
  group('缺口检测（D-08、schema §3.5）', () {
    test('空白的一天：全部缺口按优先级排列', () async {
      final gaps =
          await detectGaps('2026-09-26', records: [], device: emptyDevice);
      expect(gaps.map((g) => g.key).toList(), [
        'meal.breakfast',
        'meal.lunch',
        'meal.dinner',
        'sleep.sleep_onset',
        'sleep.wake_time',
        'sleep.quality_text',
        'exercise.any',
        'mood.any',
        'symptom.any',
      ]);
    });

    test('A-32：明确"没吃早饭"是有效回答，不再问早饭', () async {
      final gaps = await detectGaps('2026-09-26', records: [
        rec(RecordType.meal, {'meal_slot': 'breakfast', 'status': 'skipped'}),
        rec(RecordType.meal, {'meal_slot': 'lunch', 'status': 'eaten'}),
      ], device: emptyDevice);
      final keys = gaps.map((g) => g.key);
      expect(keys, isNot(contains('meal.breakfast')));
      expect(keys, isNot(contains('meal.lunch')));
      expect(keys, contains('meal.dinner'));
    });

    test('A-14：设备已提供睡眠时间时，睡眠只问感受', () async {
      final device = DeviceDayData(
        sleep: SleepSegment(
          sleepOnsetMs: 1,
          wakeMs: 2,
          sleepDurationMin: 420,
          sourceName: 'Apple Watch',
        ),
        workouts: const [],
        steps: null,
        activeEnergyKcal: null,
      );
      final gaps =
          await detectGaps('2026-09-26', records: [], device: device);
      final keys = gaps.map((g) => g.key);
      expect(keys, isNot(contains('sleep.sleep_onset')));
      expect(keys, isNot(contains('sleep.wake_time')));
      expect(keys, contains('sleep.quality_text'));
    });

    test('设备记到体能训练：不问运动；明确没有不适：不问不适', () async {
      final device = DeviceDayData(
        sleep: null,
        workouts: [
          HealthSample(
            id: 'w',
            userId: 'u',
            createdAt: 0,
            createdOnDevice: 'd',
            version: 1,
            platformUuid: 'w',
            sampleType: HealthSampleType.workout,
            startUtc: 0,
            endUtc: 1,
            tz: 'Asia/Shanghai',
            tzInferred: true,
            sourceName: 'Apple Watch',
            fetchedAt: 0,
          ),
        ],
        steps: null,
        activeEnergyKcal: null,
      );
      final gaps = await detectGaps('2026-09-26', records: [
        rec(RecordType.symptom, {'status': 'explicitly_none'}),
      ], device: device);
      final keys = gaps.map((g) => g.key);
      expect(keys, isNot(contains('exercise.any')));
      expect(keys, isNot(contains('symptom.any')));
    });
  });

  group('ReviewService（A-32）', () {
    late TestEnv env;
    late MessageRepository messages;
    late RecordRepository records;
    late ReviewPromptRepository prompts;
    late ReviewService service;

    setUp(() async {
      env = await TestEnv.create();
      messages = MessageRepository(env.db, env.ctx);
      records = RecordRepository(env.db, env.ctx);
      prompts = ReviewPromptRepository(env.db, env.ctx);
      service = ReviewService(
        messages: messages,
        records: records,
        prompts: prompts,
        deviceData: (_) async => emptyDevice,
        tz: 'Asia/Shanghai',
      );
    });

    tearDown(() => env.dispose());

    test('缺口多于 3 个时一次最多问 3 个；提问入对话流并记账', () async {
      final asked = await service.runReview(localDate: '2026-09-26');
      expect(asked, 3);

      final thread = await messages.thread();
      final promptMessages =
          thread.where((m) => m.kind == MessageKind.appPrompt).toList();
      expect(promptMessages, hasLength(3));
      expect(promptMessages.first.body, contains('早饭'));
      expect(promptMessages.first.promptMeta, contains('review_prompt'));

      final rows = await prompts.byReviewDate('2026-09-26');
      expect(rows.map((r) => r.gapKey),
          ['meal.breakfast', 'meal.lunch', 'meal.dinner']);
    });

    test('同一天再跑回顾：问过的不重复，继续问后面的缺口', () async {
      await service.runReview(localDate: '2026-09-26');
      final askedAgain = await service.runReview(localDate: '2026-09-26');
      expect(askedAgain, 3);
      final rows = await prompts.byReviewDate('2026-09-26');
      // 第二轮问的是睡眠三项，没有重复三餐。
      expect(rows.map((r) => r.gapKey).toSet(), {
        'meal.breakfast', 'meal.lunch', 'meal.dinner',
        'sleep.sleep_onset', 'sleep.wake_time', 'sleep.quality_text',
      });
    });

    test('已有记录的缺口不问（A-14 回顾只问缺的）', () async {
      await records.create(
        recordType: RecordType.meal,
        occurred: TimeValue(
            localDate: '2026-09-26',
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: '{"meal_slot":"breakfast","status":"eaten"}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r1'),
      );
      await service.runReview(localDate: '2026-09-26');
      final rows = await prompts.byReviewDate('2026-09-26');
      expect(rows.map((r) => r.gapKey), isNot(contains('meal.breakfast')));
    });

    test('跳过后当天不再问这个缺口', () async {
      await service.runReview(localDate: '2026-09-26');
      final first = (await prompts.byReviewDate('2026-09-26')).first;
      await prompts.markOutcome(first.id, ReviewOutcome.skipped);
      // 再跑不会重新问 breakfast（askedToday 含已跳过）。
      await service.runReview(localDate: '2026-09-26');
      final keys = (await prompts.byReviewDate('2026-09-26'))
          .map((r) => r.gapKey)
          .where((k) => k == 'meal.breakfast');
      expect(keys, hasLength(1));
    });
  });
}
