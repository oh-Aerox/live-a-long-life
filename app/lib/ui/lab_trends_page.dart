import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/field_meta.dart';

/// 指标趋势（v0.4，数据源是 lab_results 索引，D-27）。
/// 列表页：出现过的检验项目 + 最近数值；点进去看历史折线。
class LabTrendsPage extends StatefulWidget {
  const LabTrendsPage({super.key, required this.services});

  final AppServices services;

  @override
  State<LabTrendsPage> createState() => _LabTrendsPageState();
}

class _LabTrendsPageState extends State<LabTrendsPage> {
  List<LabResult> _items = [];

  @override
  void initState() {
    super.initState();
    widget.services.records.labResultLatestPerItem().then((items) {
      if (mounted) setState(() => _items = items);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _items[i];
                return ListTile(
                  title: Text(r.itemNameRaw),
                  subtitle: Text(
                      '最近 ${r.valueRaw}${r.unitRaw ?? ''} · ${r.examDate ?? '日期未知'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TrendDetailPage(
                          services: widget.services,
                          itemKey: r.itemKey,
                          itemName: r.itemNameRaw),
                    ),
                  ),
                );
              },
            ),
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
