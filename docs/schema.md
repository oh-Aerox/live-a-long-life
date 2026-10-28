# 数据模型

本文定义实体、字段、状态和时间语义，对应 [decisions.md](decisions.md) 中的相关决定（D-xx）。字段类型按逻辑含义书写，实现时以数据库迁移脚本为准。修改数据结构前，先修改本文。

## 1. 通用约定

### 1.1 所有实体共有的字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | UUIDv7 文本 | 在客户端生成，全局唯一，同时保证按时间有序 |
| `user_id` | UUID | 目前只有一个用户，但字段保留（R-02） |
| `created_at` | UTC 时刻 | 本条数据在本地创建的时间 |
| `created_on_device` | 设备 ID | 在哪台设备上创建 |
| `version` | 整数 | 本实体的版本号，每次修改加 1；整理批次用它判断目标是否已变（D-05） |
| `change_seq` | 整数 | 最近一次修改对应的变更日志序号（§7.2、D-13） |
| `deleted_at` | UTC 时刻，可空 | 删除标记。删除信息需要同步到其他设备，所以不直接物理删除 |

### 1.2 时间值（TimeValue）

所有"发生时间"都使用这个结构（D-06）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `instant_utc` | UTC 时刻，可空 | 只在 `precision` 为 `exact` 或 `approx` 时有值；其他精度一律为空，不编造时刻 |
| `tz` | IANA 时区名，可空 | 事发时所在的时区，比如 `Asia/Shanghai`；不知道时取发送时的时区，并由 `tz_inferred` 标明 |
| `tz_inferred` | 布尔值 | 时区是推断的（取自发送时或读取时的时区）时为真 |
| `local_date` | 日期，可空 | 事件的**自然日期**（00:00 起算），见下方规则。`precision = unknown` 且无法推断日期时为空 |
| `precision` | 枚举 | `exact` 精确 / `approx` 大约 / `part_of_day` 时段 / `date_only` 只到日期 / `unknown` 未知 |
| `part_of_day` | 枚举，可空 | `early_morning` / `morning` / `noon` / `afternoon` / `evening` / `night`。只在 `precision = part_of_day` 时有值，其他精度一律为空 |
| `source` | 枚举 | `user_stated` 用户说的 / `inferred_from_sent_at` 按发送时间推断 / `device` 设备记录 |
| `date_ambiguous` | 布尔值 | 日期理解有歧义（比如凌晨说的"今天晚饭"）时为真，界面提示用户核对 |
| `raw_text` | 文本，可空 | 用户原话中表示时间的片段，比如"昨晚大概一点" |

**各精度下的字段组合：**

| `precision` | `instant_utc` | `local_date` | `part_of_day` |
|---|---|---|---|
| `exact` / `approx` | 有 | 有（由时刻和时区算出） | 空 |
| `part_of_day` | 空 | 有 | 有 |
| `date_only` | 空 | 有 | 空 |
| `unknown` | 空 | 能按发送时间推断时有（`source = inferred_from_sent_at`），否则空 | 空 |

**自然日期的计算规则（D-06）：**
- "今天""昨天""前天"按消息 `sent_tz` 下 `sent_at` 所在的自然日推算；明确写出的日期原样保存，不改写。
- 凌晨发送的"今天"指向尚未发生的时段时，候选日期取前一天，`date_ambiguous` 为真，记录保持未核对。
- 睡眠记录：知道醒来时间时，记录的归属日期取醒来时刻的自然日；否则按原话的自然日期。
- 按日视图的分组可以在设置 `day_view_start` 中偏移（默认 00:00），只影响显示，不写入 `local_date`。

### 1.3 数据来源（provenance）

整理层的每个版本都要能回答四个问题：来自谁、经过什么处理、由哪次处理产生、依据哪些原始数据。来源和核对状态记到**字段级**，因为同一条记录的不同字段可能来自不同来源。

**版本级（`record_revisions`）：**

| 字段 | 取值 |
|---|---|
| `produced_by` | 整理批次 ID，或"用户编辑"，或"接受了某条修正建议" |

**字段级（`record_revisions.field_meta`，每个字段一项）：**

| 字段 | 取值 |
|---|---|
| `origin` | `user_stated` 从用户原话提取 / `user_edited` 用户亲手填写 / `device` 设备 / `model_inferred` 模型推断 |
| `review_status` | `unreviewed` 未核对 / `confirmed` 已确认 / `edited` 用户已修改（D-04） |
| 来源链接 | 见 `record_sources` 表，按 `field_path` 对应 |

例：一条睡眠记录里，`bedtime` 为 `user_stated` + `edited`，`duration_min` 为 `device` + `unreviewed`，`quality` 为 `user_stated` + `unreviewed`。D-07 的采用顺序在字段上比较。

## 2. 原始层

### 2.1 `messages` 消息

对话流中的每一条消息，包括用户发的和应用发的（D-05）。

| 字段 | 类型 | 说明 |
|---|---|---|
| `client_msg_id` | UUID，唯一 | 客户端生成，用于幂等写入（D-10）；可以和 `id` 相同 |
| `seq` | 整数 | 对话流中的全局顺序，决定显示顺序 |
| `role` | 枚举 | `user` 用户 / `app` 应用 |
| `kind` | 枚举 | `text` 文字 / `attachments` 附件 / `app_prompt` 回顾问题 / `app_notice` 系统提示 / `done_marker` 用户点了"记好了" |
| `text` | 文本，可空 | 当前显示的文字 |
| `revision_no` | 整数 | 当前文字的修订号，新消息为 0，每修改一次加 1。整理批次记下它，用于提交时判断输入是否变了（D-05） |
| `sent_at` | UTC 时刻 | 发送时间，也就是"记录时间" |
| `sent_tz` | IANA 时区名 | 发送时所在的时区 |
| `in_reply_to` | 消息 ID，可空 | 这条消息回答的是哪个回顾问题 |
| `prompt_meta` | JSON，可空 | 仅用于 `app_prompt`：问的是哪个缺口、用的哪个模板（D-08、D-09） |
| `organize_state` | 枚举 | `pending` 待整理 / `organized` 已整理 / `needs_reorganize` 需要重新整理 / `needs_manual` 需要手动处理（D-05）/ `not_applicable` 不需要整理 |

原件空间管理不清空消息文字。普通误发消息由 `deleted_at` 标记；医疗文件清理不改变消息或其修改历史。标记删除时消息的 `version` 加 1 并写入变更日志；整理批次的输入快照含删除状态，被删除消息的相关项按"输入已变"作废，不把已删除内容整理回来（§3.1a）。

