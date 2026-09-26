// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessageRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MessageRole>($MessagesTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<MessageKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MessageKind>($MessagesTable.$converterkind);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionNoMeta = const VerificationMeta(
    'revisionNo',
  );
  @override
  late final GeneratedColumn<int> revisionNo = GeneratedColumn<int>(
    'revision_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentTzMeta = const VerificationMeta('sentTz');
  @override
  late final GeneratedColumn<String> sentTz = GeneratedColumn<String>(
    'sent_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inReplyToMeta = const VerificationMeta(
    'inReplyTo',
  );
  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
    'in_reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptMetaMeta = const VerificationMeta(
    'promptMeta',
  );
  @override
  late final GeneratedColumn<String> promptMeta = GeneratedColumn<String>(
    'prompt_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OrganizeState, String>
  organizeState = GeneratedColumn<String>(
    'organize_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OrganizeState>($MessagesTable.$converterorganizeState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    clientMsgId,
    seq,
    role,
    kind,
    body,
    revisionNo,
    sentAt,
    sentTz,
    inReplyTo,
    promptMeta,
    organizeState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMsgIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    }
    if (data.containsKey('revision_no')) {
      context.handle(
        _revisionNoMeta,
        revisionNo.isAcceptableOrUnknown(data['revision_no']!, _revisionNoMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('sent_tz')) {
      context.handle(
        _sentTzMeta,
        sentTz.isAcceptableOrUnknown(data['sent_tz']!, _sentTzMeta),
      );
    } else if (isInserting) {
      context.missing(_sentTzMeta);
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
        _inReplyToMeta,
        inReplyTo.isAcceptableOrUnknown(data['in_reply_to']!, _inReplyToMeta),
      );
    }
    if (data.containsKey('prompt_meta')) {
      context.handle(
        _promptMetaMeta,
        promptMeta.isAcceptableOrUnknown(data['prompt_meta']!, _promptMetaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: $MessagesTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      kind: $MessagesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      revisionNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_no'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      sentTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_tz'],
      )!,
      inReplyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_reply_to'],
      ),
      promptMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_meta'],
      ),
      organizeState: $MessagesTable.$converterorganizeState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}organize_state'],
        )!,
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static TypeConverter<MessageRole, String> $converterrole =
      const EnumConverter(MessageRole.values);
  static TypeConverter<MessageKind, String> $converterkind =
      const EnumConverter(MessageKind.values);
  static TypeConverter<OrganizeState, String> $converterorganizeState =
      const EnumConverter(OrganizeState.values);
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String clientMsgId;
  final int seq;
  final MessageRole role;
  final MessageKind kind;
  final String? body;
  final int revisionNo;
  final int sentAt;
  final String sentTz;
  final String? inReplyTo;
  final String? promptMeta;
  final OrganizeState organizeState;
  const Message({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.clientMsgId,
    required this.seq,
    required this.role,
    required this.kind,
    this.body,
    required this.revisionNo,
    required this.sentAt,
    required this.sentTz,
    this.inReplyTo,
    this.promptMeta,
    required this.organizeState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['client_msg_id'] = Variable<String>(clientMsgId);
    map['seq'] = Variable<int>(seq);
    {
      map['role'] = Variable<String>($MessagesTable.$converterrole.toSql(role));
    }
    {
      map['kind'] = Variable<String>($MessagesTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || body != null) {
      map['text'] = Variable<String>(body);
    }
    map['revision_no'] = Variable<int>(revisionNo);
    map['sent_at'] = Variable<int>(sentAt);
    map['sent_tz'] = Variable<String>(sentTz);
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    if (!nullToAbsent || promptMeta != null) {
      map['prompt_meta'] = Variable<String>(promptMeta);
    }
    {
      map['organize_state'] = Variable<String>(
        $MessagesTable.$converterorganizeState.toSql(organizeState),
      );
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientMsgId: Value(clientMsgId),
      seq: Value(seq),
      role: Value(role),
      kind: Value(kind),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      revisionNo: Value(revisionNo),
      sentAt: Value(sentAt),
      sentTz: Value(sentTz),
      inReplyTo: inReplyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(inReplyTo),
      promptMeta: promptMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(promptMeta),
      organizeState: Value(organizeState),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      clientMsgId: serializer.fromJson<String>(json['clientMsgId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<MessageRole>(json['role']),
      kind: serializer.fromJson<MessageKind>(json['kind']),
      body: serializer.fromJson<String?>(json['body']),
      revisionNo: serializer.fromJson<int>(json['revisionNo']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      sentTz: serializer.fromJson<String>(json['sentTz']),
      inReplyTo: serializer.fromJson<String?>(json['inReplyTo']),
      promptMeta: serializer.fromJson<String?>(json['promptMeta']),
      organizeState: serializer.fromJson<OrganizeState>(json['organizeState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'clientMsgId': serializer.toJson<String>(clientMsgId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<MessageRole>(role),
      'kind': serializer.toJson<MessageKind>(kind),
      'body': serializer.toJson<String?>(body),
      'revisionNo': serializer.toJson<int>(revisionNo),
      'sentAt': serializer.toJson<int>(sentAt),
      'sentTz': serializer.toJson<String>(sentTz),
      'inReplyTo': serializer.toJson<String?>(inReplyTo),
      'promptMeta': serializer.toJson<String?>(promptMeta),
      'organizeState': serializer.toJson<OrganizeState>(organizeState),
    };
  }

  Message copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? clientMsgId,
    int? seq,
    MessageRole? role,
    MessageKind? kind,
    Value<String?> body = const Value.absent(),
    int? revisionNo,
    int? sentAt,
    String? sentTz,
    Value<String?> inReplyTo = const Value.absent(),
    Value<String?> promptMeta = const Value.absent(),
    OrganizeState? organizeState,
  }) => Message(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientMsgId: clientMsgId ?? this.clientMsgId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    kind: kind ?? this.kind,
    body: body.present ? body.value : this.body,
    revisionNo: revisionNo ?? this.revisionNo,
    sentAt: sentAt ?? this.sentAt,
    sentTz: sentTz ?? this.sentTz,
    inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
    promptMeta: promptMeta.present ? promptMeta.value : this.promptMeta,
    organizeState: organizeState ?? this.organizeState,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      revisionNo: data.revisionNo.present
          ? data.revisionNo.value
          : this.revisionNo,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      sentTz: data.sentTz.present ? data.sentTz.value : this.sentTz,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : this.inReplyTo,
      promptMeta: data.promptMeta.present
          ? data.promptMeta.value
          : this.promptMeta,
      organizeState: data.organizeState.present
          ? data.organizeState.value
          : this.organizeState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('revisionNo: $revisionNo, ')
          ..write('sentAt: $sentAt, ')
          ..write('sentTz: $sentTz, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('promptMeta: $promptMeta, ')
          ..write('organizeState: $organizeState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    clientMsgId,
    seq,
    role,
    kind,
    body,
    revisionNo,
    sentAt,
    sentTz,
    inReplyTo,
    promptMeta,
    organizeState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.clientMsgId == this.clientMsgId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.revisionNo == this.revisionNo &&
          other.sentAt == this.sentAt &&
          other.sentTz == this.sentTz &&
          other.inReplyTo == this.inReplyTo &&
          other.promptMeta == this.promptMeta &&
          other.organizeState == this.organizeState);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> clientMsgId;
  final Value<int> seq;
  final Value<MessageRole> role;
  final Value<MessageKind> kind;
  final Value<String?> body;
  final Value<int> revisionNo;
  final Value<int> sentAt;
  final Value<String> sentTz;
  final Value<String?> inReplyTo;
  final Value<String?> promptMeta;
  final Value<OrganizeState> organizeState;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.revisionNo = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.sentTz = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.promptMeta = const Value.absent(),
    this.organizeState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String clientMsgId,
    required int seq,
    required MessageRole role,
    required MessageKind kind,
    this.body = const Value.absent(),
    this.revisionNo = const Value.absent(),
    required int sentAt,
    required String sentTz,
    this.inReplyTo = const Value.absent(),
    this.promptMeta = const Value.absent(),
    required OrganizeState organizeState,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       clientMsgId = Value(clientMsgId),
       seq = Value(seq),
       role = Value(role),
       kind = Value(kind),
       sentAt = Value(sentAt),
       sentTz = Value(sentTz),
       organizeState = Value(organizeState);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? clientMsgId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<int>? revisionNo,
    Expression<int>? sentAt,
    Expression<String>? sentTz,
    Expression<String>? inReplyTo,
    Expression<String>? promptMeta,
    Expression<String>? organizeState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (kind != null) 'kind': kind,
      if (body != null) 'text': body,
      if (revisionNo != null) 'revision_no': revisionNo,
      if (sentAt != null) 'sent_at': sentAt,
      if (sentTz != null) 'sent_tz': sentTz,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (promptMeta != null) 'prompt_meta': promptMeta,
      if (organizeState != null) 'organize_state': organizeState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? clientMsgId,
    Value<int>? seq,
    Value<MessageRole>? role,
    Value<MessageKind>? kind,
    Value<String?>? body,
    Value<int>? revisionNo,
    Value<int>? sentAt,
    Value<String>? sentTz,
    Value<String?>? inReplyTo,
    Value<String?>? promptMeta,
    Value<OrganizeState>? organizeState,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      revisionNo: revisionNo ?? this.revisionNo,
      sentAt: sentAt ?? this.sentAt,
      sentTz: sentTz ?? this.sentTz,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      promptMeta: promptMeta ?? this.promptMeta,
      organizeState: organizeState ?? this.organizeState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $MessagesTable.$converterrole.toSql(role.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $MessagesTable.$converterkind.toSql(kind.value),
      );
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (revisionNo.present) {
      map['revision_no'] = Variable<int>(revisionNo.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (sentTz.present) {
      map['sent_tz'] = Variable<String>(sentTz.value);
    }
    if (inReplyTo.present) {
      map['in_reply_to'] = Variable<String>(inReplyTo.value);
    }
    if (promptMeta.present) {
      map['prompt_meta'] = Variable<String>(promptMeta.value);
    }
    if (organizeState.present) {
      map['organize_state'] = Variable<String>(
        $MessagesTable.$converterorganizeState.toSql(organizeState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('revisionNo: $revisionNo, ')
          ..write('sentAt: $sentAt, ')
          ..write('sentTz: $sentTz, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('promptMeta: $promptMeta, ')
          ..write('organizeState: $organizeState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageRevisionsTable extends MessageRevisions
    with TableInfo<$MessageRevisionsTable, MessageRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionNoMeta = const VerificationMeta(
    'revisionNo',
  );
  @override
  late final GeneratedColumn<int> revisionNo = GeneratedColumn<int>(
    'revision_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textBeforeMeta = const VerificationMeta(
    'textBefore',
  );
  @override
  late final GeneratedColumn<String> textBefore = GeneratedColumn<String>(
    'text_before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    messageId,
    revisionNo,
    textBefore,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('revision_no')) {
      context.handle(
        _revisionNoMeta,
        revisionNo.isAcceptableOrUnknown(data['revision_no']!, _revisionNoMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionNoMeta);
    }
    if (data.containsKey('text_before')) {
      context.handle(
        _textBeforeMeta,
        textBefore.isAcceptableOrUnknown(data['text_before']!, _textBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_textBeforeMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {messageId, revisionNo},
  ];
  @override
  MessageRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      revisionNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_no'],
      )!,
      textBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_before'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
    );
  }

  @override
  $MessageRevisionsTable createAlias(String alias) {
    return $MessageRevisionsTable(attachedDatabase, alias);
  }
}

class MessageRevision extends DataClass implements Insertable<MessageRevision> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String messageId;
  final int revisionNo;
  final String textBefore;
  final int editedAt;
  const MessageRevision({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.messageId,
    required this.revisionNo,
    required this.textBefore,
    required this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['message_id'] = Variable<String>(messageId);
    map['revision_no'] = Variable<int>(revisionNo);
    map['text_before'] = Variable<String>(textBefore);
    map['edited_at'] = Variable<int>(editedAt);
    return map;
  }

  MessageRevisionsCompanion toCompanion(bool nullToAbsent) {
    return MessageRevisionsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      messageId: Value(messageId),
      revisionNo: Value(revisionNo),
      textBefore: Value(textBefore),
      editedAt: Value(editedAt),
    );
  }

  factory MessageRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRevision(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      messageId: serializer.fromJson<String>(json['messageId']),
      revisionNo: serializer.fromJson<int>(json['revisionNo']),
      textBefore: serializer.fromJson<String>(json['textBefore']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'messageId': serializer.toJson<String>(messageId),
      'revisionNo': serializer.toJson<int>(revisionNo),
      'textBefore': serializer.toJson<String>(textBefore),
      'editedAt': serializer.toJson<int>(editedAt),
    };
  }

  MessageRevision copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? messageId,
    int? revisionNo,
    String? textBefore,
    int? editedAt,
  }) => MessageRevision(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    messageId: messageId ?? this.messageId,
    revisionNo: revisionNo ?? this.revisionNo,
    textBefore: textBefore ?? this.textBefore,
    editedAt: editedAt ?? this.editedAt,
  );
  MessageRevision copyWithCompanion(MessageRevisionsCompanion data) {
    return MessageRevision(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      revisionNo: data.revisionNo.present
          ? data.revisionNo.value
          : this.revisionNo,
      textBefore: data.textBefore.present
          ? data.textBefore.value
          : this.textBefore,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRevision(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('messageId: $messageId, ')
          ..write('revisionNo: $revisionNo, ')
          ..write('textBefore: $textBefore, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    messageId,
    revisionNo,
    textBefore,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRevision &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.messageId == this.messageId &&
          other.revisionNo == this.revisionNo &&
          other.textBefore == this.textBefore &&
          other.editedAt == this.editedAt);
}

class MessageRevisionsCompanion extends UpdateCompanion<MessageRevision> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> messageId;
  final Value<int> revisionNo;
  final Value<String> textBefore;
  final Value<int> editedAt;
  final Value<int> rowid;
  const MessageRevisionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.messageId = const Value.absent(),
    this.revisionNo = const Value.absent(),
    this.textBefore = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageRevisionsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String messageId,
    required int revisionNo,
    required String textBefore,
    required int editedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       messageId = Value(messageId),
       revisionNo = Value(revisionNo),
       textBefore = Value(textBefore),
       editedAt = Value(editedAt);
  static Insertable<MessageRevision> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? messageId,
    Expression<int>? revisionNo,
    Expression<String>? textBefore,
    Expression<int>? editedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (messageId != null) 'message_id': messageId,
      if (revisionNo != null) 'revision_no': revisionNo,
      if (textBefore != null) 'text_before': textBefore,
      if (editedAt != null) 'edited_at': editedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? messageId,
    Value<int>? revisionNo,
    Value<String>? textBefore,
    Value<int>? editedAt,
    Value<int>? rowid,
  }) {
    return MessageRevisionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      messageId: messageId ?? this.messageId,
      revisionNo: revisionNo ?? this.revisionNo,
      textBefore: textBefore ?? this.textBefore,
      editedAt: editedAt ?? this.editedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (revisionNo.present) {
      map['revision_no'] = Variable<int>(revisionNo.value);
    }
    if (textBefore.present) {
      map['text_before'] = Variable<String>(textBefore.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('messageId: $messageId, ')
          ..write('revisionNo: $revisionNo, ')
          ..write('textBefore: $textBefore, ')
          ..write('editedAt: $editedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFilenameMeta = const VerificationMeta(
    'originalFilename',
  );
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
    'original_filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstImportedAtMeta = const VerificationMeta(
    'firstImportedAt',
  );
  @override
  late final GeneratedColumn<int> firstImportedAt = GeneratedColumn<int>(
    'first_imported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    sha256,
    mimeType,
    byteSize,
    originalFilename,
    firstImportedAt,
    width,
    height,
    pageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
        _originalFilenameMeta,
        originalFilename.isAcceptableOrUnknown(
          data['original_filename']!,
          _originalFilenameMeta,
        ),
      );
    }
    if (data.containsKey('first_imported_at')) {
      context.handle(
        _firstImportedAtMeta,
        firstImportedAt.isAcceptableOrUnknown(
          data['first_imported_at']!,
          _firstImportedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstImportedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      originalFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_filename'],
      ),
      firstImportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_imported_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String sha256;
  final String mimeType;
  final int byteSize;
  final String? originalFilename;
  final int firstImportedAt;
  final int? width;
  final int? height;
  final int? pageCount;
  const Attachment({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.sha256,
    required this.mimeType,
    required this.byteSize,
    this.originalFilename,
    required this.firstImportedAt,
    this.width,
    this.height,
    this.pageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['sha256'] = Variable<String>(sha256);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    if (!nullToAbsent || originalFilename != null) {
      map['original_filename'] = Variable<String>(originalFilename);
    }
    map['first_imported_at'] = Variable<int>(firstImportedAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      sha256: Value(sha256),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      originalFilename: originalFilename == null && nullToAbsent
          ? const Value.absent()
          : Value(originalFilename),
      firstImportedAt: Value(firstImportedAt),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      sha256: serializer.fromJson<String>(json['sha256']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      originalFilename: serializer.fromJson<String?>(json['originalFilename']),
      firstImportedAt: serializer.fromJson<int>(json['firstImportedAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'sha256': serializer.toJson<String>(sha256),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'originalFilename': serializer.toJson<String?>(originalFilename),
      'firstImportedAt': serializer.toJson<int>(firstImportedAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'pageCount': serializer.toJson<int?>(pageCount),
    };
  }

  Attachment copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? sha256,
    String? mimeType,
    int? byteSize,
    Value<String?> originalFilename = const Value.absent(),
    int? firstImportedAt,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    sha256: sha256 ?? this.sha256,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    originalFilename: originalFilename.present
        ? originalFilename.value
        : this.originalFilename,
    firstImportedAt: firstImportedAt ?? this.firstImportedAt,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      firstImportedAt: data.firstImportedAt.present
          ? data.firstImportedAt.value
          : this.firstImportedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sha256: $sha256, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('firstImportedAt: $firstImportedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageCount: $pageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    sha256,
    mimeType,
    byteSize,
    originalFilename,
    firstImportedAt,
    width,
    height,
    pageCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.sha256 == this.sha256 &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.originalFilename == this.originalFilename &&
          other.firstImportedAt == this.firstImportedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.pageCount == this.pageCount);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> sha256;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<String?> originalFilename;
  final Value<int> firstImportedAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> pageCount;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.firstImportedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String sha256,
    required String mimeType,
    required int byteSize,
    this.originalFilename = const Value.absent(),
    required int firstImportedAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       sha256 = Value(sha256),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize),
       firstImportedAt = Value(firstImportedAt);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? sha256,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<String>? originalFilename,
    Expression<int>? firstImportedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? pageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (sha256 != null) 'sha256': sha256,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (firstImportedAt != null) 'first_imported_at': firstImportedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (pageCount != null) 'page_count': pageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? sha256,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<String?>? originalFilename,
    Value<int>? firstImportedAt,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? pageCount,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      sha256: sha256 ?? this.sha256,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      originalFilename: originalFilename ?? this.originalFilename,
      firstImportedAt: firstImportedAt ?? this.firstImportedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      pageCount: pageCount ?? this.pageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (firstImportedAt.present) {
      map['first_imported_at'] = Variable<int>(firstImportedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('sha256: $sha256, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('firstImportedAt: $firstImportedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageCount: $pageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentCopiesTable extends AttachmentCopies
    with TableInfo<$AttachmentCopiesTable, AttachmentCopy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentCopiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CopyState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CopyState>($AttachmentCopiesTable.$converterstate);
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<int> verifiedAt = GeneratedColumn<int>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offloadedAtMeta = const VerificationMeta(
    'offloadedAt',
  );
  @override
  late final GeneratedColumn<int> offloadedAt = GeneratedColumn<int>(
    'offloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previewPathMeta = const VerificationMeta(
    'previewPath',
  );
  @override
  late final GeneratedColumn<String> previewPath = GeneratedColumn<String>(
    'preview_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _copyVersionMeta = const VerificationMeta(
    'copyVersion',
  );
  @override
  late final GeneratedColumn<int> copyVersion = GeneratedColumn<int>(
    'copy_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastReportedAtMeta = const VerificationMeta(
    'lastReportedAt',
  );
  @override
  late final GeneratedColumn<int> lastReportedAt = GeneratedColumn<int>(
    'last_reported_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    attachmentId,
    deviceId,
    state,
    localPath,
    verifiedAt,
    offloadedAt,
    previewPath,
    copyVersion,
    lastReportedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_copies';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentCopy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('offloaded_at')) {
      context.handle(
        _offloadedAtMeta,
        offloadedAt.isAcceptableOrUnknown(
          data['offloaded_at']!,
          _offloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('preview_path')) {
      context.handle(
        _previewPathMeta,
        previewPath.isAcceptableOrUnknown(
          data['preview_path']!,
          _previewPathMeta,
        ),
      );
    }
    if (data.containsKey('copy_version')) {
      context.handle(
        _copyVersionMeta,
        copyVersion.isAcceptableOrUnknown(
          data['copy_version']!,
          _copyVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_reported_at')) {
      context.handle(
        _lastReportedAtMeta,
        lastReportedAt.isAcceptableOrUnknown(
          data['last_reported_at']!,
          _lastReportedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {attachmentId, deviceId},
  ];
  @override
  AttachmentCopy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentCopy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      state: $AttachmentCopiesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_at'],
      ),
      offloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offloaded_at'],
      ),
      previewPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_path'],
      ),
      copyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copy_version'],
      )!,
      lastReportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reported_at'],
      ),
    );
  }

  @override
  $AttachmentCopiesTable createAlias(String alias) {
    return $AttachmentCopiesTable(attachedDatabase, alias);
  }

  static TypeConverter<CopyState, String> $converterstate = const EnumConverter(
    CopyState.values,
  );
}

class AttachmentCopy extends DataClass implements Insertable<AttachmentCopy> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String attachmentId;
  final String deviceId;
  final CopyState state;
  final String? localPath;
  final int? verifiedAt;
  final int? offloadedAt;
  final String? previewPath;
  final int copyVersion;
  final int? lastReportedAt;
  const AttachmentCopy({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.attachmentId,
    required this.deviceId,
    required this.state,
    this.localPath,
    this.verifiedAt,
    this.offloadedAt,
    this.previewPath,
    required this.copyVersion,
    this.lastReportedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['attachment_id'] = Variable<String>(attachmentId);
    map['device_id'] = Variable<String>(deviceId);
    {
      map['state'] = Variable<String>(
        $AttachmentCopiesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<int>(verifiedAt);
    }
    if (!nullToAbsent || offloadedAt != null) {
      map['offloaded_at'] = Variable<int>(offloadedAt);
    }
    if (!nullToAbsent || previewPath != null) {
      map['preview_path'] = Variable<String>(previewPath);
    }
    map['copy_version'] = Variable<int>(copyVersion);
    if (!nullToAbsent || lastReportedAt != null) {
      map['last_reported_at'] = Variable<int>(lastReportedAt);
    }
    return map;
  }

  AttachmentCopiesCompanion toCompanion(bool nullToAbsent) {
    return AttachmentCopiesCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      attachmentId: Value(attachmentId),
      deviceId: Value(deviceId),
      state: Value(state),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      offloadedAt: offloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(offloadedAt),
      previewPath: previewPath == null && nullToAbsent
          ? const Value.absent()
          : Value(previewPath),
      copyVersion: Value(copyVersion),
      lastReportedAt: lastReportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReportedAt),
    );
  }

  factory AttachmentCopy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentCopy(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      state: serializer.fromJson<CopyState>(json['state']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      verifiedAt: serializer.fromJson<int?>(json['verifiedAt']),
      offloadedAt: serializer.fromJson<int?>(json['offloadedAt']),
      previewPath: serializer.fromJson<String?>(json['previewPath']),
      copyVersion: serializer.fromJson<int>(json['copyVersion']),
      lastReportedAt: serializer.fromJson<int?>(json['lastReportedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'attachmentId': serializer.toJson<String>(attachmentId),
      'deviceId': serializer.toJson<String>(deviceId),
      'state': serializer.toJson<CopyState>(state),
      'localPath': serializer.toJson<String?>(localPath),
      'verifiedAt': serializer.toJson<int?>(verifiedAt),
      'offloadedAt': serializer.toJson<int?>(offloadedAt),
      'previewPath': serializer.toJson<String?>(previewPath),
      'copyVersion': serializer.toJson<int>(copyVersion),
      'lastReportedAt': serializer.toJson<int?>(lastReportedAt),
    };
  }

  AttachmentCopy copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? attachmentId,
    String? deviceId,
    CopyState? state,
    Value<String?> localPath = const Value.absent(),
    Value<int?> verifiedAt = const Value.absent(),
    Value<int?> offloadedAt = const Value.absent(),
    Value<String?> previewPath = const Value.absent(),
    int? copyVersion,
    Value<int?> lastReportedAt = const Value.absent(),
  }) => AttachmentCopy(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    attachmentId: attachmentId ?? this.attachmentId,
    deviceId: deviceId ?? this.deviceId,
    state: state ?? this.state,
    localPath: localPath.present ? localPath.value : this.localPath,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    offloadedAt: offloadedAt.present ? offloadedAt.value : this.offloadedAt,
    previewPath: previewPath.present ? previewPath.value : this.previewPath,
    copyVersion: copyVersion ?? this.copyVersion,
    lastReportedAt: lastReportedAt.present
        ? lastReportedAt.value
        : this.lastReportedAt,
  );
  AttachmentCopy copyWithCompanion(AttachmentCopiesCompanion data) {
    return AttachmentCopy(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      state: data.state.present ? data.state.value : this.state,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      offloadedAt: data.offloadedAt.present
          ? data.offloadedAt.value
          : this.offloadedAt,
      previewPath: data.previewPath.present
          ? data.previewPath.value
          : this.previewPath,
      copyVersion: data.copyVersion.present
          ? data.copyVersion.value
          : this.copyVersion,
      lastReportedAt: data.lastReportedAt.present
          ? data.lastReportedAt.value
          : this.lastReportedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentCopy(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('deviceId: $deviceId, ')
          ..write('state: $state, ')
          ..write('localPath: $localPath, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('offloadedAt: $offloadedAt, ')
          ..write('previewPath: $previewPath, ')
          ..write('copyVersion: $copyVersion, ')
          ..write('lastReportedAt: $lastReportedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    attachmentId,
    deviceId,
    state,
    localPath,
    verifiedAt,
    offloadedAt,
    previewPath,
    copyVersion,
    lastReportedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentCopy &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.attachmentId == this.attachmentId &&
          other.deviceId == this.deviceId &&
          other.state == this.state &&
          other.localPath == this.localPath &&
          other.verifiedAt == this.verifiedAt &&
          other.offloadedAt == this.offloadedAt &&
          other.previewPath == this.previewPath &&
          other.copyVersion == this.copyVersion &&
          other.lastReportedAt == this.lastReportedAt);
}

class AttachmentCopiesCompanion extends UpdateCompanion<AttachmentCopy> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> attachmentId;
  final Value<String> deviceId;
  final Value<CopyState> state;
  final Value<String?> localPath;
  final Value<int?> verifiedAt;
  final Value<int?> offloadedAt;
  final Value<String?> previewPath;
  final Value<int> copyVersion;
  final Value<int?> lastReportedAt;
  final Value<int> rowid;
  const AttachmentCopiesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.state = const Value.absent(),
    this.localPath = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.offloadedAt = const Value.absent(),
    this.previewPath = const Value.absent(),
    this.copyVersion = const Value.absent(),
    this.lastReportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentCopiesCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String attachmentId,
    required String deviceId,
    required CopyState state,
    this.localPath = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.offloadedAt = const Value.absent(),
    this.previewPath = const Value.absent(),
    this.copyVersion = const Value.absent(),
    this.lastReportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       attachmentId = Value(attachmentId),
       deviceId = Value(deviceId),
       state = Value(state);
  static Insertable<AttachmentCopy> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? attachmentId,
    Expression<String>? deviceId,
    Expression<String>? state,
    Expression<String>? localPath,
    Expression<int>? verifiedAt,
    Expression<int>? offloadedAt,
    Expression<String>? previewPath,
    Expression<int>? copyVersion,
    Expression<int>? lastReportedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (deviceId != null) 'device_id': deviceId,
      if (state != null) 'state': state,
      if (localPath != null) 'local_path': localPath,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (offloadedAt != null) 'offloaded_at': offloadedAt,
      if (previewPath != null) 'preview_path': previewPath,
      if (copyVersion != null) 'copy_version': copyVersion,
      if (lastReportedAt != null) 'last_reported_at': lastReportedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentCopiesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? attachmentId,
    Value<String>? deviceId,
    Value<CopyState>? state,
    Value<String?>? localPath,
    Value<int?>? verifiedAt,
    Value<int?>? offloadedAt,
    Value<String?>? previewPath,
    Value<int>? copyVersion,
    Value<int?>? lastReportedAt,
    Value<int>? rowid,
  }) {
    return AttachmentCopiesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      attachmentId: attachmentId ?? this.attachmentId,
      deviceId: deviceId ?? this.deviceId,
      state: state ?? this.state,
      localPath: localPath ?? this.localPath,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      offloadedAt: offloadedAt ?? this.offloadedAt,
      previewPath: previewPath ?? this.previewPath,
      copyVersion: copyVersion ?? this.copyVersion,
      lastReportedAt: lastReportedAt ?? this.lastReportedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $AttachmentCopiesTable.$converterstate.toSql(state.value),
      );
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<int>(verifiedAt.value);
    }
    if (offloadedAt.present) {
      map['offloaded_at'] = Variable<int>(offloadedAt.value);
    }
    if (previewPath.present) {
      map['preview_path'] = Variable<String>(previewPath.value);
    }
    if (copyVersion.present) {
      map['copy_version'] = Variable<int>(copyVersion.value);
    }
    if (lastReportedAt.present) {
      map['last_reported_at'] = Variable<int>(lastReportedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentCopiesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('deviceId: $deviceId, ')
          ..write('state: $state, ')
          ..write('localPath: $localPath, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('offloadedAt: $offloadedAt, ')
          ..write('previewPath: $previewPath, ')
          ..write('copyVersion: $copyVersion, ')
          ..write('lastReportedAt: $lastReportedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageAttachmentsTable extends MessageAttachments
    with TableInfo<$MessageAttachmentsTable, MessageAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duplicateAcknowledgedMeta =
      const VerificationMeta('duplicateAcknowledged');
  @override
  late final GeneratedColumn<bool> duplicateAcknowledged =
      GeneratedColumn<bool>(
        'duplicate_acknowledged',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("duplicate_acknowledged" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    messageId,
    attachmentId,
    position,
    duplicateAcknowledged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('duplicate_acknowledged')) {
      context.handle(
        _duplicateAcknowledgedMeta,
        duplicateAcknowledged.isAcceptableOrUnknown(
          data['duplicate_acknowledged']!,
          _duplicateAcknowledgedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {messageId, attachmentId},
  ];
  @override
  MessageAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      duplicateAcknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}duplicate_acknowledged'],
      )!,
    );
  }

  @override
  $MessageAttachmentsTable createAlias(String alias) {
    return $MessageAttachmentsTable(attachedDatabase, alias);
  }
}

class MessageAttachment extends DataClass
    implements Insertable<MessageAttachment> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String messageId;
  final String attachmentId;
  final int position;
  final bool duplicateAcknowledged;
  const MessageAttachment({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.messageId,
    required this.attachmentId,
    required this.position,
    required this.duplicateAcknowledged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['message_id'] = Variable<String>(messageId);
    map['attachment_id'] = Variable<String>(attachmentId);
    map['position'] = Variable<int>(position);
    map['duplicate_acknowledged'] = Variable<bool>(duplicateAcknowledged);
    return map;
  }

  MessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MessageAttachmentsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      messageId: Value(messageId),
      attachmentId: Value(attachmentId),
      position: Value(position),
      duplicateAcknowledged: Value(duplicateAcknowledged),
    );
  }

  factory MessageAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAttachment(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      messageId: serializer.fromJson<String>(json['messageId']),
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      position: serializer.fromJson<int>(json['position']),
      duplicateAcknowledged: serializer.fromJson<bool>(
        json['duplicateAcknowledged'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'messageId': serializer.toJson<String>(messageId),
      'attachmentId': serializer.toJson<String>(attachmentId),
      'position': serializer.toJson<int>(position),
      'duplicateAcknowledged': serializer.toJson<bool>(duplicateAcknowledged),
    };
  }

  MessageAttachment copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? messageId,
    String? attachmentId,
    int? position,
    bool? duplicateAcknowledged,
  }) => MessageAttachment(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    messageId: messageId ?? this.messageId,
    attachmentId: attachmentId ?? this.attachmentId,
    position: position ?? this.position,
    duplicateAcknowledged: duplicateAcknowledged ?? this.duplicateAcknowledged,
  );
  MessageAttachment copyWithCompanion(MessageAttachmentsCompanion data) {
    return MessageAttachment(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      position: data.position.present ? data.position.value : this.position,
      duplicateAcknowledged: data.duplicateAcknowledged.present
          ? data.duplicateAcknowledged.value
          : this.duplicateAcknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachment(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('messageId: $messageId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('position: $position, ')
          ..write('duplicateAcknowledged: $duplicateAcknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    messageId,
    attachmentId,
    position,
    duplicateAcknowledged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAttachment &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.messageId == this.messageId &&
          other.attachmentId == this.attachmentId &&
          other.position == this.position &&
          other.duplicateAcknowledged == this.duplicateAcknowledged);
}

class MessageAttachmentsCompanion extends UpdateCompanion<MessageAttachment> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> messageId;
  final Value<String> attachmentId;
  final Value<int> position;
  final Value<bool> duplicateAcknowledged;
  final Value<int> rowid;
  const MessageAttachmentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.messageId = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.position = const Value.absent(),
    this.duplicateAcknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageAttachmentsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String messageId,
    required String attachmentId,
    required int position,
    this.duplicateAcknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       messageId = Value(messageId),
       attachmentId = Value(attachmentId),
       position = Value(position);
  static Insertable<MessageAttachment> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? messageId,
    Expression<String>? attachmentId,
    Expression<int>? position,
    Expression<bool>? duplicateAcknowledged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (messageId != null) 'message_id': messageId,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (position != null) 'position': position,
      if (duplicateAcknowledged != null)
        'duplicate_acknowledged': duplicateAcknowledged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? messageId,
    Value<String>? attachmentId,
    Value<int>? position,
    Value<bool>? duplicateAcknowledged,
    Value<int>? rowid,
  }) {
    return MessageAttachmentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      messageId: messageId ?? this.messageId,
      attachmentId: attachmentId ?? this.attachmentId,
      position: position ?? this.position,
      duplicateAcknowledged:
          duplicateAcknowledged ?? this.duplicateAcknowledged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (duplicateAcknowledged.present) {
      map['duplicate_acknowledged'] = Variable<bool>(
        duplicateAcknowledged.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('messageId: $messageId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('position: $position, ')
          ..write('duplicateAcknowledged: $duplicateAcknowledged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileFieldsTable extends ProfileFields
    with TableInfo<$ProfileFieldsTable, ProfileField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnDeviceMeta = const VerificationMeta(
    'createdOnDevice',
  );
  @override
  late final GeneratedColumn<String> createdOnDevice = GeneratedColumn<String>(
    'created_on_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _changeSeqMeta = const VerificationMeta(
    'changeSeq',
  );
  @override
  late final GeneratedColumn<int> changeSeq = GeneratedColumn<int>(
    'change_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProfileFieldState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProfileFieldState>($ProfileFieldsTable.$converterstate);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    fieldKey,
    value,
    state,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_on_device')) {
      context.handle(
        _createdOnDeviceMeta,
        createdOnDevice.isAcceptableOrUnknown(
          data['created_on_device']!,
          _createdOnDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOnDeviceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('change_seq')) {
      context.handle(
        _changeSeqMeta,
        changeSeq.isAcceptableOrUnknown(data['change_seq']!, _changeSeqMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fieldKey, version},
  ];
  @override
  ProfileField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOnDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on_device'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_seq'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      state: $ProfileFieldsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileFieldsTable createAlias(String alias) {
    return $ProfileFieldsTable(attachedDatabase, alias);
  }

  static TypeConverter<ProfileFieldState, String> $converterstate =
      const EnumConverter(ProfileFieldState.values);
}

class ProfileField extends DataClass implements Insertable<ProfileField> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String fieldKey;
  final String value;
  final ProfileFieldState state;
  final int updatedAt;
  const ProfileField({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.fieldKey,
    required this.value,
    required this.state,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<int>(createdAt);
    map['created_on_device'] = Variable<String>(createdOnDevice);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || changeSeq != null) {
      map['change_seq'] = Variable<int>(changeSeq);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['field_key'] = Variable<String>(fieldKey);
    map['value'] = Variable<String>(value);
    {
      map['state'] = Variable<String>(
        $ProfileFieldsTable.$converterstate.toSql(state),
      );
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProfileFieldsCompanion toCompanion(bool nullToAbsent) {
    return ProfileFieldsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      createdOnDevice: Value(createdOnDevice),
      version: Value(version),
      changeSeq: changeSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(changeSeq),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      fieldKey: Value(fieldKey),
      value: Value(value),
      state: Value(state),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileField(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      value: serializer.fromJson<String>(json['value']),
      state: serializer.fromJson<ProfileFieldState>(json['state']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOnDevice': serializer.toJson<String>(createdOnDevice),
      'version': serializer.toJson<int>(version),
      'changeSeq': serializer.toJson<int?>(changeSeq),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'value': serializer.toJson<String>(value),
      'state': serializer.toJson<ProfileFieldState>(state),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProfileField copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? fieldKey,
    String? value,
    ProfileFieldState? state,
    int? updatedAt,
  }) => ProfileField(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    fieldKey: fieldKey ?? this.fieldKey,
    value: value ?? this.value,
    state: state ?? this.state,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileField copyWithCompanion(ProfileFieldsCompanion data) {
    return ProfileField(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      value: data.value.present ? data.value.value : this.value,
      state: data.state.present ? data.state.value : this.state,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileField(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    fieldKey,
    value,
    state,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileField &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.fieldKey == this.fieldKey &&
          other.value == this.value &&
          other.state == this.state &&
          other.updatedAt == this.updatedAt);
}

class ProfileFieldsCompanion extends UpdateCompanion<ProfileField> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> fieldKey;
  final Value<String> value;
  final Value<ProfileFieldState> state;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProfileFieldsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.value = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileFieldsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String fieldKey,
    required String value,
    required ProfileFieldState state,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       fieldKey = Value(fieldKey),
       value = Value(value),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileField> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? fieldKey,
    Expression<String>? value,
    Expression<String>? state,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOnDevice != null) 'created_on_device': createdOnDevice,
      if (version != null) 'version': version,
      if (changeSeq != null) 'change_seq': changeSeq,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (fieldKey != null) 'field_key': fieldKey,
      if (value != null) 'value': value,
      if (state != null) 'state': state,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? fieldKey,
    Value<String>? value,
    Value<ProfileFieldState>? state,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfileFieldsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      fieldKey: fieldKey ?? this.fieldKey,
      value: value ?? this.value,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOnDevice.present) {
      map['created_on_device'] = Variable<String>(createdOnDevice.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeSeq.present) {
      map['change_seq'] = Variable<int>(changeSeq.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $ProfileFieldsTable.$converterstate.toSql(state.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileFieldsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final int updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, int? updatedAt}) => Setting(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageRevisionsTable messageRevisions = $MessageRevisionsTable(
    this,
  );
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AttachmentCopiesTable attachmentCopies = $AttachmentCopiesTable(
    this,
  );
  late final $MessageAttachmentsTable messageAttachments =
      $MessageAttachmentsTable(this);
  late final $ProfileFieldsTable profileFields = $ProfileFieldsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    messageRevisions,
    attachments,
    attachmentCopies,
    messageAttachments,
    profileFields,
    settings,
  ];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String clientMsgId,
      required int seq,
      required MessageRole role,
      required MessageKind kind,
      Value<String?> body,
      Value<int> revisionNo,
      required int sentAt,
      required String sentTz,
      Value<String?> inReplyTo,
      Value<String?> promptMeta,
      required OrganizeState organizeState,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> clientMsgId,
      Value<int> seq,
      Value<MessageRole> role,
      Value<MessageKind> kind,
      Value<String?> body,
      Value<int> revisionNo,
      Value<int> sentAt,
      Value<String> sentTz,
      Value<String?> inReplyTo,
      Value<String?> promptMeta,
      Value<OrganizeState> organizeState,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageRole, MessageRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<MessageKind, MessageKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentTz => $composableBuilder(
    column: $table.sentTz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptMeta => $composableBuilder(
    column: $table.promptMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OrganizeState, OrganizeState, String>
  get organizeState => $composableBuilder(
    column: $table.organizeState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentTz => $composableBuilder(
    column: $table.sentTz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptMeta => $composableBuilder(
    column: $table.promptMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizeState => $composableBuilder(
    column: $table.organizeState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get sentTz =>
      $composableBuilder(column: $table.sentTz, builder: (column) => column);

  GeneratedColumn<String> get inReplyTo =>
      $composableBuilder(column: $table.inReplyTo, builder: (column) => column);

  GeneratedColumn<String> get promptMeta => $composableBuilder(
    column: $table.promptMeta,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OrganizeState, String> get organizeState =>
      $composableBuilder(
        column: $table.organizeState,
        builder: (column) => column,
      );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> clientMsgId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<MessageRole> role = const Value.absent(),
                Value<MessageKind> kind = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<int> revisionNo = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<String> sentTz = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> promptMeta = const Value.absent(),
                Value<OrganizeState> organizeState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                clientMsgId: clientMsgId,
                seq: seq,
                role: role,
                kind: kind,
                body: body,
                revisionNo: revisionNo,
                sentAt: sentAt,
                sentTz: sentTz,
                inReplyTo: inReplyTo,
                promptMeta: promptMeta,
                organizeState: organizeState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String clientMsgId,
                required int seq,
                required MessageRole role,
                required MessageKind kind,
                Value<String?> body = const Value.absent(),
                Value<int> revisionNo = const Value.absent(),
                required int sentAt,
                required String sentTz,
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> promptMeta = const Value.absent(),
                required OrganizeState organizeState,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                clientMsgId: clientMsgId,
                seq: seq,
                role: role,
                kind: kind,
                body: body,
                revisionNo: revisionNo,
                sentAt: sentAt,
                sentTz: sentTz,
                inReplyTo: inReplyTo,
                promptMeta: promptMeta,
                organizeState: organizeState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$MessageRevisionsTableCreateCompanionBuilder =
    MessageRevisionsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String messageId,
      required int revisionNo,
      required String textBefore,
      required int editedAt,
      Value<int> rowid,
    });
typedef $$MessageRevisionsTableUpdateCompanionBuilder =
    MessageRevisionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> messageId,
      Value<int> revisionNo,
      Value<String> textBefore,
      Value<int> editedAt,
      Value<int> rowid,
    });

class $$MessageRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageRevisionsTable> {
  $$MessageRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textBefore => $composableBuilder(
    column: $table.textBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageRevisionsTable> {
  $$MessageRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textBefore => $composableBuilder(
    column: $table.textBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageRevisionsTable> {
  $$MessageRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get revisionNo => $composableBuilder(
    column: $table.revisionNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textBefore => $composableBuilder(
    column: $table.textBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);
}

class $$MessageRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageRevisionsTable,
          MessageRevision,
          $$MessageRevisionsTableFilterComposer,
          $$MessageRevisionsTableOrderingComposer,
          $$MessageRevisionsTableAnnotationComposer,
          $$MessageRevisionsTableCreateCompanionBuilder,
          $$MessageRevisionsTableUpdateCompanionBuilder,
          (
            MessageRevision,
            BaseReferences<
              _$AppDatabase,
              $MessageRevisionsTable,
              MessageRevision
            >,
          ),
          MessageRevision,
          PrefetchHooks Function()
        > {
  $$MessageRevisionsTableTableManager(
    _$AppDatabase db,
    $MessageRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> revisionNo = const Value.absent(),
                Value<String> textBefore = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageRevisionsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                messageId: messageId,
                revisionNo: revisionNo,
                textBefore: textBefore,
                editedAt: editedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String messageId,
                required int revisionNo,
                required String textBefore,
                required int editedAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageRevisionsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                messageId: messageId,
                revisionNo: revisionNo,
                textBefore: textBefore,
                editedAt: editedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageRevisionsTable,
      MessageRevision,
      $$MessageRevisionsTableFilterComposer,
      $$MessageRevisionsTableOrderingComposer,
      $$MessageRevisionsTableAnnotationComposer,
      $$MessageRevisionsTableCreateCompanionBuilder,
      $$MessageRevisionsTableUpdateCompanionBuilder,
      (
        MessageRevision,
        BaseReferences<_$AppDatabase, $MessageRevisionsTable, MessageRevision>,
      ),
      MessageRevision,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String sha256,
      required String mimeType,
      required int byteSize,
      Value<String?> originalFilename,
      required int firstImportedAt,
      Value<int?> width,
      Value<int?> height,
      Value<int?> pageCount,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> sha256,
      Value<String> mimeType,
      Value<int> byteSize,
      Value<String?> originalFilename,
      Value<int> firstImportedAt,
      Value<int?> width,
      Value<int?> height,
      Value<int?> pageCount,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstImportedAt => $composableBuilder(
    column: $table.firstImportedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstImportedAt => $composableBuilder(
    column: $table.firstImportedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstImportedAt => $composableBuilder(
    column: $table.firstImportedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            Attachment,
            BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
          ),
          Attachment,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String?> originalFilename = const Value.absent(),
                Value<int> firstImportedAt = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                sha256: sha256,
                mimeType: mimeType,
                byteSize: byteSize,
                originalFilename: originalFilename,
                firstImportedAt: firstImportedAt,
                width: width,
                height: height,
                pageCount: pageCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String sha256,
                required String mimeType,
                required int byteSize,
                Value<String?> originalFilename = const Value.absent(),
                required int firstImportedAt,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                sha256: sha256,
                mimeType: mimeType,
                byteSize: byteSize,
                originalFilename: originalFilename,
                firstImportedAt: firstImportedAt,
                width: width,
                height: height,
                pageCount: pageCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        Attachment,
        BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
      ),
      Attachment,
      PrefetchHooks Function()
    >;
typedef $$AttachmentCopiesTableCreateCompanionBuilder =
    AttachmentCopiesCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String attachmentId,
      required String deviceId,
      required CopyState state,
      Value<String?> localPath,
      Value<int?> verifiedAt,
      Value<int?> offloadedAt,
      Value<String?> previewPath,
      Value<int> copyVersion,
      Value<int?> lastReportedAt,
      Value<int> rowid,
    });
typedef $$AttachmentCopiesTableUpdateCompanionBuilder =
    AttachmentCopiesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> attachmentId,
      Value<String> deviceId,
      Value<CopyState> state,
      Value<String?> localPath,
      Value<int?> verifiedAt,
      Value<int?> offloadedAt,
      Value<String?> previewPath,
      Value<int> copyVersion,
      Value<int?> lastReportedAt,
      Value<int> rowid,
    });

class $$AttachmentCopiesTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentCopiesTable> {
  $$AttachmentCopiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CopyState, CopyState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offloadedAt => $composableBuilder(
    column: $table.offloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get copyVersion => $composableBuilder(
    column: $table.copyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReportedAt => $composableBuilder(
    column: $table.lastReportedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentCopiesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentCopiesTable> {
  $$AttachmentCopiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offloadedAt => $composableBuilder(
    column: $table.offloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get copyVersion => $composableBuilder(
    column: $table.copyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReportedAt => $composableBuilder(
    column: $table.lastReportedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentCopiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentCopiesTable> {
  $$AttachmentCopiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CopyState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offloadedAt => $composableBuilder(
    column: $table.offloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewPath => $composableBuilder(
    column: $table.previewPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get copyVersion => $composableBuilder(
    column: $table.copyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReportedAt => $composableBuilder(
    column: $table.lastReportedAt,
    builder: (column) => column,
  );
}

class $$AttachmentCopiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentCopiesTable,
          AttachmentCopy,
          $$AttachmentCopiesTableFilterComposer,
          $$AttachmentCopiesTableOrderingComposer,
          $$AttachmentCopiesTableAnnotationComposer,
          $$AttachmentCopiesTableCreateCompanionBuilder,
          $$AttachmentCopiesTableUpdateCompanionBuilder,
          (
            AttachmentCopy,
            BaseReferences<
              _$AppDatabase,
              $AttachmentCopiesTable,
              AttachmentCopy
            >,
          ),
          AttachmentCopy,
          PrefetchHooks Function()
        > {
  $$AttachmentCopiesTableTableManager(
    _$AppDatabase db,
    $AttachmentCopiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentCopiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentCopiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentCopiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> attachmentId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<CopyState> state = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int?> verifiedAt = const Value.absent(),
                Value<int?> offloadedAt = const Value.absent(),
                Value<String?> previewPath = const Value.absent(),
                Value<int> copyVersion = const Value.absent(),
                Value<int?> lastReportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentCopiesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                attachmentId: attachmentId,
                deviceId: deviceId,
                state: state,
                localPath: localPath,
                verifiedAt: verifiedAt,
                offloadedAt: offloadedAt,
                previewPath: previewPath,
                copyVersion: copyVersion,
                lastReportedAt: lastReportedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String attachmentId,
                required String deviceId,
                required CopyState state,
                Value<String?> localPath = const Value.absent(),
                Value<int?> verifiedAt = const Value.absent(),
                Value<int?> offloadedAt = const Value.absent(),
                Value<String?> previewPath = const Value.absent(),
                Value<int> copyVersion = const Value.absent(),
                Value<int?> lastReportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentCopiesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                attachmentId: attachmentId,
                deviceId: deviceId,
                state: state,
                localPath: localPath,
                verifiedAt: verifiedAt,
                offloadedAt: offloadedAt,
                previewPath: previewPath,
                copyVersion: copyVersion,
                lastReportedAt: lastReportedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentCopiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentCopiesTable,
      AttachmentCopy,
      $$AttachmentCopiesTableFilterComposer,
      $$AttachmentCopiesTableOrderingComposer,
      $$AttachmentCopiesTableAnnotationComposer,
      $$AttachmentCopiesTableCreateCompanionBuilder,
      $$AttachmentCopiesTableUpdateCompanionBuilder,
      (
        AttachmentCopy,
        BaseReferences<_$AppDatabase, $AttachmentCopiesTable, AttachmentCopy>,
      ),
      AttachmentCopy,
      PrefetchHooks Function()
    >;
typedef $$MessageAttachmentsTableCreateCompanionBuilder =
    MessageAttachmentsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String messageId,
      required String attachmentId,
      required int position,
      Value<bool> duplicateAcknowledged,
      Value<int> rowid,
    });
typedef $$MessageAttachmentsTableUpdateCompanionBuilder =
    MessageAttachmentsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> messageId,
      Value<String> attachmentId,
      Value<int> position,
      Value<bool> duplicateAcknowledged,
      Value<int> rowid,
    });

class $$MessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get duplicateAcknowledged => $composableBuilder(
    column: $table.duplicateAcknowledged,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get duplicateAcknowledged => $composableBuilder(
    column: $table.duplicateAcknowledged,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get duplicateAcknowledged => $composableBuilder(
    column: $table.duplicateAcknowledged,
    builder: (column) => column,
  );
}

class $$MessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment,
          $$MessageAttachmentsTableFilterComposer,
          $$MessageAttachmentsTableOrderingComposer,
          $$MessageAttachmentsTableAnnotationComposer,
          $$MessageAttachmentsTableCreateCompanionBuilder,
          $$MessageAttachmentsTableUpdateCompanionBuilder,
          (
            MessageAttachment,
            BaseReferences<
              _$AppDatabase,
              $MessageAttachmentsTable,
              MessageAttachment
            >,
          ),
          MessageAttachment,
          PrefetchHooks Function()
        > {
  $$MessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $MessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> attachmentId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> duplicateAcknowledged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageAttachmentsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                messageId: messageId,
                attachmentId: attachmentId,
                position: position,
                duplicateAcknowledged: duplicateAcknowledged,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String messageId,
                required String attachmentId,
                required int position,
                Value<bool> duplicateAcknowledged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageAttachmentsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                messageId: messageId,
                attachmentId: attachmentId,
                position: position,
                duplicateAcknowledged: duplicateAcknowledged,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageAttachmentsTable,
      MessageAttachment,
      $$MessageAttachmentsTableFilterComposer,
      $$MessageAttachmentsTableOrderingComposer,
      $$MessageAttachmentsTableAnnotationComposer,
      $$MessageAttachmentsTableCreateCompanionBuilder,
      $$MessageAttachmentsTableUpdateCompanionBuilder,
      (
        MessageAttachment,
        BaseReferences<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment
        >,
      ),
      MessageAttachment,
      PrefetchHooks Function()
    >;
typedef $$ProfileFieldsTableCreateCompanionBuilder =
    ProfileFieldsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String fieldKey,
      required String value,
      required ProfileFieldState state,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ProfileFieldsTableUpdateCompanionBuilder =
    ProfileFieldsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> fieldKey,
      Value<String> value,
      Value<ProfileFieldState> state,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ProfileFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileFieldsTable> {
  $$ProfileFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProfileFieldState, ProfileFieldState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileFieldsTable> {
  $$ProfileFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeSeq => $composableBuilder(
    column: $table.changeSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileFieldsTable> {
  $$ProfileFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdOnDevice => $composableBuilder(
    column: $table.createdOnDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get changeSeq =>
      $composableBuilder(column: $table.changeSeq, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProfileFieldState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfileFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileFieldsTable,
          ProfileField,
          $$ProfileFieldsTableFilterComposer,
          $$ProfileFieldsTableOrderingComposer,
          $$ProfileFieldsTableAnnotationComposer,
          $$ProfileFieldsTableCreateCompanionBuilder,
          $$ProfileFieldsTableUpdateCompanionBuilder,
          (
            ProfileField,
            BaseReferences<_$AppDatabase, $ProfileFieldsTable, ProfileField>,
          ),
          ProfileField,
          PrefetchHooks Function()
        > {
  $$ProfileFieldsTableTableManager(_$AppDatabase db, $ProfileFieldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<ProfileFieldState> state = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileFieldsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                fieldKey: fieldKey,
                value: value,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required int createdAt,
                required String createdOnDevice,
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required String fieldKey,
                required String value,
                required ProfileFieldState state,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfileFieldsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                fieldKey: fieldKey,
                value: value,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileFieldsTable,
      ProfileField,
      $$ProfileFieldsTableFilterComposer,
      $$ProfileFieldsTableOrderingComposer,
      $$ProfileFieldsTableAnnotationComposer,
      $$ProfileFieldsTableCreateCompanionBuilder,
      $$ProfileFieldsTableUpdateCompanionBuilder,
      (
        ProfileField,
        BaseReferences<_$AppDatabase, $ProfileFieldsTable, ProfileField>,
      ),
      ProfileField,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageRevisionsTableTableManager get messageRevisions =>
      $$MessageRevisionsTableTableManager(_db, _db.messageRevisions);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AttachmentCopiesTableTableManager get attachmentCopies =>
      $$AttachmentCopiesTableTableManager(_db, _db.attachmentCopies);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(_db, _db.messageAttachments);
  $$ProfileFieldsTableTableManager get profileFields =>
      $$ProfileFieldsTableTableManager(_db, _db.profileFields);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
