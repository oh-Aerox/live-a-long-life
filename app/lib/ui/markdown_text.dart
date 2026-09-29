import 'package:flutter/material.dart';

/// 轻量 Markdown 显示（模型回复、周报正文）。只覆盖模型常用的子集：
/// 标题、段落、粗体/斜体/行内代码、有序/无序列表（可嵌套一级）、引用、
/// 分隔线、代码块、简单表格。不认识的语法原样显示，不丢内容。
/// 不引第三方渲染库（与趋势图同一取舍）；整块可选中复制。
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.source, {super.key, this.style});

  final String source;

  /// 正文基准样式，默认取主题 bodyMedium。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final blocks = _parseBlocks(source.replaceAll('\r\n', '\n'));
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < blocks.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: blocks[i].build(context, base),
            ),
        ],
      ),
    );
  }

  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$');
  static final _ordered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
  static final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final _tableSep = RegExp(r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$');

  static List<_Block> _parseBlocks(String text) {
    final lines = text.split('\n');
    final blocks = <_Block>[];
    final para = <String>[];

    void flushPara() {
      if (para.isNotEmpty) {
        blocks.add(_Paragraph(para.join('\n')));
        para.clear();
      }
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushPara();
        i++;
        continue;
      }
      if (trimmed.startsWith('```')) {
        flushPara();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++; // 跳过收尾的 ```（没有收尾时到文末为止）
        blocks.add(_Code(code.join('\n')));
        continue;
      }
      final h = _heading.firstMatch(trimmed);
      if (h != null) {
        flushPara();
        blocks.add(_Heading(h.group(1)!.length, h.group(2)!));
        i++;
        continue;
      }
      if (_rule.hasMatch(trimmed)) {
        flushPara();
        blocks.add(const _Rule());
        i++;
        continue;
      }
      // 表格：表头行 + 分隔行 + 数据行。
      if (trimmed.contains('|') &&
          i + 1 < lines.length &&
          _tableSep.hasMatch(lines[i + 1])) {
        flushPara();
        final rows = <List<String>>[_cells(trimmed)];
        i += 2;
        while (i < lines.length && lines[i].trim().contains('|')) {
          rows.add(_cells(lines[i].trim()));
          i++;
        }
        blocks.add(_Table(rows));
        continue;
      }
      if (trimmed.startsWith('>')) {
        flushPara();
        final quote = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quote.add(lines[i].trim().replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        blocks.add(_Quote(quote.join('\n')));
        continue;
      }
      if (_bullet.hasMatch(line) || _ordered.hasMatch(line)) {
        flushPara();
        final items = <_ListItem>[];
        while (i < lines.length) {
          final l = lines[i];
          final b = _bullet.firstMatch(l);
          final o = _ordered.firstMatch(l);
          if (b != null) {
            items.add(_ListItem(b.group(1)!.length >= 2 ? 1 : 0, '•', b.group(2)!));
          } else if (o != null) {
            items.add(_ListItem(
                o.group(1)!.length >= 2 ? 1 : 0, '${o.group(2)}.', o.group(3)!));
          } else if (l.trim().isNotEmpty && items.isNotEmpty && l.startsWith(' ')) {
            // 列表项的续行。
            final last = items.removeLast();
            items.add(_ListItem(last.depth, last.marker, '${last.text} ${l.trim()}'));
          } else {
            break;
          }
          i++;
        }
        blocks.add(_ListBlock(items));
        continue;
      }
      para.add(trimmed);
      i++;
    }
    flushPara();
    return blocks;
  }

  /// 去掉标记符号的纯文本（截断预览用：几行摘要里不画标题和表格）。
  static String plain(String source) => source
      .split('\n')
      .where((l) => !_rule.hasMatch(l) && !_tableSep.hasMatch(l))
      .map((l) => l
          .replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '')
          .replaceFirst(RegExp(r'^\s*>\s?'), '')
          .replaceFirstMapped(
              RegExp(r'^(\s*)[-*+]\s+'), (m) => '${m.group(1)}• ')
          .replaceAll(RegExp(r'\*\*|__|`'), '')
          .replaceAll(RegExp(r'^\||\|$'), '')
          .replaceAll('|', '  '))
      .join('\n');

  static List<String> _cells(String row) {
    var r = row;
    if (r.startsWith('|')) r = r.substring(1);
    if (r.endsWith('|')) r = r.substring(0, r.length - 1);
    return r.split('|').map((c) => c.trim()).toList();
  }

  /// 行内：**粗体** / __粗体__、*斜体* / _斜体_、`代码`。
  static final _inline = RegExp(
      r'(\*\*|__)(.+?)\1|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\w)|`([^`]+)`');

  static TextSpan inline(String text, TextStyle base) =>
      TextSpan(children: _spans(text, base), style: base);

  /// 子片段不带正文样式：主题正文样式明确写了字重，套在粗体里面会把粗体盖掉。
  static List<InlineSpan> _spans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(2) != null) {
        spans.add(TextSpan(
            children: _spans(m.group(2)!, base),
            style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
            text: m.group(3), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(
            text: m.group(4),
            style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: base.color?.withValues(alpha: 0.08))));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}

abstract class _Block {
  const _Block();
  Widget build(BuildContext context, TextStyle base);
}

class _Paragraph extends _Block {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) =>
      Text.rich(MarkdownText.inline(text, base));
}

class _Heading extends _Block {
  const _Heading(this.level, this.text);
  final int level;
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) {
    final size = (base.fontSize ?? 14) + (level <= 1 ? 4 : level == 2 ? 2 : 1);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(MarkdownText.inline(
          text, base.copyWith(fontSize: size, fontWeight: FontWeight.bold))),
    );
  }
}

class _ListItem {
  const _ListItem(this.depth, this.marker, this.text);
  final int depth;
  final String marker;
  final String text;
}

class _ListBlock extends _Block {
  const _ListBlock(this.items);
  final List<_ListItem> items;

  @override
  Widget build(BuildContext context, TextStyle base) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(left: 4.0 + item.depth * 16, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: item.marker.length > 2 ? 26 : 18,
                    child: Text(item.marker, style: base),
                  ),
                  Expanded(child: Text.rich(MarkdownText.inline(item.text, base))),
                ],
              ),
            ),
        ],
      );
}

class _Quote extends _Block {
  const _Quote(this.text);
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) => Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(
              left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant, width: 3)),
        ),
        child: Text.rich(MarkdownText.inline(
            text, base.copyWith(color: base.color?.withValues(alpha: 0.75)))),
      );
}

class _Rule extends _Block {
  const _Rule();

  @override
  Widget build(BuildContext context, TextStyle base) =>
      const Divider(height: 12);
}

class _Code extends _Block {
  const _Code(this.text);
  final String text;

  @override
  Widget build(BuildContext context, TextStyle base) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: base.color?.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: base.copyWith(fontFamily: 'monospace', fontSize: 12)),
      );
}

class _Table extends _Block {
  const _Table(this.rows);
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context, TextStyle base) {
    final cols = rows.fold(0, (n, r) => r.length > n ? r.length : n);
    final border = Theme.of(context).colorScheme.outlineVariant;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: border, width: 0.5),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(children: [
              for (var c = 0; c < cols; c++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text.rich(MarkdownText.inline(
                    c < rows[r].length ? rows[r][c] : '',
                    r == 0 ? base.copyWith(fontWeight: FontWeight.bold) : base,
                  )),
                ),
            ]),
        ],
      ),
    );
  }
}