### 2.2 `message_revisions` 消息修改历史

对应 A-06。每次修改消息时，先把修改前的内容写入这里。

| 字段 | 说明 |
|---|---|
| `message_id` | 被修改的消息 |
| `revision_no` | 被替换文字原来的修订号，从 0 开始：第一次修改把修订 0 的原文存入本表，消息本身的 `revision_no` 变为 1。来源链接的 `message_revision_no` 据此总能找到对应原文 |
| `text_before` | 修改前的文字 |
| `edited_at` | 修改时间 |

修改消息后，这条消息的 `organize_state` 变为 `needs_reorganize`。

医疗文件清理不涉及本表。消息编辑保留旧文字，普通消息删除使用删除标记，不在 D-22 中设计文字及派生内容的彻底抹除。

### 2.3 `attachments` 附件身份与索引

同一内容只对应一个附件身份，文件内容在不同设备上的保存情况另记（D-10、D-22）。清理手机副本不删除这一行，不改变其版本或任何医疗记录。

| 字段 | 类型 | 说明 |
|---|---|---|
| `sha256` | 文本，唯一 | 永久用于该附件的精确去重、取回校验；手机清理不清空 |
| `mime_type` | 文本 | 文件类型 |
| `byte_size` | 整数 | 原文件大小；实际手机占用由本地副本状态计算 |
| `original_filename` | 文本，可空 | 原文件名 |
| `first_imported_at` | UTC 时刻 | 第一次导入时间，用于重复提示 |
| `width` / `height` / `page_count` | 整数，可空 | 图片尺寸或 PDF 页数 |

### 2.3a `attachment_copies` 每台设备的文件副本

以 `(attachment_id, device_id)` 唯一标识，独立于医疗记录版本。当前设备维护自己的实际状态，不能通过接收另一台设备的状态来删除本机文件。

| 字段 | 说明 |
|---|---|
| `attachment_id` / `device_id` | 哪个文件、哪台设备 |
| `state` | `present` 已保存并校验 / `offloaded` 本机已主动清理 / `missing` 本机未持有或文件意外丢失 |
| `local_path` | 本机副本的文件名（按 SHA-256 命名），仅本设备使用；清理完成后为空。不存绝对路径：iOS 覆盖安装会更换沙盒容器路径，读取时基于当前附件目录解析 |
| `verified_at` | 最近一次在该设备写入并通过哈希校验的时间 |
| `offloaded_at` | 本设备清理完成时间，可空 |
| `preview_path` | 本机可再生缓存路径；清理时一并移除 |
| `copy_version` | 副本状态版本；传输/提取/清理任务据此避免使用过期状态 |
| `last_reported_at` | 对方通告副本状态的时间；只是最近已知状态，不保证对方当前在线 |

- 导入先落盘并校验，再标为 `present`。文件未完成保存时不能显示“已保存”。
- 主动清理实际成功后转为 `offloaded`，解除本地路径；保留附件身份、消息引用与来源定位。失败或仍有活跃读取任务时不提前转状态。
- 取回由用户主动发起，从 Mac 或重新上传取得同一 SHA-256 文件后转回 `present`；不新建医疗记录，不推进医疗数据版本。
- 普通同步不自动补回 `offloaded` 文件；对方的副本状态通告仅用于显示在哪里有原件，不是删除指令。

### 2.4 `message_attachments` 消息与附件的关联

| 字段 | 说明 |
|---|---|
| `message_id` | 消息 ID |
| `attachment_id` | 附件 ID |
| `position` | 该附件在这条消息里的顺序 |
| `duplicate_acknowledged` | 布尔值。用户看到重复提示后选择了"仍然添加"时为真 |
| `deleted_at` | 可空。普通重复消息移除引用时只标记此行；D-22 空间清理不改变引用 |

同一个附件被多条消息引用时，手机清理仅释放一个物理副本，显示空间按附件 ID 去重；全部来源链接继续保留。

### 2.5 `health_samples` 设备健康样本（按条保存）

