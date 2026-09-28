import 'package:drift/drift.dart';

import '../field_meta.dart' show ReviewStatus;

/// 枚举值与数据库文本的对应（docs/schema.md 中的取值，snake_case）。
String enumToDb(Enum e) => e.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );

T enumFromDb<T extends Enum>(List<T> values, String db) =>
    values.firstWhere((v) => enumToDb(v) == db);

class EnumConverter<T extends Enum> extends TypeConverter<T, String> {
  const EnumConverter(this.values);
  final List<T> values;

  @override
  T fromSql(String fromDb) => enumFromDb(values, fromDb);

  @override
  String toSql(T value) => enumToDb(value);
}

enum MessageRole { user, app }

enum MessageKind { text, attachments, appPrompt, appNotice, doneMarker }

enum OrganizeState {
  pending,
  organized,
  needsReorganize,
  needsManual,
  notApplicable,
}

enum CopyState { present, offloaded, missing }

enum ProfileFieldState { provided, skipped, declined }

// —— v0.2 起（schema §2.5/§2.6/§3/§4.3/§4.4）——

enum HealthSampleType { sleep, workout }

enum SleepStage { inBed, asleepUnspecified, core, deep, rem, awake }

enum HealthMetric { steps, activeEnergyKcal }

enum OrganizeTrigger { doneMarker, idle, dailyReview, userReorganize }

enum OrganizeRunStatus {
  queued,
  running,
  succeeded,
  partial,
  failed,
  blockedBoundary,
}

enum OrganizeItemStatus {
  /// 已登记待提交：项 ID 在模型产出确定后、正式提交前持久化（schema §3.1a），
  /// 崩溃重试时凭它不重复建记录。
  pending,
  committed,
  staleInput,
  staleTarget,
  protectedSuggested,
  needsManual,
}

enum DataBoundary { device, lan, cloud }

enum ModelCallStatus { succeeded, failed, timeout }

enum ModelCaller { phoneOrganize, macAnalysis, externalAgent, phoneMedicalExtract }

enum RecordType { meal, sleep, mood, symptom, exercise, note, labPanel }

/// schema.md §5.1：医疗文件类型（v0.4）。
enum MedicalDocType {
  labReport,
  imagingReport,
  visitRecord,
  prescription,
  dischargeSummary,
  physicalExam,
  other,
}

enum RecordSourceKind { message, attachment, healthSample, healthDaily }

enum ModelPreset { openai, anthropic, deepseek, openaiCompatible, ollama }

enum ModelProtocol { openaiCompatible, anthropic }

enum ReviewOutcome { answered, skipped, noResponse }

enum SuggestionProposedBy { macAnalysis, organizeRun }

enum SuggestionStatus { pending, accepted, rejected, obsolete }

enum ChangeOp { upsert, delete }

enum SyncDirection { push, pull }

enum AnalysisKind { weeklyReview, visitTimeline, trend }

enum BackupStatus { building, verifying, published, failed }

/// 所有实体共有的字段（schema.md §1.1）。
/// 时间一律存 UTC 毫秒；`change_seq` 到 v0.3 建 change_log 时才使用。
mixin CommonColumns on Table {
  TextColumn get id => text()(); // UUIDv7
  TextColumn get userId => text()();
  IntColumn get createdAt => integer()();
  TextColumn get createdOnDevice => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get changeSeq => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// schema.md §2.1
class Messages extends Table with CommonColumns {
  TextColumn get clientMsgId => text().unique()();
  IntColumn get seq => integer().unique()();
  TextColumn get role => text().map(const EnumConverter(MessageRole.values))();
  TextColumn get kind => text().map(const EnumConverter(MessageKind.values))();
  TextColumn get body => text().nullable().named('text')();
  IntColumn get revisionNo => integer().withDefault(const Constant(0))();
  IntColumn get sentAt => integer()();
  TextColumn get sentTz => text()();
  TextColumn get inReplyTo => text().nullable()();
  TextColumn get promptMeta => text().nullable()();
  TextColumn get organizeState =>
      text().map(const EnumConverter(OrganizeState.values))();
}

/// schema.md §2.2：revision_no 是被替换文字原来的修订号，从 0 开始。
class MessageRevisions extends Table with CommonColumns {
  TextColumn get messageId => text()();
  IntColumn get revisionNo => integer()();
  TextColumn get textBefore => text()();
  IntColumn get editedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {messageId, revisionNo},
      ];
}

/// schema.md §2.3：同一内容只对应一个附件身份。
class Attachments extends Table with CommonColumns {
  TextColumn get sha256 => text().unique()();
  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer()();
  TextColumn get originalFilename => text().nullable()();
  IntColumn get firstImportedAt => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();
}

