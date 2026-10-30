import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/lab_review.dart';
import 'package:live_a_long_life/services/medical_extraction_service.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/text_extraction.dart';

import '../data/test_helpers.dart';
import 'organize_service_test.dart' show FakeModel;
import 'text_extraction_test.dart' show FakeExtractor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late Directory tmp;
  late AttachmentRepository attachments;
  late MedicalDocumentRepository documents;
  late RecordRepository records;
  late OrganizeRepository organize;
  late ModelConfigRepository configs;
  late FakeModel model;

  setUp(() async {
    env = await TestEnv.create();
    tmp = await Directory.systemTemp.createTemp('medex');
    attachments = AttachmentRepository(env.db, env.ctx,
        filesDir: Directory('${tmp.path}/files'));
    documents = MedicalDocumentRepository(env.db, env.ctx);
    records = RecordRepository(env.db, env.ctx);
    organize = OrganizeRepository(env.db, env.ctx);
    configs = ModelConfigRepository(env.db, env.ctx);
    model = FakeModel();
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await env.dispose();
    await tmp.delete(recursive: true);
  });

  MedicalExtractionService buildService(FakeExtractor extractor) =>
      MedicalExtractionService(
        attachments: attachments,
        documents: documents,
        records: records,
        organize: organize,
        modelConfigs: configs,
        keyStore: KeyStore(),
        extraction: TextExtractionService(
            extractor: extractor, cacheDir: Directory('${tmp.path}/cache')),
        modelCall: model.call,
      );

  Future<MedicalDocument> importDoc() async {
    final src = File('${tmp.path}/report.jpg')..writeAsBytesSync([9, 9, 9]);
    final att = (await attachments.importFile(src, mimeType: 'image/jpeg'))
        .attachment;
    return documents.create(
      pages: [
        MedicalPageRef(attachmentId: att.id, messageId: 'msg-1', pageNo: 1)
      ],
      docType: MedicalDocType.other,
    );
  }

  test('端到端：OCR → 脱敏 → 结构化 → lab_panel 记录 + locator + 回填（D-23/D-24）',
      () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '某某医院检验报告', x: 0.1, y: 0.02, w: 0.5, h: 0.03),
      OcrLine(text: '姓名：张三 性别：男', x: 0.1, y: 0.08, w: 0.5, h: 0.03),
      OcrLine(text: '检查日期 2026-09-20', x: 0.1, y: 0.12, w: 0.4, h: 0.03),
      OcrLine(text: '白细胞 6.2 10^9/L 3.5-9.5', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
    ]);
    model.reply(jsonEncode({
      'doc': {
        'doc_type': 'lab_report',
        'institution_text': '某某医院',
        'exam_date': '2026-09-20',
        'report_date': null,
      },
      'results': [
        {
          'item_name_raw': '白细胞',
          'value_raw': '6.2',
          'value_num': 6.2,
          'unit_raw': '10^9/L',
          'ref_range_raw': '3.5-9.5',
          'ref_low': 3.5,
          'ref_high': 9.5,
          'flag_raw': null,
          'source_lines': ['P1L4', 'P1L99'], // 后者是编造的，应被丢弃
        }
      ],
    }));

    final outcome = await buildService(extractor)
        .extractDocument(doc.id, knownNames: ['张三']);

    // 发送内容已脱敏：姓名不出现在发给模型的文本里。
    expect(model.calls.single, isNot(contains('张三')));
    expect(model.calls.single, contains('【姓名】'));
    expect(model.calls.single, contains('P1L4'));

    // lab_panel 记录：unreviewed，locator 带坐标，编造行号被丢。
    final rev = await records.currentRevisionOf(outcome.record.id);
    final data = jsonDecode(rev.data) as Map;
    expect(data['medical_document_id'], doc.id);
    final result = (data['results'] as List).single as Map;
    expect(result['item_name_raw'], '白细胞');
    final locators = result['locator'] as List;
    expect(locators, hasLength(1));
    expect((locators.single as Map)['page_no'], 1);
    expect((locators.single as Map)['box'], isNotNull);
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    expect(meta['results.0']!.reviewStatus, ReviewStatus.unreviewed);
    expect(outcome.record.recordType, RecordType.labPanel);

    // 来源链接指向附件。
    final sources = await records.sourcesOf(rev.id);
    expect(sources.single.sourceKind, RecordSourceKind.attachment);

    // 文件级信息回填；uploaded_at 不变。
    final updated = (await documents.byId(doc.id))!;
    expect(updated.docType, MedicalDocType.labReport);
    expect(updated.institutionText, '某某医院');
    expect(updated.uploadedAt, doc.uploadedAt);

    // 调用记录：caller 与遮蔽项数（D-16/D-24）。
    final call = (await organize.recentModelCalls()).single;
    expect(call.caller, ModelCaller.phoneMedicalExtract);
    // 锚点层已把"张三"换成占位符，第三层不再重复命中：同一处只计一次。
    expect(call.redactedCount, 1);
    expect(jsonDecode(call.sentAttachmentIds), isNotEmpty);
  });

  test('页覆盖：规则排除的页用户强制发送，规则保留的页用户排除（D-23）', () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    // 附件是 3 页 PDF：数据页 / 导读页 / 无信号页。
    final src = File('${tmp.path}/booklet.pdf')..writeAsBytesSync([7, 7]);
    final att =
        (await attachments.importFile(src, mimeType: 'application/pdf'))
            .attachment;
    final doc = await documents.create(
      pages: [
        MedicalPageRef(attachmentId: att.id, messageId: 'msg-1', pageNo: 1)
      ],
      docType: MedicalDocType.physicalExam,
    );
    final extractor = FakeExtractor(
      pageCount: 3,
      pageTexts: {
        0: '检验项目 结果 单位 参考范围\n白细胞 6.2 10^9/L 3.5-9.5\n血红蛋白 145 g/L 130-175\n血小板 210 10^9/L 125-350',
        1: '报告导读\n尊敬的客户，感谢您选择本中心，祝您身体健康，本页为导读说明',
        2: null,
      },
      ocrResults: const [OcrLine(text: '手写备注', x: 0.1, y: 0.1, w: 0.3, h: 0.05)],
    );
    final service = buildService(extractor);

    // 预览：默认判定 P1 发送、P2 排除、P3 默认保留。
    var previews = await service.previewPages(doc.id);
    expect(previews.map((p) => p.included).toList(), [true, false, true]);

    // 用户覆盖：强制发送导读页、排除无信号页。
    await documents.setPageOverride(doc.id, 2, true);
    await documents.setPageOverride(doc.id, 3, false);
    previews = await service.previewPages(doc.id);
    expect(previews[1].included, isTrue);
    expect(previews[1].overridden, isTrue);
    expect(previews[2].included, isFalse);

    model.reply(jsonEncode({'doc': {}, 'results': []}));
    await service.extractDocument(doc.id);
    // 发送内容含导读页文字、不含无信号页文字。
    expect(model.calls.single, contains('尊敬的客户'));
    expect(model.calls.single, isNot(contains('手写备注')));

    // 清掉覆盖回到默认。
    await documents.setPageOverride(doc.id, 2, null);
    previews = await service.previewPages(doc.id);
    expect(previews[1].included, isFalse);
    expect(previews[1].overridden, isFalse);
  });

  test('近似重复（D-10）：同检查日期同项目的已有记录被点名', () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    Map<String, Object?> reply() => {
          'doc': {'doc_type': 'lab_report', 'exam_date': '2026-09-20'},
          'results': [
            {
              'item_name_raw': '白细胞',
              'value_raw': '6.2',
              'value_num': 6.2,
              'unit_raw': '10^9/L',
              'ref_range_raw': '3.5-9.5',
              'source_lines': ['P1L1'],
            }
          ],
        };
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '白细胞 6.2 10^9/L 3.5-9.5', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
    ]);
    final service = buildService(extractor);

    final doc1 = await importDoc();
    model.reply(jsonEncode(reply()));
    final first = await service.extractDocument(doc1.id);
    expect(first.possibleDuplicateRecordIds, isEmpty);

    // 同一份报告又传了一次（内容不同的文件，同日期同项目）。
    final src2 = File('${tmp.path}/report2.jpg')..writeAsBytesSync([8, 8]);
    final att2 =
        (await attachments.importFile(src2, mimeType: 'image/jpeg')).attachment;
    final doc2 = await documents.create(
      pages: [
        MedicalPageRef(attachmentId: att2.id, messageId: 'msg-2', pageNo: 1)
      ],
      docType: MedicalDocType.other,
    );
    model.reply(jsonEncode(reply()));
    final second = await service.extractDocument(doc2.id);
    expect(second.possibleDuplicateRecordIds, [first.record.id]);
  });

  test('状况建议（D-25）：诊断文字建档 unreviewed，同名不重复建', () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '超声所见：胆囊壁毛糙', x: 0.1, y: 0.2, w: 0.6, h: 0.03),
      OcrLine(text: '结论：胆囊结石（多发）', x: 0.1, y: 0.3, w: 0.6, h: 0.03),
    ]);
    final service = buildService(extractor);
    Map<String, Object?> reply() => {
          'doc': {'doc_type': 'imaging_report', 'exam_date': '2026-09-20'},
          'results': [],
          'conditions': [
            {
              'name': '胆囊结石',
              'persistence': 'long_term',
              'evidence_text': '结论：胆囊结石（多发）',
              'source_lines': ['P1L2'],
            },
            {
              'name': '感冒',
              'persistence': 'temporary',
              'evidence_text': '急性上呼吸道感染',
              'source_lines': ['P1L1'],
            },
          ],
        };

    final doc1 = await importDoc();
    model.reply(jsonEncode(reply()));
    final first = await service.extractDocument(doc1.id);
    expect(first.conditionRecords, hasLength(2));

    final conditions = await records.byType(RecordType.condition);
    expect(conditions, hasLength(2));
    final rev = await records.currentRevisionOf(first.conditionRecords[0].id);
    final data = jsonDecode(rev.data) as Map;
    expect(data['name'], '胆囊结石');
    expect(data['persistence'], 'long_term');
    expect(data['status'], 'active');
    expect((data['locator'] as Map)['page_no'], 1);
    // unreviewed：确认前不算事实（D-04）。
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    expect(meta['condition']!.reviewStatus, ReviewStatus.unreviewed);
    expect(first.conditionRecords[0].localDate, '2026-09-20');

    // 同一份报告换个文件再提取：同名状况不重复建档。
    final src2 = File('${tmp.path}/again.jpg')..writeAsBytesSync([5, 5]);
    final att2 =
        (await attachments.importFile(src2, mimeType: 'image/jpeg')).attachment;
    final doc2 = await documents.create(
      pages: [
        MedicalPageRef(attachmentId: att2.id, messageId: 'msg-3', pageNo: 1)
      ],
      docType: MedicalDocType.imagingReport,
    );
    model.reply(jsonEncode(reply()));
    final second = await service.extractDocument(doc2.id);
    expect(second.conditionRecords, isEmpty);
    expect(await records.byType(RecordType.condition), hasLength(2));
  });

  test('重新提取：这份文件没核对、这次没提取出的旧状况建议删掉，确认过的和其他文件的保留', () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '结论：胆囊结石（多发） 肝囊肿 脂肪肝', x: 0.1, y: 0.3, w: 0.6, h: 0.03),
    ]);
    final service = buildService(extractor);
    String reply(List<String> names) => jsonEncode({
          'doc': {'doc_type': 'imaging_report', 'exam_date': '2026-09-20'},
          'results': [],
          'conditions': [
            for (final n in names)
              {'name': n, 'persistence': 'long_term', 'source_lines': ['P1L1']},
          ],
        });

    final doc = await importDoc();
    model.reply(reply(['胆囊结石', '肝囊肿', '肝脏钙化灶']));
    final first = await service.extractDocument(doc.id);
    // 用户确认了"肝囊肿"。
    final confirmed = first.conditionRecords[1];
    final rev = await records.currentRevisionOf(confirmed.id);
    await records.addRevision(
      recordId: confirmed.id,
      baseVersion: confirmed.version,
      occurred: TimeValue.decode(rev.occurred),
      dataJson: rev.data,
      fieldMeta: const FieldMetaMap({
        'condition': FieldMeta(
            origin: FieldOrigin.modelInferred,
            reviewStatus: ReviewStatus.confirmed),
      }),
      producedBy: ProducedBy.userEdit(),
    );

    // 重新识别：钙化灶是旧识别认错的，这次没有；多了脂肪肝。
    model.reply(reply(['胆囊结石（多发）', '脂肪肝']));
    final second = await service.extractDocument(doc.id);
    expect([for (final r in second.conditionRecords) r.id], hasLength(1));
    final names = [
      for (final r in await records.byType(RecordType.condition))
        (jsonDecode((await records.currentRevisionOf(r.id)).data) as Map)['name']
    ]..sort();
    // 胆囊结石沿用旧的那条（同一问题不重复建），已确认的肝囊肿保留。
    expect(names, ['肝囊肿', '胆囊结石', '脂肪肝']..sort());

    // 用户在档案里删掉了确认过的"肝囊肿"（提取错了）：再提取不建议回来。
    final cyst = (await records.byType(RecordType.condition)).firstWhere((r) =>
        r.id == confirmed.id);
    final cystRev = await records.currentRevisionOf(cyst.id);
    await records.addRevision(
      recordId: cyst.id,
      baseVersion: cyst.version,
      occurred: TimeValue.decode(cystRev.occurred),
      dataJson: jsonEncode({
        ...(jsonDecode(cystRev.data) as Map),
        'removed_by_user': true,
      }),
      fieldMeta: FieldMetaMap.decode(cystRev.fieldMeta),
      producedBy: ProducedBy.userEdit(),
    );
    await records.markDeleted(cyst.id);
    model.reply(reply(['胆囊结石', '肝囊肿', '脂肪肝']));
    final third = await service.extractDocument(doc.id);
    expect(third.conditionRecords, isEmpty);
    expect(await records.byType(RecordType.condition), hasLength(2));
  });

  test('体检报告汇总与明细重复（D-32）：同一份文件里同一问题、同项目同数值只留一条',
      () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '汇总：颈椎轻度骨质增生；AST 12.7U/L 低', x: 0.1, y: 0.2, w: 0.6, h: 0.03),
      OcrLine(text: '颈椎DR：颈（3）-（6）椎体缘轻度骨质增生', x: 0.1, y: 0.3, w: 0.6, h: 0.03),
    ]);
    final service = buildService(extractor);
    model.reply(jsonEncode({
      'doc': {'doc_type': 'physical_exam', 'exam_date': '2022-07-17'},
      'results': [
        {'item_name_raw': '天门冬氨酸氨基转移酶', 'value_raw': '12.7U/L', 'value_num': 12.7, 'unit_raw': 'U/L', 'flag_raw': '低', 'source_lines': ['P1L1']},
        {'item_name_raw': '天门冬氨酸氨基转移酶（AST）', 'value_raw': '12.7', 'value_num': 12.7, 'unit_raw': 'U/L', 'ref_range_raw': '15-40', 'flag_raw': '↓', 'source_lines': ['P1L2']},
      ],
      'conditions': [
        {'name': '颈椎轻度骨质增生', 'persistence': 'long_term', 'source_lines': ['P1L1']},
        {'name': '颈（3）-（6）椎体缘轻度骨质增生', 'persistence': 'long_term', 'source_lines': ['P1L2']},
      ],
    }));
    final doc = await importDoc();
    final out = await service.extractDocument(doc.id);

    expect(out.conditionRecords, hasLength(1));
    final cond = await records.currentRevisionOf(out.conditionRecords.single.id);
    expect((jsonDecode(cond.data) as Map)['name'], '颈（3）-（6）椎体缘轻度骨质增生');
    final panel = await records.currentRevisionOf(out.record.id);
    final results = (jsonDecode(panel.data) as Map)['results'] as List;
    expect(results.single['item_name_raw'], '天门冬氨酸氨基转移酶（AST）');
  });

  Future<ModelConfig> addConfigReturning() => configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.example.com',
        model: 'm',
        dataBoundary: DataBoundary.cloud,
        keychainRef: '',
      );

  Future<void> addConfig() => configs.add(
        preset: ModelPreset.anthropic,
        protocol: ModelProtocol.anthropic,
        baseUrl: 'https://api.example.com',
        model: 'm',
        dataBoundary: DataBoundary.cloud,
        keychainRef: '',
      );

  test('发送前预览（D-28）：准备阶段不调模型；用户改掉漏网信息后按改后文本发送', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '姓名：张三 性别：男', x: 0.1, y: 0.08, w: 0.5, h: 0.03),
      OcrLine(text: '家属 李四 电话 13800001111', x: 0.1, y: 0.12, w: 0.5, h: 0.03),
      OcrLine(text: '白细胞 6.2 10^9/L 3.5-9.5', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
    ]);
    final service = buildService(extractor);

    final draft = await service.prepareSend(doc.id);
    expect(model.calls, isEmpty); // 预览全程本地
    final page = draft.pages.single;
    expect(draft.lineText(page, 0), contains('【姓名】'));
    expect(draft.redactedCount, 1);
    // 规则漏掉的家属姓名和电话：用户在预览里改掉。
    draft.edits[SendDraft.lineKey(1, 1)] = '';
    expect(draft.payload, isNot(contains('李四')));
    expect(draft.sentLineCount, 2);

    model.reply(jsonEncode({
      'doc': {'doc_type': 'lab_report', 'exam_date': '2026-09-20'},
      'results': [
        {
          'item_name_raw': '白细胞',
          'value_raw': '6.2',
          'source_lines': ['P1L3', 'P1L2'], // P1L2 已删没发送，应丢弃
        }
      ],
    }));
    final outcome = await service.sendDraft(draft);
    // 发出的正是预览所见。
    expect(model.calls.single, draft.payload);
    expect(model.calls.single, isNot(contains('张三')));
    expect(model.calls.single, isNot(contains('13800001111')));
    final rev = await records.currentRevisionOf(outcome.record.id);
    final result = ((jsonDecode(rev.data) as Map)['results'] as List).single;
    expect((result as Map)['locator'] as List, hasLength(1));
    // 调用记录能查到发送范围。
    final call = (await organize.recentModelCalls()).single;
    expect(call.sentSummary, contains('1/1 页'));
    expect(call.sentSummary, contains('手动改动 1 行'));
  });

  test('只有文字的报告（D-28）：诊断/所见保留为 findings，重新提取追加版本不另建', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '彩色多普勒超声检查报告', x: 0.1, y: 0.02, w: 0.5, h: 0.03),
      OcrLine(text: '超声所见：胆囊大小正常，腔内见一强回声，大小约 0.8cm', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
      OcrLine(text: '超声提示：胆囊结石', x: 0.1, y: 0.3, w: 0.5, h: 0.03),
    ]);
    final service = buildService(extractor);
    String reply(String conclusion) => jsonEncode({
          'doc': {'doc_type': 'imaging_report', 'exam_date': '2026-09-20'},
          'results': [],
          'findings': [
            {
              'section_raw': '超声所见',
              'text_raw': '胆囊大小正常，腔内见一强回声，大小约 0.8cm',
              'source_lines': ['P1L2'],
            },
            {'section_raw': '超声提示', 'text_raw': conclusion, 'source_lines': ['P1L3']},
            {'section_raw': '空的', 'text_raw': '  ', 'source_lines': []},
          ],
        });

    model.reply(reply('胆囊结石'));
    final first = await service.extractDocument(doc.id);
    var rev = await records.currentRevisionOf(first.record.id);
    final findings = (jsonDecode(rev.data) as Map)['findings'] as List;
    expect(findings, hasLength(2)); // 空文字丢弃
    expect((findings[1] as Map)['text_raw'], '胆囊结石');
    expect(((findings[1] as Map)['locator'] as List).single, isNotNull);
    expect(FieldMetaMap.decode(rev.fieldMeta)['findings.0']!.reviewStatus,
        ReviewStatus.unreviewed);
    // 没有数值也能按文件找回记录（索引表里没有行）。
    expect(await records.labResultsOfDocument(doc.id), isEmpty);
    expect((await records.labPanelOfDocument(doc.id))!.id, first.record.id);

    model.reply(reply('胆囊结石（单发）'));
    final second = await service.extractDocument(doc.id);
    expect(second.record.id, first.record.id);
    expect(second.record.version, 2);
    expect(await records.byType(RecordType.labPanel), hasLength(1));
    rev = await records.currentRevisionOf(first.record.id);
    expect(((jsonDecode(rev.data) as Map)['findings'] as List)[1]['text_raw'],
        '胆囊结石（单发）');
  });

  group('用模型整理文字内容（D-35）', () {
    Future<(MedicalExtractionService, String)> extracted() async {
      await addConfig();
      final doc = await importDoc();
      final extractor = FakeExtractor(ocrResults: const [
        OcrLine(text: '甲状腺：甲状腺形态大小正常，回声均匀', x: 0.1, y: 0.1, w: 0.8, h: 0.03),
        OcrLine(text: '检查所见：甲状腺未见异常', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
        OcrLine(text: '建议：定期复查', x: 0.1, y: 0.3, w: 0.8, h: 0.03),
      ]);
      final service = buildService(extractor);
      model.reply(jsonEncode({
        'doc': {'doc_type': 'imaging_report', 'exam_date': '2026-09-20'},
        'results': [],
        'findings': [
          {
            'section_raw': '甲状腺',
            'text_raw': '甲状腺形态大小正常，回声均匀',
            'source_lines': ['P1L1'],
            'ocr_fixes': ['回声均云→回声均匀'],
          },
          {'section_raw': '检查所见', 'text_raw': '甲状腺未见异常', 'source_lines': ['P1L2']},
          {'section_raw': '建议', 'text_raw': '定期复查', 'source_lines': ['P1L3']},
        ],
      }));
      await service.extractDocument(doc.id);
      // 第 3 段先确认，整理时原样保留就不该退回未核对。
      final record = (await records.labPanelOfDocument(doc.id))!;
      final rev = await records.currentRevisionOf(record.id);
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      await records.addRevision(
        recordId: record.id,
        baseVersion: record.version,
        occurred: TimeValue.decode(rev.occurred),
        dataJson: rev.data,
        fieldMeta: FieldMetaMap({
          ...meta.fields,
          'findings.2': const FieldMeta(
              origin: FieldOrigin.modelInferred,
              reviewStatus: ReviewStatus.confirmed),
        }),
        producedBy: ProducedBy.userEdit(),
      );
      return (service, doc.id);
    }

    test('同一部位的所见与结论合并：定位与修正跟着走，原样保留的条目不丢核对状态', () async {
      final (service, docId) = await extracted();
      model.reply(jsonEncode({
        'findings': [
          {
            'section_raw': '甲状腺',
            'text_raw': '所见：甲状腺形态大小正常，回声均匀\n结论：甲状腺未见异常',
            'from': [1, 2],
          },
          {'section_raw': '建议', 'text_raw': '定期复查', 'from': [3]},
        ],
      }));
      final outcome = await service.tidyFindings(docId);
      expect(outcome.changed, isTrue);
      expect((outcome.before, outcome.after), (3, 2));
      // 只发已提取的文字。
      expect(model.calls.last, contains('甲状腺未见异常'));
      expect(model.calls.last, isNot(contains('P1L')));

      final rev = await records.currentRevisionOf(outcome.record.id);
      final findings = (jsonDecode(rev.data) as Map)['findings'] as List;
      expect(findings, hasLength(2));
      expect(findings[0]['section_raw'], '甲状腺');
      expect(findings[0]['locator'] as List, hasLength(2));
      expect(findings[0]['ocr_fixes'], ['回声均云→回声均匀']);
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      expect(meta['findings.0']!.reviewStatus, ReviewStatus.unreviewed);
      expect(meta['findings.1']!.reviewStatus, ReviewStatus.confirmed);
      expect(meta['findings.2'], isNull);
      expect(outcome.previousData, contains('检查所见'));
    });

    test('没有内容的条目删掉；带数字或太长的不像套话，驳回后按原位保留', () async {
      final (service, docId) = await extracted();
      model.reply(jsonEncode({
        'findings': [
          {'section_raw': '甲状腺', 'text_raw': '甲状腺形态大小正常，回声均匀', 'from': [1]},
          {'section_raw': '检查所见', 'text_raw': '甲状腺未见异常', 'from': [2]},
        ],
        'drop': [3], // 本地只按长度与数字把关，借第 3 段测删除的流程
      }));
      final outcome = await service.tidyFindings(docId);
      expect((outcome.before, outcome.after, outcome.dropped), (3, 2, 1));
      var rev = await records.currentRevisionOf(outcome.record.id);
      var findings = (jsonDecode(rev.data) as Map)['findings'] as List;
      expect([for (final f in findings) f['section_raw']], ['甲状腺', '检查所见']);
      expect(FieldMetaMap.decode(rev.fieldMeta)['findings.2'], isNull);

      // 模型想删带数字的一段：本地驳回，放回原来的位置，核对状态不丢。
      final (service2, docId2) = await extracted();
      final record = (await records.labPanelOfDocument(docId2))!;
      rev = await records.currentRevisionOf(record.id);
      final data = (jsonDecode(rev.data) as Map).cast<String, Object?>();
      (data['findings'] as List)[0] = {
        ...(data['findings'] as List)[0] as Map,
        'text_raw': '甲状腺右叶结节 0.5cm',
      };
      await records.addRevision(
        recordId: record.id,
        baseVersion: record.version,
        occurred: TimeValue.decode(rev.occurred),
        dataJson: jsonEncode(data),
        fieldMeta: FieldMetaMap.decode(rev.fieldMeta),
        producedBy: ProducedBy.userEdit(),
      );
      model.reply(jsonEncode({
        'findings': [
          {'section_raw': '检查所见', 'text_raw': '甲状腺未见异常', 'from': [2]},
        ],
        'drop': [1, 3],
      }));
      final o2 = await service2.tidyFindings(docId2);
      expect((o2.after, o2.dropped), (2, 1));
      rev = await records.currentRevisionOf(o2.record.id);
      findings = (jsonDecode(rev.data) as Map)['findings'] as List;
      expect([for (final f in findings) f['text_raw']],
          ['甲状腺右叶结节 0.5cm', '甲状腺未见异常']);
    });

    test('模型漏了某一段：整个不改；没有可合并的不写新版本', () async {
      final (service, docId) = await extracted();
      final version = (await records.labPanelOfDocument(docId))!.version;
      model.reply(jsonEncode({
        'findings': [
          {'section_raw': '甲状腺', 'text_raw': '甲状腺未见异常', 'from': [1, 2]},
        ],
      }));
      await expectLater(service.tidyFindings(docId), throwsStateError);
      expect((await records.labPanelOfDocument(docId))!.version, version);

      model.reply(jsonEncode({
        'findings': [
          {'section_raw': '甲状腺', 'text_raw': '甲状腺形态大小正常，回声均匀', 'from': [1]},
          {'section_raw': '检查所见', 'text_raw': '甲状腺未见异常', 'from': [2]},
          {'section_raw': '建议', 'text_raw': '定期复查', 'from': [3]},
        ],
      }));
      final outcome = await service.tidyFindings(docId);
      expect(outcome.changed, isFalse);
      expect((await records.labPanelOfDocument(docId))!.version, version);
    });
  });

  test('补检查大项（D-36）：只发项目名，已有大项不改，核对状态不变，索引按大项重建', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '白细胞计数（WBC） 5.33 10^9/L 3.5-9.5', x: 0.1, y: 0.1, w: 0.8, h: 0.03),
      OcrLine(text: '白细胞(LEU) neg', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
      OcrLine(text: '比重（SG） 1.025', x: 0.1, y: 0.3, w: 0.8, h: 0.03),
    ]);
    final service = buildService(extractor);
    // 模拟 D-36 之前的提取：没有 panel_raw。
    model.reply(jsonEncode({
      'doc': {'doc_type': 'lab_report', 'exam_date': '2022-07-17'},
      'results': [
        {'item_name_raw': '白细胞计数（WBC）', 'value_raw': '5.33', 'value_num': 5.33, 'source_lines': ['P1L1']},
        {'item_name_raw': '白细胞(LEU)', 'value_raw': 'neg', 'source_lines': ['P1L2']},
        {'item_name_raw': '比重（SG）', 'value_raw': '1.025', 'value_num': 1.025, 'source_lines': ['P1L3']},
      ],
    }));
    final extracted = await service.extractDocument(doc.id);
    var rev = await records.currentRevisionOf(extracted.record.id);
    final (data, meta) = LabReview.confirmResult(
        rev.data, FieldMetaMap.decode(rev.fieldMeta), 1);
    await records.addRevision(
      recordId: extracted.record.id,
      baseVersion: 1,
      occurred: TimeValue.decode(rev.occurred),
      dataJson: data,
      fieldMeta: meta,
      producedBy: ProducedBy.userEdit(),
    );
    expect((await records.labResultsOfDocument(doc.id))[1].itemKey, '白细胞');

    model.reply(jsonEncode({
      'results': [
        {'id': 1, 'panel_raw': '血常规'},
        {'id': 2, 'panel_raw': '尿常规'},
        {'id': 3, 'panel_raw': null},
        {'id': 9, 'panel_raw': '编造'},
      ],
    }));
    final outcome = await service.fillPanels(doc.id);
    expect(outcome.filled, 2);
    expect(model.calls.last, contains('白细胞(LEU)'));
    expect(model.calls.last, isNot(contains('neg')), reason: '不发数值');
    expect(model.calls.last, isNot(contains('5.33')));

    rev = await records.currentRevisionOf(extracted.record.id);
    expect(FieldMetaMap.decode(rev.fieldMeta)['results.1']!.reviewStatus,
        ReviewStatus.confirmed);
    final rows = await records.labResultsOfDocument(doc.id);
    expect([for (final r in rows) r.itemKey], ['白细胞计数', '尿白细胞', '比重']);
    expect(rows[1].panelRaw, '尿常规');

    // 新提取直接带大项。
    model.reply(jsonEncode({
      'doc': {'doc_type': 'lab_report', 'exam_date': '2022-07-17'},
      'results': [
        {'panel_raw': ' 尿常规 ', 'item_name_raw': '比重（SG）', 'value_raw': '1.025', 'source_lines': ['P1L3']},
      ],
    }));
    await service.extractDocument(doc.id);
    expect((await records.labResultsOfDocument(doc.id)).single.itemKey, '尿比重');
    // 都有大项时不调模型。
    final calls = model.calls.length;
    expect((await service.fillPanels(doc.id)).filled, 0);
    expect(model.calls.length, calls);
  });

  test('补检查大项：分批提取后续表的项目没读到标题，带上已有大项补空缺（D-36）', () async {
    await addConfig();
    final doc = await importDoc();
    final service = buildService(FakeExtractor(ocrResults: const [
      OcrLine(text: '血常规', x: 0.1, y: 0.05, w: 0.3, h: 0.03),
    ]));
    // 第 1 批读到"血常规"标题，第 2 批续表没有。
    model.reply(jsonEncode({
      'doc': {'doc_type': 'lab_report', 'exam_date': '2022-07-17'},
      'results': [
        {'panel_raw': '血常规', 'item_name_raw': '白细胞计数（WBC）', 'value_raw': '5.33', 'source_lines': ['P1L1']},
        {'panel_raw': null, 'item_name_raw': '血小板计数（PLT）', 'value_raw': '210', 'source_lines': ['P1L1']},
        {'panel_raw': '尿常规', 'item_name_raw': '白细胞(LEU)', 'value_raw': 'neg', 'source_lines': ['P1L1']},
      ],
    }));
    await service.extractDocument(doc.id);

    model.reply(jsonEncode({
      'results': [
        {'id': 2, 'panel_raw': '血常规'},
        {'id': 3, 'panel_raw': '血常规'}, // 已有大项的不改
      ],
    }));
    final outcome = await service.fillPanels(doc.id);
    expect(outcome.filled, 1);
    final sent = jsonDecode(model.calls.last) as Map;
    expect([for (final r in sent['results'] as List) r['panel_raw']],
        ['血常规', null, '尿常规']);
    expect(model.calls.last, isNot(contains('210')), reason: '不发数值');
    final rows = await records.labResultsOfDocument(doc.id);
    expect([for (final r in rows) r.panelRaw], ['血常规', '血常规', '尿常规']);
  });

  test('门诊病历（D-28）：药品按条提取、识别修正记录保留、空药名丢弃', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '主诉：咽候部寒痛不适5天', x: 0.1, y: 0.1, w: 0.5, h: 0.03),
      OcrLine(text: '头孢味辛酯片', x: 0.1, y: 0.3, w: 0.3, h: 0.03),
      OcrLine(text: '口服', x: 0.5, y: 0.3, w: 0.1, h: 0.03),
      OcrLine(text: '0.25g', x: 0.6, y: 0.3, w: 0.1, h: 0.03),
      OcrLine(text: '0.25g*12片/盒', x: 0.7, y: 0.3, w: 0.2, h: 0.03),
    ]);
    model.reply(jsonEncode({
      'doc': {'doc_type': 'visit_record', 'exam_date': '2026-09-23'},
      'results': [],
      'findings': [
        {
          'section_raw': '主诉',
          'text_raw': '咽喉部疼痛不适5天',
          'source_lines': ['P1L1'],
          'ocr_fixes': ['咽候部→咽喉部', '寒痛→疼痛'],
        }
      ],
      'medications': [
        {
          'name': '头孢呋辛酯片',
          'spec': '0.25g*12片/盒',
          'dose': '0.25g',
          'route': '口服',
          'frequency': null,
          'source_lines': ['P1L2', 'P1L3', 'P1L4', 'P1L5'],
          'ocr_fixes': ['头孢味辛酯片→头孢呋辛酯片'],
        },
        {'name': ' ', 'source_lines': []},
      ],
    }));
    final outcome = await buildService(extractor).extractDocument(doc.id);
    final rev = await records.currentRevisionOf(outcome.record.id);
    final data = jsonDecode(rev.data) as Map;
    final med = (data['medications'] as List).single as Map;
    expect(med['name'], '头孢呋辛酯片');
    expect(med['frequency'], isNull);
    expect(med['locator'] as List, hasLength(4));
    expect(med['ocr_fixes'], ['头孢味辛酯片→头孢呋辛酯片']);
    // 修正前的识别原文仍在 locator 里，可对照原件。
    expect(((med['locator'] as List).first as Map)['line_text'], '头孢味辛酯片');
    expect(((data['findings'] as List).single as Map)['ocr_fixes'], hasLength(2));
    final meta = FieldMetaMap.decode(rev.fieldMeta);
    expect(meta['medications.0']!.reviewStatus, ReviewStatus.unreviewed);
    expect(meta['medications.1'], isNull);
  });

  group('模型识图兜底（D-24）', () {
    ImageSend send(String attId) => ImageSend(
          attachmentId: attId,
          pageNo: 1,
          attachmentPage: 1,
          png: Uint8List.fromList([1, 2, 3]),
          width: 800,
          height: 400,
          cropBox: const {'x': 0.1, 'y': 0.3, 'w': 0.8, 'h': 0.5},
        );

    test('默认模型不支持图片：不发送、不建记录，提示换模型', () async {
      await addConfig(); // 没测过连接：capabilities 为空
      final doc = await importDoc();
      final images = <String>[];
      final service = MedicalExtractionService(
        attachments: attachments,
        documents: documents,
        records: records,
        organize: organize,
        modelConfigs: configs,
        keyStore: KeyStore(),
        extraction: TextExtractionService(
            extractor: FakeExtractor(), cacheDir: Directory('${tmp.path}/cache')),
        imageCall: ({required config, required apiKey, system,
            required userText, required maxTokens, required imagePngBase64}) async {
          images.add(imagePngBase64);
          throw StateError('不该调用');
        },
      );
      expect(await service.defaultModelSupportsImage(), isFalse);
      final att = MedicalPageRef.decodeList(doc.pages).single.attachmentId;
      await expectLater(
          service.extractFromImage(doc.id, send(att)), throwsStateError);
      expect(images, isEmpty);
      expect(await organize.recentModelCalls(), isEmpty);
    });

    test('支持图片：发裁剪图，结果按裁剪区域定位，调用记录不存图片', () async {
      final config = await addConfigReturning();
      await configs.updateTestResult(config.id,
          result: '连接成功（支持图片）', capabilities: ['text', 'image']);
      final doc = await importDoc();
      final att = MedicalPageRef.decodeList(doc.pages).single.attachmentId;
      final images = <String>[];
      final service = MedicalExtractionService(
        attachments: attachments,
        documents: documents,
        records: records,
        organize: organize,
        modelConfigs: configs,
        keyStore: KeyStore(),
        extraction: TextExtractionService(
            extractor: FakeExtractor(), cacheDir: Directory('${tmp.path}/cache')),
        imageCall: ({required config, required apiKey, system,
            required userText, required maxTokens, required imagePngBase64}) async {
          images.add(imagePngBase64);
          return ModelResponse(
              text: jsonEncode({
                'doc': {'doc_type': 'lab_report', 'exam_date': '2026-09-20'},
                'results': [
                  {'item_name_raw': '血糖', 'value_raw': '6.8', 'value_num': 6.8,
                   'ref_range_raw': '3.9-6.1', 'ref_low': 3.9, 'ref_high': 6.1}
                ],
                'findings': [
                  {'section_raw': '备注', 'text_raw': '空腹'}
                ],
              }),
              tokensIn: 100,
              tokensOut: 50);
        },
      );
      expect(await service.defaultModelSupportsImage(), isTrue);
      final outcome = await service.extractFromImage(doc.id, send(att));

      expect(images.single, base64Encode([1, 2, 3]));
      final rev = await records.currentRevisionOf(outcome.record.id);
      final data = jsonDecode(rev.data) as Map;
      final loc = (((data['results'] as List).single as Map)['locator'] as List)
          .single as Map;
      expect(loc['attachment_id'], att);
      expect(loc['box'], {'x': 0.1, 'y': 0.3, 'w': 0.8, 'h': 0.5});
      expect(FieldMetaMap.decode(rev.fieldMeta)['results.0']!.reviewStatus,
          ReviewStatus.unreviewed);
      expect(await records.labResultsOfDocument(doc.id), hasLength(1));

      final call = (await organize.recentModelCalls()).single;
      expect(call.sentSummary, contains('裁剪'));
      expect(call.requestText, isNot(contains(base64Encode([1, 2, 3]))));
      expect(jsonDecode(call.sentAttachmentIds), [att]);
    });
  });

  group('体检报告分批发送（2026-09-29 联调：12 页 364 行超时）', () {
    Future<MedicalDocument> importBooklet() async {
      final src = File('${tmp.path}/exam.pdf')..writeAsBytesSync([5, 5, 5]);
      final att = (await attachments.importFile(src, mimeType: 'application/pdf'))
          .attachment;
      return documents.create(
        pages: [MedicalPageRef(attachmentId: att.id, messageId: 'm', pageNo: 1)],
        docType: MedicalDocType.physicalExam,
      );
    }

    // 4 页，每页 3 行检验数据（都带数值密度，页筛选保留）。
    FakeExtractor booklet() => FakeExtractor(pageCount: 4, pageTexts: {
          for (var i = 0; i < 4; i++)
            i: '项目${i}A 1.$i mmol/L 1.0-2.0\n项目${i}B 2.$i mmol/L 2.0-3.0\n'
                '项目${i}C 3.$i mmol/L 3.0-4.0',
        });

    String replyFor(String userText, {String? examDate}) {
      final pages = RegExp(r'^P(\d+)L1:', multiLine: true)
          .allMatches(userText)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      return jsonEncode({
        'doc': {'doc_type': 'physical_exam', 'exam_date': examDate},
        'results': [
          for (final p in pages)
            {'item_name_raw': '项目${p - 1}A', 'value_raw': '1.${p - 1}',
             'source_lines': ['P${p}L1']}
        ],
        'conditions': [
          {'name': '脂肪肝', 'persistence': 'long_term', 'source_lines': ['P${pages.first}L1']}
        ],
      });
    }

    MedicalExtractionService service(
            Future<ModelResponse> Function(String userText) reply) =>
        MedicalExtractionService(
          attachments: attachments,
          documents: documents,
          records: records,
          organize: organize,
          modelConfigs: configs,
          keyStore: KeyStore(),
          extraction: TextExtractionService(
              extractor: booklet(), cacheDir: Directory('${tmp.path}/cache')),
          modelCall: ({required config, required apiKey, system,
              required userText, required maxTokens}) => reply(userText),
          batchMaxLines: 6, // 两页一批
        );

    test('按行数切批、整页不拆；行数少的文件仍一次发完', () async {
      await addConfig();
      final doc = await importBooklet();
      final draft = await service((_) async => throw StateError('x'))
          .prepareSend(doc.id);
      expect(draft.batches(maxLines: 6).map((b) => b.map((p) => p.pageNo).toList()),
          [[1, 2], [3, 4]]);
      expect(draft.batches(maxLines: 4).length, 4); // 单页超了也单独成批
      expect(draft.batches().length, 1); // 默认 90 行：一次发完
    });

    test('分批发送后合并成一条记录：定位按各自行号，日期取第一个非空，状况不重复', () async {
      await addConfig();
      final doc = await importBooklet();
      final progress = <(int, int)>[];
      final sent = <String>[];
      final ex = service((userText) async {
        sent.add(userText);
        final firstBatch = userText.contains('P1L1:');
        return ModelResponse(
            text: replyFor(userText, examDate: firstBatch ? null : '2026-09-10'),
            tokensIn: 1,
            tokensOut: 1);
      });
      final outcome = await ex.sendDraft(await ex.prepareSend(doc.id),
          onProgress: (d, t) => progress.add((d, t)));

      expect(sent, hasLength(2));
      expect(sent.every((t) => !(t.contains('P1L1:') && t.contains('P3L1:'))), isTrue);
      expect(progress.last, (2, 2));
      expect(outcome.failedPages, isEmpty);
      final data = jsonDecode(
          (await records.currentRevisionOf(outcome.record.id)).data) as Map;
      final results = data['results'] as List;
      expect(results.map((r) => (r as Map)['item_name_raw']),
          ['项目0A', '项目1A', '项目2A', '项目3A']);
      expect((((results[3] as Map)['locator'] as List).single as Map)['page_no'], 4);
      expect((await documents.byId(doc.id))!.examDate, contains('2026-09-10'));
      expect(await records.byType(RecordType.condition), hasLength(1));
      final calls = await organize.recentModelCalls();
      expect(calls, hasLength(2));
      expect(calls.map((c) => c.sentSummary), everyElement(contains('分 2 批')));
    });

    test('一批重试后仍失败：其余批次保存，点名失败的页', () async {
      await addConfig();
      final doc = await importBooklet();
      var failures = 0;
      final ex = service((userText) async {
        if (userText.contains('P3L1:')) {
          failures++;
          throw ModelClientException('请求超时', retriable: true);
        }
        return ModelResponse(text: replyFor(userText), tokensIn: 1, tokensOut: 1);
      });
      final outcome = await ex.sendDraft(await ex.prepareSend(doc.id));
      expect(failures, 2); // 重试过一次
      expect(outcome.failedPages, [3, 4]);
      final data = jsonDecode(
          (await records.currentRevisionOf(outcome.record.id)).data) as Map;
      expect(data['results'] as List, hasLength(2));
      final calls = await organize.recentModelCalls();
      expect(calls.where((c) => c.status == ModelCallStatus.failed), hasLength(2));
    });

    test('全部批次失败：抛出原错误，不建记录', () async {
      await addConfig();
      final doc = await importBooklet();
      final ex = service((_) async =>
          throw ModelClientException('请求超时', retriable: true));
      await expectLater(ex.sendDraft(await ex.prepareSend(doc.id)),
          throwsA(isA<ModelClientException>()));
      expect(await records.byType(RecordType.labPanel), isEmpty);
    });
  });

  test('文件类型：体检报告不被模型判断覆盖，未分类的由模型补上；被改掉的可修复', () async {
    await addConfig();
    Future<MedicalDocument> add(MedicalDocType type, int byte) async {
      final src = File('${tmp.path}/t$byte.jpg')..writeAsBytesSync([byte]);
      final att =
          (await attachments.importFile(src, mimeType: 'image/jpeg')).attachment;
      return documents.create(
        pages: [MedicalPageRef(attachmentId: att.id, messageId: 'm', pageNo: 1)],
        docType: type,
      );
    }
    final exam = await add(MedicalDocType.physicalExam, 41);
    final other = await add(MedicalDocType.other, 42);
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '血糖 5.1 mmol/L 3.9-6.1', x: 0.1, y: 0.1, w: 0.5, h: 0.03),
    ]);
    final reply = jsonEncode({
      'doc': {'doc_type': 'lab_report', 'institution_text': '某体检中心'},
      'results': [],
    });
    model.reply(reply);
    model.reply(reply);
    await buildService(extractor).extractDocument(exam.id);
    await buildService(extractor).extractDocument(other.id);
    expect((await documents.byId(exam.id))!.docType, MedicalDocType.physicalExam);
    expect((await documents.byId(exam.id))!.institutionText, '某体检中心');
    expect((await documents.byId(other.id))!.docType, MedicalDocType.labReport);

    // 用户改过的医疗机构，重新提取不覆盖；清空后再提取由模型补上。
    await documents.updateInstitution(exam.id, '市第一人民医院');
    model.reply(reply);
    await buildService(extractor).extractDocument(exam.id);
    expect((await documents.byId(exam.id))!.institutionText, '市第一人民医院');
    await documents.updateInstitution(exam.id, null);
    expect((await documents.byId(exam.id))!.institutionText, isNull);
    model.reply(reply);
    await buildService(extractor).extractDocument(exam.id);
    expect((await documents.byId(exam.id))!.institutionText, '某体检中心');

    // 检查日期同样：已有的不被重新提取覆盖，新记录按它归日。
    await documents.updateInfo(exam.id,
        examDate: TimeValue(
            localDate: '2024-03-05',
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated));
    model.reply(jsonEncode({
      'doc': {'exam_date': '2025-01-01'},
      'results': [],
    }));
    await buildService(extractor).extractDocument(exam.id);
    expect(
        TimeValue.decode((await documents.byId(exam.id))!.examDate!).localDate,
        '2024-03-05');
    expect((await records.labPanelOfDocument(exam.id))!.localDate, '2024-03-05');

    // 就诊标题：空的由模型补上，用户改过的不覆盖。
    await documents.updateVisitTitle(exam.id, null);
    model.reply(jsonEncode({
      'doc': {'visit_title': ' 年度体检 '},
      'results': [],
    }));
    await buildService(extractor).extractDocument(exam.id);
    expect((await documents.byId(exam.id))!.visitTitle, '年度体检');
    await documents.updateVisitTitle(exam.id, '入职体检');
    model.reply(jsonEncode({
      'doc': {'visit_title': '年度体检'},
      'results': [],
    }));
    await buildService(extractor).extractDocument(exam.id);
    expect((await documents.byId(exam.id))!.visitTitle, '入职体检');

    // 改检查日期：文件、记录、从它建议的状况一起改日。
    await records.create(
      recordType: RecordType.condition,
      occurred: TimeValue(
          localDate: '2024-03-05',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: jsonEncode({'name': '甲状腺结节', 'medical_document_id': exam.id}),
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.userEdit(),
    );
    await buildService(extractor).changeExamDate(exam.id, '2024-04-06');
    expect(
        TimeValue.decode((await documents.byId(exam.id))!.examDate!).localDate,
        '2024-04-06');
    expect((await records.labPanelOfDocument(exam.id))!.localDate, '2024-04-06');
    expect([
      for (final r in await records.byType(RecordType.condition)) r.localDate
    ], ['2024-04-06']);

    // 修复前的旧行为留下的数据：体检报告被改成了检验报告。
    await documents.updateInfo(exam.id, docType: MedicalDocType.labReport);
    expect(await documents.repairPhysicalExamType(), 1);
    expect((await documents.byId(exam.id))!.docType, MedicalDocType.physicalExam);
    expect(await documents.repairPhysicalExamType(), 0); // 幂等
    // 从没当过体检报告的不动。
    expect((await documents.byId(other.id))!.docType, MedicalDocType.labReport);
  });

  test('确认页的行修改随文件保存，下次打开恢复；原文变了不套用；全部还原清空', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '家属 李四 联系方式见背面', x: 0.1, y: 0.1, w: 0.5, h: 0.03),
      OcrLine(text: '备注：空腹采血', x: 0.1, y: 0.2, w: 0.5, h: 0.03),
      OcrLine(text: '血糖 5.1 mmol/L 3.9-6.1', x: 0.1, y: 0.3, w: 0.5, h: 0.03),
    ]);
    final service = buildService(extractor);

    final first = await service.prepareSend(doc.id);
    expect(first.restoredEdits, 0);
    first.edits[SendDraft.lineKey(1, 0)] = '';
    first.edits[SendDraft.lineKey(1, 1)] = '';
    await service.saveLineEdits(first);

    final again = await service.prepareSend(doc.id);
    expect(again.restoredEdits, 2);
    expect(again.payload, isNot(contains('李四')));
    expect(again.payload, contains('血糖'));

    // 原文对不上（比如识别结果重算后行变了）：那一行的修改不套用。
    final saved = MedicalDocumentRepository.decodeLineEdits(
        (await documents.byId(doc.id))!.lineEdits);
    final key0 = saved.keys.firstWhere((k) => k.endsWith(':0'));
    await documents.setLineEdits(doc.id, {
      ...saved,
      key0: const LineEdit(orig: '另一行原文', text: ''),
    });
    final mismatched = await service.prepareSend(doc.id);
    expect(mismatched.restoredEdits, 1);
    expect(mismatched.payload, contains('李四'));

    // 全部还原。
    mismatched.edits.clear();
    await service.saveLineEdits(mismatched);
    expect((await documents.byId(doc.id))!.lineEdits, isNull);
    expect((await service.prepareSend(doc.id)).restoredEdits, 0);
  });

  test('确认页多选：按页序连选、批量删除与恢复（体检报告要删的行多）', () async {
    await addConfig();
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '第一行', x: 0.1, y: 0.1, w: 0.5, h: 0.03),
      OcrLine(text: '第二行', x: 0.1, y: 0.2, w: 0.5, h: 0.03),
      OcrLine(text: '第三行', x: 0.1, y: 0.3, w: 0.5, h: 0.03),
      OcrLine(text: '血糖 5.1 mmol/L 3.9-6.1', x: 0.1, y: 0.4, w: 0.5, h: 0.03),
    ]);
    final service = buildService(extractor);
    final draft = await service.prepareSend(doc.id);
    final order = draft.lineOrder();
    expect(order, ['P1L1', 'P1L2', 'P1L3', 'P1L4']);
    // 反方向长按也一样：从第 3 行连到第 1 行。
    expect(SendDraft.range(order, 'P1L3', 'P1L1'), ['P1L1', 'P1L2', 'P1L3']);
    expect(SendDraft.range(order, 'P1L2', 'P9L9'), ['P9L9']);

    draft.deleteLines(SendDraft.range(order, 'P1L1', 'P1L3'));
    await service.saveLineEdits(draft);
    expect(draft.sentLineCount, 1);
    expect(draft.payload.trim(), 'P1L4: 血糖 5.1 mmol/L 3.9-6.1');
    expect((await service.prepareSend(doc.id)).restoredEdits, 3);

    draft.restoreLines(['P1L2']);
    expect(draft.payload, contains('第二行'));
    expect(draft.payload, isNot(contains('第一行')));
  });

  test('没有默认模型：不调用、不建记录', () async {
    final doc = await importDoc();
    final extractor = FakeExtractor(
        ocrResults: const [OcrLine(text: 'x', x: 0, y: 0, w: 1, h: 1)]);
    expect(() => buildService(extractor).extractDocument(doc.id),
        throwsStateError);
    expect(model.calls, isEmpty);
  });

  test('模型返回垃圾：记录失败可查，不建半成品记录', () async {
    await configs.add(
      preset: ModelPreset.anthropic,
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.example.com',
      model: 'm',
      dataBoundary: DataBoundary.cloud,
      keychainRef: '',
    );
    final doc = await importDoc();
    final extractor = FakeExtractor(ocrResults: const [
      OcrLine(text: '白细胞 6.2 10^9/L 3.5-9.5', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
    ]);
    model.reply('抱歉我不能');
    await expectLater(
        buildService(extractor).extractDocument(doc.id), throwsStateError);
    final day = await records.byDate(DateTime.now().toString().substring(0, 10));
    expect(day, isEmpty);
  });

  test('指标说明（D-50）：只发项目名、写法、分组、单位，不发数值；定性项目标阳性；不需要的返回 null', () async {
    await addConfig();
    await records.create(
      recordType: RecordType.labPanel,
      occurred: TimeValue(
          localDate: '2023-07-26',
          precision: TimePrecision.dateOnly,
          source: TimeValueSource.userStated),
      dataJson: jsonEncode({
        'results': [
          {'item_name_raw': 'MTHFR', 'value_raw': 'CT', 'panel_raw': '基因检测'},
        ],
      }),
      fieldMeta: const FieldMetaMap({}),
      producedBy: ProducedBy.medicalExtract('call-1'),
    );
    final service = buildService(FakeExtractor(ocrResults: const []));
    model.reply(jsonEncode({
      'meaning': '叶酸代谢相关的基因',
      'high': '突变型可能使同型半胱氨酸偏高',
      'low': '不该有',
      'related': '同型半胱氨酸、叶酸',
      'qualitative': true,
    }));
    final e = (await service.explainLabItem('MTHFR', group: '基因检测'))!;
    expect(e.meaning, '叶酸代谢相关的基因');
    expect(e.highLabel, '阳性');
    expect(e.low, isNull);
    expect(model.calls.last, contains('MTHFR'));
    expect(model.calls.last, isNot(contains('CT')));
    expect(model.calls.last, isNot(contains('2023')));

    model.reply(jsonEncode({'skip': true}));
    expect(await service.explainLabItem('MTHFR', group: '基因检测'), isNull);
  });
}
