import 'field_meta.dart';

/// 同一字段的一个候选值（schema §3.7）。
class FieldCandidate<T> {
  const FieldCandidate({
    required this.value,
    required this.origin,
    required this.reviewStatus,
    required this.effectiveAtMs,
  });

  final T value;
  final FieldOrigin origin;
  final ReviewStatus reviewStatus;

  /// 该值的生效时间：消息来源按消息 `sent_at`；用户手动编辑按记录版本
  /// `created_at`；设备值按 `fetched_at`（schema §3.7 第 3 条）。
  final int effectiveAtMs;

  /// D-07 的采用顺序，数字越小越优先：
  /// edited/confirmed > user_stated 且 unreviewed > device > model_inferred。
  int get rank {
    if (reviewStatus == ReviewStatus.edited ||
        reviewStatus == ReviewStatus.confirmed) {
      return 0;
    }
    switch (origin) {
      case FieldOrigin.userStated:
      case FieldOrigin.userEdited:
        return 1;
      case FieldOrigin.device:
        return 2;
      case FieldOrigin.modelInferred:
        return 3;
    }
  }
}

/// 默认显示值的计算（D-07，schema §3.7）：实时计算，不存储。
/// 返回排好序的候选列表，第一个是默认显示值，其余作为"参考"。
List<FieldCandidate<T>> rankCandidates<T>(List<FieldCandidate<T>> candidates) {
  final sorted = [...candidates]..sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      // 同一级别取最新的。
      return b.effectiveAtMs.compareTo(a.effectiveAtMs);
    });
  return sorted;
}

FieldCandidate<T>? defaultDisplayValue<T>(List<FieldCandidate<T>> candidates) =>
    candidates.isEmpty ? null : rankCandidates(candidates).first;
