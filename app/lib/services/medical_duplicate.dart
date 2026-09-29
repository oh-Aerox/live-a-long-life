import 'dart:io';

import '../data/db/app_database.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/medical_document_repository.dart';
import 'text_extraction.dart';

/// 相似医疗文件命中：已有文件 + 两项相似度（界面提示用）。
class SimilarDocumentHit {
  const SimilarDocumentHit({
    required this.document,
    required this.textScore,
    required this.numberScore,
  });

  final MedicalDocument document;
  final double textScore;
  final double numberScore;
}

/// 医疗文件内容级重复检查（D-10 补充，2026-09-29）：同一张纸重拍一次、
/// 相册重新导出一次，字节和 SHA-256 都不同，按内容哈希认不出。这里比较
/// 本地识别出的文字：
/// - 文字包含度：去空白标点后的二字组，交集 / 较短一方，≥ [textThreshold]；
/// - 数字包含度：两位以上的数字（日期、时间、编号、数值）多重集，
///   交集 / 较少一方，≥ [numberThreshold]。
/// 两项都过才算"可能重复"。只看文字会把同一医院的定期复查（项目名、参考
/// 范围一样）误判成重复，数字（日期、编号、结果）把它们分开。
/// 只用于提示，用户可以"仍然添加"；附件身份仍按 SHA-256（schema §2.3）。
/// 识别结果按 SHA-256 缓存，导入后提取时直接复用，不会识别两遍。
class MedicalDuplicateService {
  MedicalDuplicateService({
    required AttachmentRepository attachments,
    required MedicalDocumentRepository documents,
    required TextExtractionService extraction,
  })  : _attachments = attachments,
        _documents = documents,
        _extraction = extraction;

  final AttachmentRepository _attachments;
  final MedicalDocumentRepository _documents;
  final TextExtractionService _extraction;

  /// 2026-09-29 真机样本：同一病历拍两次 0.95/0.94，截图与照片 0.84/1.00；
  /// 病历与检验单 0.14/0.41。
  static const textThreshold = 0.8;
  static const numberThreshold = 0.9;

  /// 文字太少（空白照片、只有标题）不做判断，避免误报。
  static const minChars = 50;

  /// 新文件（尚未导入）与已有医疗文件逐个附件比较，返回最像的一份。
  /// [excludeDocumentId] 用于给已有文件补页时排除自身。
  Future<SimilarDocumentHit?> findSimilar({
    required String sha256,
    required File file,
    required String mimeType,
    String? excludeDocumentId,
  }) async {
    final text = _joined(await _extraction.extract(
        sha256: sha256, file: file, mimeType: mimeType));
    if (normalize(text).length < minChars) return null;

    SimilarDocumentHit? best;
    for (final doc in await _documents.all()) {
      if (doc.id == excludeDocumentId) continue;
      for (final ref in MedicalPageRef.decodeList(doc.pages)) {
        final other = await _textOfAttachment(ref.attachmentId);
        if (other == null) continue;
        final t = textContainment(text, other);
        final n = numberContainment(text, other);
        if (t < textThreshold || n < numberThreshold) continue;
        if (best == null || t + n > best.textScore + best.numberScore) {
          best = SimilarDocumentHit(document: doc, textScore: t, numberScore: n);
        }
      }
    }
    return best;
  }

  /// 已登记附件的识别文字：优先缓存；原件已清理（D-22）且没缓存时跳过。
  Future<String?> _textOfAttachment(String attachmentId) async {
    final att = await _attachments.byId(attachmentId);
    if (att == null) return null;
    final cached = await _extraction.readCache(att.sha256);
    if (cached != null) return _joined(cached);
    final path = await _attachments.localPathOf(attachmentId);
    if (path == null) return null;
    try {
      return _joined(await _extraction.extract(
          sha256: att.sha256, file: File(path), mimeType: att.mimeType));
    } catch (_) {
      return null;
    }
  }

  static String _joined(List<ExtractedPage> pages) =>
      [for (final p in pages) p.plainText].join('\n');

  static String normalize(String text) =>
      text.replaceAll(RegExp(r'[\s\p{P}\p{S}]+', unicode: true), '');

  static Set<String> _bigrams(String text) {
    final t = normalize(text);
    return {for (var i = 0; i + 1 < t.length; i++) t.substring(i, i + 2)};
  }

  /// 二字组交集占较短一方的比例（一份是另一份的截取也算高）。
  static double textContainment(String a, String b) {
    final x = _bigrams(a), y = _bigrams(b);
    if (x.isEmpty || y.isEmpty) return 0;
    final shorter = x.length < y.length ? x : y;
    final longer = identical(shorter, x) ? y : x;
    return shorter.where(longer.contains).length / shorter.length;
  }

  static Map<String, int> _numbers(String text) {
    final counts = <String, int>{};
    for (final m in RegExp(r'\d+(?:\.\d+)?').allMatches(text)) {
      final v = m.group(0)!;
      if (v.length < 2) continue; // 单个数字（序号、个位数值）区分度太低
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts;
  }

  /// 数字多重集交集占较少一方的比例。两边都没有数字时不能区分，按 1。
  static double numberContainment(String a, String b) {
    final x = _numbers(a), y = _numbers(b);
    final nx = x.values.fold(0, (s, v) => s + v);
    final ny = y.values.fold(0, (s, v) => s + v);
    if (nx == 0 && ny == 0) return 1;
    if (nx == 0 || ny == 0) return 0;
    var inter = 0;
    x.forEach((k, v) {
      final w = y[k];
      if (w != null) inter += v < w ? v : w;
    });
    return inter / (nx < ny ? nx : ny);
  }
}
