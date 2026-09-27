import 'package:drift/drift.dart';

import '../app_context.dart';
import '../db/app_database.dart';
import '../ids.dart';

/// 回顾提问记录（schema §4.4，D-08）：
/// 当天不重复提问、一次回顾最多问 3 个的依据。
class ReviewPromptRepository {
  ReviewPromptRepository(this._db, this._ctx, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final AppContext _ctx;
  final IdGenerator ids;

  Future<ReviewPrompt> add({
    required String reviewDate,
    required String promptMessageId,
    required String gapKey,
    required String templateId,
  }) async {
    return _db.into(_db.reviewPrompts).insertReturning(
          ReviewPromptsCompanion.insert(
            id: ids.newId(),
            userId: _ctx.userId,
            createdAt: ids.nowMs(),
            createdOnDevice: _ctx.deviceId,
            reviewDate: reviewDate,
            promptMessageId: promptMessageId,
            gapKey: gapKey,
            templateId: templateId,
          ),
        );
  }

  Future<ReviewPrompt> markOutcome(
    String promptId,
    ReviewOutcome outcome, {
    String? answeredMessageId,
  }) async {
    final updated = await (_db.update(_db.reviewPrompts)
          ..where((t) => t.id.equals(promptId)))
        .writeReturning(ReviewPromptsCompanion(
      outcome: Value(outcome),
      answeredMessageId: answeredMessageId == null
          ? const Value.absent()
          : Value(answeredMessageId),
    ));
    return updated.single;
  }

  /// 针对某天的全部提问。缺口当天问过（含被跳过）就不再问（A-32）。
  Future<List<ReviewPrompt>> byReviewDate(String reviewDate) =>
      (_db.select(_db.reviewPrompts)
            ..where((t) => t.reviewDate.equals(reviewDate))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// 某天某缺口是否已经问过。
  Future<bool> askedToday(String reviewDate, String gapKey) async {
    final row = await (_db.select(_db.reviewPrompts)
          ..where((t) =>
              t.reviewDate.equals(reviewDate) & t.gapKey.equals(gapKey))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
