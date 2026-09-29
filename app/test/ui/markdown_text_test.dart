import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/ui/markdown_text.dart';

/// 模型回复按 Markdown 显示，标记符号不出现在界面上（A-38 联调反馈）。
void main() {
  const reply = '''
## 结论

咽喉炎期间建议**清淡饮食**，*多饮水*。

### 饮食
- 少吃辛辣
- 限酒
  - 啤酒也算
1. 每天饮水 `2000ml` 左右
2. 久坐每小时起身

> 症状加重请及时就医。

---

| 项目 | 建议 |
|---|---|
| 运动 | 散步 |
''';

  /// 含 [needle] 的文字片段实际生效的字重（沿祖先链合并样式）。
  FontWeight? effectiveWeight(WidgetTester tester, String needle) {
    FontWeight? found;
    void walk(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is TextSpan) {
        if (span.text != null && span.text!.contains(needle)) {
          found ??= style.fontWeight;
        }
        for (final c in span.children ?? const <InlineSpan>[]) {
          walk(c, style);
        }
      }
    }

    for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
      walk(w.text, const TextStyle());
    }
    return found;
  }

  String visibleText(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((w) => w.text.toPlainText())
      .join('\n');

  testWidgets('标题、粗体、列表、引用、表格渲染后不残留标记符号', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: MarkdownText(reply)))));
    final text = visibleText(tester);
    for (final mark in ['##', '**', '`', '> ', '|', '---', '- 少吃']) {
      expect(text, isNot(contains(mark)), reason: '残留 $mark');
    }
    expect(text, contains('结论'));
    expect(text, contains('清淡饮食'));
    expect(text, contains('•'));
    expect(text, contains('1.'));
    expect(text, contains('症状加重请及时就医。'));
    expect(find.byType(Table), findsOneWidget);

    // 粗体真的加粗了：按层级合并样式，看"清淡饮食"最终生效的字重。
    expect(effectiveWeight(tester, '清淡饮食'), FontWeight.bold);
    expect(effectiveWeight(tester, '咽喉炎期间建议'), isNot(FontWeight.bold));
  });

  testWidgets('主题正文带明确字重时粗体不被覆盖', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: MarkdownText('建议**清淡饮食**',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)))));
    expect(effectiveWeight(tester, '清淡饮食'), FontWeight.bold);
  });

  testWidgets('不认识的写法原样显示，不丢内容；普通数字减号不当列表', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MarkdownText('参考范围 3.5-9.5，2*3 不是斜体'))));
    expect(visibleText(tester), contains('参考范围 3.5-9.5，2*3 不是斜体'));
  });

  test('截断预览的纯文本：去标记', () {
    final plain = MarkdownText.plain(reply);
    expect(plain, isNot(contains('**')));
    expect(plain, isNot(contains('##')));
    expect(plain, contains('• 少吃辛辣'));
    expect(plain, isNot(contains(r'$1')));
  });
}
