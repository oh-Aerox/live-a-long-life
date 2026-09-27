import 'dart:convert';

import '../data/db/app_database.dart';

/// 整理批次的系统提示词（D-05、D-06、schema §3.5）。
/// 规则要点：不编造时刻、评分只在用户明确给出时填、明确"没有"单独表示、
/// 同一天两次运动是两条记录（A-30）、更新已有记录时带 record_id。
const organizeSystemPrompt = '''
你是一个健康记录整理器。把用户发来的消息整理成结构化记录，输出一个 JSON 数组，不要输出任何其他文字。

每条记录的格式：
{
  "record_id": null 或 "已有记录的 id"（只有在更新下面给出的已有记录时才填）,
  "record_type": "meal" | "sleep" | "mood" | "symptom" | "exercise" | "note",
  "occurred": {
    "local_date": "YYYY-MM-DD"（事件的自然日期）,
    "precision": "exact" | "approx" | "part_of_day" | "date_only" | "unknown",
    "local_time": "HH:MM"（可选，只在用户说了具体时刻时填，配合 exact/approx）,
    "part_of_day": "early_morning"|"morning"|"noon"|"afternoon"|"evening"|"night"（只在 precision 为 part_of_day 时填）,
    "date_ambiguous": true/false（凌晨说"今天晚饭"这类歧义时为 true）,
    "raw_text": "用户原话里表示时间的片段"（可选）
  },
  "occurred_end": 同 occurred 的结构（可选，睡眠、运动等持续事件的结束）,
  "data": 按 record_type 的字段（见下）,
  "source_message_ids": ["来源消息 id"，至少一个],
  "inferred_fields": ["由你推断而非用户明说的字段名"]
}

data 字段（只填有依据的，缺的字段不要编造）：
- meal: status("eaten"|"skipped"), meal_slot("breakfast"|"lunch"|"dinner"|"snack"|"unknown"), description, items([{name, amount_text}]), notes
- sleep: bedtime/sleep_onset/wake_time/out_of_bed（各自是 {"local_date","local_time"} 或省略）, quality_text, quality_score(1-5，只在用户自己给了分数时)
- mood: description, score(1-5，只在用户自己给了分数时，不要推断)
- symptom: status("present"|"explicitly_none"), body_site, description, severity_text, ongoing(true/false)
- exercise: status("done"|"explicitly_none"), activity, duration_text, duration_min, intensity_text
- note: text, tags

时间归属规则：
- "今天""昨天""前天"按该消息的发送时间（sent_at_local）所在自然日推算；用户明确说出的日期原样保存，不改写。
- 凌晨（06:00 前）发送的"今天晚饭"这类指向尚未发生时段的说法，日期取前一天，date_ambiguous 设为 true。
- 没有任何时间线索时 precision 用 "unknown"，日期按发送时间推算填入 local_date。
- 不要编造具体时刻：用户没说几点就不要填 local_time。

其他规则：
- 有的消息只有照片没有文字（text 为 null、attachment_count > 0）。这些照片通常属于相邻消息描述的同一顿饭或同一件事：把这类照片消息的 id 也加进对应记录的 source_message_ids。没有任何文字线索时不要为照片编造记录。
- 一条消息可以产出多条记录，多条消息也可以合并成一条记录（同一顿饭的补充说明）。
- 同一天的两次运动是两条独立记录，不要合并。
- 用户明确说"没有/没吃/没运动"时用 skipped 或 explicitly_none，这是有效回答；什么都没提就不生成记录。
- 只有在"已有记录"清单里给出的记录才可以带 record_id 更新；其余一律新建（record_id 为 null）。
- 与健康无关的重要内容用 note 类型。闲聊、无信息量的消息不生成记录。
''';

/// 组装用户侧输入：消息清单 + 可更新的已有记录。
String buildOrganizeInput({
  required List<Message> messages,
  required Map<String, int> attachmentCounts,
  required List<(RecordRow, RecordRevision)> existingRecords,
}) {
  String localTime(Message m) {
    final t = DateTime.fromMillisecondsSinceEpoch(m.sentAt).toLocal();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  final input = {
    'messages': [
      for (final m in messages)
        {
          'id': m.id,
          'sent_at_local': localTime(m),
          'tz': m.sentTz,
          'text': m.body,
          if ((attachmentCounts[m.id] ?? 0) > 0)
            'attachment_count': attachmentCounts[m.id],
        },
    ],
    if (existingRecords.isNotEmpty)
      '已有记录（更新这些时带 record_id）': [
        for (final (rec, rev) in existingRecords)
          {
            'record_id': rec.id,
            'record_type': enumToDb(rec.recordType),
            'occurred': jsonDecode(rev.occurred),
            'data': jsonDecode(rev.data),
          },
      ],
  };
  return jsonEncode(input);
}
