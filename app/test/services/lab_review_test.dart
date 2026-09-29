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

  test('文字内容（D-28）：确认、修改、全部确认覆盖 findings；旧记录无 findings 不报错', () {
    final data = jsonEncode({
      'results': [],
      'findings': [
        {'section_raw': '诊断', 'text_raw': '咽喉炎', 'locator': []},
        {'section_raw': '处理意见', 'text_raw': '复查', 'locator': []},
      ],
    });
    const meta = FieldMetaMap({});
    var (d, m) = LabReview.confirmFinding(data, meta, 0);
    expect(m['findings.0']!.reviewStatus, ReviewStatus.confirmed);
    (d, m) = LabReview.editFinding(d, m, 1, sectionRaw: '处理意见', textRaw: '两周后复查');
    expect(((jsonDecode(d) as Map)['findings'] as List)[1]['text_raw'], '两周后复查');
    expect(m['findings.1']!.reviewStatus, ReviewStatus.edited);
    (d, m) = LabReview.confirmAll(data, meta);
    expect(m['findings.1']!.reviewStatus, ReviewStatus.confirmed);
    expect(() => LabReview.confirmFinding(data, meta, 5), throwsRangeError);
    // D-28 之前的记录没有 findings 字段。
    LabReview.confirmAll(jsonEncode({'results': []}), meta);
  });
}
