import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/services/text_extraction.dart';

/// 假提取器：脚本化 PDF 文字层与 OCR 结果（Vision 只能真机/本机验证）。
class FakeExtractor implements TextExtractor {
  FakeExtractor({
    this.pageCount = 1,
    this.pageTexts = const {},
    this.ocrResults = const [],
  });

  final int pageCount;

  /// 页号（0 起）→ 文字层文本；缺的页当作没有文字层。
  final Map<int, String?> pageTexts;
  final List<OcrLine> ocrResults;

  final renderedPages = <int>[];
  final ocredPaths = <String>[];

  @override
  Future<int> pdfPageCount(String path) async => pageCount;

  @override
  Future<String?> pdfPageText(String path, int pageIndex) async =>
      pageTexts[pageIndex];

  @override
  Future<String> renderPdfPage(
      String path, int pageIndex, String outPath) async {
    renderedPages.add(pageIndex);
    await File(outPath).writeAsBytes([0]);
    return outPath;
  }

  @override
  Future<List<OcrLine>> ocrImage(String path) async {
    ocredPaths.add(path);
    return ocrResults;
  }
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('extract_test');
  });

  tearDown(() => tmp.delete(recursive: true));

  File dummyFile(String name) {
    final f = File('${tmp.path}/$name');
    f.writeAsBytesSync([1, 2, 3]);
    return f;
  }

  test('图片：走 OCR，坐标保留，结果落缓存（D-23）', () async {
    final fake = FakeExtractor(ocrResults: const [
      OcrLine(text: '血常规检验报告', x: 0.1, y: 0.05, w: 0.5, h: 0.04),
      OcrLine(text: '白细胞 6.2 10^9/L 3.5-9.5', x: 0.1, y: 0.2, w: 0.8, h: 0.03),
    ]);
    final service = TextExtractionService(
        extractor: fake, cacheDir: Directory('${tmp.path}/cache'));

    final pages = await service.extract(
        sha256: 'sha-img', file: dummyFile('a.jpg'), mimeType: 'image/jpeg');
    expect(pages.single.source, PageTextSource.ocr);
    expect(pages.single.lines[1].text, contains('白细胞'));
    expect(pages.single.lines[1].hasBox, isTrue);

    // 第二次直接读缓存，不再调用提取器。
    await service.extract(
        sha256: 'sha-img', file: dummyFile('a.jpg'), mimeType: 'image/jpeg');
    expect(fake.ocredPaths, hasLength(1));
  });

  test('PDF 分流：有文字层的页直取（零 OCR），扫描页渲染后 OCR', () async {
    final fake = FakeExtractor(
      pageCount: 3,
      pageTexts: {
        0: '某某体检中心检验报告\n项目 结果 单位 参考范围\n白细胞 6.2 10^9/L 3.5-9.5',
        1: '扫', // 短于阈值：按无文字层处理（扫描件水印）
        2: null,
      },
      ocrResults: const [OcrLine(text: '扫描页文字', x: 0.1, y: 0.1, w: 0.4, h: 0.05)],
    );
    final service = TextExtractionService(
        extractor: fake, cacheDir: Directory('${tmp.path}/cache'));

    final pages = await service.extract(
        sha256: 'sha-pdf',
        file: dummyFile('r.pdf'),
        mimeType: 'application/pdf');

    expect(pages, hasLength(3));
    expect(pages[0].source, PageTextSource.pdfText);
    expect(pages[0].lines, hasLength(3)); // 按行切开，空行丢弃
    expect(pages[0].lines[2].hasBox, isFalse); // 文字层无坐标
    expect(pages[1].source, PageTextSource.ocr);
    expect(pages[2].source, PageTextSource.ocr);
    expect(fake.renderedPages, [1, 2]); // 只渲染扫描页
    // OCR 临时图用后即删。
    expect(fake.ocredPaths.every((p) => !File(p).existsSync()), isTrue);
  });

  test('缓存损坏：删除重算而不是崩', () async {
    final cacheDir = Directory('${tmp.path}/cache');
    final fake = FakeExtractor(
        ocrResults: const [OcrLine(text: 'x', x: 0, y: 0, w: 1, h: 1)]);
    final service =
        TextExtractionService(extractor: fake, cacheDir: cacheDir);

    await cacheDir.create(recursive: true);
    await File('${cacheDir.path}/sha-bad.extract.json')
        .writeAsString('不是 JSON');

    final pages = await service.extract(
        sha256: 'sha-bad', file: dummyFile('b.png'), mimeType: 'image/png');
    expect(pages.single.lines.single.text, 'x');

    // 重算后的缓存可正常读回。
    final cached = await service.readCache('sha-bad');
    expect(cached!.single.lines.single.text, 'x');
    // 缓存是合法 JSON。
    final raw = await File('${cacheDir.path}/sha-bad.extract.json').readAsString();
    expect(jsonDecode(raw), isA<List<dynamic>>());

    await service.evict('sha-bad');
    expect(await service.readCache('sha-bad'), isNull);
  });
}