用于睡眠分析和体能训练（D-11）。

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_uuid` | 文本，唯一 | HealthKit 样本 UUID，用于去重 |
| `sample_type` | 枚举 | `sleep` 睡眠 / `workout` 体能训练 |
| `start_utc` / `end_utc` | UTC 时刻 | |
| `tz` | IANA 时区名 | 读取时设备的时区，**不一定是事件发生时的时区**。HealthKit 样本如果带有时区元数据就用它，否则用读取时的时区 |
| `tz_inferred` | 布尔值 | `tz` 取自读取时的时区而不是样本自带的元数据时为真 |
| `source_bundle_id` | 文本，可空 | 来源应用的标识，用于多来源时按优先级取舍（D-11） |
| `sleep_stage` | 枚举，可空 | `in_bed` 在床 / `asleep_unspecified` 睡着（未分期）/ `core` 核心睡眠 / `deep` 深睡 / `rem` 快速眼动 / `awake` 清醒 |
| `workout_type` | 文本，可空 | HealthKit 的运动类型标识 |
| `energy_kcal` / `distance_m` | 数值，可空 | 体能训练消耗的能量、距离 |
| `source_name` | 文本 | 写入苹果健康的来源应用或设备名称 |
| `fetched_at` | UTC 时刻 | 本应用读取到这条样本的时间 |
| `removed_in_source_at` | UTC 时刻，可空 | anchored query 报告这条样本已在苹果健康中删除的时间。有值时不参与显示和分析 |

**锚点：** 每种样本类型的 anchored query 锚点保存在 `health_anchors` 表（`sample_type`、`anchor` 二进制、`updated_at`）。锚点失效时重新读取最近 30 天，按 `platform_uuid` 合并；30 天之前已导入的样本标为"未复核"，不当作已与苹果健康核对过。重读时没有返回的样本，不能仅凭缺席判定已被删除——读不到和被删除无法区分（D-11）。

**睡眠汇总：** 原始样本按条保存，睡眠时长、入睡和醒来时间按 D-11 的规则在读取时计算，结果作为设备来源的字段值写入睡眠记录，不直接把样本相加。

### 2.6 `health_daily` 设备健康数据（按天聚合）

用于步数和活动能量（D-11）。

| 字段 | 说明 |
|---|---|
| `local_date` | 聚合所用时区下的自然日期（00:00—24:00） |
| `agg_tz` | 聚合时使用的 IANA 时区，即当时设备的时区（D-11） |
| `interval_start_utc` / `interval_end_utc` | 这一天在 `agg_tz` 下对应的起止 UTC 时刻 |
| `metric` | `steps` 步数 / `active_energy_kcal` 活动能量 |
| `value` | 数值，来自 HealthKit 统计查询（已由系统处理多来源去重） |
| `fetched_at` | 读取时间。同一天重复读取时覆盖本行，因为这是设备数据，不是用户数据 |

**"没有这一行"表示"暂未读取到"，不表示数值为 0**（D-11）。

## 3. 整理层

### 3.1 `organize_runs` 整理批次

| 字段 | 类型 | 说明 |
|---|---|---|
| `trigger` | 枚举 | `done_marker` 点了"记好了" / `idle` 短暂无输入 / `daily_review` 每日回顾 / `user_reorganize` 用户要求重新整理 |
| `input_snapshot` | JSON | 批次开始时锁定的输入快照（D-05）：每条输入消息的 ID、`revision_no`、`version` 和删除状态；每个输入附件的 ID、实体版本及当前执行设备的 `copy_version`；每条目标记录的 ID 和当时的 `version`。之后到达的消息不加入本批次 |
| `model_config_id` | ID | 使用的模型配置 |
| `model_snapshot` | JSON | 服务、模型名、协议、数据边界（不包含 key） |
| `status` | 枚举 | `queued` 排队中 / `running` 进行中 / `succeeded` 全部写入 / `partial` 部分写入，见 `organize_run_items` / `failed` 失败 / `blocked_boundary` 模型不可用且不允许改走云端（D-16） |
| `error` | 文本，可空 | 失败原因 |
| `started_at` / `finished_at` | UTC 时刻 | |

### 3.1a `organize_run_items` 整理批次的逐项结果

批次产出的每条记录（新建或新版本）单独一行，单独提交。

| 字段 | 说明 |
|---|---|
| `organize_run_id` | 所属批次 |
| `record_id` | 目标记录。新建记录的 ID 在批次开始处理时就生成并写入本行，提交前已有稳定身份；重试时凭它识别已完成的项，不重复建记录 |
| `status` | `pending` 已登记待提交（项 ID 持久化后、事务提交前的短暂状态）/ `committed` 已写入 / `stale_input` 输入已变，作废并重新排队 / `stale_target` 目标记录已被更新，作废并重新排队 / `protected_suggested` 受保护字段未覆盖，已生成修正建议 / `needs_manual` 需要手动处理 |
| `retry_count` | 因输入或目标过时（`stale_input` / `stale_target`）而重排的次数 |
| `correction_suggestion_id` | 生成了修正建议时，对应的 ID |

**提交规则（D-05）：** 每一项在一个事务里：
1. 对照 `input_snapshot` 检查这一项用到的输入消息的 `revision_no`、`version` 和删除状态，附件内容身份或执行设备副本是否变了，是否有新的相关消息 → 变了就记 `stale_input`；
2. 检查目标记录的 `version` 是否变了 → 变了就记 `stale_target`；
3. 目标记录中 `review_status` 为 `confirmed` / `edited` 的字段不写入；新值不同时生成修正建议，记 `protected_suggested`，其余字段照常写入。这一项到此结束，不为同一保护冲突重新调用模型；修正建议的 `target_version` 是本次提交后的目标版本（§6.2）；
4. 因 `stale_input` / `stale_target` 重排的同一输入，`retry_count` 达到 2 时记 `needs_manual`，消息的 `organize_state` 改为 `needs_manual`，不再自动排队，界面上提示用户处理。

每一项的提交把记录新版本、来源链接、本行状态和相关消息的 `organize_state` 写在同一个事务里；应用中途退出后重试时，按本表已落盘的状态跳过已完成的项。

**批次不并发写入：** 同一用户只有一个整理写入队列。"记好了"、无输入预整理、每日回顾等触发合并排队，不并行处理同一输入；任务开始时重新读取处理状态，继续已有任务时复用其项 ID，避免两个批次为同一输入各建一条新记录。项 ID 在模型产出确定后、正式提交前持久化即可，不必在模型返回前预知会生成几条记录。一条消息关联多个项时，等所有相关项提交或进入待手动状态后，再汇总更新消息的 `organize_state`，不能第一项成功就标为已整理。

### 3.2 `model_calls` 模型调用记录

对应 D-16 的透明度要求。

| 字段 | 说明 |
|---|---|
| `organize_run_id` | 属于哪个整理批次，可空 |
| `model_config_id` | 使用的模型配置 |
| `data_boundary` | `device` 本机 / `lan` 局域网 / `cloud` 云端 |
| `sent_message_ids` / `sent_attachment_ids` | 本次发送了哪些消息和附件 |
| `request_at` / `response_at` | 请求和响应时间 |
| `status` | 成功、失败或超时 |
| `tokens_in` / `tokens_out` | 可空 |
| `response_text` | 可空。模型返回内容，按调试保存策略管理；手机医疗原件清理不触发派生文字级联清除 |
| `caller` | `phone_organize` 手机整理 / `mac_analysis` Mac 分析 / `phone_medical_extract` 医疗文件提取 / `user_consult` 主动咨询 / `external_agent` 用户开启的外部 agent 读取（D-20，尚未实现） |
| `redacted_count` | 可空。发送前本地脱敏遮蔽项数（D-24） |
| `sent_summary` | 可空。发送范围的人话描述（D-26/D-28） |
| `request_text` | 可空。实际发送的用户侧内容；系统提示词见 prompts.md 不重复存。与 response_text 同属调试/透明度数据，随记录同步到 Mac |

### 3.3 `records` 记录

一条记录代表一件事，比如一顿饭、一晚睡眠、一次症状。

| 字段 | 类型 | 说明 |
|---|---|---|
| `record_type` | 枚举 | 见 3.5 |
| `current_revision_id` | ID | 当前有效的版本 |
| `local_date` | 日期 | 冗余自当前版本的发生时间，用于按日查询 |

### 3.4 `record_revisions` 记录版本

| 字段 | 类型 | 说明 |
|---|---|---|
| `record_id` | ID | |
| `record_version` | 整数 | 从 1 开始递增，与所属记录的通用字段 `version` 保持一致，用于过时检查 |
| `base_version` | 整数，可空 | 本版本基于哪个版本修改。目前只有手机写入，所以不会分叉，但字段保留，为多端编辑做准备 |
| `occurred` | TimeValue | 发生时间（开始） |
| `occurred_end` | TimeValue，可空 | 发生时间（结束），用于睡眠、运动等持续一段时间的事 |
| `data` | JSON | 按记录类型定义的内容，见 3.5 |
| `produced_by` | | 见 1.3 |
| `field_meta` | JSON | 逐字段的来源和核对状态，见 1.3。所有记录类型都填写；检查单的关键字段据此判断能否作为事实（D-04） |
| `created_at` | UTC 时刻 | |

### 3.5 记录类型与 `data` 结构

共八种类型：下面六种日常类型，以及医疗文件相关的 `lab_panel`（§5.2）和 `condition`（§5.2a）。

**`meal` 饮食**

| 字段 | 说明 |
|---|---|
| `status` | `eaten` 吃了 / `skipped` 明确没吃 |
| `meal_slot` | `breakfast` 早餐 / `lunch` 午餐 / `dinner` 晚餐 / `snack` 加餐 / `drink` 饮水（单独喝水、茶、咖啡、饮料，D-47）/ `unknown` 未注明哪一顿 |
| `description` | 概括性描述，尽量沿用原话 |
| `items` | 列表，每项包含 `name`（食物）、`amount_text`（用户说的份量，比如"半碗"）、`photo_attachment_ids`（对应的照片） |
| `photo_attachment_ids` | 这顿饭的全部照片。多张照片可能是同一份食物的不同角度，不代表多份食物 |
| `notes` | 其他说明，比如"米饭只吃了一半" |

不估算热量和营养成分，避免给出虚假的精确度。

**`sleep` 睡眠**

每个时间点都是一个可空的 TimeValue，互相独立。"上床"和"入睡"是两个不同的字段（D-07）。

| 字段 | 说明 |
|---|---|
| `bedtime` | 上床时间 |
| `sleep_onset` | 入睡时间 |
| `wake_time` | 醒来时间 |
| `out_of_bed` | 起床时间 |
| `quality_text` | 用户对睡眠感受的原话 |
| `quality_score` | 1–5 分，可空。只有用户自己给了分数时才填 |

**`mood` 心情**

| 字段 | 说明 |
|---|---|
| `description` | 用户的原话 |
| `score` | 1–5 分，可空。只有用户自己给了分数时才填，不由模型推断 |

**`symptom` 身体不适**

| 字段 | 说明 |
|---|---|
| `status` | `present` 有不适 / `explicitly_none` 用户明确说没有不适 |
| `body_site` | 部位，文本 |
| `description` | 描述 |
| `severity_text` | 用户对严重程度的描述 |
| `ongoing` | 布尔值，是否仍在持续 |

**`exercise` 运动**

| 字段 | 说明 |
|---|---|
| `status` | `done` 做了运动 / `explicitly_none` 用户明确说没有运动 |
| `activity` | 运动项目 |
| `duration_text` | 用户说的时长 |
| `duration_min` | 分钟数，可空 |
| `intensity_text` | 强度描述 |
| `linked_workout_sample_ids` | 如果用户说的就是设备记录的那次运动，链接到对应样本 |

**`note` 其他**

| 字段 | 说明 |
|---|---|
| `text` | 内容 |
| `tags` | 可选标签 |

**"未记录"不需要专门的记录来表示：** 某天某一类型没有任何记录，就等于未记录。只有用户明确说"没有"时，才写入 `explicitly_none`（D-03）。`meal` 也支持明确没有：`meal_slot` 加 `status = skipped`（比如"没吃早饭"），这是有效回答，不是缺失（D-08）。

**参与缺口检测的字段（D-08）：**

| 类型 | 检测的字段 | 说明 |
|---|---|---|
| `meal` | 每个 `meal_slot`（早、午、晚）是否有记录或 `skipped` | 不追问份量、内容 |
| `sleep` | `sleep_onset` 或 `bedtime`；`wake_time`；`quality_text` | 设备已提供时间时只问感受 |
| `mood` | 当天是否有记录 | |
| `symptom` | 当天是否有记录或 `explicitly_none` | |
| `exercise` | 当天是否有记录、设备体能训练或 `explicitly_none` | |

### 3.6 `record_sources` 来源链接

| 字段 | 说明 |
|---|---|
| `record_revision_id` | 哪个记录版本 |
| `field_path` | 可空。这条来源支撑的是哪个字段，比如 `bedtime`、`items[1].amount_text`。为空表示支撑整条记录 |
| `source_kind` | `message` 消息 / `attachment` 附件 / `health_sample` 设备样本 / `health_daily` 设备日数据 |
| `source_id` | 对应的 ID |
| `message_revision_no` | 可空。来源是消息时，引用的是消息的第几个修订版本，避免消息修改后引用错位 |
| `span` | 可空。原文中被引用的字符区间，或 PDF 的页码和区域 |

**来源定位与手机清理（D-22）：** `span`、字段来源和消息修订号始终保留。原件不在本机时先显示数据，用户需要看原件时可取回；取回后沿原定位打开。清理不移除任何记录来源。

一条消息可以关联多条记录（D-05），所以这是多对多关系。

### 3.7 默认显示值的计算（D-07）

"某个字段当前显示哪个值"是**实时计算的**，不单独存储。计算方法：

1. 找出同一条记录的同一字段的所有候选值（按 `field_meta`），包括用户来源的值和设备数据的值。同一天的同类事件是不同的记录，不放在一起比较（D-07）；
2. 按 D-07 的顺序排序：`edited` / `confirmed` > `user_stated` 且 `unreviewed` > `device` > `model_inferred`；
3. 同一级别有多个值时，取最新的，按该值的生效时间：来自消息的用户值按消息 `sent_at`；用户手动编辑的值按对应记录版本的 `created_at`（手动编辑没有新消息，不能沿用旧消息的发送时间）；设备值按 `fetched_at`；
4. 取排在最前的值作为默认显示值，其他候选值作为"参考"一并显示。

设备数据与记录字段的对应关系：

| 设备数据 | 对应的记录字段 |
|---|---|
| 睡眠样本（按 D-11 的规则合并为一段睡眠，归到醒来那天） | 睡眠阶段样本算出 `sleep.sleep_onset`、`sleep.wake_time` 和时长；`in_bed` 样本对应 `bedtime`、`out_of_bed` |
| 体能训练样本 | 显示在当天的运动项里；只有用户确认是同一次运动时，才与 `exercise` 记录链接 |
| 步数、活动能量 | 没有对应的用户字段，只作为补充信息显示 |

## 4. 用户资料与设置

### 4.1 `profile_fields` 用户资料

每个字段一行，修改时写入新版本，保留历史（D-18）。

| 字段 | 说明 |
|---|---|
| `field_key` | 资料项，见下表 |
| `value` | JSON |
| `state` | `provided` 已填写 / `skipped` 暂时跳过 / `declined` 不愿透露 |
| `version` | 版本号 |
| `updated_at` | 更新时间 |

资料项：

| `field_key` | 说明 |
|---|---|
| `full_name` | 本人姓名，只用于医疗文件发送前遮蔽（D-24 第三层），不发给模型 |
| `birth_year_month` | 出生年月 |
| `sex_at_birth` | 生理性别，影响检查参考范围 |
| `gender_identity` | 性别认同，可选 |
| `height_cm` | 身高 |
| `exercise_preferences` | 运动爱好 |
| `chronic_conditions` | 慢性病 |
| `medications` | 长期用药 |
| `allergies` | 过敏 |
| `family_history` | 家族病史 |
| `smoking` | 吸烟情况 |
| `alcohol` | 饮酒情况 |

体重随时间变化，不放在用户资料里；作为记录类型尚未实现（规划中）。

### 4.2 `settings` 设置

键值对形式，只存在手机上。

| 键 | 默认值 | 说明 |
|---|---|---|
| `review_times` | `["21:30"]` | 每日回顾时间列表（R-11） |
| `review_enabled` | `true` | 是否开启每日回顾 |
| `day_view_start` | `"00:00"` | 按日视图从几点开始分组。只影响显示，不修改记录日期（D-06） |
| `home_tz` | 自动检测 | 常用时区 |
| `idle_preorganize_sec` | `180` | 无输入多少秒后在后台预整理。只触发预整理，不代表结束或确认（R-08） |
| `healthkit_enabled_types` | `["sleep","steps","workout","active_energy"]` | 读取哪些健康数据（R-17） |
| `consult_allow_lookup` | `true` | 咨询时是否允许模型用只读工具查阅记录（D-43） |

### 4.3 `model_configs` 模型配置

对应 D-16。**这张表不参与同步，也不进入备份。**

| 字段 | 说明 |
|---|---|
| `preset` | `openai` / `anthropic` / `deepseek` / `kimi` 月之暗面 / `glm` 智谱 / `openai_compatible` 其他兼容服务 / `ollama` |
| `protocol` | `openai_compatible` / `anthropic` |
| `base_url` | 服务地址 |
| `model` | 模型名 |
| `capabilities` | 支持哪些输入：`text` / `image` / `pdf`，由测试连接的结果写入 |
| `data_boundary` | `device` 本机 / `lan` 局域网 / `cloud` 云端 |
| `keychain_ref` | key 在系统安全存储中的引用名。key 本身不进入数据库 |
| `is_default` | 是否为默认模型 |
| `last_test_at` / `last_test_result` | 最近一次测试连接的时间和结果 |

### 4.4 `review_prompts` 回顾提问记录

每次回顾问的每一个问题一行（D-08），用于当天不重复提问，以及检查问题数量是否控制在 3 个以内。

| 字段 | 说明 |
|---|---|
| `review_date` | 针对哪一天的回顾 |
| `prompt_message_id` | 对应对话流中的哪条 `app_prompt` 消息 |
| `gap_key` | 问的是哪个缺口，比如 `meal.breakfast`、`sleep.wake_time`、`profile.height_cm` |
| `template_id` | 使用的模板（D-09） |
| `outcome` | `answered` 已回答 / `skipped` 用户跳过 / `no_response` 没有回应 |
| `answered_message_id` | 可空。回答它的消息 |

每个缺口项当天的状态（已记录 / 明确没有 / 待整理 / 已跳过 / 缺失）实时计算，不存储：由记录、消息的 `organize_state` 和本表共同算出。

### 4.5 `consult_messages` 主动咨询的问答历史

对应 D-26、D-43。咨询是问答，不是录入：不进消息流、不参与整理、不生成记录。**这张表保存在设备本地，不写变更日志、不同步，也不进入 Mac 备份**；手机的导出与恢复包含它。

| 字段 | 说明 |
|---|---|
| `id` | 主键 |
| `session_id` | 所属咨询会话，同一会话的多轮问答共用 |
| `role` | `user` 用户提问 / `assistant` 模型回答 |
| `body` | 问题或回答的正文 |
| `context_note` | 可空。这一问附带了哪些上下文（给人看的描述，与 `model_calls.sent_summary` 一致） |
| `model_call_id` | 可空。对应的模型调用记录（`model_calls`），用来查看实际发送和返回的内容 |
| `created_at` | 创建时间 |

## 5. 病历与检查单

### 5.1 `medical_documents` 医疗文件

一份医疗文件由一个或多个附件组成，这些附件**可以来自不同的消息**（比如一份多页报告分两次拍照发送）。

| 字段 | 说明 |
|---|---|
| `pages` | 有序列表，每项包含 `attachment_id`、`message_id`（从哪条消息来）、`page_no`（在这份文件中的第几页）。页序由用户或模型确定，用户可以调整 |
| `doc_type` | `lab_report` 检验报告 / `imaging_report` 影像报告 / `visit_record` 门诊病历 / `prescription` 处方 / `discharge_summary` 出院小结 / `physical_exam` 体检报告 / `other` 其他 |
| `institution_text` | 医疗机构名称，按原文；用户可改，重新提取只在为空时填 |
| `visit_title` | 就诊标题，模型按单据概括这次就诊或检查的原因（如"膝关节扭伤复诊"），列表以它为主标题；用户可改，重新提取只在为空时填（D-37） |
| `exam_date` | 检查日期，TimeValue；用户改日期时，提取记录和从它建议出的身体状况一起改日（新版本），重新提取只在为空时填 |
| `report_date` | 报告日期，TimeValue |
| `uploaded_at` | 上传时间。与检查日期、报告日期是三个不同的时间 |
| `review_status` | 核对状态 |
| `page_overrides` | 可空。页筛选的用户覆盖（D-23）：JSON `{"页号": true/false}`，true 强制发送、false 强制排除，没写的页按规则默认 |
| `line_edits` | 可空。发送前确认页的行修改，见 §5.2 |

### 5.2 `lab_panel` 检验结果记录

记录类型为 `lab_panel`，`data` 中包含 `results` 列表，每项的结构如下：

| 字段 | 说明 |
|---|---|
| `panel_raw` | 所属检查大项，按报告大标题原文（血常规、尿常规、肝功能…），可空。提取时填（D-36）；为空的记录可在详情页用模型补（只发项目名称），或修改单项时手填 |
| `item_name_raw` | 报告上的项目名称，按原文 |
| `item_code` | 可空。规划中：映射到 LOINC 等标准编码，尚未实现 |
| `value_raw` | 报告上的数值，按原文 |
| `value_num` | 解析出的数值，可空 |
| `unit_raw` | 报告上的单位，按原文 |
| `unit_norm` | 标准化后的单位，可空 |
| `ref_range_raw` | 报告上的参考范围，按原文 |
| `ref_low` / `ref_high` | 解析出的参考范围上下限，可空 |
| `flag_raw` | 报告上的异常标记，比如 ↑、↓、H、L |
| `locator` | 在原件中的位置：附件 ID、页码、区域坐标 |
| `field_meta` | 逐字段的来源和核对状态（见 1.3） |

项目、数值、单位、参考范围、检查日期这五项全部为 `confirmed` 或 `edited` 后，这条结果才作为"事实"参与分析（D-04）。

`data` 另有 `findings` 列表（D-28）：报告与病历的文字内容，只有文字没有数值的文件（门诊病历、超声/彩超报告）靠它保留，不因 `results` 为空而丢弃。

| findings 字段 | 说明 |
|---|---|
| `section_raw` | 栏目名称，按原文（主诉、诊断、处理意见、超声所见、超声提示、结论等），可空 |
| `text_raw` | 栏目下的文字，按原文 |
| `locator` | 在原件中的位置（同 results） |

`data` 还有 `medications` 列表（D-28）：病历、处方、医嘱里开具的药品，一个药一条。

| medications 字段 | 说明 |
|---|---|
| `name` | 药品名称 |
| `spec` / `dose` / `route` / `frequency` / `duration` / `quantity` | 规格、单次用量、用法、频次、疗程、开具数量；报告没写的为 null，不推断 |
| `locator` | 在原件中的位置（同 results） |

- results、findings、medications 每项都可带 `ocr_fixes`：模型对 OCR 识别错误做的修正（"原文→修正后"字符串列表），核对页展示；修正前的识别原文在 locator 的 `line_text`。`*_raw` 字段存修正后的文字。
- 核对状态在 `field_meta` 的 `findings.{i}` / `medications.{i}`，确认或修改后才作为事实（D-04）；没有这两个字段的记录按空处理。
- 一份医疗文件对应一条 `lab_panel` 记录（`medical_document_id` 关联）：重新提取在这条记录上追加新版本，不另建记录。文字内容不进 `lab_results` 索引。
- 发送前确认页的行修改存在 `medical_documents.line_edits`（JSON：键 `<附件 ID>:<附件内页号>:<行下标>`，值 `{orig, text}`，空 text 表示不发送）；只作用于发送副本，原文对不上时不套用。随医疗文件同步、进备份。
- 模型识图兜底得到的项没有行号，`locator` 为页码 + 用户的裁剪区域（`box` 即裁剪框；整页时没有 `box`），没有 `line_text`。

### 5.2a `condition` 身体状况记录（D-25）

记录类型为 `condition`，长期状况档案与临时疾病共用一个类型，`persistence` 区分。`occurred` 是首次发现/诊断日期（R-34：康复不改写既往病史；复查、发展作为新版本追加，历史版本保留）。

| data 字段 | 说明 |
|---|---|
| `name` | 状况名称，按原文（肾结石、青霉素过敏、感冒等） |
| `persistence` | `long_term` 长期状况（结石、囊肿、结节、慢性病、过敏等不会自行消失的）/ `temporary` 临时疾病（感冒发烧等预期痊愈的） |
| `status` | `active` / `resolved`（临时疾病痊愈、长期状况解除时标记，不删除记录） |
| `source_kind` | `report` 检查报告 / `visit` 就医 / `user_stated` 用户自述 |
| `evidence_text` | 依据原文片段（报告结论、诊断一栏） |
| `development_text` | 最近一次复查的发展情况描述（历史发展看记录版本） |
| `last_checked_date` | 最近复查日期，可空 |
| `medical_document_id` | 来源医疗文件，可空 |
| `locator` | 在原件中的位置（同 §5.2），可空 |

- 分析口径（D-25）：长期状况档案 = `persistence=long_term` 且已核对（confirmed/edited）的全部记录；临时疾病只取近 30 天。未核对不算事实（D-04）。
- 提取来源：结构化提取从报告的诊断/结论/印象文字中建议（unreviewed），用户核对；用户也可在档案页手动添加（user_stated，直接算已核对）。同一份文件里说的是同一问题的只建一条（汇总与明细写法不同也算，留名称更具体的）；这份文件或同一检查日期的文件已建过的不再建；其他日期报告里的同一问题各建一条，看当前状况时归成一组取最新（D-32）。

### 5.3 `lab_results` 检验项目索引（派生，D-27）

`lab_panel` 的 results 存在记录版本的 JSON 里，利于版本与溯源，但没法按项目跨时间查询（"近五年的血红蛋白"）。本表把当前版本的每个检验项目展开成一行做**冗余索引**，供趋势视图与后续分析直接查。

- **派生数据，不是事实源：** 随 lab_panel 记录版本变化在同一事务里重建（新版本 → 整条记录的行删了重插；记录删除 → 行删除）；可整表重算。
- **不入变更日志、不同步、不进备份：** 各设备从已同步的记录自行重建，与 organize_state、副本状态同类（§7.2）。

| 字段 | 说明 |
|---|---|
| `record_id` + `result_index` + `part` | 主键：哪条记录的第几项、拆成几行时的第几部分（`part`，D-39）：0 不拆；血压写成一项"122/86"的拆成 1 收缩压、2 舒张压两行，和分开写的报告进同一条趋势；医疗文件详情把两行合回一行按原文核对 |
| `revision_id` | 派生自哪个记录版本（核对后版本变化，行随之重建） |
| `medical_document_id` | 可空。来源医疗文件；机构名等展示信息查询时联表取，不冗余（避免文件信息更新后索引过期） |
| `item_name_raw` | 项目名称原文 |
| `panel_raw` | 检查大项原文，可空（D-36）；趋势列表按它分组（尿液分析、尿沉渣归"尿常规"；同类叫法按关键词归一，没有大项的按项目认，见 D-42；都认不出的归"其他"） |
| `item_key` | 查询键：原文去空白，去掉括号里的英文缩写与检测方法（"天门冬氨酸氨基转移酶（AST）""甲胎蛋白(AFP)（酶免法）"）和中文名后斜杠跟的缩写（"体重指数/BMI"）和项目名前后的互认标记（"*白细胞计数"的"*"、"★""※"等），同一项目在汇总与明细、不同年份报告里写法不同也能对上（D-32）；大项是尿、便检查的（尿常规、尿液分析、便常规…）键前加标本并统一写法（"白细胞(LEU)"→"尿白细胞"，"葡萄糖"→"尿糖"，"比重"/"尿比重"→"尿比重"），不与血里的同名项目混（D-36）；复测（"复测血压""收缩压（复测第1次）"）去掉"复测"和首次测量同键（D-39）；同一记录里同项目同数值只建一行。规划中：映射 `item_code`（LOINC）后按 code 查 |
| `value_raw` / `value_num` | 数值原文 / 解析值。白细胞分类的小数比值、写成小数的红细胞压积换算成百分数（原文写进参考说明）；没测的占位值（"-""未测"）建行供核对，但不进趋势 |
| `unit_raw` | 单位原文 |
| `ref_range_raw` / `ref_low` / `ref_high` | 参考范围 |
| `flag_raw` | 异常标记原文 |
| `exam_date` | 检查日期（记录的 occurred.local_date） |
| `review_status` | 该项的核对状态（fieldMeta `results.{i}`），趋势与分析据此过滤或标注未核对 |
| `updated_at` | 重建时间 |

## 6. 分析层（由 Mac 生成）

### 6.1 `analysis_artifacts` 分析结果

| 字段 | 说明 |
|---|---|
| `kind` | `weekly_review` 周报 / `visit_timeline` 就诊时间线 / `trend` 趋势。目前只实现了 `weekly_review`，另两种尚未实现 |
| `period_start` / `period_end` | 覆盖的日期范围 |
| `data_generation` / `data_cutoff_seq` | 生成时依据的手机端数据代次和变更序号（D-13、D-14） |
| `depends_on` | 依赖范围：日期区间和数据类型列表，比如 `{"dates": ["2026-09-20", "2026-09-26"], "types": ["meal", "sleep", "health_daily"]}`（D-14） |
| `generated_at` | 生成时间 |
| `generator` | 生成方式（`app` 应用内分析 / `external_agent` 外部 agent，后者尚未实现）、版本、使用的模型配置（D-20） |
| `model_call_ids` | 生成过程中的模型调用记录 |
| `content_md` | 正文，Markdown 格式 |
| `citations` | 列表，每项包含 `claim_id`（正文中某条陈述的标识）和 `record_revision_ids`、`message_ids`、`attachment_ids`（A-17） |
| `is_stale` | 在手机上实时计算，不存储。截止点之后依赖范围内的事实新增、纠错、作废或健康数据更新、数据代次改变时需要更新。仅清理/取回附件副本不令分析过期 |

### 6.2 `correction_suggestions` 修正建议

本表归在分析层，但手机整理批次遇到受保护字段时同样会提出修正建议（D-05 第 3 条、A-25）。`organize_run_id` 记录提出它的批次，Mac 分析提出时为空。目前只有手机整理批次会提出修正建议，Mac 分析提出尚未实现。

| 字段 | 说明 |
|---|---|
| `proposed_by` | `mac_analysis` Mac 分析提出 / `organize_run` 手机整理批次遇到受保护字段时提出（D-05） |
| `target_record_id` | 建议修改哪条记录 |
| `target_version` | 建议是基于该记录的哪个版本提出的。整理批次在同一次提交里还更新了该记录的其他字段时，取提交后的新版本，避免建议一生成就 `obsolete`（§3.1a） |
| `proposed_data` | 建议的新内容 |
| `reason` | 理由 |
| `status` | `pending` 待处理 / `accepted` 已接受 / `rejected` 已拒绝 / `obsolete` 已失效（目标记录已有更新的版本） |

用户在手机上接受后，手机生成该记录的新版本，状态为 `confirmed`，`produced_by` 指向这条建议。

## 7. 同步

### 7.1 `peers` 已配对设备

| 字段 | 说明 |
|---|---|
| `peer_device_id` | 对方设备 ID |
| `display_name` | 显示名称 |
| `cert_fingerprint` | 对方证书指纹，配对时固定下来（D-13） |
| `paired_at` | 配对时间 |
| `last_seen_addr` | 最近一次连接的地址 |
| `revoked_at` | 解除配对的时间，可空 |

### 7.2 `change_logs` 变更日志

每台设备各有一份。需要同步的本地产生业务变更（新增、纠错、作废）在同一事务里追加（D-13）。接收对方变更不再次产生同内容的回传变更。设备文件可用性独立通告，不混入医疗数据变更日志。

| 字段 | 说明 |
|---|---|
| `source_device_id` | 产生变更的设备 |
| `generation` | 数据代次，随机生成的唯一标识（D-13）。从备份恢复、换手机迁移时生成全新代次；同一份备份恢复两次得到两个不同的代次，不与旧确认状态碰撞 |
| `change_seq` | 本设备、本代次内单调递增，无空洞 |
| `entity_type` / `entity_id` | 变更的是哪张表的哪一行 |
| `entity_version` | 变更后该实体的 `version` |
| `op` | `upsert` 新建或修改 / `delete` 业务数据作废标记；手机文件清理不是 `delete` |
| `payload` | 变更发生时该实体行的完整快照（JSON，数据库原值）。为满足下方"负载与 entity_version 一致"，在记录变更的同一事务里对行拍快照，发送时用快照而不读当前行 |
| `depends_on_blob` | 可空。这条变更依赖的附件 `sha256`，附件确认前这条变更不算完成 |
| `created_at` | 时间 |

**不入本日志的：** `attachment_copies`（副本可用状态独立通告，见 §7.4）、`review_prompts` 与 `settings`（不同步）、消息 `organize_state` 的单独变化（手机内部状态，不抬版本；Mac 副本以最后一次实体变更为准）。`data_generation` 存在 settings，不随导出走——恢复后首次写入时生成全新代次。

**变更包的版本、操作与正文对应同一状态：** 发送序号 N 的变更时，负载必须是 `entity_version` 所指的那个版本的内容，不能读实体当前内容——同一实体离线连改两次后，先发的旧序号会出现"包头 v1、正文 v2"的混装。实现时保留与版本一致的负载，或引用可按版本读取的不可变修订（记录版本、消息修改历史本身就是不可变的）。**不合并待发送条目：** 每条变更按序号依次发送、依次确认，即使同一实体有多条未发送的变更；否则被跳过的旧序号永远得不到确认，连续游标（§7.3）无法推进。合并发送尚未实现，前提是先定义一次确认覆盖哪些旧序号。

### 7.3 `sync_states` 同步进度

| 字段 | 说明 |
|---|---|
| `peer_device_id` | 对方设备 |
| `direction` | `push` 本机发往对方 / `pull` 对方发往本机 |
| `generation` | 当前同步的数据代次 |
| `acked_contiguous_seq` | 对方从头开始**连续**确认的最大 `change_seq`。只有它之前的变更全部确认后才能推进，不取已确认序号的最大值 |
| `acked_ranges` | 已确认但还不连续的序号区间，比如 `[[15,15]]`，用于续传时跳过 |
| `pending_count` | 待传数量，用于界面显示 |
| `last_success_at` | 最近一次成功同步的时间 |
| `last_error` | 最近一次错误 |

**代次变化：** 接收方发现对方的 `generation` 变了（对方从备份恢复或换了手机），不沿用旧的序号。完整恢复是用户明确执行的操作：Mac 按新代次以手机当前状态重建手机数据的副本，不做跨代次的 `entity_version` 大小比较；Mac 上恢复点之后的手机数据保留还是清除，在恢复界面向用户说明，不由版本比较隐式决定。Mac 自己生成的分析结果和修正建议不在重建范围内。之后从新代次的序号继续（D-13）。具体做法（D-34）：Mac 收到新代次先拒收并记下待重建，用户确认后先备份，再清掉这台手机的副本行（Mac 自己的和其他设备的保留），接收进度改到新代次从 1 开始；手机端回填标记记已回填的代次，换代次后在新代次里回填全部数据。不提供"保留 Mac 多出的"：恢复后消息序号会与 Mac 上多出的消息撞号。

### 7.4 各类数据的同步范围

| 数据 | 手机 → Mac | Mac → 手机 |
|---|---|---|
| 消息、消息修改历史、附件索引和关联 | ✓ | |
| 附件文件 | 初次归档到 Mac | 用户主动取回时 |
| 设备副本可用状态通告 | ✓，仅描述手机副本 | ✓，仅描述 Mac 副本 |
| 整理批次、记录、记录版本、来源链接 | ✓ | |
| 模型调用记录 | ✓ | |
| 设备健康样本、日聚合数据 | ✓ | |
| 用户资料 | ✓ | |
| 医疗文件 | ✓ | |
| 分析结果、修正建议 | | ✓ |
| 修正建议的处理状态 | ✓ | |
| 模型配置、key、设置 | 不同步 | 不同步 |

**附件的传输规则：** 发送方先告诉对方文件的 `sha256`，对方没有这个文件时才传输。对方写入并校验哈希通过后返回确认。依赖这个附件的变更（`depends_on_blob`）在附件确认后才算确认，之后才能推进 `acked_contiguous_seq`。对方可以先保存记录，在附件到齐前标为"附件缺失"。

**手机原件清理：** 只更新手机自己的 `attachment_copies`。Mac 收到手机状态通告后保留本机原件，不删除病历或文件。普通同步不向手机推回已主动清理的文件（A-33）。

**取回：** 用户选择查看原件时，手机请求同一附件 ID 和哈希的文件。完成落盘校验后更新手机副本，现有来源链接即可重新打开（A-21）。若 Mac 不可达或文件已缺失，显示不可用，不影响已提取数据。

**任务协调：** 原件导入、模型提取或文件发送正在读取的本机文件不进入清理；等待任务结束再清理。文件传输中断和重试沿用原附件身份，不产生医疗记录删除或新建。

### 7.5 `backup_runs` 备份记录（Mac 端）

| 字段 | 说明 |
|---|---|
| `backup_id` | 备份 ID |
| `data_generation` / `cutoff_seq` | 数据库快照对应的数据代次和变更序号 |
| `manifest` | 文件清单：截止点时所有应存在的附件 `sha256` 和大小，以及数据库快照的哈希 |
| `status` | `building` 生成中 / `verifying` 校验中 / `published` 可用 / `failed` 失败 |
| `target_path` | 备份文件位置。生成中使用临时文件名，校验通过后才改为正式文件名 |
| `verified_at` | 校验通过的时间 |
| `error` | 失败原因，可空 |

**文件一致性：** 获取快照前先保护所需的 Mac 文件，登记清单后保持到备份结束；失败任务或应用重启后释放遗留的保护（D-15）。手机清理不影响 Mac 原件。Mac 缺失的原件必须在备份清单中列为缺失；恢复时区分“原件完整恢复”和“仅恢复提取数据”，不能把文件缺失当成业务记录删除。

**备份密钥：** 由用户设置的备份密码派生，存在 Mac 的 Keychain，不进入数据库（D-15）。

## 8. 医疗原件清理与历史数据保留

对应 R-32、R-34 和 D-22。

| 操作 | 手机文件 | 历史医疗数据、核对状态与来源 | Mac / 备份 |
|---|---|---|---|
| 清理手机原件 | 实际清理后标为 `offloaded`，释放空间 | 全部保留；事实版本不变 | 已有原件保留 |
| 从 Mac 取回或重新提供同一文件 | 校验后转为 `present` | 不新增重复记录，来源可重新打开 | 不删除已有副本 |
| 康复、复查或新的就诊 | 不自动操作文件 | 追加新的带日期记录，既往病史保留 | 正常同步新记录 |
| 识别错误、误录纠错 | 不自动清理文件 | 按已有纠错机制生成修订，保留历史 | 同步修订；独立于空间清理 |

- 范围主要是医疗图片、PDF，不扩展到文字原文清除、历史字段抹除或全设备删除。
- 正在提取或发送的文件不清理；默认批量选已提取、已核对的医疗文件。用户清理唯一已知原件前显示无法再次核对的后果，允许取消或明确保留提取数据后继续。
- 未核对指标仍未核对，不因清理而自动确认；没有可用原件时不能再次 OCR。取回后可重新核对，重新提取也不能自动覆盖已确认事实。
- 导出始终包含保留的记录与附件索引；只复制当前可用的文件，清单区分主动清理、已知远端副本和意外缺失。整库恢复与单文件取回是两条独立流程。
- 不提供“删除原件及全部派生数据”与跨设备彻底抹除，医疗原件空间管理也不以它们为前提。
