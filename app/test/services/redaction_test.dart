import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/services/redaction.dart';
import 'package:live_a_long_life/services/text_extraction.dart';

void main() {
  const service = RedactionService();

  List<OcrLine> lines(List<String> texts) =>
      [for (final t in texts) OcrLine(text: t)];

  test('第一层锚点：同行"标签：值"，姓名与各类卡号都被遮蔽', () {
    final r = service.redactPage(lines([
      '姓名：张三 性别：男 年龄：45',
      '身份证号：110101199003077758',
      '社保卡号：A123456789',
      '医保卡号 330100123456',
    ]));
    expect(r.lines[0].text, contains('【姓名】'));
    expect(r.lines[0].text, isNot(contains('张三')));
    // 性别、年龄保留（参考范围与分析依赖，D-24 明确不删）。
    expect(r.lines[0].text, contains('性别：男'));
    expect(r.lines[0].text, contains('年龄：45'));
    expect(r.lines[1].text, '身份证号：【证件号】');
    expect(r.lines[2].text, contains('【证件号】'));
    expect(r.lines[3].text, contains('【证件号】'));
    expect(r.redactedCount, 4);
  });

  test('第二层校验位：散落的 18 位身份证被遮，随机 18 位数字不误伤', () {
    final r = service.redactPage(lines([
      '条码 110101199003077758 采样',
      '流水号 123456789012345678', // 校验位不对：不是身份证
    ]));
    expect(r.lines[0].text, '条码 【证件号】 采样');
    expect(r.lines[1].text, contains('123456789012345678'));
  });

  test('OCR 易混字符归一化后仍能识别身份证；日期不被误伤', () {
    final r = service.redactPage(lines([
      '11O1O1199OO3O77758', // O→0 归一化后校验通过
      '检查日期 2026-09-20 报告日期 2026-09-21',
    ]));
    expect(r.lines[0].text, '【证件号】');
    expect(r.lines[1].text, contains('2026-09-20'));
    expect(r.lines[1].text, contains('2026-09-21'));
  });

  test('第三层已知姓名：全文替换，单字姓名不替（防误伤）', () {
    final r = service.redactPage(
      lines(['受检人为李四，李四的空腹血糖正常', '王某某审核']),
      knownNames: ['李四', '王'],
    );
    expect(r.lines[0].text, isNot(contains('李四')));
    expect('【姓名】'.allMatches(r.lines[0].text).length, 2);
    expect(r.lines[1].text, '王某某审核'); // 单字不替
  });

  test('表格版式：标签单独成行，按坐标遮同行右邻的值', () {
    final r = service.redactPage([
      const OcrLine(text: '姓名', x: 0.05, y: 0.10, w: 0.08, h: 0.03),
      const OcrLine(text: '张三丰', x: 0.18, y: 0.10, w: 0.10, h: 0.03),
      const OcrLine(text: '白细胞', x: 0.05, y: 0.30, w: 0.10, h: 0.03),
      const OcrLine(text: '6.2', x: 0.30, y: 0.30, w: 0.06, h: 0.03),
    ]);
    expect(r.lines[1].text, '【姓名】');
    expect(r.lines[3].text, '6.2'); // 检验值不受影响
    expect(r.redactedCount, 1);
  });

  test('身份证校验位算法本身', () {
    expect(RedactionService.isValidCitizenId('110101199003077758'), isTrue);
    expect(RedactionService.isValidCitizenId('110101199003077757'), isFalse);
    expect(RedactionService.isValidCitizenId('11010119901307775X'), isFalse); // 13 月
  });
}