/// schema.md §2.3a：每台设备的文件副本状态。
class AttachmentCopies extends Table with CommonColumns {
  TextColumn get attachmentId => text()();
  TextColumn get deviceId => text()();
  TextColumn get state => text().map(const EnumConverter(CopyState.values))();
  TextColumn get localPath => text().nullable()();
  IntColumn get verifiedAt => integer().nullable()();
  IntColumn get offloadedAt => integer().nullable()();
  TextColumn get previewPath => text().nullable()();
  IntColumn get copyVersion => integer().withDefault(const Constant(1))();
  IntColumn get lastReportedAt => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {attachmentId, deviceId},
      ];
}

/// schema.md §2.4
class MessageAttachments extends Table with CommonColumns {
  TextColumn get messageId => text()();
  TextColumn get attachmentId => text()();
  IntColumn get position => integer()();
  BoolColumn get duplicateAcknowledged =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {messageId, attachmentId},
      ];
}

/// schema.md §4.1：追加式，每次修改写入新版本行，历史全部保留。
class ProfileFields extends Table with CommonColumns {
  TextColumn get fieldKey => text()();
  TextColumn get value => text()(); // JSON
  TextColumn get state =>
      text().map(const EnumConverter(ProfileFieldState.values))();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {fieldKey, version},
      ];
}

/// schema.md §4.2：键值对，只存在手机上。
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

/// schema.md §2.5：设备健康样本，按条保存，`platform_uuid` 去重。
class HealthSamples extends Table with CommonColumns {
  TextColumn get platformUuid => text().unique()();
  TextColumn get sampleType =>
      text().map(const EnumConverter(HealthSampleType.values))();
  IntColumn get startUtc => integer()();
  IntColumn get endUtc => integer()();
  TextColumn get tz => text()();
  BoolColumn get tzInferred => boolean().withDefault(const Constant(false))();
  TextColumn get sourceBundleId => text().nullable()();
  TextColumn get sleepStage =>
      text().map(const EnumConverter(SleepStage.values)).nullable()();
  TextColumn get workoutType => text().nullable()();
  RealColumn get energyKcal => real().nullable()();
  RealColumn get distanceM => real().nullable()();
  TextColumn get sourceName => text()();
  IntColumn get fetchedAt => integer()();
  IntColumn get removedInSourceAt => integer().nullable()();
}

/// schema.md §2.5：anchored query 的锚点，每种样本类型一行。
class HealthAnchors extends Table {
  TextColumn get sampleType =>
      text().map(const EnumConverter(HealthSampleType.values))();
  BlobColumn get anchor => blob()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {sampleType};
}

/// schema.md §2.6：按天聚合的设备数据。同一天重复读取覆盖本行；
/// 没有行表示"暂未读取到"，不表示 0（D-11）。
class HealthDaily extends Table with CommonColumns {
  TextColumn get localDate => text()();
  TextColumn get aggTz => text()();
  IntColumn get intervalStartUtc => integer()();
  IntColumn get intervalEndUtc => integer()();
  TextColumn get metric =>
      text().map(const EnumConverter(HealthMetric.values))();
  RealColumn get value => real()();
  IntColumn get fetchedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {localDate, metric},
      ];
}

/// schema.md §3.1：整理批次。
class OrganizeRuns extends Table with CommonColumns {
  TextColumn get trigger =>
      text().map(const EnumConverter(OrganizeTrigger.values))();
  TextColumn get inputSnapshot => text()(); // JSON（D-05）
  TextColumn get modelConfigId => text().nullable()();
  TextColumn get modelSnapshot => text().nullable()(); // JSON，不含 key
  TextColumn get status =>
      text().map(const EnumConverter(OrganizeRunStatus.values))();
  TextColumn get error => text().nullable()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get finishedAt => integer().nullable()();
}

/// schema.md §3.1a：批次的逐项结果，单独提交；
/// `record_id` 在提交前就持久化，重试凭它不重复建记录。
class OrganizeRunItems extends Table with CommonColumns {
  TextColumn get organizeRunId => text()();
  TextColumn get recordId => text()();
  TextColumn get status =>
      text().map(const EnumConverter(OrganizeItemStatus.values))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get correctionSuggestionId => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {organizeRunId, recordId},
      ];
}

/// schema.md §3.2：模型调用记录（D-16 透明度）。
class ModelCalls extends Table with CommonColumns {
  TextColumn get organizeRunId => text().nullable()();
  TextColumn get modelConfigId => text()();
  TextColumn get dataBoundary =>
      text().map(const EnumConverter(DataBoundary.values))();
  TextColumn get sentMessageIds => text()(); // JSON 数组
  TextColumn get sentAttachmentIds => text()(); // JSON 数组
  IntColumn get requestAt => integer()();
  IntColumn get responseAt => integer().nullable()();
  TextColumn get status =>
      text().map(const EnumConverter(ModelCallStatus.values))();
  IntColumn get tokensIn => integer().nullable()();
  IntColumn get tokensOut => integer().nullable()();
  TextColumn get responseText => text().nullable()();
  TextColumn get caller =>
      text().map(const EnumConverter(ModelCaller.values))();

