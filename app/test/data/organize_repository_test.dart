import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late OrganizeRepository organize;

  setUp(() async {
    env = await TestEnv.create();
    organize = OrganizeRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  Future<OrganizeRun> newRun() => organize.createRun(
        trigger: OrganizeTrigger.doneMarker,
        inputSnapshotJson: '{"messages":[]}',
        modelConfigId: 'cfg-1',
        modelSnapshotJson: '{"model":"m"}',
      );

  test('批次生命周期：queued → running → succeeded', () async {
    final run = await newRun();
    expect(run.status, OrganizeRunStatus.queued);

    final next = await organize.nextQueuedRun();
    expect(next!.id, run.id);

    await organize.updateRunStatus(run.id, OrganizeRunStatus.running,
        startedAt: 1);
    final done = await organize.updateRunStatus(
        run.id, OrganizeRunStatus.succeeded,
        finishedAt: 2);
    expect(done.status, OrganizeRunStatus.succeeded);
    expect(done.startedAt, 1);
    expect(done.finishedAt, 2);

    expect(await organize.nextQueuedRun(), isNull);
  });

  test('排队按创建顺序取用', () async {
    final first = await newRun();
    await newRun();
    final next = await organize.nextQueuedRun();
    expect(next!.id, first.id);
  });

  test('同一 (批次, 记录) 的项幂等：重试不重复建（schema §3.1a）', () async {
    final run = await newRun();
    final item1 = await organize.upsertItem(
      organizeRunId: run.id,
      recordId: 'rec-1',
      status: OrganizeItemStatus.committed,
    );
    final item2 = await organize.upsertItem(
      organizeRunId: run.id,
      recordId: 'rec-1',
      status: OrganizeItemStatus.staleInput,
    );
    expect(item2.id, item1.id);
    // 已有项原样返回，状态不被第二次调用改写。
    expect(item2.status, OrganizeItemStatus.committed);
    expect(await organize.itemsOf(run.id), hasLength(1));
  });

  test('stale 状态使 retry_count 递增，其他状态不计（D-05 第 4 条）', () async {
    final run = await newRun();
    final item = await organize.upsertItem(
      organizeRunId: run.id,
      recordId: 'rec-1',
      status: OrganizeItemStatus.staleInput,
    );
    expect(item.retryCount, 0);

    var updated =
        await organize.markItem(item.id, OrganizeItemStatus.staleInput);
    expect(updated.retryCount, 1);
    updated =
        await organize.markItem(item.id, OrganizeItemStatus.staleTarget);
    expect(updated.retryCount, 2);
    // retry_count 达到 2，调用方转 needs_manual；这次不再递增。
    updated =
        await organize.markItem(item.id, OrganizeItemStatus.needsManual);
    expect(updated.retryCount, 2);
    expect(updated.status, OrganizeItemStatus.needsManual);
  });

  test('protected_suggested 记下修正建议 ID', () async {
    final run = await newRun();
    final item = await organize.upsertItem(
      organizeRunId: run.id,
      recordId: 'rec-1',
      status: OrganizeItemStatus.committed,
    );
    final updated = await organize.markItem(
      item.id,
      OrganizeItemStatus.protectedSuggested,
      correctionSuggestionId: 'sugg-1',
    );
    expect(updated.correctionSuggestionId, 'sugg-1');
    expect(updated.retryCount, 0);
  });

  test('模型调用记录：按时间倒序可查（D-16）', () async {
    final run = await newRun();
    await organize.recordModelCall(
      organizeRunId: run.id,
      modelConfigId: 'cfg-1',
      dataBoundary: DataBoundary.cloud,
      sentMessageIdsJson: '["m1","m2"]',
      sentAttachmentIdsJson: '[]',
      requestAt: 100,
      responseAt: 200,
      status: ModelCallStatus.succeeded,
      tokensIn: 10,
      tokensOut: 20,
      caller: ModelCaller.phoneOrganize,
    );
    await organize.recordModelCall(
      modelConfigId: 'cfg-1',
      dataBoundary: DataBoundary.device,
      sentMessageIdsJson: '["m3"]',
      sentAttachmentIdsJson: '[]',
      requestAt: 300,
      status: ModelCallStatus.timeout,
      caller: ModelCaller.phoneOrganize,
    );

    final calls = await organize.recentModelCalls();
    expect(calls, hasLength(2));
    expect(calls.first.requestAt, 300);
    expect(calls.first.status, ModelCallStatus.timeout);
    expect(calls.last.sentMessageIds, '["m1","m2"]');
  });
}
