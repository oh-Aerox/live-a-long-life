import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/medical_document_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/consult_tools.dart';
import 'package:live_a_long_life/services/health_service.dart';
import 'package:live_a_long_life/services/sleep_merge.dart';
import 'package:live_a_long_life/services/tool_chat.dart';

import '../data/test_helpers.dart';

const unreviewed = FieldMeta(
    origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.unreviewed);
const confirmed = FieldMeta(
    origin: FieldOrigin.modelInferred, reviewStatus: ReviewStatus.confirmed);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestEnv env;
  late RecordRepository records;
  late MedicalDocumentRepository documents;
  late Map<String, DeviceDayData> device;
  late ConsultTools tools;

  setUp(() async {
    env = await TestEnv.create();
    records = RecordRepository(env.db, env.ctx);
    documents = MedicalDocumentRepository(env.db, env.ctx);
    device = {};
    tools = ConsultTools(
      db: env.db,
      records: records,
      documents: documents,
      deviceData: (date) async =>
          device[date] ??
          const DeviceDayData(
              sleep: null, workouts: [], steps: null, activeEnergyKcal: null),
    );
  });

  tearDown(() => env.dispose());

  Future<void> add(String date, RecordType type, Map<String, Object?> data,
          [Map<String, FieldMeta> meta = const {}]) =>
      records.create(
        recordType: type,
        occurred: TimeValue(
            localDate: date,
            precision: TimePrecision.dateOnly,
            source: TimeValueSource.userStated),
        dataJson: jsonEncode(data),
        fieldMeta: FieldMetaMap(meta),
        producedBy: ProducedBy.userEdit(),
      );

  Future<(Map<String, Object?>, String)> run(
      String name, Map<String, Object?> args) async {
    final out =
        await tools.run(ToolCall(id: 'c', name: name, arguments: args));
    return ((jsonDecode(out.content) as Map).cast<String, Object?>(), out.note);
  }

  test('get_records：按日期范围和类型；睡眠带时间；医疗类只发已核对要点（D-04）', () async {
    await add('2026-10-20', RecordType.sleep, {
      'sleep_onset': {'local_date': '2026-10-19', 'local_time': '23:40'},
      'wake_time': {'local_date': '2026-10-20', 'local_time': '07:05'},
    });
    await add('2026-10-21', RecordType.meal,
        {'status': 'eaten', 'description': '牛肉面'});
    await add('2026-10-25', RecordType.meal,
        {'status': 'eaten', 'description': '范围外'});
    await add('2026-10-20', RecordType.condition,
        {'name': '胆囊息肉', 'persistence': 'long_term', 'status': 'active'},
        {'condition': unreviewed});
    await add('2026-10-21', RecordType.labPanel, {
      'medical_document_id': 'd2',
      'results': [
        {'item_name_raw': '白细胞', 'value_raw': '11.2', 'value_num': 11.2,
         'unit_raw': '10^9/L', 'ref_range_raw': '3.5-9.5', 'ref_low': 3.5,
         'ref_high': 9.5},
        {'item_name_raw': '血红蛋白', 'value_raw': '145', 'value_num': 145,
         'ref_low': 130, 'ref_high': 175},
      ],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '1.咽喉炎 2.上呼吸道感染'},
        {'section_raw': '现病史', 'text_raw': '患者5天前出现不适'},
      ],
      'medications': [
        {'name': '头孢呋辛酯片'},
        {'name': '未核对的药'},
      ],
    }, {
      'results.0': confirmed,
      'results.1': confirmed,
      'findings.0': confirmed,
      'findings.1': confirmed,
      'medications.0': confirmed,
      'medications.1': unreviewed,
    });

    final (out, note) = await run(
        'get_records', {'start_date': '2026-10-20', 'end_date': '2026-10-22'});
    final summaries = [
      for (final r in out['records'] as List) (r as Map)['summary'] as String
    ];
    final all = summaries.join('\n');
    expect(summaries, hasLength(3)); // 睡眠 + 饮食 + 已核对的报告
    expect(all, contains('入睡 23:40'));
    expect(all, contains('牛肉面'));
    expect(all, isNot(contains('范围外')));
    expect(all, isNot(contains('胆囊息肉')));
    expect(all, contains('诊断：1.咽喉炎 2.上呼吸道感染'));
    expect(all, contains('白细胞 11.210^9/L'));
    expect(all, isNot(contains('血红蛋白')));
    expect(all, contains('开药：头孢呋辛酯片'));
    expect(all, isNot(contains('未核对')));
    expect(note, '记录 10-20~10-22（3 条）');

    final (meals, _) = await run('get_records', {
      'start_date': '2026-10-20',
      'end_date': '2026-10-22',
      'types': ['meal'],
    });
    expect(meals['records'] as List, hasLength(1));
  });

  test('日期范围：超过 31 天、格式不对、结束早于开始都把错误回给模型', () async {
    final (tooLong, note) = await run(
        'get_records', {'start_date': '2026-01-01', 'end_date': '2026-03-01'});
    expect(tooLong['error'], contains('31 天'));
    expect(note, contains('参数有误'));
    final (badFormat, _) = await run(
        'get_device_data', {'start_date': '2026/10/01', 'end_date': '2026-10-02'});
    expect(badFormat['error'], contains('YYYY-MM-DD'));
    final (reversed, _) = await run(
        'get_records', {'start_date': '2026-10-05', 'end_date': '2026-10-01'});
    expect(reversed['error'], contains('早于'));
    final (unknown, _) = await run('drop_table', {});
    expect(unknown['error'], contains('没有这个工具'));
  });

  test('get_device_data：有数据的天给摘要，没数据的天单列（≠ 0，D-11）', () async {
    final onset = DateTime(2026, 10, 23, 23, 30).millisecondsSinceEpoch;
    final wake = DateTime(2026, 10, 24, 7, 0).millisecondsSinceEpoch;
    device['2026-10-24'] = DeviceDayData(
      sleep: SleepSegment(
          sleepOnsetMs: onset,
          wakeMs: wake,
          sleepDurationMin: 420,
          sourceName: 'Apple Watch'),
      workouts: [
        HealthSample(
          id: 'w1',
          userId: 'u',
          createdAt: 0,
          createdOnDevice: 'd',
          version: 1,
          platformUuid: 'p1',
          sampleType: HealthSampleType.workout,
          startUtc: DateTime(2026, 10, 24, 18, 0).millisecondsSinceEpoch,
          endUtc: DateTime(2026, 10, 24, 18, 30).millisecondsSinceEpoch,
          tz: 'Asia/Shanghai',
          tzInferred: true,
          workoutType: '跑步',
          energyKcal: 250,
          sourceName: 'Apple Watch',
          fetchedAt: 0,
        ),
      ],
      steps: 8123.0,
      activeEnergyKcal: 410.4,
    );

    final (out, note) = await run('get_device_data',
        {'start_date': '2026-10-23', 'end_date': '2026-10-24'});
    final day = (out['days'] as List).single as Map;
    expect(day['date'], '2026-10-24');
    expect(day['sleep'], '睡眠 7 小时 0 分钟，入睡 23:30，醒来 07:00');
    expect(day['steps'], 8123);
    expect(day['active_energy_kcal'], 410);
    expect((day['workouts'] as List).single, '跑步，18:00 起 30 分钟，250 千卡');
    expect(out['days_without_data'], ['2026-10-23']);
    expect(note, '健康数据 10-23~10-24（1 天有数据）');
  });

  test('检验：列表与历史只含已核对的；按名字找到项目，同名不同标本分开列', () async {
    await add('2025-05-01', RecordType.labPanel, {
      'results': [
        {'item_name_raw': '血红蛋白', 'value_raw': '128', 'value_num': 128,
         'unit_raw': 'g/L', 'ref_range_raw': '130-175', 'ref_low': 130,
         'ref_high': 175, 'panel_raw': '血常规'},
        {'item_name_raw': '白细胞', 'value_raw': '6.1', 'value_num': 6.1,
         'panel_raw': '血常规'},
        {'item_name_raw': '白细胞', 'value_raw': '阴性', 'panel_raw': '尿常规'},
      ],
    }, {
      'results.0': confirmed,
      'results.1': confirmed,
      'results.2': confirmed,
    });
    await add('2026-05-01', RecordType.labPanel, {
      'results': [
        {'item_name_raw': '血红蛋白', 'value_raw': '140', 'value_num': 140,
         'unit_raw': 'g/L', 'ref_range_raw': '130-175', 'ref_low': 130,
         'ref_high': 175, 'panel_raw': '血常规'},
        {'item_name_raw': '尿酸', 'value_raw': '520', 'value_num': 520,
         'ref_low': 208, 'ref_high': 428},
      ],
    }, {
      'results.0': confirmed,
      'results.1': unreviewed, // 未核对：列表和历史都不出现
    });

    final (list, listNote) = await run('list_lab_items', {});
    final items = {
      for (final i in list['items'] as List) (i as Map)['item']: i
    };
    expect(items.keys, isNot(contains('尿酸')));
    final hb = items['血红蛋白'] as Map;
    expect(hb['latest'], '140g/L');
    expect(hb['abnormal'], isFalse);
    expect(hb['times'], 2);
    expect(listNote, contains('${items.length} 项'));

    final (history, note) = await run('get_lab_history', {'item': '血红蛋白'});
    final hbHistory = ((history['items'] as List).first as Map)['history'] as List;
    expect([for (final h in hbHistory) (h as Map)['value']], ['128', '140']);
    expect((hbHistory.first as Map)['abnormal'], isTrue);
    expect(note, '检验历史"血红蛋白"（1 项 2 次）');

    final (wbc, _) = await run('get_lab_history', {'item': '白细胞'});
    expect(wbc['items'] as List, hasLength(2)); // 血、尿各一项

    final (none, _) = await run('get_lab_history', {'item': '尿酸'});
    expect(none['items'], isEmpty);
  });

  test('search_medical_documents：只给已核对内容，带文件类型和机构，按关键词和日期筛', () async {
    final doc = await documents.create(
      pages: const [MedicalPageRef(attachmentId: 'a', messageId: 'm', pageNo: 1)],
      docType: MedicalDocType.imagingReport,
      institutionText: '市一医院',
    );
    await add('2026-03-01', RecordType.labPanel, {
      'medical_document_id': doc.id,
      'results': [],
      'findings': [
        {'section_raw': '超声所见', 'text_raw': '胆囊内见强回声，后伴声影'},
        {'section_raw': '超声提示', 'text_raw': '胆囊结石'},
      ],
    }, {
      'findings.0': confirmed,
      'findings.1': confirmed,
    });
    await add('2026-04-01', RecordType.labPanel, {
      'results': [],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '未核对的诊断'},
      ],
    }, {
      'findings.0': unreviewed,
    });

    final (all, note) = await run('search_medical_documents', {});
    final docs = all['documents'] as List;
    expect(docs, hasLength(1)); // 未核对的那份整份不出现
    final d = docs.single as Map;
    expect(d['type'], '影像报告');
    expect(d['institution'], '市一医院');
    expect(d['findings'], contains('超声所见：胆囊内见强回声，后伴声影'));
    expect(note, contains('1 份'));

    final (hit, _) = await run('search_medical_documents', {'keyword': '结石'});
    expect(hit['documents'] as List, hasLength(1));
    final (miss, _) = await run('search_medical_documents', {'keyword': '肾'});
    expect(miss['documents'], isEmpty);
    final (outOfRange, _) = await run('search_medical_documents',
        {'start_date': '2026-03-02', 'end_date': '2026-12-31'});
    expect(outOfRange['documents'], isEmpty);
  });
}