  /// 本次发送前本地脱敏遮蔽的项数（D-24 透明度）；不适用的调用为 null。
  IntColumn get redactedCount => integer().nullable()();
}

/// schema.md §3.3：记录。数据类名避开 dart:core 的 Record。
@DataClassName('RecordRow')
class Records extends Table with CommonColumns {
  TextColumn get recordType =>
      text().map(const EnumConverter(RecordType.values))();
  TextColumn get currentRevisionId => text().nullable()();
  TextColumn get localDate => text().nullable()(); // 冗余自当前版本，按日查询用
}

/// schema.md §3.4：记录版本。`record_version` 即 schema 的 `version`，
/// 改名避开通用字段；与所属记录的通用 `version` 保持一致，用于过时检查。
class RecordRevisions extends Table with CommonColumns {
  TextColumn get recordId => text()();
  IntColumn get recordVersion => integer()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get occurred => text()(); // TimeValue JSON（schema §1.2）
  TextColumn get occurredEnd => text().nullable()();
  TextColumn get data => text()(); // JSON，按类型见 schema §3.5
  TextColumn get producedBy => text()(); // JSON（schema §1.3 版本级）
  TextColumn get fieldMeta => text()(); // JSON（schema §1.3 字段级）

  @override
  List<Set<Column>> get uniqueKeys => [
        {recordId, recordVersion},
      ];
}

/// schema.md §3.6：来源链接，消息与记录多对多。
class RecordSources extends Table with CommonColumns {
  TextColumn get recordRevisionId => text()();
  TextColumn get fieldPath => text().nullable()();
  TextColumn get sourceKind =>
      text().map(const EnumConverter(RecordSourceKind.values))();
  TextColumn get sourceId => text()();
  IntColumn get messageRevisionNo => integer().nullable()();
  TextColumn get span => text().nullable()(); // JSON
}

/// schema.md §4.3：模型配置。不参与同步、不进备份；key 只存 Keychain 引用。
class ModelConfigs extends Table with CommonColumns {
  TextColumn get preset =>
      text().map(const EnumConverter(ModelPreset.values))();
  TextColumn get protocol =>
      text().map(const EnumConverter(ModelProtocol.values))();
  TextColumn get baseUrl => text()();
  TextColumn get model => text()();
  TextColumn get capabilities =>
      text().withDefault(const Constant('[]'))(); // JSON：["text","image","pdf"]
  TextColumn get dataBoundary =>
      text().map(const EnumConverter(DataBoundary.values))();
  TextColumn get keychainRef => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get lastTestAt => integer().nullable()();
  TextColumn get lastTestResult => text().nullable()();
}

/// schema.md §6.2：修正建议。表定义在分析层（v0.3），但手机整理遇到
/// 受保护字段时也会提出（D-05 第 3 条，A-25 是 v0.2 验收），所以现在就建。
class CorrectionSuggestions extends Table with CommonColumns {
  TextColumn get proposedBy =>
      text().map(const EnumConverter(SuggestionProposedBy.values))();
  TextColumn get organizeRunId => text().nullable()();
  TextColumn get targetRecordId => text()();
  IntColumn get targetVersion => integer()();
  TextColumn get proposedData => text()(); // JSON：{field_path: 新值}
  TextColumn get reason => text()();
  TextColumn get status =>
      text().map(const EnumConverter(SuggestionStatus.values))();
}

/// schema.md §7.5：备份记录（Mac 端）。生成中用临时目录名，
/// 校验通过后才改正式名并转 published。
class BackupRuns extends Table {
  TextColumn get backupId => text()();
  TextColumn get dataGeneration => text()();
  IntColumn get cutoffSeq => integer()();
  TextColumn get manifest => text()(); // JSON：文件清单 + 数据库快照哈希
  TextColumn get status =>
      text().map(const EnumConverter(BackupStatus.values))();
  TextColumn get targetPath => text()();
  IntColumn get verifiedAt => integer().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {backupId};
}

/// schema.md §6.1：分析结果（Mac 生成，回传手机）。
/// `is_stale` 实时计算不存储。
class AnalysisArtifacts extends Table with CommonColumns {
  TextColumn get kind =>
      text().map(const EnumConverter(AnalysisKind.values))();
  TextColumn get periodStart => text()();
  TextColumn get periodEnd => text()();
  TextColumn get dataGeneration => text()();
  IntColumn get dataCutoffSeq => integer()();
  TextColumn get dependsOn => text()(); // JSON（D-14）
  IntColumn get generatedAt => integer()();
  TextColumn get generator => text()(); // JSON（方式/版本/模型配置，D-20）
  TextColumn get modelCallIds => text()(); // JSON 数组
  TextColumn get contentMd => text()();
  TextColumn get citations => text()(); // JSON（A-17）
}

