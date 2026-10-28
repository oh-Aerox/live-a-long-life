import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/change_log.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;

  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  test('回填：埋点前的存量行补进变更日志，已在日志的不重复', () async {
    // 模拟存量：直接插一条 message（不走仓库，因此没有变更日志），
    // 就像变更日志上线之前录入的数据。
    await env.db.customInsert(
      "INSERT INTO messages (id, user_id, created_at, created_on_device, "
      "version, client_msg_id, seq, role, kind, text, revision_no, sent_at, "
      "sent_tz, organize_state) VALUES "
      "('old-1','u',1,'d',1,'cmid-old',1,'user','text','旧消息',0,1,'Asia/Shanghai','organized')",
    );
    // 一条走仓库的记录：已经有变更日志。
    await RecordRepository(env.db, env.ctx).create(
      recordId: 'rec-new',
      recordType: RecordType.meal,
      occurred: TimeValue(
          localDate: '2026-09-28',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: '{"status":"eaten"}',
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.organizeRun('r1'),
    );
    final beforeRecordLogs = (await env.db.select(env.db.changeLogs).get())
        .where((c) => c.entityId == 'rec-new')
        .length;

    final n = await env.db.backfillChangeLogIfNeeded('d');
    expect(n, 1); // 只回填了那条存量消息

    final logs = await (env.db.select(env.db.changeLogs)
          ..orderBy([(t) => OrderingTerm.asc(t.changeSeq)]))
        .get();
    // 存量消息现在有日志。
    expect(logs.where((c) => c.entityId == 'old-1'), hasLength(1));
    // 已有日志的记录没被重复回填。
    expect(logs.where((c) => c.entityId == 'rec-new').length,
        beforeRecordLogs);

    // 再调一次：标记已置，不再回填。
    expect(await env.db.backfillChangeLogIfNeeded('d'), 0);
  });

  test('回填保持 change_seq 无空洞递增', () async {
    for (var i = 0; i < 3; i++) {
      await env.db.customInsert(
        "INSERT INTO messages (id, user_id, created_at, created_on_device, "
        "version, client_msg_id, seq, role, kind, text, revision_no, sent_at, "
        "sent_tz, organize_state) VALUES "
        "('m$i','u',1,'d',1,'c$i',${i + 1},'user','text','t$i',0,1,'Asia/Shanghai','pending')",
      );
    }
    await env.db.backfillChangeLogIfNeeded('d');
    final seqs = (await (env.db.select(env.db.changeLogs)
              ..orderBy([(t) => OrderingTerm.asc(t.changeSeq)]))
            .get())
        .map((c) => c.changeSeq)
        .toList();
    expect(seqs, [1, 2, 3]);
  });
}
