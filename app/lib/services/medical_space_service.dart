import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/medical_document_repository.dart';
import 'app_log.dart';
import 'sync/sync_service.dart';
import 'text_extraction.dart';

/// 一份可管理的医疗原件（按实际文件去重，A-34：多处引用只计一份占用）。
class MedicalFile {
  const MedicalFile({
    required this.attachment,
    required this.state,
    required this.byteSize,
    required this.referenceCount,
    required this.documentIds,
    required this.docLabel,
    required this.extracted,
    required this.reviewed,
    required this.archivedOnMac,
  });

  final Attachment attachment;
  final CopyState state;
  final int byteSize;

  /// 消息与医疗文件对它的引用总数（清理只删一个物理副本，引用全保留）。
  final int referenceCount;
  final List<String> documentIds;
  final String docLabel;

  /// 是否已提取出检验数据。
  final bool extracted;

  /// 提取出的项是否全部核对过（confirmed/edited）。
  final bool reviewed;

  /// Mac 是否已确认归档（依据：附件变更已被连续游标覆盖——变更确认
  /// 以文件本体校验为前提，schema §7.4）。
  final bool archivedOnMac;

  /// 默认勾选：已提取、已核对、Mac 已归档（D-22 的默认批量选择）。
  bool get defaultSelected =>
      state == CopyState.present && extracted && reviewed && archivedOnMac;
}

class CleanupResult {
  const CleanupResult({required this.freedBytes, required this.failures});

  final int freedBytes;
  final Map<String, String> failures; // attachmentId → 原因
}

/// 医疗文件空间管理（V4-M5，D-22/schema §8）：列出、清理、取回。
/// 只处理医疗文件引用的附件；清理只删本机文件副本，事实与索引不动。
class MedicalSpaceService {
  MedicalSpaceService({
    required AppDatabase db,
    required AttachmentRepository attachments,
    required MedicalDocumentRepository documents,
    required SyncService sync,
    required TextExtractionService extraction,
  })  : _db = db,
        _attachments = attachments,
        _documents = documents,
        _sync = sync,
        _extraction = extraction;

  final AppDatabase _db;
  final AttachmentRepository _attachments;
  final MedicalDocumentRepository _documents;
  final SyncService _sync;
  final TextExtractionService _extraction;

  /// 全部医疗原件，按文件去重（A-34），大文件在前。
  Future<List<MedicalFile>> list() async {
    // 附件 → 引用它的医疗文件。
    final docsByAttachment = <String, List<MedicalDocument>>{};
    for (final doc in await _documents.all()) {
      for (final ref in MedicalPageRef.decodeList(doc.pages)) {
        docsByAttachment.putIfAbsent(ref.attachmentId, () => []).add(doc);
      }
    }
    if (docsByAttachment.isEmpty) return [];

    // Mac 已确认的连续游标（没有配对/没同步过则视为未归档）。
    final pushStates = await (_db.select(_db.syncStates)
          ..where((t) => t.direction.equalsValue(SyncDirection.push)))
        .get();
    final acked = pushStates.isEmpty
        ? -1
        : pushStates
            .map((s) => s.ackedContiguousSeq)
            .reduce((a, b) => a > b ? a : b);

    final out = <MedicalFile>[];
    for (final entry in docsByAttachment.entries) {
      final att = await _attachments.byId(entry.key);
      if (att == null) continue;
      final state = await _attachments.copyStateOf(att.id);
      final messageRefs =
          (await _attachments.messageIdsReferencing(att.id)).length;

      // 提取与核对状态：看这些文件的检验索引行。
      var extracted = false;
      var reviewed = true;
      for (final doc in entry.value) {
        final rows = await (_db.select(_db.labResults)
              ..where((t) => t.medicalDocumentId.equals(doc.id)))
            .get();
        if (rows.isNotEmpty) extracted = true;
        if (rows.any((r) => r.reviewStatus == ReviewStatus.unreviewed)) {
          reviewed = false;
        }
      }
      if (!extracted) reviewed = false;

      out.add(MedicalFile(
        attachment: att,
        state: state,
        byteSize: att.byteSize,
        referenceCount: messageRefs + entry.value.length,
        documentIds: [for (final d in entry.value) d.id],
        docLabel: entry.value.map((d) => d.docType).toSet().length == 1
            ? entry.value.first.docType.name
            : 'mixed',
        extracted: extracted,
        reviewed: reviewed,
        archivedOnMac:
            att.changeSeq != null && acked >= 0 && att.changeSeq! <= acked,
      ));
    }
    out.sort((a, b) => b.byteSize.compareTo(a.byteSize));
    return out;
  }

  /// 清理所选文件的本机副本（D-22/A-36）：逐个删，删成功才计入释放；
  /// 未归档 Mac 的文件属于"正在传输/无已知副本"，调用方要先让用户明确
  /// 确认（这里不再拦，界面负责说明后果）。顺手清掉提取缓存（可重算）。
  Future<CleanupResult> cleanup(List<MedicalFile> files) async {
    var freed = 0;
    final failures = <String, String>{};
    for (final f in files) {
      try {
        freed += await _attachments.offloadCopy(f.attachment.id);
        await _extraction.evict(f.attachment.sha256);
      } catch (e) {
        failures[f.attachment.id] = '$e';
        AppLog.I.w('space', '清理失败 ${f.attachment.id}：$e');
      }
    }
    AppLog.I.i('space',
        '清理完成：释放 $freed 字节，失败 ${failures.length} 个');
    return CleanupResult(freedBytes: freed, failures: failures);
  }

  /// 从 Mac 取回一个原件（A-21）：哈希校验落盘、副本转 present、
  /// 沿用同一附件身份，不重复建档。Mac 不可达或没有时返回 false。
  Future<bool> retrieve(String attachmentId) async {
    final att = await _attachments.byId(attachmentId);
    if (att == null) return false;
    final path = await _sync.retrieveBlob(att.sha256);
    if (path == null) return false;
    await _attachments.markCopyPresent(att.id, att.sha256);
    AppLog.I.i('space', '取回原件成功：${att.sha256}');
    return true;
  }
}
