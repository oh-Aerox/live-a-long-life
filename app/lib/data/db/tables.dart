import 'package:drift/drift.dart';

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
