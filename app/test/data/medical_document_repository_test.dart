import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;
  late MedicalDocumentRepository docs;

  setUp(() async {
    env = await TestEnv.create();
    docs = MedicalDocumentRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  const page1 = MedicalPageRef(
      attachmentId: 'att-1', messageId: 'msg-1', pageNo: 1);
  const page2 = MedicalPageRef(
      attachmentId: 'att-2', messageId: 'msg-2', pageNo: 2);

  Future<List<ChangeLog>> changesFor(String entityId) async {
    final all = await env.db.select(env.db.changeLogs).get();
    return all
        .where((c) =>
            c.entityType == 'medical_documents' && c.entityId == entityId)
        .toList();
  }

  test('新建医疗文件：多页跨消息、默认未核对、入变更日志（schema §5.1/§7.2）',
      () async {
    final doc = await docs.create(
      pages: const [page1, page2],
      docType: MedicalDocType.labReport,
      institutionText: '某某医院检验科',
    );
    expect(doc.reviewStatus, ReviewStatus.unreviewed);
    expect(doc.examDate, isNull);

    final pages = MedicalPageRef.decodeList(doc.pages);
    expect(pages, hasLength(2));
    expect(pages[0].attachmentId, 'att-1');
    expect(pages[1].messageId, 'msg-2');

    // 变更日志埋点（漏埋 = 永远同步不到，plan-v0.3 风险）。
    final changes = await changesFor(doc.id);
    expect(changes, hasLength(1));
    expect(changes.single.op, ChangeOp.upsert);
  });

  test('调整页序、回填提取信息：版本递增，每次写都记变更', () async {
    final doc = await docs.create(
        pages: const [page1, page2], docType: MedicalDocType.labReport);

    // 页序对调。
    final reordered = await docs.updatePages(doc.id, const [
      MedicalPageRef(attachmentId: 'att-2', messageId: 'msg-2', pageNo: 1),
      MedicalPageRef(attachmentId: 'att-1', messageId: 'msg-1', pageNo: 2),
    ]);
    expect(reordered.version, doc.version + 1);
    expect(MedicalPageRef.decodeList(reordered.pages).first.attachmentId,
        'att-2');

    // 提取后回填检查日期与机构。
    final updated = await docs.updateInfo(
      doc.id,
      institutionText: '市一院',
      examDate: TimeValue(
          localDate: '2026-09-20',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
    );
    expect(updated.version, reordered.version + 1);
    expect(TimeValue.decode(updated.examDate!).localDate, '2026-09-20');
    // uploaded_at 不因回填变化（检查/报告/上传是三个时间，D-06）。
    expect(updated.uploadedAt, doc.uploadedAt);

    expect(await changesFor(doc.id), hasLength(3));
  });

  test('核对状态、删除：删除记 delete 操作；空页拒绝', () async {
    final doc = await docs.create(
        pages: const [page1], docType: MedicalDocType.imagingReport);
    final confirmed =
        await docs.setReviewStatus(doc.id, ReviewStatus.confirmed);
    expect(confirmed.reviewStatus, ReviewStatus.confirmed);

    final deleted = await docs.markDeleted(doc.id);
    expect(deleted.deletedAt, isNotNull);
    expect(await docs.byId(doc.id), isNull);
    final changes = await changesFor(doc.id);
    expect(changes.last.op, ChangeOp.delete);

    expect(() => docs.create(pages: const [], docType: MedicalDocType.other),
        throwsArgumentError);
  });
}
