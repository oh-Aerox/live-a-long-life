# 模型调用场景与内置提示词

本文说明每一个调用模型的场景：在哪里触发、代码位置、内置的系统提示词全文、发送什么数据。**代码是唯一事实源**——任何改动提示词的提交必须同步更新本文，评审时对照检查。

所有调用（测试连接除外）都写入 `model_calls` 调用记录，应用内"模型调用记录"页可查（D-16 透明度）。

## 场景总览

| 场景 | caller | 提示词位置 | 发送的数据 | 触发 |
|---|---|---|---|---|
| 手机整理批次 | `phoneOrganize` | `app/lib/services/organize_prompt.dart` | 未整理消息的文字 + 附件数量元信息 + 可更新的已有记录。**不发图片** | 用户点"记好了"；空闲定时器预整理；每日回顾结束；记录上点"重新整理" |
| Mac 周报生成 | `macAnalysis` | `app/lib/services/analysis_service.dart` | 近 7 天记录的当前版本 + 按天健康数据。纯文本 | Mac 主页周报卡片手动触发 |
| 检验单结构化提取 | `phoneMedicalExtract` | `app/lib/services/medical_extraction_service.dart` | 经页筛选（D-23）与脱敏（D-24）的本地 OCR 文本，带行索引。**不发图片；调用记录含遮蔽项数** | 医疗文件提取（V4-M2 接 UI） |
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
- 输入里的 long_term_conditions 是用户已确认的长期身体状况档案
  （结石、慢性病、过敏等），下周建议要把它们考虑进去（比如结石注意
  饮食和饮水、过敏避开过敏原）；recent_temporary_conditions 是近期
  临时疾病，只影响近期建议。两者都可能为空；
- 不做医疗诊断，不给用药建议；可以温和提示值得留意的模式；
- 用户手动修改过的值以记录为准，不要质疑。
```

状况输入（D-25，2026-09-28 加入）：`long_term_conditions` = 全部已核对（confirmed/edited）的长期状况；`recent_temporary_conditions` = 近 30 天内、active、已核对的临时疾病。未核对的一律不进（D-04）。

## 3. 检验单结构化提取

- **系统提示词：** `labExtractSystemPrompt`（medical_extraction_service.dart）
- **用户侧输入：** 每行 `P{页}L{行}: 文本`——本地 OCR/PDF 文字层输出，经页筛选（被排除页不发送）与脱敏（姓名、证件号已替换为占位符）
- **约束来源：** D-23（行索引引用 → 应用映射回坐标写 locator，A-19 溯源）、D-24（脱敏）、D-04（结果全部 unreviewed，五关键字段确认才算事实）

```
你是检验报告的结构化提取器。输入是一份医疗文件经本地文字识别后的文本，
每行有形如 P2L5 的行号（第 2 页第 5 行）。只输出一个 JSON 对象，不要输出其他文字：
{
  "doc": {
    "doc_type": "lab_report" | "imaging_report" | "visit_record" | "prescription" | "discharge_summary" | "other",
    "institution_text": "医疗机构名称，按原文" 或 null,
    "exam_date": "YYYY-MM-DD" 或 null（检查/采样日期）,
    "report_date": "YYYY-MM-DD" 或 null（报告日期）
  },
  "results": [
    {
      "item_name_raw": "报告上的项目名称，按原文",
      "value_raw": "报告上的数值，按原文",
      "value_num": 解析出的数值 或 null,
      "unit_raw": "报告上的单位，按原文" 或 null,
      "ref_range_raw": "报告上的参考范围，按原文" 或 null,
      "ref_low": 参考范围下限 或 null,
      "ref_high": 参考范围上限 或 null,
      "flag_raw": "报告上的异常标记（↑、↓、H、L 等）" 或 null,
      "source_lines": ["该项数据来自的行号，如 P1L3"，至少一个]
    }
  ],
  "conditions": [
    {
      "name": "疾病或身体状况名称，按原文（如 胆囊结石、青霉素过敏）",
      "persistence": "long_term" | "temporary",
      "evidence_text": "依据的原文片段（诊断、结论、印象一栏）",
      "source_lines": ["来源行号"，至少一个]
    }
  ]
}

规则：
- *_raw 字段一律按原文抄写，不要改写、翻译或归一化；
- 解析不出的数值字段（value_num、ref_low、ref_high）留 null，不要猜；
- source_lines 只能用输入里出现的行号，不要编造；
- 没有检验数值表时 results 为空数组；检查所见、结论等文字内容不进 results；
- conditions 只收诊断/结论/印象/病史文字里明确写出的疾病或状况；
  结石、囊肿、结节、慢性病、过敏等不会自行消失的算 long_term，
  感冒、急性感染等预期痊愈的算 temporary，拿不准按 long_term（会由用户核对）；
  检验数值异常本身不是状况，不要凭数值推断疾病；没有就给空数组；
- 文本里的【姓名】【证件号】是脱敏占位符，不是数据，忽略它们；
- 检查日期和报告日期是两个日期，分不清时只填能确认的那个。
```

应用侧的防线：编造的行号在映射 locator 时被丢弃；`item_name_raw`/`value_raw` 缺失的项整项丢弃；全部结果 unreviewed。状况建议（D-25，2026-09-28 加入）：同名（去空白）状况已有档案时不重复建；persistence 非法值整条丢弃；全部 unreviewed，在长期状况档案页核对。

## 4. 测试连接

- **位置：** `ModelClient.testConnection` / `_probeImage`（model_client.dart）
- **发送内容：** 文本探测 `收到请回复"OK"`；图片能力探测 `这是图片能力测试，回复"OK"` + 内置 1 像素级探测 PNG（`_probePng` 常量）
- 不含任何用户数据，用于连通性验证和 D-16 能力标注（支持文本/图片）。

## 5. 规划中的调用场景（v0.4，实现时补入本文）

| 场景 | 状态 | 约束来源 |
|---|---|---|
| 多模态识图（显式） | V4-M3。用户显式发起、裁剪后的图片 | D-24 |
| 主动咨询 | V4-M6。用户问题 + 最小上下文，caller=userConsult | D-26 |

（长期状况分类已并入"检验单结构化提取"的 conditions 输出，2026-09-28。）
