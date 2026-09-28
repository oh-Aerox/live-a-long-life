import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/services/page_filter.dart';
import 'package:live_a_long_life/services/text_extraction.dart';

void main() {
  const filter = PageFilter();

  ExtractedPage page(int no, List<String> texts) => ExtractedPage(
        pageNo: no,
        source: PageTextSource.ocr,
        lines: [for (final t in texts) OcrLine(text: t)],
      );

  test('检验数据页：数值密度信号保留，即使混着"温馨提示"', () {
    final d = filter.decide(page(1, [
      '温馨提示：结果仅供参考',
      '白细胞 6.2 10^9/L 3.5-9.5',
      '血红蛋白 145 g/L 130-175',
      '血小板 210 10^9/L 125-350',
      '谷丙转氨酶 25 U/L 9-50',
    ]));
    expect(d.included, isTrue);
  });

  test('检查文字报告（散文体）与总检建议：靠保留锚点留下（D-23）', () {
    expect(
        filter
            .decide(page(2, ['腹部彩超', '肝脏大小形态正常', '所见：胆囊壁毛糙', '结论：胆囊炎改变']))
            .included,
        isTrue);
    expect(
        filter.decide(page(3, ['总检建议', '低盐低脂饮食，规律作息，建议复查血脂'])).included,
        isTrue);
  });

  test('导读、机构介绍、健康宣教页：默认排除', () {
    expect(filter.decide(page(4, ['报告导读', '尊敬的客户，感谢您选择本中心'])).included,
        isFalse);
    expect(
        filter.decide(page(5, ['健康宣教', '什么是高血压？高血压是指……'])).included, isFalse);
  });

  test('认不出版式的页：默认保留（宁可多发不静默丢）', () {
    expect(filter.decide(page(6, ['随手写的一页', '没有任何锚点词'])).included, isTrue);
  });
}
