import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/health_overview.dart';

import '../data/test_helpers.dart';

void main() {
  late TestEnv env;
  late RecordRepository records;
  late MedicalDocumentRepository documents;

  setUp(() async {
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
    documents = MedicalDocumentRepository(env.db, env.ctx);
  });

  tearDown(() => env.dispose());

  TimeValue day(String d) => TimeValue(
    localDate: d,
    precision: TimePrecision.dateOnly,
    source: TimeValueSource.userStated,
  );

  FieldMeta meta(ReviewStatus s) =>
      FieldMeta(origin: FieldOrigin.modelInferred, reviewStatus: s);

  Future<MedicalDocument> doc(MedicalDocType type, {String? examDate}) =>
      documents.create(
        pages: const [
          MedicalPageRef(attachmentId: 'a', messageId: 'm', pageNo: 1),
        ],
        docType: type,
        examDate: examDate == null ? null : day(examDate),
      );

  Future<void> panel(String docId, ReviewStatus status) => records.create(
    recordType: RecordType.labPanel,
    occurred: day('2024-01-01'),
    dataJson: jsonEncode({
      'medical_document_id': docId,
      'results': [
        {'item_name_raw': '血红蛋白', 'value_raw': '145', 'value_num': 145},
      ],
    }),
    fieldMeta: FieldMetaMap({'results.0': meta(status)}),
    producedBy: ProducedBy.medicalExtract('c'),
  );

  test('健康档案概况：待核对、未提取、最近体检、待核对状况、指标数', () async {
    final pending = await doc(MedicalDocType.labReport);
    final reviewed = await doc(MedicalDocType.labReport);
    await doc(MedicalDocType.other); // 未提取
    final exam1 = await doc(
      MedicalDocType.physicalExam,
      examDate: '2023-11-30',
    );
    await doc(MedicalDocType.physicalExam, examDate: '2024-12-10'); // 未提取
    await panel(pending.id, ReviewStatus.unreviewed);
    await panel(reviewed.id, ReviewStatus.confirmed);
    await panel(exam1.id, ReviewStatus.unreviewed);
    await records.create(
      recordType: RecordType.condition,
      occurred: day('2024-01-01'),
      dataJson: jsonEncode({'name': '脂肪肝', 'status': 'active'}),
      fieldMeta: FieldMetaMap({'condition': meta(ReviewStatus.unreviewed)}),
      producedBy: ProducedBy.userEdit(),
    );

    final o = await HealthOverview.load(
      records: records,
      documents: documents,
      profile: ProfileRepository(env.db, env.ctx),
    );
    expect(o.pendingRecordDocs, 1);
    expect(o.unextractedRecordDocs, 1);
    expect(o.pendingExamDocs, 1);
    expect(o.unextractedExamDocs, 1);
    expect(o.lastExamDate, '2024-12-10');
    expect(o.pendingConditions, 1);
    expect(o.labItems, 1);
  });

  test('待核对状况按组数：最新那条已确认或痊愈，较早报告的记录不再算（D-32）', () async {
    Future<void> condition(String date, String status, ReviewStatus review) =>
        records.create(
          recordType: RecordType.condition,
          occurred: day(date),
          dataJson: jsonEncode({'name': '寻常疣', 'status': status}),
          fieldMeta: FieldMetaMap({'condition': meta(review)}),
          producedBy: ProducedBy.userEdit(),
        );
    await condition('2024-12-10', 'active', ReviewStatus.unreviewed);
    await condition('2025-03-07', 'active', ReviewStatus.unreviewed);
    await condition('2025-05-20', 'resolved', ReviewStatus.edited);

    final o = await HealthOverview.load(
      records: records,
      documents: documents,
      profile: ProfileRepository(env.db, env.ctx),
    );
    expect(o.pendingConditions, 0);
  });
}
