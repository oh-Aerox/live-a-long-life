import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/record_repository.dart';
import 'package:live_a_long_life/data/time_value.dart';
import 'package:live_a_long_life/services/body_map.dart';
import 'package:live_a_long_life/ui/body_map_points.dart';

import '../data/test_helpers.dart';

void main() {
  group('检验项目归属', () {
    test('中文名与缩写', () {
      expect(BodyMapRules.organOfLabItem('丙氨酸氨基转移酶(ALT)'), 'liver');
      expect(BodyMapRules.organOfLabItem('AST'), 'liver');
      expect(BodyMapRules.organOfLabItem('促甲状腺激素'), 'thyroid');
      expect(BodyMapRules.organOfLabItem('FT3'), 'thyroid');
      expect(BodyMapRules.organOfLabItem('肌酐'), 'kidney');
      expect(BodyMapRules.organOfLabItem('总前列腺特异性抗原'), 'prostate');
      expect(BodyMapRules.organOfLabItem('CA125'), 'ovary');
      expect(BodyMapRules.organOfLabItem('血红蛋白'), bloodOrganId);
      expect(BodyMapRules.organOfLabItem('甘油三酯 TG'), bloodOrganId);
    });

    test('具体的先匹配：尿白细胞归膀胱，不归血液', () {
      expect(BodyMapRules.organOfLabItem('尿白细胞'), 'bladder');
      expect(BodyMapRules.organOfLabItem('白细胞'), bloodOrganId);
      expect(BodyMapRules.organOfLabItem('尿微量白蛋白'), 'kidney');
    });

    test('缩写不误中更长的缩写', () {
      // "Ca"（钙）不能命中 CA153，"T3" 不能命中 FT3 之外的词。
      expect(BodyMapRules.organOfLabItem('CA153'), 'breast');
      expect(BodyMapRules.organOfLabItem('Ca'), bloodOrganId);
      expect(BodyMapRules.organOfLabItem('TGAb'), 'thyroid');
      expect(BodyMapRules.organOfLabItem('某未知项目'), otherOrganId);
    });
  });

  test('文字归属', () {
    expect(BodyMapRules.organsOfText('胆囊结石'), ['gallbladder']);
    expect(BodyMapRules.organsOfText('甲状腺结节 TI-RADS 3 类'), ['thyroid']);
    expect(BodyMapRules.organsOfText('脂肪肝，胆囊息肉'),
        containsAll(['liver', 'gallbladder']));
    expect(BodyMapRules.organsOfText('窦性心律不齐'), ['heart']);
    expect(BodyMapRules.organsOfText('高血压'), [bloodOrganId]);
    expect(BodyMapRules.organsOfText('恶心'), ['stomach']);
    expect(BodyMapRules.organsOfText('阴道炎'), ['vagina']);
    expect(BodyMapRules.organsOfText('颈部淋巴结肿大'), isEmpty);
  });

  test('异常句子：解释与建议、写着正常的不算，检查名前缀不参与判断', () {
    expect(
        BodyMapRules.abnormalSentences(
            '腹部超声提示：脂肪肝（中度）。脂肪肝的发生与肥胖、糖尿病等有关。建议定期复查'),
        ['脂肪肝（中度）']);
    expect(
        BodyMapRules.abnormalSentences(
            '8.肿瘤检测提示：异常糖链糖蛋白（TAP）检测正常/无明显凝集物'),
        isEmpty);
  });

  test('异常句子：否定的不算', () {
    expect(BodyMapRules.abnormalSentences('肝内未见明显占位。胆囊壁毛糙，胆囊内见强回声'),
        ['胆囊壁毛糙，胆囊内见强回声']);
    expect(BodyMapRules.abnormalSentences('双肾未见异常；膀胱充盈良好'), isEmpty);
    // 紧挨关键词的"不"是否定（2024-10 体检报告胰腺描述被误判）。
    expect(
        BodyMapRules.abnormalSentences(
            '胰腺形态大小正常，轮廓规整，实质回声均匀，主胰管不扩张'),
        isEmpty);
    expect(BodyMapRules.abnormalSentences('胆总管不明显增宽，肝内胆管不扩张'), isEmpty);
    expect(BodyMapRules.abnormalSentences('肝右叶见不规则低回声区'), hasLength(1));
    expect(BodyMapRules.abnormalSentences('甲状腺右叶结节，大小约 5mm'),
        ['甲状腺右叶结节，大小约 5mm']);
    expect(BodyMapRules.abnormalSentences('否认高血压、糖尿病史'), isEmpty);
    expect(BodyMapRules.abnormalSentences('无结石'), isEmpty);
  });

  test('数值异常', () {
    expect(BodyMapRules.isAbnormalLab(flagRaw: '↑'), isTrue);
    expect(BodyMapRules.isAbnormalLab(flagRaw: '-'), isFalse);
    expect(
        BodyMapRules.isAbnormalLab(valueNum: 65, refLow: 9, refHigh: 50), isTrue);
    expect(
        BodyMapRules.isAbnormalLab(valueNum: 30, refLow: 9, refHigh: 50), isFalse);
    expect(
        BodyMapRules.isAbnormalLab(valueRaw: '阳性(+)', refRangeRaw: '阴性'),
        isTrue);
    expect(BodyMapRules.isAbnormalLab(valueRaw: '阴性', refRangeRaw: '阴性'),
        isFalse);
  });

  test('生理性别自由文本', () {
    expect(BodyMapRules.parseSex('男'), BodySex.male);
    expect(BodyMapRules.parseSex('female'), BodySex.female);
    expect(BodyMapRules.parseSex('女性'), BodySex.female);
    expect(BodyMapRules.parseSex(null), isNull);
    expect(BodyMapRules.parseSex('不详'), isNull);
  });

  test('每个图上的器官都有点位，点位都在分区内', () {
    for (final (sex, figure) in [
      (BodySex.male, maleFigure),
      (BodySex.female, femaleFigure),
    ]) {
      for (final o in organs.where((o) => o.sex == null || o.sex == sex)) {
        final p = figure.points[o.id];
        expect(p, isNotNull, reason: '$sex 缺 ${o.id}');
        expect(figure.regions[o.region]!.contains(p!.offset), isTrue,
            reason: '$sex ${o.id} 不在 ${o.region} 分区内');
      }
    }
  });

  group('加载', () {
    late TestEnv env;
    late RecordRepository records;
    late ProfileRepository profile;

    setUp(() async {
      env = await TestEnv.create();
      records = RecordRepository(env.db, env.ctx);
      profile = ProfileRepository(env.db, env.ctx);
    });

    tearDown(() => env.dispose());

    TimeValue day(String d) => TimeValue(
        localDate: d,
        precision: TimePrecision.dateOnly,
        source: TimeValueSource.userStated);

    Future<void> addPanel(String date, List<Map<String, Object?>> results,
        {List<Map<String, Object?>> findings = const [],
        Map<String, FieldMeta> meta = const {}}) async {
      await records.create(
        recordType: RecordType.labPanel,
        occurred: day(date),
        dataJson: jsonEncode({
          'medical_document_id': 'doc-$date',
          'results': results,
          'findings': findings,
        }),
        fieldMeta: FieldMetaMap(meta),
        producedBy: ProducedBy.medicalExtract('c-$date'),
      );
    }

    Future<void> addCondition(String date, String name, String docId,
        {String status = 'active'}) =>
        records.create(
          recordType: RecordType.condition,
          occurred: day(date),
          dataJson: jsonEncode({
            'name': name,
            'persistence': 'long_term',
            'status': status,
            'medical_document_id': docId,
          }),
          fieldMeta: const FieldMetaMap({}),
          producedBy: ProducedBy.medicalExtract('c-$name'),
        );

    test('当前状况取最新（D-32）：同一问题跨报告只留最新，同份报告的文字不重复列',
        () async {
      await addPanel('2019-05-11', [
        {'item_name_raw': '丙氨酸氨基转移酶', 'value_raw': '89.1', 'value_num': 89.1, 'ref_high': 50},
      ], findings: [
        {'section_raw': '汇总分析', 'text_raw': '腹部超声提示：脂肪肝（轻度）；生化检验提示：丙氨酸氨基转移酶高'},
        {'section_raw': '检查所见', 'text_raw': '脂肪肝（轻度）'},
      ]);
      await addPanel('2022-07-17', [
        // 汇总与明细各写一遍 AST，名称带不带缩写。
        {'item_name_raw': '天门冬氨酸氨基转移酶', 'value_raw': '12.7U/L', 'value_num': 12.7, 'unit_raw': 'U/L', 'flag_raw': '低'},
        {'item_name_raw': '丙氨酸氨基转移酶（ALT）', 'value_raw': '14.4', 'value_num': 14.4, 'ref_high': 50},
        {'item_name_raw': '天门冬氨酸氨基转移酶（AST）', 'value_raw': '12.7', 'value_num': 12.7, 'unit_raw': 'U/L', 'ref_range_raw': '15-40', 'flag_raw': '↓'},
      ], findings: [
        {'section_raw': '汇总分析', 'text_raw': '1.腹部超声提示：脂肪肝（中度）。脂肪肝的发生与肥胖有关'},
        {'section_raw': '检查所见', 'text_raw': '脂肪肝（中度）'},
      ]);
      await addCondition('2019-05-11', '脂肪肝（轻度）', 'doc-2019-05-11');
      await addCondition('2022-07-17', '脂肪肝（中度）', 'doc-2022-07-17');

      final data = await BodyMapService(records: records, profile: profile)
          .load(now: DateTime(2026, 9, 30));
      final liver = data.of('liver');
      expect(liver.map((f) => f.title), [
        '脂肪肝（中度）',
        '天门冬氨酸氨基转移酶（AST） 12.7U/L ↓',
      ], reason: 'ALT 2022 已正常；AST 两条合一；报告文字被同份报告的诊断覆盖');
      expect(liver.first.detail, contains('此前：2019-05-11 脂肪肝（轻度）'));
    });

    test('尿常规的项目归膀胱/肾，不和血液里的同名项目混（D-36）', () async {
      await addPanel('2022-07-17', [
        {'panel_raw': '血常规', 'item_name_raw': '白细胞计数（WBC）', 'value_raw': '5.33', 'value_num': 5.33, 'ref_low': 3.5, 'ref_high': 9.5},
        {'panel_raw': '尿常规', 'item_name_raw': '白细胞(LEU)', 'value_raw': '+', 'flag_raw': '↑'},
        {'panel_raw': '尿常规', 'item_name_raw': '蛋白质(PRO)', 'value_raw': '+', 'flag_raw': '↑'},
        {'panel_raw': '尿常规', 'item_name_raw': 'pH值(pH)', 'value_raw': '8.5', 'value_num': 8.5, 'ref_low': 4.5, 'ref_high': 8},
      ]);
      final data = await BodyMapService(records: records, profile: profile)
          .load(now: DateTime(2026, 9, 30));
      expect(data.of('bladder').map((f) => f.title), ['白细胞(LEU) + ↑']);
      expect(data.of('kidney').map((f) => f.title),
          containsAll(['蛋白质(PRO) + ↑', 'pH值(pH) 8.5']));
      expect(data.of(bloodOrganId), isEmpty, reason: '血白细胞正常，尿白细胞不算血液');
      expect(data.of('stomach'), isEmpty, reason: 'pH 不被 Hp 规则误中');
    });

    test('检验只看每项最近一次；报告文字、状况、不适各自归位', () async {
      await profile.setField('sex_at_birth', value: '女');
      await addPanel('2025-03-01', [
        {'item_name_raw': 'ALT', 'value_raw': '80', 'value_num': 80, 'ref_high': 50},
        {'item_name_raw': 'TSH', 'value_raw': '6.1', 'value_num': 6.1, 'ref_high': 4.2},
      ]);
      await addPanel('2026-03-01', [
        // ALT 已恢复正常，不再提示；TSH 仍偏高。
        {'item_name_raw': 'ALT', 'value_raw': '30', 'value_num': 30, 'ref_high': 50},
        {'item_name_raw': 'TSH', 'value_raw': '5.0', 'value_num': 5.0, 'ref_high': 4.2, 'flag_raw': '↑'},
      ], findings: [
        {'section_raw': '超声提示', 'text_raw': '甲状腺右叶结节。肝脏未见异常'},
        {'section_raw': '建议', 'text_raw': '甲状腺结节定期复查'},
      ], meta: {
        'results.1': const FieldMeta(
            origin: FieldOrigin.modelInferred,
            reviewStatus: ReviewStatus.confirmed),
      });
      await records.create(
        recordType: RecordType.condition,
        occurred: day('2024-06-01'),
        dataJson: jsonEncode({
          'name': '胆囊结石',
          'persistence': 'long_term',
          'status': 'active',
        }),
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.medicalExtract('c1'),
      );
      await records.create(
        recordType: RecordType.condition,
        occurred: day('2024-06-01'),
        dataJson: jsonEncode({
          'name': '感冒',
          'persistence': 'temporary',
          'status': 'active',
        }),
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.medicalExtract('c2'),
      );
      await records.create(
        recordType: RecordType.symptom,
        occurred: day('2026-09-28'),
        dataJson: jsonEncode({
          'status': 'present',
          'body_site': '胃',
          'description': '饭后胀痛',
        }),
        fieldMeta: const FieldMetaMap({}),
        producedBy: ProducedBy.organizeRun('r1'),
      );

      final data = await BodyMapService(records: records, profile: profile)
          .load(now: DateTime(2026, 9, 30));

      expect(data.sex, BodySex.female);
      expect(data.of('liver'), isEmpty);
      final thyroid = data.of('thyroid');
      expect(thyroid.map((f) => f.kind),
          containsAll([BodyFindingKind.lab, BodyFindingKind.finding]));
      expect(thyroid.length, 2, reason: '"建议"栏不重复列');
      final tsh = thyroid.firstWhere((f) => f.kind == BodyFindingKind.lab);
      expect(tsh.reviewed, isTrue);
      expect(tsh.medicalDocumentId, 'doc-2026-03-01');
      expect(data.of('gallbladder').single.reviewed, isFalse);
      expect(data.of('stomach').single.kind, BodyFindingKind.symptom);
      // 临时疾病超过 30 天不列。
      expect(data.byOrgan.values.expand((l) => l).map((f) => f.title),
          isNot(contains('感冒')));
    });
  });
}
