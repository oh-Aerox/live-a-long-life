import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/body_map.dart';
import 'adaptive.dart';
import 'body_map_points.dart';
import 'medical_document_page.dart';
import 'record_detail_page.dart';
import 'source_viewer_page.dart';

/// 人体图（D-31）：全身 → 点分区放大 → 两侧标签用指引线指到器官 →
/// 点标签看需要关注的内容 → 跳到原文件。
class BodyMapPage extends StatefulWidget {
  const BodyMapPage({super.key, required this.services, this.previewData});

  final AppServices? services;

  /// 测试与截图用：直接给数据，不读库。
  @visibleForTesting
  final BodyMapData? previewData;

  @override
  State<BodyMapPage> createState() => _BodyMapPageState();
}

/// 图片的一次摆放：以全身视图为基准，先缩放再平移。
class _View {
  const _View(this.scale, this.shift);

  final double scale;
  final Offset shift;

  Offset apply(Offset p) => p * scale + shift;
  Rect applyRect(Rect r) =>
      Rect.fromPoints(apply(r.topLeft), apply(r.bottomRight));

  static _View lerp(_View a, _View b, double t) => _View(
      a.scale + (b.scale - a.scale) * t, Offset.lerp(a.shift, b.shift, t)!);
}

/// 一个标签：锚点（屏幕坐标）、放左边还是右边、显示什么。
class _Label {
  _Label({
    required this.id,
    required this.name,
    required this.anchor,
    required this.onLeft,
    required this.findings,
  });

  final String id;
  final String name;
  final Offset anchor;
  final bool onLeft;
  final List<BodyFinding> findings;
  double top = 0;
}

const _labelWidth = 86.0;
const _labelHeight = 32.0;
const _labelGap = 8.0;
const _edge = 10.0;

Color _statusColor(BuildContext context, List<BodyFinding> fs) {
  if (fs.any((f) => f.reviewed)) return Colors.red.shade400;
  if (fs.isNotEmpty) return Colors.orange.shade600;
  return Theme.of(context).colorScheme.outline;
}

