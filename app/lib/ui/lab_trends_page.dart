import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/same_item.dart';
import 'adaptive.dart';

/// 指标趋势（v0.4，数据源是 lab_results 索引，D-27）。
/// 列表页：出现过的检验项目 + 最近数值，按检查大项分组（D-36）；点进去看
/// 历史折线。
class LabTrendsPage extends StatefulWidget {
  const LabTrendsPage({super.key, required this.services});

  final AppServices services;

  @override
  State<LabTrendsPage> createState() => _LabTrendsPageState();
}

class _LabTrendsPageState extends State<LabTrendsPage> {
  List<LabResult> _items = [];
  Map<String, Set<String>> _names = {};
  Map<String, String> _itemGroups = {};
  String _query = '';

  /// 分组顺序：体检报告的常见顺序在前，其余按名字，"其他"最后。
  static const _groupOrder = [
    '一般检查', '血常规', '尿常规', '便常规', '生化', '肝功能', '肾功能', //
    '血脂', '血糖', '甲状腺功能', '肿瘤标志物', '凝血功能', '传染病筛查',
    '血型', '过敏原检测',
  ];

  static int _compareGroups(String a, String b) {
    int rank(String g) {
      final i = _groupOrder.indexOf(g);
      if (i >= 0) return i;
      return g == '其他' ? 1 << 20 : _groupOrder.length;
    }

    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.compareTo(b);
  }

