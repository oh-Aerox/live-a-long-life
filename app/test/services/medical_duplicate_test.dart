import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/medical_duplicate.dart';
import 'package:live_a_long_life/services/medical_extraction_service.dart';
import 'package:live_a_long_life/services/text_extraction.dart';

import '../data/test_helpers.dart';
import 'text_extraction_test.dart' show FakeExtractor;

/// 内容级重复（D-10 补充）：同一张纸重拍，字节不同但文字相同。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const visit = '某某医院 门（急）诊病历 性别：男性 出生日期：1980-01-01\n'
      '主诉：咽喉部疼痛不适5天 就诊时间：2026-09-23 16:18\n'
      '现病史：患者5天前出现咽喉部疼痛不适，吞咽时加重，伴低热，来我科就诊。\n'
      '诊断：1.咽喉炎 2.上呼吸道感染\n'
      '头孢呋辛酯片 口服 0.25g 0.25g*12片/盒 蓝芩口服液 10ml*12支/盒';

  group('相似度打分', () {
    test('同一张纸重拍（有少量识别差异）：两项都高', () {
      final rephoto = visit
          .replaceAll('咽喉部', '咽候部')
          .replaceAll('感染', '感來')
          .replaceAll('16:18', '16:1B');
      expect(MedicalDuplicateService.textContainment(visit, rephoto),
          greaterThan(MedicalDuplicateService.textThreshold));
      expect(MedicalDuplicateService.numberContainment(visit, rephoto),
          greaterThan(MedicalDuplicateService.numberThreshold));
    });

    test('同一医院同一版式的复查检验单：文字像但数字对不上，不算重复', () {
      const first = '某某医院检验报告单 采样时间：2026-01-27 08:08 检验编号：3016455321\n'
          '白细胞 6.2 10^9/L 3.5-9.5\n红细胞 4.85 10^12/L 4.30-5.80\n'
          '血红蛋白 145 g/L 130-175\n血小板 210 10^9/L 125-350';
      const retest = '某某医院检验报告单 采样时间：2026-07-15 09:21 检验编号：3019982214\n'
          '白细胞 7.9 10^9/L 3.5-9.5\n红细胞 4.61 10^12/L 4.30-5.80\n'
          '血红蛋白 139 g/L 130-175\n血小板 188 10^9/L 125-350';
      // 文字大半相同（项目名、单位、参考范围），靠数字把两份分开。
      expect(MedicalDuplicateService.textContainment(first, retest),
          greaterThan(0.7));
      expect(MedicalDuplicateService.numberContainment(first, retest),
          lessThan(MedicalDuplicateService.numberThreshold));
    });
  });

  group('服务', () {
    late TestEnv env;
    late Directory tmp;
    late AttachmentRepository attachments;
    late MedicalDocumentRepository documents;
    late RecordRepository records;

    setUp(() async {
      env = await TestEnv.create();
      tmp = await Directory.systemTemp.createTemp('meddup');
      attachments = AttachmentRepository(env.db, env.ctx,
          filesDir: Directory('${tmp.path}/files'));
      documents = MedicalDocumentRepository(env.db, env.ctx);
      records = RecordRepository(env.db, env.ctx);
      FlutterSecureStorage.setMockInitialValues({});
    });
    tearDown(() async {
      await env.dispose();
      await tmp.delete(recursive: true);
    });

    /// 按文件字节决定识别文字的假识别器：[texts] 键是文件首字节。
    FakeExtractor extractorFor(Map<int, String> texts) =>
        FakeExtractor(ocrByFirstByte: {
          for (final e in texts.entries)
            e.key: [for (final l in e.value.split('\n')) OcrLine(text: l)],
        });

    Future<MedicalDocument> addDoc(int firstByte) async {
      final f = File('${tmp.path}/p$firstByte.jpg')
        ..writeAsBytesSync([firstByte, 1, 2]);
      final att =
          (await attachments.importFile(f, mimeType: 'image/jpeg')).attachment;
      return documents.create(
        pages: [MedicalPageRef(attachmentId: att.id, messageId: 'm', pageNo: 1)],
        docType: MedicalDocType.visitRecord,
      );
    }

    test('重拍的同一份病历被点名；不同文件、文字太少不提示', () async {
      final extraction = TextExtractionService(
        extractor: extractorFor({
          1: visit,
          2: visit.replaceAll('咽喉部', '咽候部'), // 重拍：字节不同，文字几乎一样
          3: '某某医院检验报告单 白细胞 6.2 10^9/L 3.5-9.5 血红蛋白 145 g/L 130-175 '
              '采样时间 2026-01-27 08:08 检验编号 3016455321 报告日期 2026-02-03',
          4: '空白',
        }),
        cacheDir: Directory('${tmp.path}/cache'),
      );
      final service = MedicalDuplicateService(
          attachments: attachments, documents: documents, extraction: extraction);
      final existing = await addDoc(1);

      Future<SimilarDocumentHit?> check(int firstByte) async {
        final f = File('${tmp.path}/new$firstByte.jpg')
          ..writeAsBytesSync([firstByte, 9, 9]);
        return service.findSimilar(
            sha256: await AttachmentRepository.hashFile(f),
            file: f,
            mimeType: 'image/jpeg');
      }

      final hit = await check(2);
      expect(hit?.document.id, existing.id);
      expect(await check(3), isNull);
      expect(await check(4), isNull);
    });

    test('删除医疗文件：提取记录与未核对的状况建议一起删，已确认的状况保留', () async {
      final doc = await addDoc(1);
      final service = MedicalExtractionService(
        attachments: attachments,
        documents: documents,
        records: records,
        organize: OrganizeRepository(env.db, env.ctx),
        modelConfigs: ModelConfigRepository(env.db, env.ctx),
        keyStore: KeyStore(),
        extraction: TextExtractionService(
            extractor: extractorFor({1: visit}),
            cacheDir: Directory('${tmp.path}/cache')),
      );
      final occurred = TimeValue(
          localDate: '2026-09-23',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated);
      Future<RecordRow> condition(ReviewStatus status) => records.create(
            recordType: RecordType.condition,
            occurred: occurred,
            dataJson: '{"name":"咽喉炎","medical_document_id":"${doc.id}"}',
            fieldMeta: FieldMetaMap({
              'condition': FieldMeta(
                  origin: FieldOrigin.modelInferred, reviewStatus: status),
            }),
            producedBy: ProducedBy.userEdit(),
          );
      final panel = await records.create(
        recordType: RecordType.labPanel,
        occurred: occurred,
        dataJson: '{"medical_document_id":"${doc.id}","results":[]}',
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.userEdit(),
      );
      final pending = await condition(ReviewStatus.unreviewed);
      final confirmed = await condition(ReviewStatus.confirmed);

      await service.deleteDocument(doc.id);

      expect(await documents.all(), isEmpty);
      expect((await records.byId(panel.id))!.deletedAt, isNotNull);
      expect((await records.byId(pending.id))!.deletedAt, isNotNull);
      expect((await records.byId(confirmed.id))!.deletedAt, isNull);
    });
  });
}
