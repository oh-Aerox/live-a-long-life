import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/ids.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/repositories/review_prompt_repository.dart';
import 'health_service.dart';
import 'organize_service.dart';
import 'record_gaps.dart';

/// 每日回顾（D-08、D-09，plan-v0.2 V2-M5）：只问缺的。
///
/// - 先跑一次整理（daily_review 触发），让已发的消息先变成记录；
/// - 缺口按 schema §3.5 的表检测；设备已提供睡眠时间时只问感受；
/// - 当天问过（含被跳过）的缺口不再问；一次回顾最多问 3 个（A-32）；
/// - 提问以 app_prompt 消息进入对话流，并记入 review_prompts。
class ReviewService {
  ReviewService({
    required MessageRepository messages,
    required RecordRepository records,
    required ReviewPromptRepository prompts,
    required Future<DeviceDayData> Function(String localDate) deviceData,
    OrganizeService? organize,
    required String tz,
    this.ids = const IdGenerator(),
  })  : _messages = messages,
        _records = records,
        _prompts = prompts,
        _deviceData = deviceData,
        _organize = organize,
        _tz = tz;

  final MessageRepository _messages;
  final RecordRepository _records;
  final ReviewPromptRepository _prompts;
  final Future<DeviceDayData> Function(String) _deviceData;
  final OrganizeService? _organize;
  final String _tz;
  final IdGenerator ids;

  static const maxQuestionsPerReview = 3;

  /// 执行一次回顾，返回本次实际提问数。
  Future<int> runReview({String? localDate}) async {
    final date = localDate ?? _today();

    // 回顾也是整理触发器之一（D-05）：先把已发的消息整理掉。
    final organize = _organize;
    if (organize != null) {
      await organize.enqueue(OrganizeTrigger.dailyReview);
      await organize.pump();
    }

    final gaps = await detectGaps(
      date,
      records: await _recordsWithData(date),
      device: await _deviceData(date),
    );

    var asked = 0;
    for (final gap in gaps) {
      if (asked >= maxQuestionsPerReview) break;
      if (await _prompts.askedToday(date, gap.key)) continue;
      final prompt = await _messages.send(
        clientMsgId: ids.newId(),
        role: MessageRole.app,
        kind: MessageKind.appPrompt,
        text: gap.question,
        sentTz: _tz,
        organizeState: OrganizeState.notApplicable,
      );
      final row = await _prompts.add(
        reviewDate: date,
        promptMessageId: prompt.id,
        gapKey: gap.key,
        templateId: gap.templateId,
      );
      // 提示元数据带上记账行，界面用它提供"跳过"。
      await (_messages.setPromptMeta(
          prompt.id, jsonEncode({'kind': 'review_prompt', 'prompt_row_id': row.id})));
      asked++;
    }
    return asked;
  }

  Future<List<(RecordType, Map<String, Object?>)>> _recordsWithData(
      String date) async {
    final rows = await _records.byDate(date);
    final result = <(RecordType, Map<String, Object?>)>[];
    for (final r in rows) {
      final rev = await _records.currentRevisionOf(r.id);
      result.add(
          (r.recordType, (jsonDecode(rev.data) as Map).cast<String, Object?>()));
    }
    return result;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
