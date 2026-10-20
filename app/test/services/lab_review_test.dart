import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/services/lab_review.dart';

void main() {
  final dataJson = jsonEncode({
    'medical_document_id': 'doc-1',
    'results': [
      {
        'item_name_raw': '白细胞',
        'value_raw': '6.2',
        'value_num': 6.2,
        'unit_raw': '10^9/L',
        'ref_range_raw': '3.5-9.5',
        'ref_low': 3.5,
        'ref_high': 9.5,
        'locator': [],
      },
      {
        'item_name_raw': '血红蛋白',
        'value_raw': '145',
        'value_num': 145,
        'unit_raw': 'g/L',
        'ref_range_raw': '130-175',
        'locator': [],
      },
    ],
  });
  final meta = FieldMetaMap({
    'results.0': const FieldMeta(
        origin: FieldOrigin.modelInferred,
        reviewStatus: ReviewStatus.unreviewed),
    'results.1': const FieldMeta(
        origin: FieldOrigin.modelInferred,
        reviewStatus: ReviewStatus.unreviewed),
  });

  test('确认一项：数据不动，状态转 confirmed，其余项不受影响（D-04）', () {
    final (data, newMeta) = LabReview.confirmResult(dataJson, meta, 0);
    expect(data, dataJson);
    expect(newMeta['results.0']!.reviewStatus, ReviewStatus.confirmed);
    expect(newMeta['results.0']!.origin, FieldOrigin.modelInferred);
    expect(newMeta['results.1']!.reviewStatus, ReviewStatus.unreviewed);
  });

  test('全部确认', () {
    final (_, newMeta) = LabReview.confirmAll(dataJson, meta);
    expect(newMeta['results.0']!.reviewStatus, ReviewStatus.confirmed);
    expect(newMeta['results.1']!.reviewStatus, ReviewStatus.confirmed);
  });

  test('修改：只更新传入字段，数值/参考范围同步重算，状态转 edited', () {
    final (data, newMeta) = LabReview.editResult(dataJson, meta, 0,
        valueRaw: '7.8', refRangeRaw: '4.0~10.0');
    final r = ((jsonDecode(data) as Map)['results'] as List)[0] as Map;
    expect(r['value_raw'], '7.8');
    expect(r['value_num'], 7.8);
    expect(r['ref_low'], 4.0);
    expect(r['ref_high'], 10.0);
    expect(r['item_name_raw'], '白细胞'); // 没传的不动
    expect(newMeta['results.0']!.reviewStatus, ReviewStatus.edited);
    expect(newMeta['results.0']!.origin, FieldOrigin.userEdited);
  });

  test('修改成解析不出的数值：value_num 置 null，不猜', () {
    final (data, _) = LabReview.editResult(dataJson, meta, 1, valueRaw: '阴性');
    final r = ((jsonDecode(data) as Map)['results'] as List)[1] as Map;
    expect(r['value_raw'], '阴性');
    expect(r['value_num'], isNull);
  });

  test('越界索引拒绝', () {
    expect(() => LabReview.confirmResult(dataJson, meta, 5), throwsRangeError);
    expect(() => LabReview.editResult(dataJson, meta, -1, valueRaw: '1'),
        throwsRangeError);
  });

  test('文字内容与药品（D-28）：确认、修改、全部确认；旧记录无这两个字段不报错', () {
    final data = jsonEncode({
      'results': [],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '咽喉炎', 'locator': []},
        {'section_raw': '处理意见', 'text_raw': '复查', 'locator': []},
      ],
      'medications': [
        {'name': '头孢呋辛酯片', 'dose': '0.25g', 'route': '口服', 'locator': [],
         'ocr_fixes': ['头孢味辛酯片→头孢呋辛酯片']},
      ],
    });
    const meta = FieldMetaMap({});
    var (d, m) = LabReview.confirmEntry(data, meta, 'findings', 0);
    expect(m['findings.0']!.reviewStatus, ReviewStatus.confirmed);
    (d, m) = LabReview.editEntry(d, m, 'findings', 1,
        {'section_raw': '处理意见', 'text_raw': '两周后复查'});
    expect(((jsonDecode(d) as Map)['findings'] as List)[1]['text_raw'], '两周后复查');
    expect(m['findings.1']!.reviewStatus, ReviewStatus.edited);
    (d, m) = LabReview.editEntry(d, m, 'medications', 0,
        {'name': '头孢呋辛酯片', 'frequency': '每日2次', 'dose': ''});
    final med = ((jsonDecode(d) as Map)['medications'] as List).single as Map;
    expect(med['frequency'], '每日2次');
    expect(med['dose'], isNull); // 空串存 null
    expect(med['ocr_fixes'], isNotEmpty); // 修正记录保留
    (d, m) = LabReview.confirmAll(data, meta);
    expect(m['findings.1']!.reviewStatus, ReviewStatus.confirmed);
    expect(m['medications.0']!.reviewStatus, ReviewStatus.confirmed);
    expect(() => LabReview.confirmEntry(data, meta, 'findings', 5),
        throwsRangeError);
    LabReview.confirmAll(jsonEncode({'results': []}), meta);
  });

  test('删除一条文字内容：后面各条前移，核对状态跟着移', () {
    final data = jsonEncode({
      'results': [],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '脂肪肝'},
        {'section_raw': '备注', 'text_raw': '无'},
        {'section_raw': '建议', 'text_raw': '复查'},
      ],
    });
    final meta = FieldMetaMap({
      'findings.0': const FieldMeta(
          origin: FieldOrigin.modelInferred,
          reviewStatus: ReviewStatus.confirmed),
      'findings.1': const FieldMeta(
          origin: FieldOrigin.modelInferred,
          reviewStatus: ReviewStatus.unreviewed),
      'findings.2': const FieldMeta(
          origin: FieldOrigin.userEdited, reviewStatus: ReviewStatus.edited),
    });
    final (d, m) = LabReview.deleteEntry(data, meta, 'findings', 1);
    final findings = (jsonDecode(d) as Map)['findings'] as List;
    expect([for (final f in findings) f['section_raw']], ['诊断', '建议']);
    expect(m['findings.0']!.reviewStatus, ReviewStatus.confirmed);
    expect(m['findings.1']!.reviewStatus, ReviewStatus.edited);
    expect(m['findings.2'], isNull);
    expect(() => LabReview.deleteEntry(data, meta, 'findings', 3),
        throwsRangeError);
  });

  test('删除检验结果：后面的前移、状态跟着移；汇总与明细重复的同项同值一起删', () {
    final data = jsonEncode({
      'results': [
        {'item_name_raw': '*白细胞计数', 'value_raw': '6.2', 'value_num': 6.2},
        {'item_name_raw': '身高', 'value_raw': '172', 'value_num': 172},
        {'item_name_raw': '血红蛋白', 'value_raw': '145', 'value_num': 145},
        {'item_name_raw': '白细胞计数', 'value_raw': '6.2', 'value_num': 6.2},
        {'item_name_raw': '白细胞计数', 'value_raw': '5.0', 'value_num': 5.0},
      ],
    });
    const unreviewed = FieldMeta(
        origin: FieldOrigin.modelInferred,
        reviewStatus: ReviewStatus.unreviewed);
    final meta = FieldMetaMap({
      for (var i = 0; i < 5; i++) 'results.$i': unreviewed,
      'results.2': const FieldMeta(
          origin: FieldOrigin.modelInferred,
          reviewStatus: ReviewStatus.confirmed),
    });
    var (d, m) = LabReview.deleteResult(data, meta, 1);
    List names(String d) =>
        [for (final r in (jsonDecode(d) as Map)['results'] as List) r['value_raw']];
    expect(names(d), ['6.2', '145', '6.2', '5.0']);
    expect(m['results.1']!.reviewStatus, ReviewStatus.confirmed);
    expect(m['results.4'], isNull);

    (d, m) = LabReview.deleteResult(d, m, 2);
    expect(names(d), ['145', '5.0']); // 两条 6.2 一起删，5.0 不是同值留下
    expect(m['results.0']!.reviewStatus, ReviewStatus.confirmed);
    expect(m['results.1']!.reviewStatus, ReviewStatus.unreviewed);
    expect(m['results.2'], isNull);
  });
}