/// schema.md §7.3：同步进度。push = 本机发往对方，pull = 对方发来。
/// `acked_contiguous_seq` 只在它之前全部确认后才推进。
class SyncStates extends Table {
  TextColumn get peerDeviceId => text()();
  TextColumn get direction =>
      text().map(const EnumConverter(SyncDirection.values))();
  TextColumn get generation => text()();
  IntColumn get ackedContiguousSeq =>
      integer().withDefault(const Constant(0))();
  TextColumn get ackedRanges => text().withDefault(const Constant('[]'))();
  IntColumn get pendingCount => integer().withDefault(const Constant(0))();
  IntColumn get lastSuccessAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {peerDeviceId, direction};
}

/// schema.md §7.1：已配对设备。`cert_fingerprint` 是配对密钥的
/// SHA-256 指纹（配对时固定，D-13）；密钥本体存系统安全存储。
class Peers extends Table {
  TextColumn get peerDeviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get certFingerprint => text()();
  IntColumn get pairedAt => integer()();
  TextColumn get lastSeenAddr => text().nullable()();
  IntColumn get revokedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {peerDeviceId};
}

/// schema.md §7.2：变更日志。本设备本代次内 change_seq 单调递增无空洞；
/// payload 是变更同一事务里的行快照（负载与 entity_version 一致）。
/// 只记本机产生的业务变更；接收对方变更不回传（D-13）。
class ChangeLogs extends Table {
  TextColumn get sourceDeviceId => text()();
  TextColumn get generation => text()();
  IntColumn get changeSeq => integer()();
  TextColumn get entityType => text()(); // SQLite 表名
  TextColumn get entityId => text()();
  IntColumn get entityVersion => integer()();
  TextColumn get op => text().map(const EnumConverter(ChangeOp.values))();
  TextColumn get payload => text()(); // JSON 行快照
  TextColumn get dependsOnBlob => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {generation, changeSeq};
}

/// schema.md §4.4：回顾提问记录，用于当天不重复提问、问题数量 ≤3（D-08）。
class ReviewPrompts extends Table with CommonColumns {
  TextColumn get reviewDate => text()();
  TextColumn get promptMessageId => text()();
  TextColumn get gapKey => text()();
  TextColumn get templateId => text()();
  TextColumn get outcome =>
      text().map(const EnumConverter(ReviewOutcome.values)).nullable()();
  TextColumn get answeredMessageId => text().nullable()();
}

/// schema.md §5.1：医疗文件（v0.4）。一份文件由一或多个附件页组成，
/// 页可以来自不同消息；页序用户可调。exam_date / report_date / uploaded_at
/// 是三个不同的时间（D-06 区分发生与记录）。
class MedicalDocuments extends Table with CommonColumns {
  /// JSON 有序列表：[{"attachment_id","message_id","page_no"}]。
  TextColumn get pages => text()();
  TextColumn get docType =>
      text().map(const EnumConverter(MedicalDocType.values))();
  TextColumn get institutionText => text().nullable()();
  TextColumn get examDate => text().nullable()(); // TimeValue JSON
  TextColumn get reportDate => text().nullable()(); // TimeValue JSON
  IntColumn get uploadedAt => integer()();
  TextColumn get reviewStatus => text()
      .map(const EnumConverter(ReviewStatus.values))
      .withDefault(const Constant('unreviewed'))();

  /// 页筛选的用户覆盖（D-23 默认筛选+用户可改）：JSON {"页号": true/false}，
  /// true 强制发送、false 强制排除；没写的页用规则默认。设备本地展示与
  /// 发送范围，参与同步（手机是唯一编辑者）。
  TextColumn get pageOverrides => text().nullable()();
}

/// schema.md §5.3：检验项目索引（v0.4，D-27）。派生数据：随 lab_panel
/// 记录版本同事务重建，可整表重算；不入变更日志、不同步、不进备份。
class LabResults extends Table {
  TextColumn get recordId => text()();
  IntColumn get resultIndex => integer()();
  TextColumn get revisionId => text()();
  TextColumn get medicalDocumentId => text().nullable()();
  TextColumn get itemNameRaw => text()();
  TextColumn get itemKey => text()();
  TextColumn get valueRaw => text()();
  RealColumn get valueNum => real().nullable()();
  TextColumn get unitRaw => text().nullable()();
  TextColumn get refRangeRaw => text().nullable()();
  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();
  TextColumn get flagRaw => text().nullable()();
  TextColumn get examDate => text().nullable()();
  TextColumn get reviewStatus => text()
      .map(const EnumConverter(ReviewStatus.values))
      .withDefault(const Constant('unreviewed'))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {recordId, resultIndex};
}