class _BodyMapPageState extends State<BodyMapPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  BodyMapData? _data;
  BodySex? _sex;
  BodyRegion? _region;
  BodyRegion? _fromRegion;
  bool _calibrating = false;
  Offset? _lastTap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = widget.services;
    final data = widget.previewData ??
        await BodyMapService(records: s!.records, profile: s.profile).load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _sex ??= data.sex ?? BodySex.male;
    });
  }

  BodyFigure get _figure => figureFor(_sex ?? BodySex.male);

  void _zoomTo(BodyRegion? region) {
    if (region == _region) return;
    setState(() {
      _fromRegion = _region;
      _region = region;
    });
    _zoom.forward(from: 0);
  }

  /// 全身视图下图片在舞台上的位置：居中。图片两侧是手臂，标签压在手臂
  /// 外缘也不挡器官，所以不必给标签单独留宽度。
  Rect _baseRect(Size size) {
    final w = math.min(size.width * 0.86, size.height * 0.96 * BodyFigure.aspect);
    final h = w / BodyFigure.aspect;
    return Rect.fromLTWH(
        (size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  _View _viewFor(Size size, Rect base, BodyRegion? region) {
    if (region == null) return const _View(1, Offset.zero);
    final r = _figure.regions[region]!;
    final rect = Rect.fromLTRB(
      base.left + r.left * base.width,
      base.top + r.top * base.height,
      base.left + r.right * base.width,
      base.top + r.bottom * base.height,
    );
    // 分区放大到舞台中间约六成宽，两侧给标签。
    final scale = math
        .min(size.width * 0.62 / rect.width, size.height * 0.92 / rect.height)
        .clamp(1.0, 4.0);
    final center = size.center(Offset.zero);
    return _View(scale, center - rect.center * scale);
  }

  Offset _pointOf(Rect base, BodyPoint p) =>
      Offset(base.left + p.x * base.width, base.top + p.y * base.height);

  bool _organVisible(Organ o) {
    if (!_figure.points.containsKey(o.id)) return false;
    return o.sex == null ||
        o.sex == _sex ||
        (_data?.of(o.id).isNotEmpty ?? false);
  }

  Iterable<Organ> _organsIn(BodyRegion r) =>
      organs.where((o) => o.region == r && _organVisible(o));

  List<_Label> _labels(Rect base, _View view) {
    final data = _data;
    if (data == null) return [];
    final region = _region;
    if (region == null) {
      // 全身：每个分区一个标签，指向分区中心。
      const leftSide = {BodyRegion.chest, BodyRegion.pelvis};
      return [
        for (final r in BodyRegion.values)
          _Label(
            id: r.name,
            name: regionNames[r]!,
            anchor: view.apply(_pointOf(
                base,
                BodyPoint(_figure.regions[r]!.center.dx,
                    _figure.regions[r]!.center.dy))),
            onLeft: leftSide.contains(r),
            findings: [
              for (final o in _organsIn(r)) ...data.of(o.id),
            ],
          ),
      ];
    }
    return [
      for (final o in _organsIn(region))
        _Label(
          id: o.id,
          name: o.name,
          anchor: view.apply(_pointOf(base, _figure.points[o.id]!)),
          onLeft: _figure.points[o.id]!.labelOnLeft,
          findings: data.of(o.id),
        ),
    ];
  }

  /// 同一侧的标签按锚点高度排开，互不重叠，也不超出舞台。
  void _layout(List<_Label> labels, double height) {
    for (final left in [true, false]) {
      final side = labels.where((l) => l.onLeft == left).toList()
        ..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
      var y = _edge;
      for (final l in side) {
        l.top = math.max(l.anchor.dy - _labelHeight / 2, y);
        y = l.top + _labelHeight + _labelGap;
      }
      var limit = height - _edge - _labelHeight;
      for (final l in side.reversed) {
        l.top = math.min(l.top, limit);
        limit = l.top - _labelHeight - _labelGap;
      }
    }
  }

  void _onStageTap(Offset pos, Rect base, _View view) {
    final img = view.applyRect(base);
    final nx = (pos.dx - img.left) / img.width;
    final ny = (pos.dy - img.top) / img.height;
    if (_calibrating) {
      debugPrint('人体图点位 x: ${nx.toStringAsFixed(3)}, '
          'y: ${ny.toStringAsFixed(3)}');
      setState(() => _lastTap = Offset(nx, ny));
      return;
    }
    if (_region != null) {
      // 放大后点在器官点位附近也能打开。
      for (final o in _organsIn(_region!)) {
        final p = view.apply(_pointOf(base, _figure.points[o.id]!));
        if ((p - pos).distance < 24) {
          _openOrgan(o.id, o.name);
          return;
        }
      }
      return;
    }
    final hits = BodyRegion.values
        .where((r) => _figure.regions[r]!.contains(Offset(nx, ny)))
        .toList()
      ..sort((a, b) => (_figure.regions[a]!.center - Offset(nx, ny))
          .distance
          .compareTo((_figure.regions[b]!.center - Offset(nx, ny)).distance));
    if (hits.isNotEmpty) _zoomTo(hits.first);
  }

  Future<void> _openOrgan(String id, String name) async {
    final data = _data;
    if (data == null) return;
    final picked = await showModalBottomSheet<(bool, BodyFinding)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FindingsSheet(name: name, findings: data.of(id)),
    );
    if (picked == null || !mounted) return;
    final (source, f) = picked;
    final s = widget.services;
    if (s == null) return;
    final Widget page;
    if (source && f.locator != null) {
      page = SourceViewerPage(services: s, locator: f.locator!, title: name);
    } else if (f.medicalDocumentId != null) {
      page = MedicalDocumentPage(services: s, documentId: f.medicalDocumentId!);
    } else {
      page = RecordDetailPage(services: s, recordId: f.recordId);
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // 可能在原文件里核对过，回来重算。
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final sex = _sex ?? BodySex.male;
    return PopScope(
      canPop: _region == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _zoomTo(null);
      },
      child: Scaffold(
        appBar: adaptiveAppBar(
          context,
          title: Text(_region == null ? '人体图' : regionNames[_region]!),
          actions: [
            if (kDebugMode)
              NavAction(
                icon: _calibrating ? Icons.gps_fixed : Icons.gps_not_fixed,
                cupertinoIcon:
                    _calibrating ? CupertinoIcons.scope : CupertinoIcons.circle,
                tooltip: _calibrating ? '退出标点位' : '标点位',
                onPressed: () => setState(() {
                  _calibrating = !_calibrating;
                  _lastTap = null;
                }),
              ),
            NavAction(
              icon: sex == BodySex.male ? Icons.female : Icons.male,
              cupertinoIcon: sex == BodySex.male ? Icons.female : Icons.male,
              tooltip: sex == BodySex.male ? '切换为女性图' : '切换为男性图',
              onPressed: () => setState(() => _sex =
                  sex == BodySex.male ? BodySex.female : BodySex.male),
            ),
          ],
        ),
        body: _data == null
            ? const Center(child: CircularProgressIndicator.adaptive())
            : Column(
                children: [
                  Expanded(child: _buildStage(context)),
                  _buildFooter(context),
                ],
              ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = c.biggest;
      final base = _baseRect(size);
      final from = _viewFor(size, base, _fromRegion);
      final to = _viewFor(size, base, _region);
      return AnimatedBuilder(
        animation: _zoom,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_zoom.value);
          final view = _View.lerp(from, to, t);
          final settled = !_zoom.isAnimating;
          final labels = settled ? _labels(base, view) : <_Label>[];
          _layout(labels, size.height);
          final lines = [
            for (final l in labels)
              (
                Offset(l.onLeft ? _edge + _labelWidth : size.width - _edge - _labelWidth,
                    l.top + _labelHeight / 2),
                l.anchor,
                _statusColor(context, l.findings),
              ),
          ];
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onStageTap(d.localPosition, base, view),
                  ),
                ),
                Positioned.fromRect(
                  rect: view.applyRect(base),
                  child: IgnorePointer(
                    child: Image.asset(_figure.asset,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: size,
                    painter: _LinesPainter(
                      lines,
                      calibrationPoints: _calibrating
                          ? [
                              for (final p in _figure.points.values)
                                view.apply(_pointOf(base, p)),
                            ]
                          : const [],
                    ),
                  ),
                ),
                for (final l in labels)
                  Positioned(
                    left: l.onLeft ? _edge : size.width - _edge - _labelWidth,
                    top: l.top,
                    width: _labelWidth,
                    height: _labelHeight,
                    child: _LabelChip(
                      label: l,
                      onTap: () => _region == null
                          ? _zoomTo(BodyRegion.values.byName(l.id))
                          : _openOrgan(l.id, l.name),
                    ),
                  ),
                if (_calibrating && _lastTap != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        color: Colors.black87,
                        child: Text(
                          'x: ${_lastTap!.dx.toStringAsFixed(3)}  '
                          'y: ${_lastTap!.dy.toStringAsFixed(3)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildFooter(BuildContext context) {
    final data = _data!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (final id in [bloodOrganId, otherOrganId]) ...[
                  Expanded(
                    child: _ExtraChip(
                      name: extraOrganNames[id]!,
                      findings: data.of(id),
                      onTap: () => _openOrgan(id, extraOrganNames[id]!),
                    ),
                  ),
                  if (id == bloodOrganId) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Dot(color: Colors.red.shade400),
                Text(' 需关注   ', style: TextStyle(fontSize: 12, color: muted)),
                _Dot(color: Colors.orange.shade600),
                Text(' 待核对   ', style: TextStyle(fontSize: 12, color: muted)),
                Text(
                    _region == null
                        ? '点身体部位放大'
                        : '点标签查看 · 返回键回到全身',
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.lines, {this.calibrationPoints = const []});

  final List<(Offset, Offset, Color)> lines;
  final List<Offset> calibrationPoints;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (from, to, color) in lines) {
      final line = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      // 标签边出来先走一小段水平线，再斜向指到器官。
      final knee = Offset(from.dx + (to.dx > from.dx ? 10 : -10), from.dy);
      canvas.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..lineTo(knee.dx, knee.dy)
            ..lineTo(to.dx, to.dy),
          line);
      canvas.drawCircle(to, 5, Paint()..color = Colors.white);
      canvas.drawCircle(to, 3.5, Paint()..color = color);
    }
    for (final p in calibrationPoints) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.purple);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => true;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.findings});

  final List<BodyFinding> findings;

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _statusColor(context, findings),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text('${findings.length}',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.onTap});

  final _Label label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(context, label.findings);
    return Semantics(
      button: true,
      label: label.findings.isEmpty
          ? label.name
          : '${label.name}，${label.findings.length} 条需要关注',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(_labelHeight / 2),
            border: Border.all(
                color: label.findings.isEmpty
                    ? cs.outlineVariant
                    : color.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(label.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: cs.onSurface)),
              ),
              _Badge(findings: label.findings),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraChip extends StatelessWidget {
  const _ExtraChip(
      {required this.name, required this.findings, required this.onTap});

  final String name;
  final List<BodyFinding> findings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                  child: Text(name,
                      style: TextStyle(fontSize: 14, color: cs.onSurface))),
              _Badge(findings: findings),
              Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

const _kindLabels = {
  BodyFindingKind.lab: '检验',
  BodyFindingKind.finding: '报告文字',
  BodyFindingKind.condition: '身体状况',
  BodyFindingKind.symptom: '自述不适',
};

const _kindIcons = {
  BodyFindingKind.lab: Icons.science_outlined,
  BodyFindingKind.finding: Icons.description_outlined,
  BodyFindingKind.condition: Icons.healing_outlined,
  BodyFindingKind.symptom: Icons.sick_outlined,
};

/// 点标签弹出的浮层：这个器官需要关注的内容。选中一条返回
/// (是否看原件, 这一条)，由页面负责跳转。
class _FindingsSheet extends StatelessWidget {
  const _FindingsSheet({required this.name, required this.findings});

  final String name;
  final List<BodyFinding> findings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: findings.length > 3 ? 0.6 : 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          if (findings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                '没有需要关注的记录。\n检验数值异常、报告里的异常描述、身体状况，'
                '以及近 30 天的身体不适会显示在这里。',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
              ),
            ),
          for (final f in findings)
            ListTile(
              leading: Icon(_kindIcons[f.kind],
                  color: _statusColor(context, [f])),
              title: Text(f.title),
              subtitle: Text([
                _kindLabels[f.kind]!,
                if (f.date != null) f.date!,
                if (!f.reviewed) '待核对',
                if (f.detail != null && f.detail!.isNotEmpty) f.detail!,
              ].join(' · ')),
              trailing: f.locator == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.image_search_outlined),
                      tooltip: '看原件',
                      onPressed: () => Navigator.pop(context, (true, f)),
                    ),
              onTap: () => Navigator.pop(context, (false, f)),
            ),
        ],
      ),
    );
  }
}
