import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'adaptive.dart';

/// 裁剪结果：只在内存里交给识图调用，不落库（D-24）。
class CropResult {
  const CropResult({
    required this.png,
    required this.width,
    required this.height,
    this.cropBox,
  });

  final Uint8List png;
  final int width;
  final int height;

  /// 相对原页的归一化区域；null = 整页。
  final Map<String, double>? cropBox;
}

/// 识图前的裁剪（V4-M3，D-24）：提示用户裁掉姓名、证件号等区域，在图上
/// 拖动框出要识别的部分。可以跳过裁剪发整页，但先确认风险。应用内不做
/// 打码；原图不改，裁剪图只用于这一次发送。
class MedicalCropPage extends StatefulWidget {
  const MedicalCropPage({super.key, required this.bytes, required this.title});

  final Uint8List bytes;
  final String title;

  @override
  State<MedicalCropPage> createState() => _MedicalCropPageState();
}

class _MedicalCropPageState extends State<MedicalCropPage> {
  /// 发送图片长边上限：足够看清检验单，又不把 4000 万像素原图整张发出去。
  static const _maxSide = 2048.0;

  ui.Image? _image;
  String? _error;

  /// 归一化选区（0～1，相对原图）。
  Rect? _sel;
  Offset? _dragStart;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    decodeImageFromList(widget.bytes).then((img) {
      if (mounted) setState(() => _image = img);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = '图片打不开：$e');
    });
  }

  /// 图片在画布里按"完整显示"摆放的区域。
  Rect _fit(Size box, ui.Image img) {
    final scale = math.min(box.width / img.width, box.height / img.height);
    final w = img.width * scale, h = img.height * scale;
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  Offset _toNorm(Offset local, Rect shown) => Offset(
        ((local.dx - shown.left) / shown.width).clamp(0.0, 1.0),
        ((local.dy - shown.top) / shown.height).clamp(0.0, 1.0),
      );

  Future<CropResult> _render(Rect? sel) async {
    final img = _image!;
    final w = img.width.toDouble(), h = img.height.toDouble();
    final src = sel == null
        ? Rect.fromLTWH(0, 0, w, h)
        : Rect.fromLTRB(sel.left * w, sel.top * h, sel.right * w, sel.bottom * h);
    final scale = math.min(1.0, _maxSide / math.max(src.width, src.height));
    final outW = math.max(1, (src.width * scale).round());
    final outH = math.max(1, (src.height * scale).round());
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      img,
      src,
      Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(outW, outH);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    return CropResult(
      png: data!.buffer.asUint8List(),
      width: outW,
      height: outH,
      cropBox: sel == null
          ? null
          : {'x': sel.left, 'y': sel.top, 'w': sel.width, 'h': sel.height},
    );
  }

  Future<void> _sendSelection() async {
    setState(() => _busy = true);
    final result = await _render(_sel);
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _sendWhole() async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('发送整页？'),
        content: const Text('整页图片可能带着姓名、证件号、门诊卡号等个人信息，'
            '会一起发给模型。有些报告姓名和指标混在一起裁不开，可以整页发送，'
            '但建议先试着框出需要识别的部分。'),
        actions: [
          DialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('回去框选')),
          DialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('仍然发送整页')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _render(null);
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    final sel = _sel;
    final validSel = sel != null && sel.width > 0.02 && sel.height > 0.02;
    return Scaffold(
      appBar: AppBar(title: Text('裁剪后识图 · ${widget.title}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            child: const Text(
              '在图上拖动，框出要识别的部分，把姓名、证件号、门诊卡号所在的区域留在框外。'
              '只有框里的图片会发给模型，原图不变，裁剪图用完即弃。',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : img == null
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : LayoutBuilder(builder: (context, c) {
                        final shown = _fit(c.biggest, img);
                        return GestureDetector(
                          onPanStart: _busy
                              ? null
                              : (d) {
                                  _dragStart = _toNorm(d.localPosition, shown);
                                  setState(() => _sel = null);
                                },
                          onPanUpdate: _busy
                              ? null
                              : (d) {
                                  final start = _dragStart;
                                  if (start == null) return;
                                  setState(() => _sel = Rect.fromPoints(
                                      start, _toNorm(d.localPosition, shown)));
                                },
                          child: CustomPaint(
                            size: c.biggest,
                            painter: _CropPainter(img, shown, sel),
                          ),
                        );
                      }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _busy || img == null ? null : _sendWhole,
                    child: const Text('不裁剪，发送整页'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _busy || !validSel ? null : _sendSelection,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('发送框选的部分'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.shown, this.sel);

  final ui.Image image;
  final Rect shown;
  final Rect? sel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      shown,
      Paint()..filterQuality = FilterQuality.medium,
    );
    final s = sel;
    if (s == null) return;
    final r = Rect.fromLTRB(
      shown.left + s.left * shown.width,
      shown.top + s.top * shown.height,
      shown.left + s.right * shown.width,
      shown.top + s.bottom * shown.height,
    );
    // 框外压暗，框内保持原样：一眼看清哪些会被发出去。
    final outside = Path()
      ..addRect(shown)
      ..addRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = const Color(0x99000000));
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4CAF50),
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.sel != sel || old.shown != shown;
}