  /// 趋势页的项目名：尿、便检查的项目后面带上大项，脱离大项也认得出。
  static String _titleOf(LabResult r) =>
      SameItem.specimenOf(r.panelRaw) == null
          ? SameItem.itemName(r.itemNameRaw)
          : '${SameItem.itemName(r.itemNameRaw)}（${SameItem.panelGroup(r.panelRaw)}）';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = widget.services.records;
    final items = await records.labResultLatestPerItem();
    final names = await records.labItemNames();
    final groups = await records.labItemGroups();
    if (mounted) {
      setState(() {
        _items = items;
        _names = names;
        _itemGroups = groups;
      });
    }
  }

  /// 搜索：项目名、各报告里出现过的写法（含括号里的英文缩写）、检查大项，
  /// 不分大小写、忽略空白。
  bool _matches(LabResult r) {
    final q = _query.replaceAll(RegExp(r'\s'), '').toLowerCase();
    if (q.isEmpty) return true;
    return [
      _titleOf(r),
      r.itemKey,
      _groupOf(r),
      ...?_names[r.itemKey],
    ].any((t) => t.replaceAll(RegExp(r'\s'), '').toLowerCase().contains(q));
  }

  String _groupOf(LabResult r) =>
      _itemGroups[r.itemKey] ?? SameItem.trendGroup(r.panelRaw, r.itemKey);

  /// 按项目分组（[RecordRepository.labItemGroups]）：最近一次能认出分组的为准。
  List<MapEntry<String, List<LabResult>>> _groups() {
    final groups = <String, List<LabResult>>{};
    for (final r in _items.where(_matches)) {
      (groups[_groupOf(r)] ??= []).add(r);
    }
    return groups.entries.toList()
      ..sort((a, b) => _compareGroups(a.key, b.key));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    return Scaffold(
      appBar: AppBar(title: const Text('指标趋势')),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                '还没有检验数据\n在病例夹或体检里提取检查报告后，这里能看每项指标的历史变化',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: useCupertino(context)
                    ? CupertinoSearchTextField(
                        placeholder: '搜索项目、缩写或大项',
                        onChanged: (v) => setState(() => _query = v),
                      )
                    : TextField(
                        decoration: const InputDecoration(
                          hintText: '搜索项目、缩写或大项',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
              ),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('没有找到"${_query.trim()}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                ),
              for (final group in groups)
                ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(group.key,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                  for (final r in group.value) ...[
                    ListTile(
                      title: Text(SameItem.itemName(r.itemNameRaw)),
                      subtitle: Text(
                          '最近 ${r.valueRaw}${r.unitRaw ?? ''} · ${r.examDate ?? '日期未知'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _TrendDetailPage(
                              services: widget.services,
                              itemKey: r.itemKey,
                              itemName: _titleOf(r)),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ],
            ]),
    );
  }
}

class _TrendDetailPage extends StatefulWidget {
  const _TrendDetailPage(
      {required this.services, required this.itemKey, required this.itemName});

  final AppServices services;
  final String itemKey;
  final String itemName;

  @override
  State<_TrendDetailPage> createState() => _TrendDetailPageState();
}

class _TrendDetailPageState extends State<_TrendDetailPage> {
  List<LabResult> _history = [];

  @override
  void initState() {
    super.initState();
    widget.services.records.labResultHistory(widget.itemKey).then((rows) {
      if (mounted) setState(() => _history = rows);
    });
  }

  @override
  Widget build(BuildContext context) {
    final numeric = _history.where((r) => r.valueNum != null).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemName)),
      body: ListView(
        children: [
          if (numeric.length >= 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _TrendChartPainter(
                    points: numeric,
                    lineColor: Theme.of(context).colorScheme.primary,
                    bandColor: Colors.green.withValues(alpha: 0.12),
                    textStyle: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('数值点不足两个，暂不画趋势线',
                  style: TextStyle(color: Colors.grey)),
            ),
          const Divider(),
          for (final r in _history.reversed)
            ListTile(
              dense: true,
              title: Text('${r.valueRaw} ${r.unitRaw ?? ''}'),
              subtitle: Text([
                r.examDate ?? '日期未知',
                if (r.refRangeRaw != null) '参考 ${r.refRangeRaw}',
              ].join(' · ')),
              trailing: Text(
                [
                  if (r.flagRaw != null) r.flagRaw!,
                  if (r.reviewStatus == ReviewStatus.unreviewed) '未核对',
                ].join(' '),
                style: TextStyle(
                    fontSize: 11,
                    color:
                        r.flagRaw != null ? Colors.orange : Colors.grey),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('空心点表示该次数值还未核对。绿色区域是最近一次报告的参考范围。',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

/// 简单折线图：x 按次序均匀分布（检查间隔不均，等距更可读），
/// y 覆盖数值与参考范围；参考范围画色带；未核对的点画空心。
class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.points,
    required this.lineColor,
    required this.bandColor,
    required this.textStyle,
  });

  final List<LabResult> points;
  final Color lineColor;
  final Color bandColor;
  final TextStyle textStyle;

  static const _padLeft = 40.0, _padRight = 12.0, _padTop = 12.0, _padBottom = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _padLeft - _padRight;
    final h = size.height - _padTop - _padBottom;

    final values = [for (final p in points) p.valueNum!];
    final last = points.last;
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (last.refLow != null) lo = lo < last.refLow! ? lo : last.refLow!;
    if (last.refHigh != null) hi = hi > last.refHigh! ? hi : last.refHigh!;
    if (hi == lo) hi = lo + 1;
    final span = (hi - lo) * 1.15;
    final base = lo - (hi - lo) * 0.075;

    double x(int i) =>
        _padLeft + (points.length == 1 ? w / 2 : w * i / (points.length - 1));
    double y(double v) => _padTop + h - (v - base) / span * h;

    // 参考范围色带（取最近一次报告的范围）。
    if (last.refLow != null && last.refHigh != null) {
      canvas.drawRect(
        Rect.fromLTRB(_padLeft, y(last.refHigh!), _padLeft + w, y(last.refLow!)),
        Paint()..color = bandColor,
      );
    }

    // 折线。
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(path, line);

    // 数据点：已核对实心，未核对空心。
    for (var i = 0; i < points.length; i++) {
      final reviewed = points[i].reviewStatus != ReviewStatus.unreviewed;
      final center = Offset(x(i), y(values[i]));
      if (reviewed) {
        canvas.drawCircle(center, 4, Paint()..color = lineColor);
      } else {
        canvas.drawCircle(center, 4, Paint()..color = Colors.white);
        canvas.drawCircle(
            center,
            4,
            Paint()
              ..color = lineColor
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke);
      }
    }

    // y 轴上下值、x 轴首末日期。
    void label(String text, Offset offset, {TextAlign align = TextAlign.left}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout();
      tp.paint(canvas, offset);
    }

    label(_fmt(hi), Offset(0, y(hi) - 6));
    label(_fmt(lo), Offset(0, y(lo) - 6));
    label(points.first.examDate ?? '', Offset(_padLeft, size.height - 16));
    final lastDate = points.last.examDate ?? '';
    final tp = TextPainter(
      text: TextSpan(text: lastDate, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(size.width - _padRight - tp.width, size.height - 16));
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.points != points;
}
