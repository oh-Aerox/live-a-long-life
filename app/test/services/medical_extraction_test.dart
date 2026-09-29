import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/model_config_repository.dart';
import 'package:live_a_long_life/data/repositories/organize_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/services/key_store.dart';
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

  group('模型识图兜底（V4-M3，D-24）', () {
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
}
