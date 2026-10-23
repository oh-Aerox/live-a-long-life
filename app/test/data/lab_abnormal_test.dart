import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/field_meta.dart';
import 'package:live_a_long_life/data/lab_abnormal.dart';
import 'package:live_a_long_life/data/record_summary.dart';

void main() {
  test('数值异常', () {
    expect(isAbnormalLab(flagRaw: '↑'), isTrue);
    expect(isAbnormalLab(flagRaw: '-'), isFalse);
    expect(isAbnormalLab(flagRaw: '0级'), isFalse);
    expect(isAbnormalLab(flagRaw: '2级'), isTrue);
    expect(isAbnormalLab(valueNum: 65, refLow: 9, refHigh: 50), isTrue);
    expect(isAbnormalLab(valueNum: 30, refLow: 9, refHigh: 50), isFalse);
    expect(isAbnormalLab(valueRaw: '阳性(+)', refRangeRaw: '阴性'), isTrue);
    expect(isAbnormalLab(valueRaw: '阴性', refRangeRaw: '阴性'), isFalse);
  });

  test('咨询摘要的异常指标与核对页同一口径：标记写着正常的不算', () {
    const ok = FieldMeta(
      origin: FieldOrigin.modelInferred,
      reviewStatus: ReviewStatus.confirmed,
    );
    final summary = reviewedMedicalSummary({
      'results': [
        {
          'item_name_raw': '屋尘',
          'value_raw': '0.00',
          'value_num': 0.0,
          'unit_raw': 'IU/ml',
          'ref_range_raw': '<0.35',
          'ref_high': 0.35,
          'flag_raw': '0级',
        },
        {
          'item_name_raw': '鸡蛋',
          'value_raw': '172',
          'value_num': 172.0,
          'unit_raw': 'U/ml',
          'ref_range_raw': '<50',
          'ref_high': 50.0,
          'flag_raw': '*',
        },
      ],
    }, const FieldMetaMap({'results.0': ok, 'results.1': ok}));
    expect(summary, contains('鸡蛋'));
    expect(summary, isNot(contains('屋尘')));
  });
}
