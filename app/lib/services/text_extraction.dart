import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'app_log.dart';

/// 一行识别出的文字及其在页面中的归一化区域（0–1，原点左上）。
/// PDF 文字层直取的行没有坐标（box 为 null），locator 用页码+文字片段。
class OcrLine {
  const OcrLine({required this.text, this.x, this.y, this.w, this.h});

  final String text;
  final double? x, y, w, h;

  bool get hasBox => x != null && y != null && w != null && h != null;

  Map<String, Object?> toJson() => {
        'text': text,
        if (hasBox) 'x': x,
        if (hasBox) 'y': y,
        if (hasBox) 'w': w,
        if (hasBox) 'h': h,
      };

  static OcrLine fromJson(Map<String, Object?> json) => OcrLine(
        text: json['text'] as String,
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        w: (json['w'] as num?)?.toDouble(),
        h: (json['h'] as num?)?.toDouble(),
      );
}

/// 提取来源：PDF 文字层直取（零识别误差）或本地 OCR（D-23）。
enum PageTextSource { pdfText, ocr }

/// 一页的提取结果。pageNo 从 1 开始，对应 medical_documents.pages 的页序。
class ExtractedPage {
  const ExtractedPage(
      {required this.pageNo, required this.source, required this.lines});

  final int pageNo;
  final PageTextSource source;
  final List<OcrLine> lines;

  String get plainText => lines.map((l) => l.text).join('\n');

  Map<String, Object?> toJson() => {
        'page_no': pageNo,
        'source': source.name,
        'lines': [for (final l in lines) l.toJson()],
      };

  static ExtractedPage fromJson(Map<String, Object?> json) => ExtractedPage(
        pageNo: json['page_no'] as int,
        source: PageTextSource.values.byName(json['source'] as String),
        lines: [
          for (final l in json['lines'] as List)
            OcrLine.fromJson((l as Map).cast<String, Object?>()),
        ],
      );
}

/// 底层文字提取能力。真实实现走 platform channel（Apple Vision + PDFKit），
/// 测试用假实现（native 侧无法进 flutter test，只能真机/本机验证）。
abstract class TextExtractor {
  /// PDF 页数；打不开时抛异常。
  Future<int> pdfPageCount(String path);

  /// 某页的文字层文本（0 起页号）；没有文字层时返回 null 或空串。
  Future<String?> pdfPageText(String path, int pageIndex);

  /// 把某页渲染成 PNG 供 OCR，返回输出文件路径。
  Future<String> renderPdfPage(String path, int pageIndex, String outPath);

  /// 对一张图片做本地 OCR，返回行与归一化坐标。
  Future<List<OcrLine>> ocrImage(String path);
}

/// platform channel 实现：iOS / macOS 侧用 PDFKit + Vision（D-23）。
class PlatformTextExtractor implements TextExtractor {
  static const _channel = MethodChannel('life.long/medical_text');

  @override
  Future<int> pdfPageCount(String path) async =>
      (await _channel.invokeMethod<int>('pdfPageCount', {'path': path}))!;

  @override
  Future<String?> pdfPageText(String path, int pageIndex) =>
      _channel.invokeMethod<String>(
          'pdfPageText', {'path': path, 'page': pageIndex});

  @override
  Future<String> renderPdfPage(
          String path, int pageIndex, String outPath) async =>
      (await _channel.invokeMethod<String>('renderPdfPage',
          {'path': path, 'page': pageIndex, 'outPath': outPath}))!;

  @override
  Future<List<OcrLine>> ocrImage(String path) async {
    final raw =
        await _channel.invokeMethod<List<Object?>>('ocrImage', {'path': path});
    return [
      for (final e in raw!)
        OcrLine.fromJson((e as Map).cast<String, Object?>()),
    ];
  }
}

/// 提取管线（D-23 第一段）：PDF 先探测文字层，有就直取；扫描件 PDF 逐页
/// 渲染成图与照片同路径走 OCR。结果按附件哈希写 sidecar 缓存——OCR 输出
/// 是原始层的派生缓存，不算事实、不入库、不同步，删了可重算。
class TextExtractionService {
  TextExtractionService({
    required TextExtractor extractor,
    required Directory cacheDir,
  })  : _extractor = extractor,
        _cacheDir = cacheDir;

  final TextExtractor _extractor;
  final Directory _cacheDir;

  /// 文字层短于这个字数按"没有文字层"处理（扫描件常带少量水印文字）。
  static const minTextLayerChars = 20;

  File _cacheFile(String sha256) =>
      File(p.join(_cacheDir.path, '$sha256.extract.json'));

  /// 提取一个附件的全部页。[sha256] 是附件内容哈希（缓存键）；
  /// [mimeType] 决定走 PDF 分流还是图片 OCR。
  Future<List<ExtractedPage>> extract({
    required String sha256,
    required File file,
    required String mimeType,
  }) async {
    final cached = await readCache(sha256);
    if (cached != null) return cached;

    final pages = mimeType == 'application/pdf'
        ? await _extractPdf(file.path)
        : [
            ExtractedPage(
              pageNo: 1,
              source: PageTextSource.ocr,
              lines: await _extractor.ocrImage(file.path),
            ),
          ];
    await _writeCache(sha256, pages);
    return pages;
  }

  Future<List<ExtractedPage>> _extractPdf(String path) async {
    final count = await _extractor.pdfPageCount(path);
    final pages = <ExtractedPage>[];
    for (var i = 0; i < count; i++) {
      final text = await _extractor.pdfPageText(path, i);
      if (text != null && text.trim().length >= minTextLayerChars) {
        // 文字层直取：按行切开，无坐标（locator 用页码+文字片段）。
        pages.add(ExtractedPage(
          pageNo: i + 1,
          source: PageTextSource.pdfText,
          lines: [
            for (final line in const LineSplitter().convert(text))
              if (line.trim().isNotEmpty) OcrLine(text: line.trim()),
          ],
        ));
        continue;
      }
      // 扫描页：渲染成图走 OCR，临时图用后即删。
      final tmp = p.join(
          Directory.systemTemp.path, 'pdf_ocr_${DateTime.now().microsecondsSinceEpoch}_$i.png');
      try {
        await _extractor.renderPdfPage(path, i, tmp);
        pages.add(ExtractedPage(
          pageNo: i + 1,
          source: PageTextSource.ocr,
          lines: await _extractor.ocrImage(tmp),
        ));
      } finally {
        final f = File(tmp);
        if (await f.exists()) await f.delete();
      }
    }
    return pages;
  }

  /// 读缓存；没有或损坏返回 null（损坏就删掉重算）。
  Future<List<ExtractedPage>?> readCache(String sha256) async {
    final f = _cacheFile(sha256);
    if (!await f.exists()) return null;
    try {
      final json = jsonDecode(await f.readAsString()) as List;
      return [
        for (final e in json)
          ExtractedPage.fromJson((e as Map).cast<String, Object?>()),
      ];
    } catch (e) {
      AppLog.I.w('extract', '提取缓存损坏，删除重算：$sha256（$e）');
      await f.delete();
      return null;
    }
  }

  Future<void> _writeCache(String sha256, List<ExtractedPage> pages) async {
    await _cacheDir.create(recursive: true);
    await _cacheFile(sha256)
        .writeAsString(jsonEncode([for (final p in pages) p.toJson()]));
  }

  /// 清掉一个附件的提取缓存（原件清理时随手清，可重算）。
  Future<void> evict(String sha256) async {
    final f = _cacheFile(sha256);
    if (await f.exists()) await f.delete();
  }
}
