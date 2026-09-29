import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/ui/adaptive.dart';

Future<void> _openDialog(WidgetTester tester, TargetPlatform platform) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(platform: platform),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => showAdaptiveDialog<bool>(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('删除？'),
            content: const Text('不可撤销'),
            actions: [
              DialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消')),
              DialogAction(
                  onPressed: () => Navigator.pop(context, true),
                  isDestructiveAction: true,
                  child: const Text('删除')),
            ],
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

// AlertDialog.adaptive 返回的是 AlertDialog 的私有子类，byType 匹配不到。
final _alertDialog = find.byWidgetPredicate((w) => w is AlertDialog);

void main() {
  testWidgets('iOS 上显示为 Cupertino 对话框', (tester) async {
    await _openDialog(tester, TargetPlatform.iOS);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('安卓上保持 Material 对话框', (tester) async {
    await _openDialog(tester, TargetPlatform.android);
    expect(_alertDialog, findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNothing);
    expect(
        find.descendant(
            of: _alertDialog, matching: find.byType(TextButton)),
        findsNWidgets(2));
  });

  testWidgets('iOS 输入对话框用 CupertinoTextField，确认返回输入内容', (tester) async {
    final result = <Object?>[];
    await _pumpLauncher(
        tester,
        TargetPlatform.iOS,
        (context) => showFieldsDialog(context, title: '修改这一项', fields: const [
              DialogField(label: '项目', initial: '尿酸'),
              DialogField(label: '数值', initial: '420'),
            ]),
        result);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNWidgets(2));
    await tester.enterText(find.byType(CupertinoTextField).last, '380');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(result, [
      ['尿酸', '380']
    ]);
  });

  testWidgets('输入对话框取消返回 null（安卓用 Material TextField）', (tester) async {
    final result = <Object?>[];
    await _pumpLauncher(
        tester,
        TargetPlatform.android,
        (context) => showFieldsDialog(context,
            title: '编辑消息', fields: const [DialogField(initial: 'abc')]),
        result);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, [null]);
  });

  testWidgets('iOS 操作菜单是 CupertinoActionSheet，带取消', (tester) async {
    final result = <Object?>[];
    await _pumpLauncher(
        tester,
        TargetPlatform.iOS,
        (context) => showActionSheet<String>(context, actions: const [
              SheetAction(value: 'edit', label: '编辑'),
              SheetAction(
                  value: 'delete', label: '删除', isDestructiveAction: true),
            ]),
        result);
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(result, [null, 'delete']);
  });

  testWidgets('iOS 列表行副标题完整换行，不截成一行', (tester) async {
    const long = '超声所见：胆囊大小形态正常，壁光滑，囊内可见一强回声，'
        '大小约 0.8cm×0.6cm，后伴声影，随体位改变移动。';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Scaffold(
        body: ListView(children: const [
          AdaptiveSection(header: '诊断与检查文字', children: [
            AdaptiveTile(title: Text('超声'), subtitle: Text(long)),
          ]),
        ]),
      ),
    ));
    expect(find.byType(CupertinoListSection), findsOneWidget);
    final paragraph =
        tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.maxLines, isNull);
    expect(paragraph.didExceedMaxLines, isFalse);
  });
}

/// 在指定平台下渲染一个按钮，点按钮执行 [open]，结果存进 [result]。
Future<void> _pumpLauncher(WidgetTester tester, TargetPlatform platform,
    Future<Object?> Function(BuildContext) open, List<Object?> result) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(platform: platform),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result.add(await open(context)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

