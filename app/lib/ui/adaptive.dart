import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS / macOS 用 Cupertino 样式，其它平台保持 Material。按主题里的平台判断，
/// 测试里可以用 ThemeData(platform: ...) 切换。
bool useCupertino(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

/// 对话框按钮，与 `AlertDialog.adaptive` 配套：iOS / macOS 上是
/// CupertinoDialogAction，其它平台是 TextButton。
///
/// 只用于纯文字内容的对话框——CupertinoAlertDialog 下面没有 Material，
/// 放 TextField 会报错；要输入内容用 [showFieldsDialog]。
class DialogAction extends StatelessWidget {
  const DialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// 删除、替换这类不可撤销的操作；iOS 上显示为红色。
  final bool isDestructiveAction;

  @override
  Widget build(BuildContext context) {
    if (useCupertino(context)) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructiveAction,
        child: child,
      );
    }
    return TextButton(onPressed: onPressed, child: child);
  }
}

// ---- 导航栏 ----

/// 导航栏右侧的一个按钮。两套图标分别给 Material 和 Cupertino。
class NavAction {
  const NavAction({
    required this.icon,
    required this.cupertinoIcon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final IconData cupertinoIcon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 图标颜色；null 用默认的次要文字色。只有首页底栏用。
  final Color? color;
}

/// iOS 上是 CupertinoNavigationBar（返回键是 ‹），其它平台是 AppBar。
PreferredSizeWidget adaptiveAppBar(BuildContext context,
    {Widget? title, List<NavAction> actions = const []}) {
  if (!useCupertino(context)) {
    return AppBar(title: title, actions: [
      for (final a in actions)
        IconButton(
            icon: Icon(a.icon), tooltip: a.tooltip, onPressed: a.onPressed),
    ]);
  }
  return CupertinoNavigationBar(
    middle: title,
    // 页面走的是 MaterialPageRoute，标题跨页过渡动画用不上，关掉免得 Hero 冲突。
    transitionBetweenRoutes: false,
    trailing: actions.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                Semantics(
                  label: a.tooltip,
                  button: true,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(34, 34),
                    onPressed: a.onPressed,
                    child: Icon(a.cupertinoIcon, size: 24),
                  ),
                ),
            ],
          ),
  );
}

// ---- 操作菜单 ----

/// 菜单里的一项。[icon] 只在 Material 底部面板里显示（iOS 操作表不带图标）。
class SheetAction<T> {
  const SheetAction({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.isDestructiveAction = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool isDestructiveAction;
}

/// 选一项：iOS 上是 CupertinoActionSheet（底部带"取消"），其它平台是
/// Material 底部面板。取消或点空白处返回 null。
Future<T?> showActionSheet<T>(BuildContext context,
    {String? title, required List<SheetAction<T>> actions}) {
  if (useCupertino(context)) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title == null ? null : Text(title),
        actions: [
          for (final a in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: a.isDestructiveAction,
              onPressed: () => Navigator.pop(context, a.value),
              child: a.subtitle == null
                  ? Text(a.label)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.label),
                        Text(a.subtitle!,
                            style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context))),
                      ],
                    ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          for (final a in actions)
            ListTile(
              leading: a.icon == null ? null : Icon(a.icon),
              title: Text(a.label),
              subtitle: a.subtitle == null ? null : Text(a.subtitle!),
              onTap: () => Navigator.pop(context, a.value),
            ),
        ],
      ),
    ),
  );
}

// ---- 输入对话框 ----

/// 输入对话框里的一个输入框。[maxLines] 为 null 表示随内容变高。
class DialogField {
  const DialogField({
    this.label,
    this.initial = '',
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
  });

  final String? label;
  final String initial;
  final String? hint;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
}

/// 带输入框的对话框：iOS 上是 CupertinoAlertDialog + CupertinoTextField，
/// 其它平台是 AlertDialog + TextField。确认返回各输入框的原文（未 trim），
/// 取消返回 null。第一个输入框自动获得焦点。
Future<List<String>?> showFieldsDialog(
  BuildContext context, {
  required String title,
  required List<DialogField> fields,
  String confirmLabel = '保存',
}) {
  return showAdaptiveDialog<List<String>>(
    context: context,
    builder: (context) =>
        _FieldsDialog(title: title, fields: fields, confirmLabel: confirmLabel),
  );
}

class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog(
      {required this.title, required this.fields, required this.confirmLabel});

  final String title;
  final List<DialogField> fields;
  final String confirmLabel;

  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial)
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() =>
      Navigator.pop(context, [for (final c in _controllers) c.text]);

  @override
  Widget build(BuildContext context) {
    final fields = widget.fields;
    if (!useCupertino(context)) {
      return AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fields.length; i++)
                TextField(
                  controller: _controllers[i],
                  autofocus: i == 0,
                  obscureText: fields[i].obscureText,
                  maxLines: fields[i].maxLines,
                  minLines: fields[i].minLines,
                  decoration: InputDecoration(
                      labelText: fields[i].label, hintText: fields[i].hint),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
        ],
      );
    }
    final labelStyle = TextStyle(
        fontSize: 12,
        color: CupertinoColors.secondaryLabel.resolveFrom(context));
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (fields[i].label != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2, left: 2),
                child: Text(fields[i].label!, style: labelStyle),
              )
            else
              const SizedBox(height: 8),
            CupertinoTextField(
              controller: _controllers[i],
              autofocus: i == 0,
              obscureText: fields[i].obscureText,
              maxLines: fields[i].maxLines,
              minLines: fields[i].minLines,
              placeholder: fields[i].hint,
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _confirm,
            child: Text(widget.confirmLabel)),
      ],
    );
  }
}

// ---- 分组列表 ----

/// 一组列表行：iOS 上是圆角分组（CupertinoListSection.insetGrouped），
/// 其它平台是粗体小标题加普通 ListTile。[children] 不能为空。
class AdaptiveSection extends StatelessWidget {
  const AdaptiveSection(
      {super.key, this.header, this.footer, required this.children});

  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (useCupertino(context)) {
      return CupertinoListSection.insetGrouped(
        header: header == null ? null : Text(header!),
        footer: footer == null
            ? null
            : Text(footer!,
                style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context))),
        children: children,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(header!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ...children,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(footer!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
    );
  }
}

/// 列表行：iOS 上是 CupertinoListTile，其它平台是 ListTile。
/// 副标题在 iOS 上也完整换行显示（CupertinoListTile 默认只显示一行，
/// 核对病历文字时不能被截断）。
class AdaptiveTile extends StatelessWidget {
  const AdaptiveTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 只影响 Material 的 ListTile。
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (!useCupertino(context)) {
      return ListTile(
        dense: dense,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
    final sub = subtitle;
    final tail = trailing;
    return CupertinoListTile(
      // 默认上下内边距为 0、只靠最小高度居中，副标题一换行就贴着边框。
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 16, 12),
      title: title,
      subtitle: sub == null
          ? null
          // 新的 DefaultTextStyle 不带 maxLines，覆盖掉外层的单行限制。
          : Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 14, height: 1.4),
                    child: sub),
              )),
      trailing: tail == null
          ? null
          : Padding(padding: const EdgeInsets.only(left: 12), child: tail),
      onTap: onTap,
    );
  }
}
