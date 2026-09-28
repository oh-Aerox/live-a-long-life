# 模型调用场景与内置提示词

本文说明每一个调用模型的场景：在哪里触发、代码位置、内置的系统提示词全文、发送什么数据。**代码是唯一事实源**——任何改动提示词的提交必须同步更新本文，评审时对照检查。

所有调用（测试连接除外）都写入 `model_calls` 调用记录，应用内"模型调用记录"页可查（D-16 透明度）。

## 场景总览

| 场景 | caller | 提示词位置 | 发送的数据 | 触发 |
|---|---|---|---|---|
| 手机整理批次 | `phoneOrganize` | `app/lib/services/organize_prompt.dart` | 未整理消息的文字 + 附件数量元信息 + 可更新的已有记录。**不发图片** | 用户点"记好了"；空闲定时器预整理；每日回顾结束 |
| Mac 周报生成 | `macAnalysis` | `app/lib/services/analysis_service.dart` | 近 7 天记录的当前版本 + 按天健康数据。纯文本 | Mac 主页周报卡片手动触发 |
| 测试连接 | 不记录 | `app/lib/services/model_client.dart` | 固定示例文本 + 内置探测小图。**无任何用户数据** | 模型配置页"测试连接" |

`ModelCaller.externalAgent` 只有枚举定义，无调用路径（D-20 外部 agent 入口默认关闭，未实现）。

## 1. 手机整理批次

- **系统提示词：** `organizeSystemPrompt`（organize_prompt.dart）
- **用户侧输入：** `buildOrganizeInput()` 组装的 JSON——每条消息的 id、本地发送时间、时区、文字、附件数；有可更新记录时附"已有记录"清单（record_id、类型、时间、data）
- **约束来源：** D-05（批次与并发）、D-06（时间语义）、schema §3.5（各类型字段）

```
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
```

## 2. Mac 周报生成

- **系统提示词：** `weeklyReviewSystemPrompt`（analysis_service.dart）
- **用户侧输入：** JSON——`period` 起止日期、`records`（每条含 revision_id、类型、日期、data）、`health_daily`（日期、指标、数值）
- **约束来源：** D-20（不诊断不开药）、D-14（截止点由代码记录，不在提示词里）、R-35（下周建议，2026-09-28 加入）

```
你是健康记录的周报分析师。根据输入的一周记录写一份简短周报（Markdown），
只输出一个 JSON 对象，不要输出其他文字：
{"content_md": "周报正文", "citations": [{"claim_id": "C1", "record_revision_ids": ["..."]}]}

要求：
- 正文分节：饮食、睡眠、运动、心情与不适、值得注意的变化、下周建议；
- 每条事实陈述末尾标注 [C1] [C2] 这样的引用号，citations 里给出该陈述
  依据的 record_revision_ids（用输入里给出的 revision_id，不要编造）；
- 只描述记录里有的事实和趋势，没有数据的方面写"本周没有记录"；
- 下周建议：根据本周记录给出下周在饮食、运动、睡眠等方面的具体注意事项，
  同样标注引用。本周有症状、不适或就医相关记录时，围绕它给出针对性的
  留意事项（比如饮食调整、控制运动强度、保证睡眠）；感冒发烧这类短期不适
  只影响近期建议，不要把它写成长期结论。没有特别情况时给一两条简短的
  维持性建议即可，不要凑数；
- 不做医疗诊断，不给用药建议；可以温和提示值得留意的模式；
- 用户手动修改过的值以记录为准，不要质疑。
```

v0.4 有长期状况档案（D-25）后，周报输入将加入长期状况清单与近期临时疾病，使下周建议更有针对性。

## 3. 测试连接

- **位置：** `ModelClient.testConnection` / `_probeImage`（model_client.dart）
- **发送内容：** 文本探测 `收到请回复"OK"`；图片能力探测 `这是图片能力测试，回复"OK"` + 内置 1 像素级探测 PNG（`_probePng` 常量）
- 不含任何用户数据，用于连通性验证和 D-16 能力标注（支持文本/图片）。

## 4. 规划中的调用场景（v0.4，实现时补入本文）

| 场景 | 状态 | 约束来源 |
|---|---|---|
| 检验单结构化提取 | V4-M1。输入为经页筛选（D-23）和脱敏（D-24）的 OCR 文本（带行索引），要求逐字段返回行索引引用 | D-23/D-24 |
| 长期状况分类 | V4-M4。就医/体检信息区分临时疾病与长期状况，模型建议、用户核对 | D-25 |
| 多模态识图（显式） | V4-M3。用户显式发起、裁剪后的图片 | D-24 |
| 主动咨询 | V4-M6。用户问题 + 最小上下文，caller=userConsult | D-26 |
