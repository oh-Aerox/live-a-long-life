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

class $HealthSamplesTable extends HealthSamples
    with TableInfo<$HealthSamplesTable, HealthSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthSamplesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _platformUuidMeta = const VerificationMeta(
    'platformUuid',
  );
  @override
  late final GeneratedColumn<String> platformUuid = GeneratedColumn<String>(
    'platform_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HealthSampleType, String>
  sampleType = GeneratedColumn<String>(
    'sample_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HealthSampleType>($HealthSamplesTable.$convertersampleType);
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
    'end_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
    'tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzInferredMeta = const VerificationMeta(
    'tzInferred',
  );
  @override
  late final GeneratedColumn<bool> tzInferred = GeneratedColumn<bool>(
    'tz_inferred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tz_inferred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceBundleIdMeta = const VerificationMeta(
    'sourceBundleId',
  );
  @override
  late final GeneratedColumn<String> sourceBundleId = GeneratedColumn<String>(
    'source_bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SleepStage?, String> sleepStage =
      GeneratedColumn<String>(
        'sleep_stage',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SleepStage?>($HealthSamplesTable.$convertersleepStagen);
  static const VerificationMeta _workoutTypeMeta = const VerificationMeta(
    'workoutType',
  );
  @override
  late final GeneratedColumn<String> workoutType = GeneratedColumn<String>(
    'workout_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedInSourceAtMeta = const VerificationMeta(
    'removedInSourceAt',
  );
  @override
  late final GeneratedColumn<int> removedInSourceAt = GeneratedColumn<int>(
    'removed_in_source_at',
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
    platformUuid,
    sampleType,
    startUtc,
    endUtc,
    tz,
    tzInferred,
    sourceBundleId,
    sleepStage,
    workoutType,
    energyKcal,
    distanceM,
    sourceName,
    fetchedAt,
    removedInSourceAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthSample> instance, {
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
    if (data.containsKey('platform_uuid')) {
      context.handle(
        _platformUuidMeta,
        platformUuid.isAcceptableOrUnknown(
          data['platform_uuid']!,
          _platformUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_platformUuidMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    } else if (isInserting) {
      context.missing(_tzMeta);
    }
    if (data.containsKey('tz_inferred')) {
      context.handle(
        _tzInferredMeta,
        tzInferred.isAcceptableOrUnknown(data['tz_inferred']!, _tzInferredMeta),
      );
    }
    if (data.containsKey('source_bundle_id')) {
      context.handle(
        _sourceBundleIdMeta,
        sourceBundleId.isAcceptableOrUnknown(
          data['source_bundle_id']!,
          _sourceBundleIdMeta,
        ),
      );
    }
    if (data.containsKey('workout_type')) {
      context.handle(
        _workoutTypeMeta,
        workoutType.isAcceptableOrUnknown(
          data['workout_type']!,
          _workoutTypeMeta,
        ),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('removed_in_source_at')) {
      context.handle(
        _removedInSourceAtMeta,
        removedInSourceAt.isAcceptableOrUnknown(
          data['removed_in_source_at']!,
          _removedInSourceAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthSample(
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
      platformUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_uuid'],
      )!,
      sampleType: $HealthSamplesTable.$convertersampleType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sample_type'],
        )!,
      ),
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_utc'],
      )!,
      tz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz'],
      )!,
      tzInferred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tz_inferred'],
      )!,
      sourceBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_bundle_id'],
      ),
      sleepStage: $HealthSamplesTable.$convertersleepStagen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sleep_stage'],
        ),
      ),
      workoutType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_type'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      removedInSourceAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed_in_source_at'],
      ),
    );
  }

  @override
  $HealthSamplesTable createAlias(String alias) {
    return $HealthSamplesTable(attachedDatabase, alias);
  }

  static TypeConverter<HealthSampleType, String> $convertersampleType =
      const EnumConverter(HealthSampleType.values);
  static TypeConverter<SleepStage, String> $convertersleepStage =
      const EnumConverter(SleepStage.values);
  static TypeConverter<SleepStage?, String?> $convertersleepStagen =
      NullAwareTypeConverter.wrap($convertersleepStage);
}

class HealthSample extends DataClass implements Insertable<HealthSample> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String platformUuid;
  final HealthSampleType sampleType;
  final int startUtc;
  final int endUtc;
  final String tz;
  final bool tzInferred;
  final String? sourceBundleId;
  final SleepStage? sleepStage;
  final String? workoutType;
  final double? energyKcal;
  final double? distanceM;
  final String sourceName;
  final int fetchedAt;
  final int? removedInSourceAt;
  const HealthSample({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.platformUuid,
    required this.sampleType,
    required this.startUtc,
    required this.endUtc,
    required this.tz,
    required this.tzInferred,
    this.sourceBundleId,
    this.sleepStage,
    this.workoutType,
    this.energyKcal,
    this.distanceM,
    required this.sourceName,
    required this.fetchedAt,
    this.removedInSourceAt,
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
    map['platform_uuid'] = Variable<String>(platformUuid);
    {
      map['sample_type'] = Variable<String>(
        $HealthSamplesTable.$convertersampleType.toSql(sampleType),
      );
    }
    map['start_utc'] = Variable<int>(startUtc);
    map['end_utc'] = Variable<int>(endUtc);
    map['tz'] = Variable<String>(tz);
    map['tz_inferred'] = Variable<bool>(tzInferred);
    if (!nullToAbsent || sourceBundleId != null) {
      map['source_bundle_id'] = Variable<String>(sourceBundleId);
    }
    if (!nullToAbsent || sleepStage != null) {
      map['sleep_stage'] = Variable<String>(
        $HealthSamplesTable.$convertersleepStagen.toSql(sleepStage),
      );
    }
    if (!nullToAbsent || workoutType != null) {
      map['workout_type'] = Variable<String>(workoutType);
    }
    if (!nullToAbsent || energyKcal != null) {
      map['energy_kcal'] = Variable<double>(energyKcal);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    map['source_name'] = Variable<String>(sourceName);
    map['fetched_at'] = Variable<int>(fetchedAt);
    if (!nullToAbsent || removedInSourceAt != null) {
      map['removed_in_source_at'] = Variable<int>(removedInSourceAt);
    }
    return map;
  }

  HealthSamplesCompanion toCompanion(bool nullToAbsent) {
    return HealthSamplesCompanion(
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
      platformUuid: Value(platformUuid),
      sampleType: Value(sampleType),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      tz: Value(tz),
      tzInferred: Value(tzInferred),
      sourceBundleId: sourceBundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceBundleId),
      sleepStage: sleepStage == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepStage),
      workoutType: workoutType == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutType),
      energyKcal: energyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(energyKcal),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      sourceName: Value(sourceName),
      fetchedAt: Value(fetchedAt),
      removedInSourceAt: removedInSourceAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedInSourceAt),
    );
  }

  factory HealthSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthSample(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      platformUuid: serializer.fromJson<String>(json['platformUuid']),
      sampleType: serializer.fromJson<HealthSampleType>(json['sampleType']),
      startUtc: serializer.fromJson<int>(json['startUtc']),
      endUtc: serializer.fromJson<int>(json['endUtc']),
      tz: serializer.fromJson<String>(json['tz']),
      tzInferred: serializer.fromJson<bool>(json['tzInferred']),
      sourceBundleId: serializer.fromJson<String?>(json['sourceBundleId']),
      sleepStage: serializer.fromJson<SleepStage?>(json['sleepStage']),
      workoutType: serializer.fromJson<String?>(json['workoutType']),
      energyKcal: serializer.fromJson<double?>(json['energyKcal']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      removedInSourceAt: serializer.fromJson<int?>(json['removedInSourceAt']),
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
      'platformUuid': serializer.toJson<String>(platformUuid),
      'sampleType': serializer.toJson<HealthSampleType>(sampleType),
      'startUtc': serializer.toJson<int>(startUtc),
      'endUtc': serializer.toJson<int>(endUtc),
      'tz': serializer.toJson<String>(tz),
      'tzInferred': serializer.toJson<bool>(tzInferred),
      'sourceBundleId': serializer.toJson<String?>(sourceBundleId),
      'sleepStage': serializer.toJson<SleepStage?>(sleepStage),
      'workoutType': serializer.toJson<String?>(workoutType),
      'energyKcal': serializer.toJson<double?>(energyKcal),
      'distanceM': serializer.toJson<double?>(distanceM),
      'sourceName': serializer.toJson<String>(sourceName),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'removedInSourceAt': serializer.toJson<int?>(removedInSourceAt),
    };
  }

  HealthSample copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? platformUuid,
    HealthSampleType? sampleType,
    int? startUtc,
    int? endUtc,
    String? tz,
    bool? tzInferred,
    Value<String?> sourceBundleId = const Value.absent(),
    Value<SleepStage?> sleepStage = const Value.absent(),
    Value<String?> workoutType = const Value.absent(),
    Value<double?> energyKcal = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    String? sourceName,
    int? fetchedAt,
    Value<int?> removedInSourceAt = const Value.absent(),
  }) => HealthSample(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    platformUuid: platformUuid ?? this.platformUuid,
    sampleType: sampleType ?? this.sampleType,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    tz: tz ?? this.tz,
    tzInferred: tzInferred ?? this.tzInferred,
    sourceBundleId: sourceBundleId.present
        ? sourceBundleId.value
        : this.sourceBundleId,
    sleepStage: sleepStage.present ? sleepStage.value : this.sleepStage,
    workoutType: workoutType.present ? workoutType.value : this.workoutType,
    energyKcal: energyKcal.present ? energyKcal.value : this.energyKcal,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    sourceName: sourceName ?? this.sourceName,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    removedInSourceAt: removedInSourceAt.present
        ? removedInSourceAt.value
        : this.removedInSourceAt,
  );
  HealthSample copyWithCompanion(HealthSamplesCompanion data) {
    return HealthSample(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      platformUuid: data.platformUuid.present
          ? data.platformUuid.value
          : this.platformUuid,
      sampleType: data.sampleType.present
          ? data.sampleType.value
          : this.sampleType,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      tz: data.tz.present ? data.tz.value : this.tz,
      tzInferred: data.tzInferred.present
          ? data.tzInferred.value
          : this.tzInferred,
      sourceBundleId: data.sourceBundleId.present
          ? data.sourceBundleId.value
          : this.sourceBundleId,
      sleepStage: data.sleepStage.present
          ? data.sleepStage.value
          : this.sleepStage,
      workoutType: data.workoutType.present
          ? data.workoutType.value
          : this.workoutType,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      removedInSourceAt: data.removedInSourceAt.present
          ? data.removedInSourceAt.value
          : this.removedInSourceAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthSample(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('platformUuid: $platformUuid, ')
          ..write('sampleType: $sampleType, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('tz: $tz, ')
          ..write('tzInferred: $tzInferred, ')
          ..write('sourceBundleId: $sourceBundleId, ')
          ..write('sleepStage: $sleepStage, ')
          ..write('workoutType: $workoutType, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('distanceM: $distanceM, ')
          ..write('sourceName: $sourceName, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('removedInSourceAt: $removedInSourceAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    platformUuid,
    sampleType,
    startUtc,
    endUtc,
    tz,
    tzInferred,
    sourceBundleId,
    sleepStage,
    workoutType,
    energyKcal,
    distanceM,
    sourceName,
    fetchedAt,
    removedInSourceAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSample &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.platformUuid == this.platformUuid &&
          other.sampleType == this.sampleType &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.tz == this.tz &&
          other.tzInferred == this.tzInferred &&
          other.sourceBundleId == this.sourceBundleId &&
          other.sleepStage == this.sleepStage &&
          other.workoutType == this.workoutType &&
          other.energyKcal == this.energyKcal &&
          other.distanceM == this.distanceM &&
          other.sourceName == this.sourceName &&
          other.fetchedAt == this.fetchedAt &&
          other.removedInSourceAt == this.removedInSourceAt);
}

class HealthSamplesCompanion extends UpdateCompanion<HealthSample> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> platformUuid;
  final Value<HealthSampleType> sampleType;
  final Value<int> startUtc;
  final Value<int> endUtc;
  final Value<String> tz;
  final Value<bool> tzInferred;
  final Value<String?> sourceBundleId;
  final Value<SleepStage?> sleepStage;
  final Value<String?> workoutType;
  final Value<double?> energyKcal;
  final Value<double?> distanceM;
  final Value<String> sourceName;
  final Value<int> fetchedAt;
  final Value<int?> removedInSourceAt;
  final Value<int> rowid;
  const HealthSamplesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.platformUuid = const Value.absent(),
    this.sampleType = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.tz = const Value.absent(),
    this.tzInferred = const Value.absent(),
    this.sourceBundleId = const Value.absent(),
    this.sleepStage = const Value.absent(),
    this.workoutType = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.removedInSourceAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthSamplesCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String platformUuid,
    required HealthSampleType sampleType,
    required int startUtc,
    required int endUtc,
    required String tz,
    this.tzInferred = const Value.absent(),
    this.sourceBundleId = const Value.absent(),
    this.sleepStage = const Value.absent(),
    this.workoutType = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.distanceM = const Value.absent(),
    required String sourceName,
    required int fetchedAt,
    this.removedInSourceAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       platformUuid = Value(platformUuid),
       sampleType = Value(sampleType),
       startUtc = Value(startUtc),
       endUtc = Value(endUtc),
       tz = Value(tz),
       sourceName = Value(sourceName),
       fetchedAt = Value(fetchedAt);
  static Insertable<HealthSample> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? platformUuid,
    Expression<String>? sampleType,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<String>? tz,
    Expression<bool>? tzInferred,
    Expression<String>? sourceBundleId,
    Expression<String>? sleepStage,
    Expression<String>? workoutType,
    Expression<double>? energyKcal,
    Expression<double>? distanceM,
    Expression<String>? sourceName,
    Expression<int>? fetchedAt,
    Expression<int>? removedInSourceAt,
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
      if (platformUuid != null) 'platform_uuid': platformUuid,
      if (sampleType != null) 'sample_type': sampleType,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (tz != null) 'tz': tz,
      if (tzInferred != null) 'tz_inferred': tzInferred,
      if (sourceBundleId != null) 'source_bundle_id': sourceBundleId,
      if (sleepStage != null) 'sleep_stage': sleepStage,
      if (workoutType != null) 'workout_type': workoutType,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (distanceM != null) 'distance_m': distanceM,
      if (sourceName != null) 'source_name': sourceName,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (removedInSourceAt != null) 'removed_in_source_at': removedInSourceAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthSamplesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? platformUuid,
    Value<HealthSampleType>? sampleType,
    Value<int>? startUtc,
    Value<int>? endUtc,
    Value<String>? tz,
    Value<bool>? tzInferred,
    Value<String?>? sourceBundleId,
    Value<SleepStage?>? sleepStage,
    Value<String?>? workoutType,
    Value<double?>? energyKcal,
    Value<double?>? distanceM,
    Value<String>? sourceName,
    Value<int>? fetchedAt,
    Value<int?>? removedInSourceAt,
    Value<int>? rowid,
  }) {
    return HealthSamplesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      platformUuid: platformUuid ?? this.platformUuid,
      sampleType: sampleType ?? this.sampleType,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      tz: tz ?? this.tz,
      tzInferred: tzInferred ?? this.tzInferred,
      sourceBundleId: sourceBundleId ?? this.sourceBundleId,
      sleepStage: sleepStage ?? this.sleepStage,
      workoutType: workoutType ?? this.workoutType,
      energyKcal: energyKcal ?? this.energyKcal,
      distanceM: distanceM ?? this.distanceM,
      sourceName: sourceName ?? this.sourceName,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      removedInSourceAt: removedInSourceAt ?? this.removedInSourceAt,
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
    if (platformUuid.present) {
      map['platform_uuid'] = Variable<String>(platformUuid.value);
    }
    if (sampleType.present) {
      map['sample_type'] = Variable<String>(
        $HealthSamplesTable.$convertersampleType.toSql(sampleType.value),
      );
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (tzInferred.present) {
      map['tz_inferred'] = Variable<bool>(tzInferred.value);
    }
    if (sourceBundleId.present) {
      map['source_bundle_id'] = Variable<String>(sourceBundleId.value);
    }
    if (sleepStage.present) {
      map['sleep_stage'] = Variable<String>(
        $HealthSamplesTable.$convertersleepStagen.toSql(sleepStage.value),
      );
    }
    if (workoutType.present) {
      map['workout_type'] = Variable<String>(workoutType.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (removedInSourceAt.present) {
      map['removed_in_source_at'] = Variable<int>(removedInSourceAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthSamplesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('platformUuid: $platformUuid, ')
          ..write('sampleType: $sampleType, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('tz: $tz, ')
          ..write('tzInferred: $tzInferred, ')
          ..write('sourceBundleId: $sourceBundleId, ')
          ..write('sleepStage: $sleepStage, ')
          ..write('workoutType: $workoutType, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('distanceM: $distanceM, ')
          ..write('sourceName: $sourceName, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('removedInSourceAt: $removedInSourceAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthAnchorsTable extends HealthAnchors
    with TableInfo<$HealthAnchorsTable, HealthAnchor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthAnchorsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<HealthSampleType, String>
  sampleType = GeneratedColumn<String>(
    'sample_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HealthSampleType>($HealthAnchorsTable.$convertersampleType);
  static const VerificationMeta _anchorMeta = const VerificationMeta('anchor');
  @override
  late final GeneratedColumn<Uint8List> anchor = GeneratedColumn<Uint8List>(
    'anchor',
    aliasedName,
    false,
    type: DriftSqlType.blob,
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
  List<GeneratedColumn> get $columns => [sampleType, anchor, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_anchors';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthAnchor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anchor')) {
      context.handle(
        _anchorMeta,
        anchor.isAcceptableOrUnknown(data['anchor']!, _anchorMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorMeta);
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
  Set<GeneratedColumn> get $primaryKey => {sampleType};
  @override
  HealthAnchor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthAnchor(
      sampleType: $HealthAnchorsTable.$convertersampleType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sample_type'],
        )!,
      ),
      anchor: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}anchor'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HealthAnchorsTable createAlias(String alias) {
    return $HealthAnchorsTable(attachedDatabase, alias);
  }

  static TypeConverter<HealthSampleType, String> $convertersampleType =
      const EnumConverter(HealthSampleType.values);
}

class HealthAnchor extends DataClass implements Insertable<HealthAnchor> {
  final HealthSampleType sampleType;
  final Uint8List anchor;
  final int updatedAt;
  const HealthAnchor({
    required this.sampleType,
    required this.anchor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['sample_type'] = Variable<String>(
        $HealthAnchorsTable.$convertersampleType.toSql(sampleType),
      );
    }
    map['anchor'] = Variable<Uint8List>(anchor);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  HealthAnchorsCompanion toCompanion(bool nullToAbsent) {
    return HealthAnchorsCompanion(
      sampleType: Value(sampleType),
      anchor: Value(anchor),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthAnchor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthAnchor(
      sampleType: serializer.fromJson<HealthSampleType>(json['sampleType']),
      anchor: serializer.fromJson<Uint8List>(json['anchor']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sampleType': serializer.toJson<HealthSampleType>(sampleType),
      'anchor': serializer.toJson<Uint8List>(anchor),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  HealthAnchor copyWith({
    HealthSampleType? sampleType,
    Uint8List? anchor,
    int? updatedAt,
  }) => HealthAnchor(
    sampleType: sampleType ?? this.sampleType,
    anchor: anchor ?? this.anchor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HealthAnchor copyWithCompanion(HealthAnchorsCompanion data) {
    return HealthAnchor(
      sampleType: data.sampleType.present
          ? data.sampleType.value
          : this.sampleType,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthAnchor(')
          ..write('sampleType: $sampleType, ')
          ..write('anchor: $anchor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sampleType, $driftBlobEquality.hash(anchor), updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthAnchor &&
          other.sampleType == this.sampleType &&
          $driftBlobEquality.equals(other.anchor, this.anchor) &&
          other.updatedAt == this.updatedAt);
}

class HealthAnchorsCompanion extends UpdateCompanion<HealthAnchor> {
  final Value<HealthSampleType> sampleType;
  final Value<Uint8List> anchor;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const HealthAnchorsCompanion({
    this.sampleType = const Value.absent(),
    this.anchor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthAnchorsCompanion.insert({
    required HealthSampleType sampleType,
    required Uint8List anchor,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : sampleType = Value(sampleType),
       anchor = Value(anchor),
       updatedAt = Value(updatedAt);
  static Insertable<HealthAnchor> custom({
    Expression<String>? sampleType,
    Expression<Uint8List>? anchor,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sampleType != null) 'sample_type': sampleType,
      if (anchor != null) 'anchor': anchor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthAnchorsCompanion copyWith({
    Value<HealthSampleType>? sampleType,
    Value<Uint8List>? anchor,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return HealthAnchorsCompanion(
      sampleType: sampleType ?? this.sampleType,
      anchor: anchor ?? this.anchor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sampleType.present) {
      map['sample_type'] = Variable<String>(
        $HealthAnchorsTable.$convertersampleType.toSql(sampleType.value),
      );
    }
    if (anchor.present) {
      map['anchor'] = Variable<Uint8List>(anchor.value);
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
    return (StringBuffer('HealthAnchorsCompanion(')
          ..write('sampleType: $sampleType, ')
          ..write('anchor: $anchor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthDailyTable extends HealthDaily
    with TableInfo<$HealthDailyTable, HealthDailyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthDailyTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggTzMeta = const VerificationMeta('aggTz');
  @override
  late final GeneratedColumn<String> aggTz = GeneratedColumn<String>(
    'agg_tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalStartUtcMeta = const VerificationMeta(
    'intervalStartUtc',
  );
  @override
  late final GeneratedColumn<int> intervalStartUtc = GeneratedColumn<int>(
    'interval_start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalEndUtcMeta = const VerificationMeta(
    'intervalEndUtc',
  );
  @override
  late final GeneratedColumn<int> intervalEndUtc = GeneratedColumn<int>(
    'interval_end_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HealthMetric, String> metric =
      GeneratedColumn<String>(
        'metric',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HealthMetric>($HealthDailyTable.$convertermetric);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
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
    localDate,
    aggTz,
    intervalStartUtc,
    intervalEndUtc,
    metric,
    value,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthDailyData> instance, {
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
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('agg_tz')) {
      context.handle(
        _aggTzMeta,
        aggTz.isAcceptableOrUnknown(data['agg_tz']!, _aggTzMeta),
      );
    } else if (isInserting) {
      context.missing(_aggTzMeta);
    }
    if (data.containsKey('interval_start_utc')) {
      context.handle(
        _intervalStartUtcMeta,
        intervalStartUtc.isAcceptableOrUnknown(
          data['interval_start_utc']!,
          _intervalStartUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalStartUtcMeta);
    }
    if (data.containsKey('interval_end_utc')) {
      context.handle(
        _intervalEndUtcMeta,
        intervalEndUtc.isAcceptableOrUnknown(
          data['interval_end_utc']!,
          _intervalEndUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalEndUtcMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localDate, metric},
  ];
  @override
  HealthDailyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthDailyData(
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
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      aggTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agg_tz'],
      )!,
      intervalStartUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_start_utc'],
      )!,
      intervalEndUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_end_utc'],
      )!,
      metric: $HealthDailyTable.$convertermetric.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}metric'],
        )!,
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $HealthDailyTable createAlias(String alias) {
    return $HealthDailyTable(attachedDatabase, alias);
  }

  static TypeConverter<HealthMetric, String> $convertermetric =
      const EnumConverter(HealthMetric.values);
}

class HealthDailyData extends DataClass implements Insertable<HealthDailyData> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String localDate;
  final String aggTz;
  final int intervalStartUtc;
  final int intervalEndUtc;
  final HealthMetric metric;
  final double value;
  final int fetchedAt;
  const HealthDailyData({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.localDate,
    required this.aggTz,
    required this.intervalStartUtc,
    required this.intervalEndUtc,
    required this.metric,
    required this.value,
    required this.fetchedAt,
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
    map['local_date'] = Variable<String>(localDate);
    map['agg_tz'] = Variable<String>(aggTz);
    map['interval_start_utc'] = Variable<int>(intervalStartUtc);
    map['interval_end_utc'] = Variable<int>(intervalEndUtc);
    {
      map['metric'] = Variable<String>(
        $HealthDailyTable.$convertermetric.toSql(metric),
      );
    }
    map['value'] = Variable<double>(value);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  HealthDailyCompanion toCompanion(bool nullToAbsent) {
    return HealthDailyCompanion(
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
      localDate: Value(localDate),
      aggTz: Value(aggTz),
      intervalStartUtc: Value(intervalStartUtc),
      intervalEndUtc: Value(intervalEndUtc),
      metric: Value(metric),
      value: Value(value),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory HealthDailyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthDailyData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      localDate: serializer.fromJson<String>(json['localDate']),
      aggTz: serializer.fromJson<String>(json['aggTz']),
      intervalStartUtc: serializer.fromJson<int>(json['intervalStartUtc']),
      intervalEndUtc: serializer.fromJson<int>(json['intervalEndUtc']),
      metric: serializer.fromJson<HealthMetric>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
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
      'localDate': serializer.toJson<String>(localDate),
      'aggTz': serializer.toJson<String>(aggTz),
      'intervalStartUtc': serializer.toJson<int>(intervalStartUtc),
      'intervalEndUtc': serializer.toJson<int>(intervalEndUtc),
      'metric': serializer.toJson<HealthMetric>(metric),
      'value': serializer.toJson<double>(value),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  HealthDailyData copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? localDate,
    String? aggTz,
    int? intervalStartUtc,
    int? intervalEndUtc,
    HealthMetric? metric,
    double? value,
    int? fetchedAt,
  }) => HealthDailyData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    localDate: localDate ?? this.localDate,
    aggTz: aggTz ?? this.aggTz,
    intervalStartUtc: intervalStartUtc ?? this.intervalStartUtc,
    intervalEndUtc: intervalEndUtc ?? this.intervalEndUtc,
    metric: metric ?? this.metric,
    value: value ?? this.value,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  HealthDailyData copyWithCompanion(HealthDailyCompanion data) {
    return HealthDailyData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      aggTz: data.aggTz.present ? data.aggTz.value : this.aggTz,
      intervalStartUtc: data.intervalStartUtc.present
          ? data.intervalStartUtc.value
          : this.intervalStartUtc,
      intervalEndUtc: data.intervalEndUtc.present
          ? data.intervalEndUtc.value
          : this.intervalEndUtc,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthDailyData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('localDate: $localDate, ')
          ..write('aggTz: $aggTz, ')
          ..write('intervalStartUtc: $intervalStartUtc, ')
          ..write('intervalEndUtc: $intervalEndUtc, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('fetchedAt: $fetchedAt')
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
    localDate,
    aggTz,
    intervalStartUtc,
    intervalEndUtc,
    metric,
    value,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthDailyData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.localDate == this.localDate &&
          other.aggTz == this.aggTz &&
          other.intervalStartUtc == this.intervalStartUtc &&
          other.intervalEndUtc == this.intervalEndUtc &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.fetchedAt == this.fetchedAt);
}

class HealthDailyCompanion extends UpdateCompanion<HealthDailyData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> localDate;
  final Value<String> aggTz;
  final Value<int> intervalStartUtc;
  final Value<int> intervalEndUtc;
  final Value<HealthMetric> metric;
  final Value<double> value;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const HealthDailyCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.localDate = const Value.absent(),
    this.aggTz = const Value.absent(),
    this.intervalStartUtc = const Value.absent(),
    this.intervalEndUtc = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthDailyCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String localDate,
    required String aggTz,
    required int intervalStartUtc,
    required int intervalEndUtc,
    required HealthMetric metric,
    required double value,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       localDate = Value(localDate),
       aggTz = Value(aggTz),
       intervalStartUtc = Value(intervalStartUtc),
       intervalEndUtc = Value(intervalEndUtc),
       metric = Value(metric),
       value = Value(value),
       fetchedAt = Value(fetchedAt);
  static Insertable<HealthDailyData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? localDate,
    Expression<String>? aggTz,
    Expression<int>? intervalStartUtc,
    Expression<int>? intervalEndUtc,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<int>? fetchedAt,
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
      if (localDate != null) 'local_date': localDate,
      if (aggTz != null) 'agg_tz': aggTz,
      if (intervalStartUtc != null) 'interval_start_utc': intervalStartUtc,
      if (intervalEndUtc != null) 'interval_end_utc': intervalEndUtc,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthDailyCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? localDate,
    Value<String>? aggTz,
    Value<int>? intervalStartUtc,
    Value<int>? intervalEndUtc,
    Value<HealthMetric>? metric,
    Value<double>? value,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return HealthDailyCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      localDate: localDate ?? this.localDate,
      aggTz: aggTz ?? this.aggTz,
      intervalStartUtc: intervalStartUtc ?? this.intervalStartUtc,
      intervalEndUtc: intervalEndUtc ?? this.intervalEndUtc,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      fetchedAt: fetchedAt ?? this.fetchedAt,
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
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (aggTz.present) {
      map['agg_tz'] = Variable<String>(aggTz.value);
    }
    if (intervalStartUtc.present) {
      map['interval_start_utc'] = Variable<int>(intervalStartUtc.value);
    }
    if (intervalEndUtc.present) {
      map['interval_end_utc'] = Variable<int>(intervalEndUtc.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(
        $HealthDailyTable.$convertermetric.toSql(metric.value),
      );
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthDailyCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('localDate: $localDate, ')
          ..write('aggTz: $aggTz, ')
          ..write('intervalStartUtc: $intervalStartUtc, ')
          ..write('intervalEndUtc: $intervalEndUtc, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizeRunsTable extends OrganizeRuns
    with TableInfo<$OrganizeRunsTable, OrganizeRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizeRunsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<OrganizeTrigger, String> trigger =
      GeneratedColumn<String>(
        'trigger',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OrganizeTrigger>($OrganizeRunsTable.$convertertrigger);
  static const VerificationMeta _inputSnapshotMeta = const VerificationMeta(
    'inputSnapshot',
  );
  @override
  late final GeneratedColumn<String> inputSnapshot = GeneratedColumn<String>(
    'input_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelConfigIdMeta = const VerificationMeta(
    'modelConfigId',
  );
  @override
  late final GeneratedColumn<String> modelConfigId = GeneratedColumn<String>(
    'model_config_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelSnapshotMeta = const VerificationMeta(
    'modelSnapshot',
  );
  @override
  late final GeneratedColumn<String> modelSnapshot = GeneratedColumn<String>(
    'model_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OrganizeRunStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OrganizeRunStatus>($OrganizeRunsTable.$converterstatus);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
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
    trigger,
    inputSnapshot,
    modelConfigId,
    modelSnapshot,
    status,
    error,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organize_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrganizeRun> instance, {
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
    if (data.containsKey('input_snapshot')) {
      context.handle(
        _inputSnapshotMeta,
        inputSnapshot.isAcceptableOrUnknown(
          data['input_snapshot']!,
          _inputSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputSnapshotMeta);
    }
    if (data.containsKey('model_config_id')) {
      context.handle(
        _modelConfigIdMeta,
        modelConfigId.isAcceptableOrUnknown(
          data['model_config_id']!,
          _modelConfigIdMeta,
        ),
      );
    }
    if (data.containsKey('model_snapshot')) {
      context.handle(
        _modelSnapshotMeta,
        modelSnapshot.isAcceptableOrUnknown(
          data['model_snapshot']!,
          _modelSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrganizeRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizeRun(
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
      trigger: $OrganizeRunsTable.$convertertrigger.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}trigger'],
        )!,
      ),
      inputSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_snapshot'],
      )!,
      modelConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_config_id'],
      ),
      modelSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_snapshot'],
      ),
      status: $OrganizeRunsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $OrganizeRunsTable createAlias(String alias) {
    return $OrganizeRunsTable(attachedDatabase, alias);
  }

  static TypeConverter<OrganizeTrigger, String> $convertertrigger =
      const EnumConverter(OrganizeTrigger.values);
  static TypeConverter<OrganizeRunStatus, String> $converterstatus =
      const EnumConverter(OrganizeRunStatus.values);
}

class OrganizeRun extends DataClass implements Insertable<OrganizeRun> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final OrganizeTrigger trigger;
  final String inputSnapshot;
  final String? modelConfigId;
  final String? modelSnapshot;
  final OrganizeRunStatus status;
  final String? error;
  final int? startedAt;
  final int? finishedAt;
  const OrganizeRun({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.trigger,
    required this.inputSnapshot,
    this.modelConfigId,
    this.modelSnapshot,
    required this.status,
    this.error,
    this.startedAt,
    this.finishedAt,
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
    {
      map['trigger'] = Variable<String>(
        $OrganizeRunsTable.$convertertrigger.toSql(trigger),
      );
    }
    map['input_snapshot'] = Variable<String>(inputSnapshot);
    if (!nullToAbsent || modelConfigId != null) {
      map['model_config_id'] = Variable<String>(modelConfigId);
    }
    if (!nullToAbsent || modelSnapshot != null) {
      map['model_snapshot'] = Variable<String>(modelSnapshot);
    }
    {
      map['status'] = Variable<String>(
        $OrganizeRunsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<int>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    return map;
  }

  OrganizeRunsCompanion toCompanion(bool nullToAbsent) {
    return OrganizeRunsCompanion(
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
      trigger: Value(trigger),
      inputSnapshot: Value(inputSnapshot),
      modelConfigId: modelConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelConfigId),
      modelSnapshot: modelSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(modelSnapshot),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory OrganizeRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizeRun(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      trigger: serializer.fromJson<OrganizeTrigger>(json['trigger']),
      inputSnapshot: serializer.fromJson<String>(json['inputSnapshot']),
      modelConfigId: serializer.fromJson<String?>(json['modelConfigId']),
      modelSnapshot: serializer.fromJson<String?>(json['modelSnapshot']),
      status: serializer.fromJson<OrganizeRunStatus>(json['status']),
      error: serializer.fromJson<String?>(json['error']),
      startedAt: serializer.fromJson<int?>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
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
      'trigger': serializer.toJson<OrganizeTrigger>(trigger),
      'inputSnapshot': serializer.toJson<String>(inputSnapshot),
      'modelConfigId': serializer.toJson<String?>(modelConfigId),
      'modelSnapshot': serializer.toJson<String?>(modelSnapshot),
      'status': serializer.toJson<OrganizeRunStatus>(status),
      'error': serializer.toJson<String?>(error),
      'startedAt': serializer.toJson<int?>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
    };
  }

  OrganizeRun copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    OrganizeTrigger? trigger,
    String? inputSnapshot,
    Value<String?> modelConfigId = const Value.absent(),
    Value<String?> modelSnapshot = const Value.absent(),
    OrganizeRunStatus? status,
    Value<String?> error = const Value.absent(),
    Value<int?> startedAt = const Value.absent(),
    Value<int?> finishedAt = const Value.absent(),
  }) => OrganizeRun(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    trigger: trigger ?? this.trigger,
    inputSnapshot: inputSnapshot ?? this.inputSnapshot,
    modelConfigId: modelConfigId.present
        ? modelConfigId.value
        : this.modelConfigId,
    modelSnapshot: modelSnapshot.present
        ? modelSnapshot.value
        : this.modelSnapshot,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  OrganizeRun copyWithCompanion(OrganizeRunsCompanion data) {
    return OrganizeRun(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      inputSnapshot: data.inputSnapshot.present
          ? data.inputSnapshot.value
          : this.inputSnapshot,
      modelConfigId: data.modelConfigId.present
          ? data.modelConfigId.value
          : this.modelConfigId,
      modelSnapshot: data.modelSnapshot.present
          ? data.modelSnapshot.value
          : this.modelSnapshot,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizeRun(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('trigger: $trigger, ')
          ..write('inputSnapshot: $inputSnapshot, ')
          ..write('modelConfigId: $modelConfigId, ')
          ..write('modelSnapshot: $modelSnapshot, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
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
    trigger,
    inputSnapshot,
    modelConfigId,
    modelSnapshot,
    status,
    error,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizeRun &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.trigger == this.trigger &&
          other.inputSnapshot == this.inputSnapshot &&
          other.modelConfigId == this.modelConfigId &&
          other.modelSnapshot == this.modelSnapshot &&
          other.status == this.status &&
          other.error == this.error &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class OrganizeRunsCompanion extends UpdateCompanion<OrganizeRun> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<OrganizeTrigger> trigger;
  final Value<String> inputSnapshot;
  final Value<String?> modelConfigId;
  final Value<String?> modelSnapshot;
  final Value<OrganizeRunStatus> status;
  final Value<String?> error;
  final Value<int?> startedAt;
  final Value<int?> finishedAt;
  final Value<int> rowid;
  const OrganizeRunsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.trigger = const Value.absent(),
    this.inputSnapshot = const Value.absent(),
    this.modelConfigId = const Value.absent(),
    this.modelSnapshot = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizeRunsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required OrganizeTrigger trigger,
    required String inputSnapshot,
    this.modelConfigId = const Value.absent(),
    this.modelSnapshot = const Value.absent(),
    required OrganizeRunStatus status,
    this.error = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       trigger = Value(trigger),
       inputSnapshot = Value(inputSnapshot),
       status = Value(status);
  static Insertable<OrganizeRun> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? trigger,
    Expression<String>? inputSnapshot,
    Expression<String>? modelConfigId,
    Expression<String>? modelSnapshot,
    Expression<String>? status,
    Expression<String>? error,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
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
      if (trigger != null) 'trigger': trigger,
      if (inputSnapshot != null) 'input_snapshot': inputSnapshot,
      if (modelConfigId != null) 'model_config_id': modelConfigId,
      if (modelSnapshot != null) 'model_snapshot': modelSnapshot,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizeRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<OrganizeTrigger>? trigger,
    Value<String>? inputSnapshot,
    Value<String?>? modelConfigId,
    Value<String?>? modelSnapshot,
    Value<OrganizeRunStatus>? status,
    Value<String?>? error,
    Value<int?>? startedAt,
    Value<int?>? finishedAt,
    Value<int>? rowid,
  }) {
    return OrganizeRunsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      trigger: trigger ?? this.trigger,
      inputSnapshot: inputSnapshot ?? this.inputSnapshot,
      modelConfigId: modelConfigId ?? this.modelConfigId,
      modelSnapshot: modelSnapshot ?? this.modelSnapshot,
      status: status ?? this.status,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
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
    if (trigger.present) {
      map['trigger'] = Variable<String>(
        $OrganizeRunsTable.$convertertrigger.toSql(trigger.value),
      );
    }
    if (inputSnapshot.present) {
      map['input_snapshot'] = Variable<String>(inputSnapshot.value);
    }
    if (modelConfigId.present) {
      map['model_config_id'] = Variable<String>(modelConfigId.value);
    }
    if (modelSnapshot.present) {
      map['model_snapshot'] = Variable<String>(modelSnapshot.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $OrganizeRunsTable.$converterstatus.toSql(status.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizeRunsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('trigger: $trigger, ')
          ..write('inputSnapshot: $inputSnapshot, ')
          ..write('modelConfigId: $modelConfigId, ')
          ..write('modelSnapshot: $modelSnapshot, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizeRunItemsTable extends OrganizeRunItems
    with TableInfo<$OrganizeRunItemsTable, OrganizeRunItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizeRunItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _organizeRunIdMeta = const VerificationMeta(
    'organizeRunId',
  );
  @override
  late final GeneratedColumn<String> organizeRunId = GeneratedColumn<String>(
    'organize_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OrganizeItemStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OrganizeItemStatus>($OrganizeRunItemsTable.$converterstatus);
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctionSuggestionIdMeta =
      const VerificationMeta('correctionSuggestionId');
  @override
  late final GeneratedColumn<String> correctionSuggestionId =
      GeneratedColumn<String>(
        'correction_suggestion_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
    organizeRunId,
    recordId,
    status,
    retryCount,
    correctionSuggestionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organize_run_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrganizeRunItem> instance, {
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
    if (data.containsKey('organize_run_id')) {
      context.handle(
        _organizeRunIdMeta,
        organizeRunId.isAcceptableOrUnknown(
          data['organize_run_id']!,
          _organizeRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizeRunIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('correction_suggestion_id')) {
      context.handle(
        _correctionSuggestionIdMeta,
        correctionSuggestionId.isAcceptableOrUnknown(
          data['correction_suggestion_id']!,
          _correctionSuggestionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {organizeRunId, recordId},
  ];
  @override
  OrganizeRunItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizeRunItem(
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
      organizeRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organize_run_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      status: $OrganizeRunItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      correctionSuggestionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_suggestion_id'],
      ),
    );
  }

  @override
  $OrganizeRunItemsTable createAlias(String alias) {
    return $OrganizeRunItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<OrganizeItemStatus, String> $converterstatus =
      const EnumConverter(OrganizeItemStatus.values);
}

class OrganizeRunItem extends DataClass implements Insertable<OrganizeRunItem> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String organizeRunId;
  final String recordId;
  final OrganizeItemStatus status;
  final int retryCount;
  final String? correctionSuggestionId;
  const OrganizeRunItem({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.organizeRunId,
    required this.recordId,
    required this.status,
    required this.retryCount,
    this.correctionSuggestionId,
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
    map['organize_run_id'] = Variable<String>(organizeRunId);
    map['record_id'] = Variable<String>(recordId);
    {
      map['status'] = Variable<String>(
        $OrganizeRunItemsTable.$converterstatus.toSql(status),
      );
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || correctionSuggestionId != null) {
      map['correction_suggestion_id'] = Variable<String>(
        correctionSuggestionId,
      );
    }
    return map;
  }

  OrganizeRunItemsCompanion toCompanion(bool nullToAbsent) {
    return OrganizeRunItemsCompanion(
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
      organizeRunId: Value(organizeRunId),
      recordId: Value(recordId),
      status: Value(status),
      retryCount: Value(retryCount),
      correctionSuggestionId: correctionSuggestionId == null && nullToAbsent
          ? const Value.absent()
          : Value(correctionSuggestionId),
    );
  }

  factory OrganizeRunItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizeRunItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      organizeRunId: serializer.fromJson<String>(json['organizeRunId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      status: serializer.fromJson<OrganizeItemStatus>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      correctionSuggestionId: serializer.fromJson<String?>(
        json['correctionSuggestionId'],
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
      'organizeRunId': serializer.toJson<String>(organizeRunId),
      'recordId': serializer.toJson<String>(recordId),
      'status': serializer.toJson<OrganizeItemStatus>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'correctionSuggestionId': serializer.toJson<String?>(
        correctionSuggestionId,
      ),
    };
  }

  OrganizeRunItem copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? organizeRunId,
    String? recordId,
    OrganizeItemStatus? status,
    int? retryCount,
    Value<String?> correctionSuggestionId = const Value.absent(),
  }) => OrganizeRunItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    organizeRunId: organizeRunId ?? this.organizeRunId,
    recordId: recordId ?? this.recordId,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    correctionSuggestionId: correctionSuggestionId.present
        ? correctionSuggestionId.value
        : this.correctionSuggestionId,
  );
  OrganizeRunItem copyWithCompanion(OrganizeRunItemsCompanion data) {
    return OrganizeRunItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      organizeRunId: data.organizeRunId.present
          ? data.organizeRunId.value
          : this.organizeRunId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      correctionSuggestionId: data.correctionSuggestionId.present
          ? data.correctionSuggestionId.value
          : this.correctionSuggestionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizeRunItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('organizeRunId: $organizeRunId, ')
          ..write('recordId: $recordId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('correctionSuggestionId: $correctionSuggestionId')
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
    organizeRunId,
    recordId,
    status,
    retryCount,
    correctionSuggestionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizeRunItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.organizeRunId == this.organizeRunId &&
          other.recordId == this.recordId &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.correctionSuggestionId == this.correctionSuggestionId);
}

class OrganizeRunItemsCompanion extends UpdateCompanion<OrganizeRunItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> organizeRunId;
  final Value<String> recordId;
  final Value<OrganizeItemStatus> status;
  final Value<int> retryCount;
  final Value<String?> correctionSuggestionId;
  final Value<int> rowid;
  const OrganizeRunItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.organizeRunId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.correctionSuggestionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizeRunItemsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String organizeRunId,
    required String recordId,
    required OrganizeItemStatus status,
    this.retryCount = const Value.absent(),
    this.correctionSuggestionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       organizeRunId = Value(organizeRunId),
       recordId = Value(recordId),
       status = Value(status);
  static Insertable<OrganizeRunItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? organizeRunId,
    Expression<String>? recordId,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? correctionSuggestionId,
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
      if (organizeRunId != null) 'organize_run_id': organizeRunId,
      if (recordId != null) 'record_id': recordId,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (correctionSuggestionId != null)
        'correction_suggestion_id': correctionSuggestionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizeRunItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? organizeRunId,
    Value<String>? recordId,
    Value<OrganizeItemStatus>? status,
    Value<int>? retryCount,
    Value<String?>? correctionSuggestionId,
    Value<int>? rowid,
  }) {
    return OrganizeRunItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      organizeRunId: organizeRunId ?? this.organizeRunId,
      recordId: recordId ?? this.recordId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      correctionSuggestionId:
          correctionSuggestionId ?? this.correctionSuggestionId,
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
    if (organizeRunId.present) {
      map['organize_run_id'] = Variable<String>(organizeRunId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $OrganizeRunItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (correctionSuggestionId.present) {
      map['correction_suggestion_id'] = Variable<String>(
        correctionSuggestionId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizeRunItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('organizeRunId: $organizeRunId, ')
          ..write('recordId: $recordId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('correctionSuggestionId: $correctionSuggestionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelCallsTable extends ModelCalls
    with TableInfo<$ModelCallsTable, ModelCall> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelCallsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _organizeRunIdMeta = const VerificationMeta(
    'organizeRunId',
  );
  @override
  late final GeneratedColumn<String> organizeRunId = GeneratedColumn<String>(
    'organize_run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelConfigIdMeta = const VerificationMeta(
    'modelConfigId',
  );
  @override
  late final GeneratedColumn<String> modelConfigId = GeneratedColumn<String>(
    'model_config_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataBoundary, String>
  dataBoundary = GeneratedColumn<String>(
    'data_boundary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DataBoundary>($ModelCallsTable.$converterdataBoundary);
  static const VerificationMeta _sentMessageIdsMeta = const VerificationMeta(
    'sentMessageIds',
  );
  @override
  late final GeneratedColumn<String> sentMessageIds = GeneratedColumn<String>(
    'sent_message_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAttachmentIdsMeta = const VerificationMeta(
    'sentAttachmentIds',
  );
  @override
  late final GeneratedColumn<String> sentAttachmentIds =
      GeneratedColumn<String>(
        'sent_attachment_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requestAtMeta = const VerificationMeta(
    'requestAt',
  );
  @override
  late final GeneratedColumn<int> requestAt = GeneratedColumn<int>(
    'request_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseAtMeta = const VerificationMeta(
    'responseAt',
  );
  @override
  late final GeneratedColumn<int> responseAt = GeneratedColumn<int>(
    'response_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ModelCallStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ModelCallStatus>($ModelCallsTable.$converterstatus);
  static const VerificationMeta _tokensInMeta = const VerificationMeta(
    'tokensIn',
  );
  @override
  late final GeneratedColumn<int> tokensIn = GeneratedColumn<int>(
    'tokens_in',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensOutMeta = const VerificationMeta(
    'tokensOut',
  );
  @override
  late final GeneratedColumn<int> tokensOut = GeneratedColumn<int>(
    'tokens_out',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseTextMeta = const VerificationMeta(
    'responseText',
  );
  @override
  late final GeneratedColumn<String> responseText = GeneratedColumn<String>(
    'response_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ModelCaller, String> caller =
      GeneratedColumn<String>(
        'caller',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ModelCaller>($ModelCallsTable.$convertercaller);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    createdOnDevice,
    version,
    changeSeq,
    deletedAt,
    organizeRunId,
    modelConfigId,
    dataBoundary,
    sentMessageIds,
    sentAttachmentIds,
    requestAt,
    responseAt,
    status,
    tokensIn,
    tokensOut,
    responseText,
    caller,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_calls';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelCall> instance, {
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
    if (data.containsKey('organize_run_id')) {
      context.handle(
        _organizeRunIdMeta,
        organizeRunId.isAcceptableOrUnknown(
          data['organize_run_id']!,
          _organizeRunIdMeta,
        ),
      );
    }
    if (data.containsKey('model_config_id')) {
      context.handle(
        _modelConfigIdMeta,
        modelConfigId.isAcceptableOrUnknown(
          data['model_config_id']!,
          _modelConfigIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelConfigIdMeta);
    }
    if (data.containsKey('sent_message_ids')) {
      context.handle(
        _sentMessageIdsMeta,
        sentMessageIds.isAcceptableOrUnknown(
          data['sent_message_ids']!,
          _sentMessageIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentMessageIdsMeta);
    }
    if (data.containsKey('sent_attachment_ids')) {
      context.handle(
        _sentAttachmentIdsMeta,
        sentAttachmentIds.isAcceptableOrUnknown(
          data['sent_attachment_ids']!,
          _sentAttachmentIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentAttachmentIdsMeta);
    }
    if (data.containsKey('request_at')) {
      context.handle(
        _requestAtMeta,
        requestAt.isAcceptableOrUnknown(data['request_at']!, _requestAtMeta),
      );
    } else if (isInserting) {
      context.missing(_requestAtMeta);
    }
    if (data.containsKey('response_at')) {
      context.handle(
        _responseAtMeta,
        responseAt.isAcceptableOrUnknown(data['response_at']!, _responseAtMeta),
      );
    }
    if (data.containsKey('tokens_in')) {
      context.handle(
        _tokensInMeta,
        tokensIn.isAcceptableOrUnknown(data['tokens_in']!, _tokensInMeta),
      );
    }
    if (data.containsKey('tokens_out')) {
      context.handle(
        _tokensOutMeta,
        tokensOut.isAcceptableOrUnknown(data['tokens_out']!, _tokensOutMeta),
      );
    }
    if (data.containsKey('response_text')) {
      context.handle(
        _responseTextMeta,
        responseText.isAcceptableOrUnknown(
          data['response_text']!,
          _responseTextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelCall map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelCall(
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
      organizeRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organize_run_id'],
      ),
      modelConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_config_id'],
      )!,
      dataBoundary: $ModelCallsTable.$converterdataBoundary.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}data_boundary'],
        )!,
      ),
      sentMessageIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_message_ids'],
      )!,
      sentAttachmentIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_attachment_ids'],
      )!,
      requestAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}request_at'],
      )!,
      responseAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_at'],
      ),
      status: $ModelCallsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      tokensIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_in'],
      ),
      tokensOut: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_out'],
      ),
      responseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_text'],
      ),
      caller: $ModelCallsTable.$convertercaller.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}caller'],
        )!,
      ),
    );
  }

  @override
  $ModelCallsTable createAlias(String alias) {
    return $ModelCallsTable(attachedDatabase, alias);
  }

  static TypeConverter<DataBoundary, String> $converterdataBoundary =
      const EnumConverter(DataBoundary.values);
  static TypeConverter<ModelCallStatus, String> $converterstatus =
      const EnumConverter(ModelCallStatus.values);
  static TypeConverter<ModelCaller, String> $convertercaller =
      const EnumConverter(ModelCaller.values);
}

class ModelCall extends DataClass implements Insertable<ModelCall> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String? organizeRunId;
  final String modelConfigId;
  final DataBoundary dataBoundary;
  final String sentMessageIds;
  final String sentAttachmentIds;
  final int requestAt;
  final int? responseAt;
  final ModelCallStatus status;
  final int? tokensIn;
  final int? tokensOut;
  final String? responseText;
  final ModelCaller caller;
  const ModelCall({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    this.organizeRunId,
    required this.modelConfigId,
    required this.dataBoundary,
    required this.sentMessageIds,
    required this.sentAttachmentIds,
    required this.requestAt,
    this.responseAt,
    required this.status,
    this.tokensIn,
    this.tokensOut,
    this.responseText,
    required this.caller,
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
    if (!nullToAbsent || organizeRunId != null) {
      map['organize_run_id'] = Variable<String>(organizeRunId);
    }
    map['model_config_id'] = Variable<String>(modelConfigId);
    {
      map['data_boundary'] = Variable<String>(
        $ModelCallsTable.$converterdataBoundary.toSql(dataBoundary),
      );
    }
    map['sent_message_ids'] = Variable<String>(sentMessageIds);
    map['sent_attachment_ids'] = Variable<String>(sentAttachmentIds);
    map['request_at'] = Variable<int>(requestAt);
    if (!nullToAbsent || responseAt != null) {
      map['response_at'] = Variable<int>(responseAt);
    }
    {
      map['status'] = Variable<String>(
        $ModelCallsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || tokensIn != null) {
      map['tokens_in'] = Variable<int>(tokensIn);
    }
    if (!nullToAbsent || tokensOut != null) {
      map['tokens_out'] = Variable<int>(tokensOut);
    }
    if (!nullToAbsent || responseText != null) {
      map['response_text'] = Variable<String>(responseText);
    }
    {
      map['caller'] = Variable<String>(
        $ModelCallsTable.$convertercaller.toSql(caller),
      );
    }
    return map;
  }

  ModelCallsCompanion toCompanion(bool nullToAbsent) {
    return ModelCallsCompanion(
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
      organizeRunId: organizeRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(organizeRunId),
      modelConfigId: Value(modelConfigId),
      dataBoundary: Value(dataBoundary),
      sentMessageIds: Value(sentMessageIds),
      sentAttachmentIds: Value(sentAttachmentIds),
      requestAt: Value(requestAt),
      responseAt: responseAt == null && nullToAbsent
          ? const Value.absent()
          : Value(responseAt),
      status: Value(status),
      tokensIn: tokensIn == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensIn),
      tokensOut: tokensOut == null && nullToAbsent
          ? const Value.absent()
          : Value(tokensOut),
      responseText: responseText == null && nullToAbsent
          ? const Value.absent()
          : Value(responseText),
      caller: Value(caller),
    );
  }

  factory ModelCall.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelCall(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      organizeRunId: serializer.fromJson<String?>(json['organizeRunId']),
      modelConfigId: serializer.fromJson<String>(json['modelConfigId']),
      dataBoundary: serializer.fromJson<DataBoundary>(json['dataBoundary']),
      sentMessageIds: serializer.fromJson<String>(json['sentMessageIds']),
      sentAttachmentIds: serializer.fromJson<String>(json['sentAttachmentIds']),
      requestAt: serializer.fromJson<int>(json['requestAt']),
      responseAt: serializer.fromJson<int?>(json['responseAt']),
      status: serializer.fromJson<ModelCallStatus>(json['status']),
      tokensIn: serializer.fromJson<int?>(json['tokensIn']),
      tokensOut: serializer.fromJson<int?>(json['tokensOut']),
      responseText: serializer.fromJson<String?>(json['responseText']),
      caller: serializer.fromJson<ModelCaller>(json['caller']),
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
      'organizeRunId': serializer.toJson<String?>(organizeRunId),
      'modelConfigId': serializer.toJson<String>(modelConfigId),
      'dataBoundary': serializer.toJson<DataBoundary>(dataBoundary),
      'sentMessageIds': serializer.toJson<String>(sentMessageIds),
      'sentAttachmentIds': serializer.toJson<String>(sentAttachmentIds),
      'requestAt': serializer.toJson<int>(requestAt),
      'responseAt': serializer.toJson<int?>(responseAt),
      'status': serializer.toJson<ModelCallStatus>(status),
      'tokensIn': serializer.toJson<int?>(tokensIn),
      'tokensOut': serializer.toJson<int?>(tokensOut),
      'responseText': serializer.toJson<String?>(responseText),
      'caller': serializer.toJson<ModelCaller>(caller),
    };
  }

  ModelCall copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> organizeRunId = const Value.absent(),
    String? modelConfigId,
    DataBoundary? dataBoundary,
    String? sentMessageIds,
    String? sentAttachmentIds,
    int? requestAt,
    Value<int?> responseAt = const Value.absent(),
    ModelCallStatus? status,
    Value<int?> tokensIn = const Value.absent(),
    Value<int?> tokensOut = const Value.absent(),
    Value<String?> responseText = const Value.absent(),
    ModelCaller? caller,
  }) => ModelCall(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    organizeRunId: organizeRunId.present
        ? organizeRunId.value
        : this.organizeRunId,
    modelConfigId: modelConfigId ?? this.modelConfigId,
    dataBoundary: dataBoundary ?? this.dataBoundary,
    sentMessageIds: sentMessageIds ?? this.sentMessageIds,
    sentAttachmentIds: sentAttachmentIds ?? this.sentAttachmentIds,
    requestAt: requestAt ?? this.requestAt,
    responseAt: responseAt.present ? responseAt.value : this.responseAt,
    status: status ?? this.status,
    tokensIn: tokensIn.present ? tokensIn.value : this.tokensIn,
    tokensOut: tokensOut.present ? tokensOut.value : this.tokensOut,
    responseText: responseText.present ? responseText.value : this.responseText,
    caller: caller ?? this.caller,
  );
  ModelCall copyWithCompanion(ModelCallsCompanion data) {
    return ModelCall(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      organizeRunId: data.organizeRunId.present
          ? data.organizeRunId.value
          : this.organizeRunId,
      modelConfigId: data.modelConfigId.present
          ? data.modelConfigId.value
          : this.modelConfigId,
      dataBoundary: data.dataBoundary.present
          ? data.dataBoundary.value
          : this.dataBoundary,
      sentMessageIds: data.sentMessageIds.present
          ? data.sentMessageIds.value
          : this.sentMessageIds,
      sentAttachmentIds: data.sentAttachmentIds.present
          ? data.sentAttachmentIds.value
          : this.sentAttachmentIds,
      requestAt: data.requestAt.present ? data.requestAt.value : this.requestAt,
      responseAt: data.responseAt.present
          ? data.responseAt.value
          : this.responseAt,
      status: data.status.present ? data.status.value : this.status,
      tokensIn: data.tokensIn.present ? data.tokensIn.value : this.tokensIn,
      tokensOut: data.tokensOut.present ? data.tokensOut.value : this.tokensOut,
      responseText: data.responseText.present
          ? data.responseText.value
          : this.responseText,
      caller: data.caller.present ? data.caller.value : this.caller,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelCall(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('organizeRunId: $organizeRunId, ')
          ..write('modelConfigId: $modelConfigId, ')
          ..write('dataBoundary: $dataBoundary, ')
          ..write('sentMessageIds: $sentMessageIds, ')
          ..write('sentAttachmentIds: $sentAttachmentIds, ')
          ..write('requestAt: $requestAt, ')
          ..write('responseAt: $responseAt, ')
          ..write('status: $status, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('responseText: $responseText, ')
          ..write('caller: $caller')
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
    organizeRunId,
    modelConfigId,
    dataBoundary,
    sentMessageIds,
    sentAttachmentIds,
    requestAt,
    responseAt,
    status,
    tokensIn,
    tokensOut,
    responseText,
    caller,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelCall &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.organizeRunId == this.organizeRunId &&
          other.modelConfigId == this.modelConfigId &&
          other.dataBoundary == this.dataBoundary &&
          other.sentMessageIds == this.sentMessageIds &&
          other.sentAttachmentIds == this.sentAttachmentIds &&
          other.requestAt == this.requestAt &&
          other.responseAt == this.responseAt &&
          other.status == this.status &&
          other.tokensIn == this.tokensIn &&
          other.tokensOut == this.tokensOut &&
          other.responseText == this.responseText &&
          other.caller == this.caller);
}

class ModelCallsCompanion extends UpdateCompanion<ModelCall> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String?> organizeRunId;
  final Value<String> modelConfigId;
  final Value<DataBoundary> dataBoundary;
  final Value<String> sentMessageIds;
  final Value<String> sentAttachmentIds;
  final Value<int> requestAt;
  final Value<int?> responseAt;
  final Value<ModelCallStatus> status;
  final Value<int?> tokensIn;
  final Value<int?> tokensOut;
  final Value<String?> responseText;
  final Value<ModelCaller> caller;
  final Value<int> rowid;
  const ModelCallsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.organizeRunId = const Value.absent(),
    this.modelConfigId = const Value.absent(),
    this.dataBoundary = const Value.absent(),
    this.sentMessageIds = const Value.absent(),
    this.sentAttachmentIds = const Value.absent(),
    this.requestAt = const Value.absent(),
    this.responseAt = const Value.absent(),
    this.status = const Value.absent(),
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.responseText = const Value.absent(),
    this.caller = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelCallsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.organizeRunId = const Value.absent(),
    required String modelConfigId,
    required DataBoundary dataBoundary,
    required String sentMessageIds,
    required String sentAttachmentIds,
    required int requestAt,
    this.responseAt = const Value.absent(),
    required ModelCallStatus status,
    this.tokensIn = const Value.absent(),
    this.tokensOut = const Value.absent(),
    this.responseText = const Value.absent(),
    required ModelCaller caller,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       modelConfigId = Value(modelConfigId),
       dataBoundary = Value(dataBoundary),
       sentMessageIds = Value(sentMessageIds),
       sentAttachmentIds = Value(sentAttachmentIds),
       requestAt = Value(requestAt),
       status = Value(status),
       caller = Value(caller);
  static Insertable<ModelCall> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? organizeRunId,
    Expression<String>? modelConfigId,
    Expression<String>? dataBoundary,
    Expression<String>? sentMessageIds,
    Expression<String>? sentAttachmentIds,
    Expression<int>? requestAt,
    Expression<int>? responseAt,
    Expression<String>? status,
    Expression<int>? tokensIn,
    Expression<int>? tokensOut,
    Expression<String>? responseText,
    Expression<String>? caller,
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
      if (organizeRunId != null) 'organize_run_id': organizeRunId,
      if (modelConfigId != null) 'model_config_id': modelConfigId,
      if (dataBoundary != null) 'data_boundary': dataBoundary,
      if (sentMessageIds != null) 'sent_message_ids': sentMessageIds,
      if (sentAttachmentIds != null) 'sent_attachment_ids': sentAttachmentIds,
      if (requestAt != null) 'request_at': requestAt,
      if (responseAt != null) 'response_at': responseAt,
      if (status != null) 'status': status,
      if (tokensIn != null) 'tokens_in': tokensIn,
      if (tokensOut != null) 'tokens_out': tokensOut,
      if (responseText != null) 'response_text': responseText,
      if (caller != null) 'caller': caller,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelCallsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String?>? organizeRunId,
    Value<String>? modelConfigId,
    Value<DataBoundary>? dataBoundary,
    Value<String>? sentMessageIds,
    Value<String>? sentAttachmentIds,
    Value<int>? requestAt,
    Value<int?>? responseAt,
    Value<ModelCallStatus>? status,
    Value<int?>? tokensIn,
    Value<int?>? tokensOut,
    Value<String?>? responseText,
    Value<ModelCaller>? caller,
    Value<int>? rowid,
  }) {
    return ModelCallsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      organizeRunId: organizeRunId ?? this.organizeRunId,
      modelConfigId: modelConfigId ?? this.modelConfigId,
      dataBoundary: dataBoundary ?? this.dataBoundary,
      sentMessageIds: sentMessageIds ?? this.sentMessageIds,
      sentAttachmentIds: sentAttachmentIds ?? this.sentAttachmentIds,
      requestAt: requestAt ?? this.requestAt,
      responseAt: responseAt ?? this.responseAt,
      status: status ?? this.status,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      responseText: responseText ?? this.responseText,
      caller: caller ?? this.caller,
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
    if (organizeRunId.present) {
      map['organize_run_id'] = Variable<String>(organizeRunId.value);
    }
    if (modelConfigId.present) {
      map['model_config_id'] = Variable<String>(modelConfigId.value);
    }
    if (dataBoundary.present) {
      map['data_boundary'] = Variable<String>(
        $ModelCallsTable.$converterdataBoundary.toSql(dataBoundary.value),
      );
    }
    if (sentMessageIds.present) {
      map['sent_message_ids'] = Variable<String>(sentMessageIds.value);
    }
    if (sentAttachmentIds.present) {
      map['sent_attachment_ids'] = Variable<String>(sentAttachmentIds.value);
    }
    if (requestAt.present) {
      map['request_at'] = Variable<int>(requestAt.value);
    }
    if (responseAt.present) {
      map['response_at'] = Variable<int>(responseAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ModelCallsTable.$converterstatus.toSql(status.value),
      );
    }
    if (tokensIn.present) {
      map['tokens_in'] = Variable<int>(tokensIn.value);
    }
    if (tokensOut.present) {
      map['tokens_out'] = Variable<int>(tokensOut.value);
    }
    if (responseText.present) {
      map['response_text'] = Variable<String>(responseText.value);
    }
    if (caller.present) {
      map['caller'] = Variable<String>(
        $ModelCallsTable.$convertercaller.toSql(caller.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelCallsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('organizeRunId: $organizeRunId, ')
          ..write('modelConfigId: $modelConfigId, ')
          ..write('dataBoundary: $dataBoundary, ')
          ..write('sentMessageIds: $sentMessageIds, ')
          ..write('sentAttachmentIds: $sentAttachmentIds, ')
          ..write('requestAt: $requestAt, ')
          ..write('responseAt: $responseAt, ')
          ..write('status: $status, ')
          ..write('tokensIn: $tokensIn, ')
          ..write('tokensOut: $tokensOut, ')
          ..write('responseText: $responseText, ')
          ..write('caller: $caller, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, RecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<RecordType, String> recordType =
      GeneratedColumn<String>(
        'record_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordType>($RecordsTable.$converterrecordType);
  static const VerificationMeta _currentRevisionIdMeta = const VerificationMeta(
    'currentRevisionId',
  );
  @override
  late final GeneratedColumn<String> currentRevisionId =
      GeneratedColumn<String>(
        'current_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    recordType,
    currentRevisionId,
    localDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordRow> instance, {
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
    if (data.containsKey('current_revision_id')) {
      context.handle(
        _currentRevisionIdMeta,
        currentRevisionId.isAcceptableOrUnknown(
          data['current_revision_id']!,
          _currentRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRow(
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
      recordType: $RecordsTable.$converterrecordType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}record_type'],
        )!,
      ),
      currentRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_revision_id'],
      ),
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      ),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<RecordType, String> $converterrecordType =
      const EnumConverter(RecordType.values);
}

class RecordRow extends DataClass implements Insertable<RecordRow> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final RecordType recordType;
  final String? currentRevisionId;
  final String? localDate;
  const RecordRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.recordType,
    this.currentRevisionId,
    this.localDate,
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
    {
      map['record_type'] = Variable<String>(
        $RecordsTable.$converterrecordType.toSql(recordType),
      );
    }
    if (!nullToAbsent || currentRevisionId != null) {
      map['current_revision_id'] = Variable<String>(currentRevisionId);
    }
    if (!nullToAbsent || localDate != null) {
      map['local_date'] = Variable<String>(localDate);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
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
      recordType: Value(recordType),
      currentRevisionId: currentRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRevisionId),
      localDate: localDate == null && nullToAbsent
          ? const Value.absent()
          : Value(localDate),
    );
  }

  factory RecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recordType: serializer.fromJson<RecordType>(json['recordType']),
      currentRevisionId: serializer.fromJson<String?>(
        json['currentRevisionId'],
      ),
      localDate: serializer.fromJson<String?>(json['localDate']),
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
      'recordType': serializer.toJson<RecordType>(recordType),
      'currentRevisionId': serializer.toJson<String?>(currentRevisionId),
      'localDate': serializer.toJson<String?>(localDate),
    };
  }

  RecordRow copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    RecordType? recordType,
    Value<String?> currentRevisionId = const Value.absent(),
    Value<String?> localDate = const Value.absent(),
  }) => RecordRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recordType: recordType ?? this.recordType,
    currentRevisionId: currentRevisionId.present
        ? currentRevisionId.value
        : this.currentRevisionId,
    localDate: localDate.present ? localDate.value : this.localDate,
  );
  RecordRow copyWithCompanion(RecordsCompanion data) {
    return RecordRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      currentRevisionId: data.currentRevisionId.present
          ? data.currentRevisionId.value
          : this.currentRevisionId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordType: $recordType, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('localDate: $localDate')
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
    recordType,
    currentRevisionId,
    localDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.recordType == this.recordType &&
          other.currentRevisionId == this.currentRevisionId &&
          other.localDate == this.localDate);
}

class RecordsCompanion extends UpdateCompanion<RecordRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<RecordType> recordType;
  final Value<String?> currentRevisionId;
  final Value<String?> localDate;
  final Value<int> rowid;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recordType = const Value.absent(),
    this.currentRevisionId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required RecordType recordType,
    this.currentRevisionId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       recordType = Value(recordType);
  static Insertable<RecordRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? recordType,
    Expression<String>? currentRevisionId,
    Expression<String>? localDate,
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
      if (recordType != null) 'record_type': recordType,
      if (currentRevisionId != null) 'current_revision_id': currentRevisionId,
      if (localDate != null) 'local_date': localDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<RecordType>? recordType,
    Value<String?>? currentRevisionId,
    Value<String?>? localDate,
    Value<int>? rowid,
  }) {
    return RecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      recordType: recordType ?? this.recordType,
      currentRevisionId: currentRevisionId ?? this.currentRevisionId,
      localDate: localDate ?? this.localDate,
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
    if (recordType.present) {
      map['record_type'] = Variable<String>(
        $RecordsTable.$converterrecordType.toSql(recordType.value),
      );
    }
    if (currentRevisionId.present) {
      map['current_revision_id'] = Variable<String>(currentRevisionId.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordType: $recordType, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('localDate: $localDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordRevisionsTable extends RecordRevisions
    with TableInfo<$RecordRevisionsTable, RecordRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordRevisionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordVersionMeta = const VerificationMeta(
    'recordVersion',
  );
  @override
  late final GeneratedColumn<int> recordVersion = GeneratedColumn<int>(
    'record_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredMeta = const VerificationMeta(
    'occurred',
  );
  @override
  late final GeneratedColumn<String> occurred = GeneratedColumn<String>(
    'occurred',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredEndMeta = const VerificationMeta(
    'occurredEnd',
  );
  @override
  late final GeneratedColumn<String> occurredEnd = GeneratedColumn<String>(
    'occurred_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _producedByMeta = const VerificationMeta(
    'producedBy',
  );
  @override
  late final GeneratedColumn<String> producedBy = GeneratedColumn<String>(
    'produced_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMetaMeta = const VerificationMeta(
    'fieldMeta',
  );
  @override
  late final GeneratedColumn<String> fieldMeta = GeneratedColumn<String>(
    'field_meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    recordId,
    recordVersion,
    baseVersion,
    occurred,
    occurredEnd,
    data,
    producedBy,
    fieldMeta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordRevision> instance, {
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
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('record_version')) {
      context.handle(
        _recordVersionMeta,
        recordVersion.isAcceptableOrUnknown(
          data['record_version']!,
          _recordVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordVersionMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('occurred')) {
      context.handle(
        _occurredMeta,
        occurred.isAcceptableOrUnknown(data['occurred']!, _occurredMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredMeta);
    }
    if (data.containsKey('occurred_end')) {
      context.handle(
        _occurredEndMeta,
        occurredEnd.isAcceptableOrUnknown(
          data['occurred_end']!,
          _occurredEndMeta,
        ),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('produced_by')) {
      context.handle(
        _producedByMeta,
        producedBy.isAcceptableOrUnknown(data['produced_by']!, _producedByMeta),
      );
    } else if (isInserting) {
      context.missing(_producedByMeta);
    }
    if (data.containsKey('field_meta')) {
      context.handle(
        _fieldMetaMeta,
        fieldMeta.isAcceptableOrUnknown(data['field_meta']!, _fieldMetaMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMetaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {recordId, recordVersion},
  ];
  @override
  RecordRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordRevision(
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
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      recordVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_version'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      occurred: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred'],
      )!,
      occurredEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_end'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      producedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}produced_by'],
      )!,
      fieldMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_meta'],
      )!,
    );
  }

  @override
  $RecordRevisionsTable createAlias(String alias) {
    return $RecordRevisionsTable(attachedDatabase, alias);
  }
}

class RecordRevision extends DataClass implements Insertable<RecordRevision> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String recordId;
  final int recordVersion;
  final int? baseVersion;
  final String occurred;
  final String? occurredEnd;
  final String data;
  final String producedBy;
  final String fieldMeta;
  const RecordRevision({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.recordId,
    required this.recordVersion,
    this.baseVersion,
    required this.occurred,
    this.occurredEnd,
    required this.data,
    required this.producedBy,
    required this.fieldMeta,
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
    map['record_id'] = Variable<String>(recordId);
    map['record_version'] = Variable<int>(recordVersion);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['occurred'] = Variable<String>(occurred);
    if (!nullToAbsent || occurredEnd != null) {
      map['occurred_end'] = Variable<String>(occurredEnd);
    }
    map['data'] = Variable<String>(data);
    map['produced_by'] = Variable<String>(producedBy);
    map['field_meta'] = Variable<String>(fieldMeta);
    return map;
  }

  RecordRevisionsCompanion toCompanion(bool nullToAbsent) {
    return RecordRevisionsCompanion(
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
      recordId: Value(recordId),
      recordVersion: Value(recordVersion),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      occurred: Value(occurred),
      occurredEnd: occurredEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(occurredEnd),
      data: Value(data),
      producedBy: Value(producedBy),
      fieldMeta: Value(fieldMeta),
    );
  }

  factory RecordRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordRevision(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recordId: serializer.fromJson<String>(json['recordId']),
      recordVersion: serializer.fromJson<int>(json['recordVersion']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      occurred: serializer.fromJson<String>(json['occurred']),
      occurredEnd: serializer.fromJson<String?>(json['occurredEnd']),
      data: serializer.fromJson<String>(json['data']),
      producedBy: serializer.fromJson<String>(json['producedBy']),
      fieldMeta: serializer.fromJson<String>(json['fieldMeta']),
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
      'recordId': serializer.toJson<String>(recordId),
      'recordVersion': serializer.toJson<int>(recordVersion),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'occurred': serializer.toJson<String>(occurred),
      'occurredEnd': serializer.toJson<String?>(occurredEnd),
      'data': serializer.toJson<String>(data),
      'producedBy': serializer.toJson<String>(producedBy),
      'fieldMeta': serializer.toJson<String>(fieldMeta),
    };
  }

  RecordRevision copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? recordId,
    int? recordVersion,
    Value<int?> baseVersion = const Value.absent(),
    String? occurred,
    Value<String?> occurredEnd = const Value.absent(),
    String? data,
    String? producedBy,
    String? fieldMeta,
  }) => RecordRevision(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recordId: recordId ?? this.recordId,
    recordVersion: recordVersion ?? this.recordVersion,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    occurred: occurred ?? this.occurred,
    occurredEnd: occurredEnd.present ? occurredEnd.value : this.occurredEnd,
    data: data ?? this.data,
    producedBy: producedBy ?? this.producedBy,
    fieldMeta: fieldMeta ?? this.fieldMeta,
  );
  RecordRevision copyWithCompanion(RecordRevisionsCompanion data) {
    return RecordRevision(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      recordVersion: data.recordVersion.present
          ? data.recordVersion.value
          : this.recordVersion,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      occurred: data.occurred.present ? data.occurred.value : this.occurred,
      occurredEnd: data.occurredEnd.present
          ? data.occurredEnd.value
          : this.occurredEnd,
      data: data.data.present ? data.data.value : this.data,
      producedBy: data.producedBy.present
          ? data.producedBy.value
          : this.producedBy,
      fieldMeta: data.fieldMeta.present ? data.fieldMeta.value : this.fieldMeta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordRevision(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordId: $recordId, ')
          ..write('recordVersion: $recordVersion, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('occurred: $occurred, ')
          ..write('occurredEnd: $occurredEnd, ')
          ..write('data: $data, ')
          ..write('producedBy: $producedBy, ')
          ..write('fieldMeta: $fieldMeta')
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
    recordId,
    recordVersion,
    baseVersion,
    occurred,
    occurredEnd,
    data,
    producedBy,
    fieldMeta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordRevision &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.recordId == this.recordId &&
          other.recordVersion == this.recordVersion &&
          other.baseVersion == this.baseVersion &&
          other.occurred == this.occurred &&
          other.occurredEnd == this.occurredEnd &&
          other.data == this.data &&
          other.producedBy == this.producedBy &&
          other.fieldMeta == this.fieldMeta);
}

class RecordRevisionsCompanion extends UpdateCompanion<RecordRevision> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> recordId;
  final Value<int> recordVersion;
  final Value<int?> baseVersion;
  final Value<String> occurred;
  final Value<String?> occurredEnd;
  final Value<String> data;
  final Value<String> producedBy;
  final Value<String> fieldMeta;
  final Value<int> rowid;
  const RecordRevisionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recordId = const Value.absent(),
    this.recordVersion = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.occurred = const Value.absent(),
    this.occurredEnd = const Value.absent(),
    this.data = const Value.absent(),
    this.producedBy = const Value.absent(),
    this.fieldMeta = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordRevisionsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recordId,
    required int recordVersion,
    this.baseVersion = const Value.absent(),
    required String occurred,
    this.occurredEnd = const Value.absent(),
    required String data,
    required String producedBy,
    required String fieldMeta,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       recordId = Value(recordId),
       recordVersion = Value(recordVersion),
       occurred = Value(occurred),
       data = Value(data),
       producedBy = Value(producedBy),
       fieldMeta = Value(fieldMeta);
  static Insertable<RecordRevision> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? recordId,
    Expression<int>? recordVersion,
    Expression<int>? baseVersion,
    Expression<String>? occurred,
    Expression<String>? occurredEnd,
    Expression<String>? data,
    Expression<String>? producedBy,
    Expression<String>? fieldMeta,
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
      if (recordId != null) 'record_id': recordId,
      if (recordVersion != null) 'record_version': recordVersion,
      if (baseVersion != null) 'base_version': baseVersion,
      if (occurred != null) 'occurred': occurred,
      if (occurredEnd != null) 'occurred_end': occurredEnd,
      if (data != null) 'data': data,
      if (producedBy != null) 'produced_by': producedBy,
      if (fieldMeta != null) 'field_meta': fieldMeta,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? recordId,
    Value<int>? recordVersion,
    Value<int?>? baseVersion,
    Value<String>? occurred,
    Value<String?>? occurredEnd,
    Value<String>? data,
    Value<String>? producedBy,
    Value<String>? fieldMeta,
    Value<int>? rowid,
  }) {
    return RecordRevisionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      recordId: recordId ?? this.recordId,
      recordVersion: recordVersion ?? this.recordVersion,
      baseVersion: baseVersion ?? this.baseVersion,
      occurred: occurred ?? this.occurred,
      occurredEnd: occurredEnd ?? this.occurredEnd,
      data: data ?? this.data,
      producedBy: producedBy ?? this.producedBy,
      fieldMeta: fieldMeta ?? this.fieldMeta,
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
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (recordVersion.present) {
      map['record_version'] = Variable<int>(recordVersion.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (occurred.present) {
      map['occurred'] = Variable<String>(occurred.value);
    }
    if (occurredEnd.present) {
      map['occurred_end'] = Variable<String>(occurredEnd.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (producedBy.present) {
      map['produced_by'] = Variable<String>(producedBy.value);
    }
    if (fieldMeta.present) {
      map['field_meta'] = Variable<String>(fieldMeta.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordId: $recordId, ')
          ..write('recordVersion: $recordVersion, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('occurred: $occurred, ')
          ..write('occurredEnd: $occurredEnd, ')
          ..write('data: $data, ')
          ..write('producedBy: $producedBy, ')
          ..write('fieldMeta: $fieldMeta, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordSourcesTable extends RecordSources
    with TableInfo<$RecordSourcesTable, RecordSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordSourcesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordRevisionIdMeta = const VerificationMeta(
    'recordRevisionId',
  );
  @override
  late final GeneratedColumn<String> recordRevisionId = GeneratedColumn<String>(
    'record_revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldPathMeta = const VerificationMeta(
    'fieldPath',
  );
  @override
  late final GeneratedColumn<String> fieldPath = GeneratedColumn<String>(
    'field_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordSourceKind, String>
  sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RecordSourceKind>($RecordSourcesTable.$convertersourceKind);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageRevisionNoMeta = const VerificationMeta(
    'messageRevisionNo',
  );
  @override
  late final GeneratedColumn<int> messageRevisionNo = GeneratedColumn<int>(
    'message_revision_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spanMeta = const VerificationMeta('span');
  @override
  late final GeneratedColumn<String> span = GeneratedColumn<String>(
    'span',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    recordRevisionId,
    fieldPath,
    sourceKind,
    sourceId,
    messageRevisionNo,
    span,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordSource> instance, {
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
    if (data.containsKey('record_revision_id')) {
      context.handle(
        _recordRevisionIdMeta,
        recordRevisionId.isAcceptableOrUnknown(
          data['record_revision_id']!,
          _recordRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordRevisionIdMeta);
    }
    if (data.containsKey('field_path')) {
      context.handle(
        _fieldPathMeta,
        fieldPath.isAcceptableOrUnknown(data['field_path']!, _fieldPathMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('message_revision_no')) {
      context.handle(
        _messageRevisionNoMeta,
        messageRevisionNo.isAcceptableOrUnknown(
          data['message_revision_no']!,
          _messageRevisionNoMeta,
        ),
      );
    }
    if (data.containsKey('span')) {
      context.handle(
        _spanMeta,
        span.isAcceptableOrUnknown(data['span']!, _spanMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordSource(
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
      recordRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_revision_id'],
      )!,
      fieldPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_path'],
      ),
      sourceKind: $RecordSourcesTable.$convertersourceKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_kind'],
        )!,
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      messageRevisionNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_revision_no'],
      ),
      span: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}span'],
      ),
    );
  }

  @override
  $RecordSourcesTable createAlias(String alias) {
    return $RecordSourcesTable(attachedDatabase, alias);
  }

  static TypeConverter<RecordSourceKind, String> $convertersourceKind =
      const EnumConverter(RecordSourceKind.values);
}

class RecordSource extends DataClass implements Insertable<RecordSource> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String recordRevisionId;
  final String? fieldPath;
  final RecordSourceKind sourceKind;
  final String sourceId;
  final int? messageRevisionNo;
  final String? span;
  const RecordSource({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.recordRevisionId,
    this.fieldPath,
    required this.sourceKind,
    required this.sourceId,
    this.messageRevisionNo,
    this.span,
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
    map['record_revision_id'] = Variable<String>(recordRevisionId);
    if (!nullToAbsent || fieldPath != null) {
      map['field_path'] = Variable<String>(fieldPath);
    }
    {
      map['source_kind'] = Variable<String>(
        $RecordSourcesTable.$convertersourceKind.toSql(sourceKind),
      );
    }
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || messageRevisionNo != null) {
      map['message_revision_no'] = Variable<int>(messageRevisionNo);
    }
    if (!nullToAbsent || span != null) {
      map['span'] = Variable<String>(span);
    }
    return map;
  }

  RecordSourcesCompanion toCompanion(bool nullToAbsent) {
    return RecordSourcesCompanion(
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
      recordRevisionId: Value(recordRevisionId),
      fieldPath: fieldPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldPath),
      sourceKind: Value(sourceKind),
      sourceId: Value(sourceId),
      messageRevisionNo: messageRevisionNo == null && nullToAbsent
          ? const Value.absent()
          : Value(messageRevisionNo),
      span: span == null && nullToAbsent ? const Value.absent() : Value(span),
    );
  }

  factory RecordSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordSource(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      recordRevisionId: serializer.fromJson<String>(json['recordRevisionId']),
      fieldPath: serializer.fromJson<String?>(json['fieldPath']),
      sourceKind: serializer.fromJson<RecordSourceKind>(json['sourceKind']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      messageRevisionNo: serializer.fromJson<int?>(json['messageRevisionNo']),
      span: serializer.fromJson<String?>(json['span']),
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
      'recordRevisionId': serializer.toJson<String>(recordRevisionId),
      'fieldPath': serializer.toJson<String?>(fieldPath),
      'sourceKind': serializer.toJson<RecordSourceKind>(sourceKind),
      'sourceId': serializer.toJson<String>(sourceId),
      'messageRevisionNo': serializer.toJson<int?>(messageRevisionNo),
      'span': serializer.toJson<String?>(span),
    };
  }

  RecordSource copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? recordRevisionId,
    Value<String?> fieldPath = const Value.absent(),
    RecordSourceKind? sourceKind,
    String? sourceId,
    Value<int?> messageRevisionNo = const Value.absent(),
    Value<String?> span = const Value.absent(),
  }) => RecordSource(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    recordRevisionId: recordRevisionId ?? this.recordRevisionId,
    fieldPath: fieldPath.present ? fieldPath.value : this.fieldPath,
    sourceKind: sourceKind ?? this.sourceKind,
    sourceId: sourceId ?? this.sourceId,
    messageRevisionNo: messageRevisionNo.present
        ? messageRevisionNo.value
        : this.messageRevisionNo,
    span: span.present ? span.value : this.span,
  );
  RecordSource copyWithCompanion(RecordSourcesCompanion data) {
    return RecordSource(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      recordRevisionId: data.recordRevisionId.present
          ? data.recordRevisionId.value
          : this.recordRevisionId,
      fieldPath: data.fieldPath.present ? data.fieldPath.value : this.fieldPath,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      messageRevisionNo: data.messageRevisionNo.present
          ? data.messageRevisionNo.value
          : this.messageRevisionNo,
      span: data.span.present ? data.span.value : this.span,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordSource(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordRevisionId: $recordRevisionId, ')
          ..write('fieldPath: $fieldPath, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceId: $sourceId, ')
          ..write('messageRevisionNo: $messageRevisionNo, ')
          ..write('span: $span')
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
    recordRevisionId,
    fieldPath,
    sourceKind,
    sourceId,
    messageRevisionNo,
    span,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordSource &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.recordRevisionId == this.recordRevisionId &&
          other.fieldPath == this.fieldPath &&
          other.sourceKind == this.sourceKind &&
          other.sourceId == this.sourceId &&
          other.messageRevisionNo == this.messageRevisionNo &&
          other.span == this.span);
}

class RecordSourcesCompanion extends UpdateCompanion<RecordSource> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> recordRevisionId;
  final Value<String?> fieldPath;
  final Value<RecordSourceKind> sourceKind;
  final Value<String> sourceId;
  final Value<int?> messageRevisionNo;
  final Value<String?> span;
  final Value<int> rowid;
  const RecordSourcesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.recordRevisionId = const Value.absent(),
    this.fieldPath = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.messageRevisionNo = const Value.absent(),
    this.span = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordSourcesCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String recordRevisionId,
    this.fieldPath = const Value.absent(),
    required RecordSourceKind sourceKind,
    required String sourceId,
    this.messageRevisionNo = const Value.absent(),
    this.span = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       recordRevisionId = Value(recordRevisionId),
       sourceKind = Value(sourceKind),
       sourceId = Value(sourceId);
  static Insertable<RecordSource> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? recordRevisionId,
    Expression<String>? fieldPath,
    Expression<String>? sourceKind,
    Expression<String>? sourceId,
    Expression<int>? messageRevisionNo,
    Expression<String>? span,
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
      if (recordRevisionId != null) 'record_revision_id': recordRevisionId,
      if (fieldPath != null) 'field_path': fieldPath,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (sourceId != null) 'source_id': sourceId,
      if (messageRevisionNo != null) 'message_revision_no': messageRevisionNo,
      if (span != null) 'span': span,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? recordRevisionId,
    Value<String?>? fieldPath,
    Value<RecordSourceKind>? sourceKind,
    Value<String>? sourceId,
    Value<int?>? messageRevisionNo,
    Value<String?>? span,
    Value<int>? rowid,
  }) {
    return RecordSourcesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      recordRevisionId: recordRevisionId ?? this.recordRevisionId,
      fieldPath: fieldPath ?? this.fieldPath,
      sourceKind: sourceKind ?? this.sourceKind,
      sourceId: sourceId ?? this.sourceId,
      messageRevisionNo: messageRevisionNo ?? this.messageRevisionNo,
      span: span ?? this.span,
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
    if (recordRevisionId.present) {
      map['record_revision_id'] = Variable<String>(recordRevisionId.value);
    }
    if (fieldPath.present) {
      map['field_path'] = Variable<String>(fieldPath.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(
        $RecordSourcesTable.$convertersourceKind.toSql(sourceKind.value),
      );
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (messageRevisionNo.present) {
      map['message_revision_no'] = Variable<int>(messageRevisionNo.value);
    }
    if (span.present) {
      map['span'] = Variable<String>(span.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordSourcesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('recordRevisionId: $recordRevisionId, ')
          ..write('fieldPath: $fieldPath, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('sourceId: $sourceId, ')
          ..write('messageRevisionNo: $messageRevisionNo, ')
          ..write('span: $span, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelConfigsTable extends ModelConfigs
    with TableInfo<$ModelConfigsTable, ModelConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelConfigsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<ModelPreset, String> preset =
      GeneratedColumn<String>(
        'preset',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ModelPreset>($ModelConfigsTable.$converterpreset);
  @override
  late final GeneratedColumnWithTypeConverter<ModelProtocol, String> protocol =
      GeneratedColumn<String>(
        'protocol',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ModelProtocol>($ModelConfigsTable.$converterprotocol);
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capabilitiesMeta = const VerificationMeta(
    'capabilities',
  );
  @override
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
    'capabilities',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataBoundary, String>
  dataBoundary = GeneratedColumn<String>(
    'data_boundary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DataBoundary>($ModelConfigsTable.$converterdataBoundary);
  static const VerificationMeta _keychainRefMeta = const VerificationMeta(
    'keychainRef',
  );
  @override
  late final GeneratedColumn<String> keychainRef = GeneratedColumn<String>(
    'keychain_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastTestAtMeta = const VerificationMeta(
    'lastTestAt',
  );
  @override
  late final GeneratedColumn<int> lastTestAt = GeneratedColumn<int>(
    'last_test_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTestResultMeta = const VerificationMeta(
    'lastTestResult',
  );
  @override
  late final GeneratedColumn<String> lastTestResult = GeneratedColumn<String>(
    'last_test_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    preset,
    protocol,
    baseUrl,
    model,
    capabilities,
    dataBoundary,
    keychainRef,
    isDefault,
    lastTestAt,
    lastTestResult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelConfig> instance, {
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
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('capabilities')) {
      context.handle(
        _capabilitiesMeta,
        capabilities.isAcceptableOrUnknown(
          data['capabilities']!,
          _capabilitiesMeta,
        ),
      );
    }
    if (data.containsKey('keychain_ref')) {
      context.handle(
        _keychainRefMeta,
        keychainRef.isAcceptableOrUnknown(
          data['keychain_ref']!,
          _keychainRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keychainRefMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('last_test_at')) {
      context.handle(
        _lastTestAtMeta,
        lastTestAt.isAcceptableOrUnknown(
          data['last_test_at']!,
          _lastTestAtMeta,
        ),
      );
    }
    if (data.containsKey('last_test_result')) {
      context.handle(
        _lastTestResultMeta,
        lastTestResult.isAcceptableOrUnknown(
          data['last_test_result']!,
          _lastTestResultMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelConfig(
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
      preset: $ModelConfigsTable.$converterpreset.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}preset'],
        )!,
      ),
      protocol: $ModelConfigsTable.$converterprotocol.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}protocol'],
        )!,
      ),
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      capabilities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities'],
      )!,
      dataBoundary: $ModelConfigsTable.$converterdataBoundary.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}data_boundary'],
        )!,
      ),
      keychainRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keychain_ref'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      lastTestAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_test_at'],
      ),
      lastTestResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_test_result'],
      ),
    );
  }

  @override
  $ModelConfigsTable createAlias(String alias) {
    return $ModelConfigsTable(attachedDatabase, alias);
  }

  static TypeConverter<ModelPreset, String> $converterpreset =
      const EnumConverter(ModelPreset.values);
  static TypeConverter<ModelProtocol, String> $converterprotocol =
      const EnumConverter(ModelProtocol.values);
  static TypeConverter<DataBoundary, String> $converterdataBoundary =
      const EnumConverter(DataBoundary.values);
}

class ModelConfig extends DataClass implements Insertable<ModelConfig> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final ModelPreset preset;
  final ModelProtocol protocol;
  final String baseUrl;
  final String model;
  final String capabilities;
  final DataBoundary dataBoundary;
  final String keychainRef;
  final bool isDefault;
  final int? lastTestAt;
  final String? lastTestResult;
  const ModelConfig({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.preset,
    required this.protocol,
    required this.baseUrl,
    required this.model,
    required this.capabilities,
    required this.dataBoundary,
    required this.keychainRef,
    required this.isDefault,
    this.lastTestAt,
    this.lastTestResult,
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
    {
      map['preset'] = Variable<String>(
        $ModelConfigsTable.$converterpreset.toSql(preset),
      );
    }
    {
      map['protocol'] = Variable<String>(
        $ModelConfigsTable.$converterprotocol.toSql(protocol),
      );
    }
    map['base_url'] = Variable<String>(baseUrl);
    map['model'] = Variable<String>(model);
    map['capabilities'] = Variable<String>(capabilities);
    {
      map['data_boundary'] = Variable<String>(
        $ModelConfigsTable.$converterdataBoundary.toSql(dataBoundary),
      );
    }
    map['keychain_ref'] = Variable<String>(keychainRef);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || lastTestAt != null) {
      map['last_test_at'] = Variable<int>(lastTestAt);
    }
    if (!nullToAbsent || lastTestResult != null) {
      map['last_test_result'] = Variable<String>(lastTestResult);
    }
    return map;
  }

  ModelConfigsCompanion toCompanion(bool nullToAbsent) {
    return ModelConfigsCompanion(
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
      preset: Value(preset),
      protocol: Value(protocol),
      baseUrl: Value(baseUrl),
      model: Value(model),
      capabilities: Value(capabilities),
      dataBoundary: Value(dataBoundary),
      keychainRef: Value(keychainRef),
      isDefault: Value(isDefault),
      lastTestAt: lastTestAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestAt),
      lastTestResult: lastTestResult == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestResult),
    );
  }

  factory ModelConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelConfig(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      preset: serializer.fromJson<ModelPreset>(json['preset']),
      protocol: serializer.fromJson<ModelProtocol>(json['protocol']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      model: serializer.fromJson<String>(json['model']),
      capabilities: serializer.fromJson<String>(json['capabilities']),
      dataBoundary: serializer.fromJson<DataBoundary>(json['dataBoundary']),
      keychainRef: serializer.fromJson<String>(json['keychainRef']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      lastTestAt: serializer.fromJson<int?>(json['lastTestAt']),
      lastTestResult: serializer.fromJson<String?>(json['lastTestResult']),
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
      'preset': serializer.toJson<ModelPreset>(preset),
      'protocol': serializer.toJson<ModelProtocol>(protocol),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'model': serializer.toJson<String>(model),
      'capabilities': serializer.toJson<String>(capabilities),
      'dataBoundary': serializer.toJson<DataBoundary>(dataBoundary),
      'keychainRef': serializer.toJson<String>(keychainRef),
      'isDefault': serializer.toJson<bool>(isDefault),
      'lastTestAt': serializer.toJson<int?>(lastTestAt),
      'lastTestResult': serializer.toJson<String?>(lastTestResult),
    };
  }

  ModelConfig copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    ModelPreset? preset,
    ModelProtocol? protocol,
    String? baseUrl,
    String? model,
    String? capabilities,
    DataBoundary? dataBoundary,
    String? keychainRef,
    bool? isDefault,
    Value<int?> lastTestAt = const Value.absent(),
    Value<String?> lastTestResult = const Value.absent(),
  }) => ModelConfig(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    preset: preset ?? this.preset,
    protocol: protocol ?? this.protocol,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    capabilities: capabilities ?? this.capabilities,
    dataBoundary: dataBoundary ?? this.dataBoundary,
    keychainRef: keychainRef ?? this.keychainRef,
    isDefault: isDefault ?? this.isDefault,
    lastTestAt: lastTestAt.present ? lastTestAt.value : this.lastTestAt,
    lastTestResult: lastTestResult.present
        ? lastTestResult.value
        : this.lastTestResult,
  );
  ModelConfig copyWithCompanion(ModelConfigsCompanion data) {
    return ModelConfig(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      preset: data.preset.present ? data.preset.value : this.preset,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      model: data.model.present ? data.model.value : this.model,
      capabilities: data.capabilities.present
          ? data.capabilities.value
          : this.capabilities,
      dataBoundary: data.dataBoundary.present
          ? data.dataBoundary.value
          : this.dataBoundary,
      keychainRef: data.keychainRef.present
          ? data.keychainRef.value
          : this.keychainRef,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      lastTestAt: data.lastTestAt.present
          ? data.lastTestAt.value
          : this.lastTestAt,
      lastTestResult: data.lastTestResult.present
          ? data.lastTestResult.value
          : this.lastTestResult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelConfig(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('preset: $preset, ')
          ..write('protocol: $protocol, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('capabilities: $capabilities, ')
          ..write('dataBoundary: $dataBoundary, ')
          ..write('keychainRef: $keychainRef, ')
          ..write('isDefault: $isDefault, ')
          ..write('lastTestAt: $lastTestAt, ')
          ..write('lastTestResult: $lastTestResult')
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
    preset,
    protocol,
    baseUrl,
    model,
    capabilities,
    dataBoundary,
    keychainRef,
    isDefault,
    lastTestAt,
    lastTestResult,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelConfig &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.preset == this.preset &&
          other.protocol == this.protocol &&
          other.baseUrl == this.baseUrl &&
          other.model == this.model &&
          other.capabilities == this.capabilities &&
          other.dataBoundary == this.dataBoundary &&
          other.keychainRef == this.keychainRef &&
          other.isDefault == this.isDefault &&
          other.lastTestAt == this.lastTestAt &&
          other.lastTestResult == this.lastTestResult);
}

class ModelConfigsCompanion extends UpdateCompanion<ModelConfig> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<ModelPreset> preset;
  final Value<ModelProtocol> protocol;
  final Value<String> baseUrl;
  final Value<String> model;
  final Value<String> capabilities;
  final Value<DataBoundary> dataBoundary;
  final Value<String> keychainRef;
  final Value<bool> isDefault;
  final Value<int?> lastTestAt;
  final Value<String?> lastTestResult;
  final Value<int> rowid;
  const ModelConfigsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.preset = const Value.absent(),
    this.protocol = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.model = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.dataBoundary = const Value.absent(),
    this.keychainRef = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.lastTestAt = const Value.absent(),
    this.lastTestResult = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelConfigsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required ModelPreset preset,
    required ModelProtocol protocol,
    required String baseUrl,
    required String model,
    this.capabilities = const Value.absent(),
    required DataBoundary dataBoundary,
    required String keychainRef,
    this.isDefault = const Value.absent(),
    this.lastTestAt = const Value.absent(),
    this.lastTestResult = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       preset = Value(preset),
       protocol = Value(protocol),
       baseUrl = Value(baseUrl),
       model = Value(model),
       dataBoundary = Value(dataBoundary),
       keychainRef = Value(keychainRef);
  static Insertable<ModelConfig> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? preset,
    Expression<String>? protocol,
    Expression<String>? baseUrl,
    Expression<String>? model,
    Expression<String>? capabilities,
    Expression<String>? dataBoundary,
    Expression<String>? keychainRef,
    Expression<bool>? isDefault,
    Expression<int>? lastTestAt,
    Expression<String>? lastTestResult,
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
      if (preset != null) 'preset': preset,
      if (protocol != null) 'protocol': protocol,
      if (baseUrl != null) 'base_url': baseUrl,
      if (model != null) 'model': model,
      if (capabilities != null) 'capabilities': capabilities,
      if (dataBoundary != null) 'data_boundary': dataBoundary,
      if (keychainRef != null) 'keychain_ref': keychainRef,
      if (isDefault != null) 'is_default': isDefault,
      if (lastTestAt != null) 'last_test_at': lastTestAt,
      if (lastTestResult != null) 'last_test_result': lastTestResult,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<ModelPreset>? preset,
    Value<ModelProtocol>? protocol,
    Value<String>? baseUrl,
    Value<String>? model,
    Value<String>? capabilities,
    Value<DataBoundary>? dataBoundary,
    Value<String>? keychainRef,
    Value<bool>? isDefault,
    Value<int?>? lastTestAt,
    Value<String?>? lastTestResult,
    Value<int>? rowid,
  }) {
    return ModelConfigsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      preset: preset ?? this.preset,
      protocol: protocol ?? this.protocol,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      capabilities: capabilities ?? this.capabilities,
      dataBoundary: dataBoundary ?? this.dataBoundary,
      keychainRef: keychainRef ?? this.keychainRef,
      isDefault: isDefault ?? this.isDefault,
      lastTestAt: lastTestAt ?? this.lastTestAt,
      lastTestResult: lastTestResult ?? this.lastTestResult,
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
    if (preset.present) {
      map['preset'] = Variable<String>(
        $ModelConfigsTable.$converterpreset.toSql(preset.value),
      );
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(
        $ModelConfigsTable.$converterprotocol.toSql(protocol.value),
      );
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (dataBoundary.present) {
      map['data_boundary'] = Variable<String>(
        $ModelConfigsTable.$converterdataBoundary.toSql(dataBoundary.value),
      );
    }
    if (keychainRef.present) {
      map['keychain_ref'] = Variable<String>(keychainRef.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (lastTestAt.present) {
      map['last_test_at'] = Variable<int>(lastTestAt.value);
    }
    if (lastTestResult.present) {
      map['last_test_result'] = Variable<String>(lastTestResult.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelConfigsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('preset: $preset, ')
          ..write('protocol: $protocol, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('capabilities: $capabilities, ')
          ..write('dataBoundary: $dataBoundary, ')
          ..write('keychainRef: $keychainRef, ')
          ..write('isDefault: $isDefault, ')
          ..write('lastTestAt: $lastTestAt, ')
          ..write('lastTestResult: $lastTestResult, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewPromptsTable extends ReviewPrompts
    with TableInfo<$ReviewPromptsTable, ReviewPrompt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewPromptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reviewDateMeta = const VerificationMeta(
    'reviewDate',
  );
  @override
  late final GeneratedColumn<String> reviewDate = GeneratedColumn<String>(
    'review_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMessageIdMeta = const VerificationMeta(
    'promptMessageId',
  );
  @override
  late final GeneratedColumn<String> promptMessageId = GeneratedColumn<String>(
    'prompt_message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gapKeyMeta = const VerificationMeta('gapKey');
  @override
  late final GeneratedColumn<String> gapKey = GeneratedColumn<String>(
    'gap_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewOutcome?, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ReviewOutcome?>($ReviewPromptsTable.$converteroutcomen);
  static const VerificationMeta _answeredMessageIdMeta = const VerificationMeta(
    'answeredMessageId',
  );
  @override
  late final GeneratedColumn<String> answeredMessageId =
      GeneratedColumn<String>(
        'answered_message_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
    reviewDate,
    promptMessageId,
    gapKey,
    templateId,
    outcome,
    answeredMessageId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewPrompt> instance, {
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
    if (data.containsKey('review_date')) {
      context.handle(
        _reviewDateMeta,
        reviewDate.isAcceptableOrUnknown(data['review_date']!, _reviewDateMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewDateMeta);
    }
    if (data.containsKey('prompt_message_id')) {
      context.handle(
        _promptMessageIdMeta,
        promptMessageId.isAcceptableOrUnknown(
          data['prompt_message_id']!,
          _promptMessageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promptMessageIdMeta);
    }
    if (data.containsKey('gap_key')) {
      context.handle(
        _gapKeyMeta,
        gapKey.isAcceptableOrUnknown(data['gap_key']!, _gapKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gapKeyMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('answered_message_id')) {
      context.handle(
        _answeredMessageIdMeta,
        answeredMessageId.isAcceptableOrUnknown(
          data['answered_message_id']!,
          _answeredMessageIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewPrompt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewPrompt(
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
      reviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_date'],
      )!,
      promptMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_message_id'],
      )!,
      gapKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gap_key'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      outcome: $ReviewPromptsTable.$converteroutcomen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        ),
      ),
      answeredMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answered_message_id'],
      ),
    );
  }

  @override
  $ReviewPromptsTable createAlias(String alias) {
    return $ReviewPromptsTable(attachedDatabase, alias);
  }

  static TypeConverter<ReviewOutcome, String> $converteroutcome =
      const EnumConverter(ReviewOutcome.values);
  static TypeConverter<ReviewOutcome?, String?> $converteroutcomen =
      NullAwareTypeConverter.wrap($converteroutcome);
}

class ReviewPrompt extends DataClass implements Insertable<ReviewPrompt> {
  final String id;
  final String userId;
  final int createdAt;
  final String createdOnDevice;
  final int version;
  final int? changeSeq;
  final int? deletedAt;
  final String reviewDate;
  final String promptMessageId;
  final String gapKey;
  final String templateId;
  final ReviewOutcome? outcome;
  final String? answeredMessageId;
  const ReviewPrompt({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.createdOnDevice,
    required this.version,
    this.changeSeq,
    this.deletedAt,
    required this.reviewDate,
    required this.promptMessageId,
    required this.gapKey,
    required this.templateId,
    this.outcome,
    this.answeredMessageId,
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
    map['review_date'] = Variable<String>(reviewDate);
    map['prompt_message_id'] = Variable<String>(promptMessageId);
    map['gap_key'] = Variable<String>(gapKey);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(
        $ReviewPromptsTable.$converteroutcomen.toSql(outcome),
      );
    }
    if (!nullToAbsent || answeredMessageId != null) {
      map['answered_message_id'] = Variable<String>(answeredMessageId);
    }
    return map;
  }

  ReviewPromptsCompanion toCompanion(bool nullToAbsent) {
    return ReviewPromptsCompanion(
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
      reviewDate: Value(reviewDate),
      promptMessageId: Value(promptMessageId),
      gapKey: Value(gapKey),
      templateId: Value(templateId),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      answeredMessageId: answeredMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredMessageId),
    );
  }

  factory ReviewPrompt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewPrompt(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOnDevice: serializer.fromJson<String>(json['createdOnDevice']),
      version: serializer.fromJson<int>(json['version']),
      changeSeq: serializer.fromJson<int?>(json['changeSeq']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      reviewDate: serializer.fromJson<String>(json['reviewDate']),
      promptMessageId: serializer.fromJson<String>(json['promptMessageId']),
      gapKey: serializer.fromJson<String>(json['gapKey']),
      templateId: serializer.fromJson<String>(json['templateId']),
      outcome: serializer.fromJson<ReviewOutcome?>(json['outcome']),
      answeredMessageId: serializer.fromJson<String?>(
        json['answeredMessageId'],
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
      'reviewDate': serializer.toJson<String>(reviewDate),
      'promptMessageId': serializer.toJson<String>(promptMessageId),
      'gapKey': serializer.toJson<String>(gapKey),
      'templateId': serializer.toJson<String>(templateId),
      'outcome': serializer.toJson<ReviewOutcome?>(outcome),
      'answeredMessageId': serializer.toJson<String?>(answeredMessageId),
    };
  }

  ReviewPrompt copyWith({
    String? id,
    String? userId,
    int? createdAt,
    String? createdOnDevice,
    int? version,
    Value<int?> changeSeq = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    String? reviewDate,
    String? promptMessageId,
    String? gapKey,
    String? templateId,
    Value<ReviewOutcome?> outcome = const Value.absent(),
    Value<String?> answeredMessageId = const Value.absent(),
  }) => ReviewPrompt(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    createdOnDevice: createdOnDevice ?? this.createdOnDevice,
    version: version ?? this.version,
    changeSeq: changeSeq.present ? changeSeq.value : this.changeSeq,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    reviewDate: reviewDate ?? this.reviewDate,
    promptMessageId: promptMessageId ?? this.promptMessageId,
    gapKey: gapKey ?? this.gapKey,
    templateId: templateId ?? this.templateId,
    outcome: outcome.present ? outcome.value : this.outcome,
    answeredMessageId: answeredMessageId.present
        ? answeredMessageId.value
        : this.answeredMessageId,
  );
  ReviewPrompt copyWithCompanion(ReviewPromptsCompanion data) {
    return ReviewPrompt(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOnDevice: data.createdOnDevice.present
          ? data.createdOnDevice.value
          : this.createdOnDevice,
      version: data.version.present ? data.version.value : this.version,
      changeSeq: data.changeSeq.present ? data.changeSeq.value : this.changeSeq,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      reviewDate: data.reviewDate.present
          ? data.reviewDate.value
          : this.reviewDate,
      promptMessageId: data.promptMessageId.present
          ? data.promptMessageId.value
          : this.promptMessageId,
      gapKey: data.gapKey.present ? data.gapKey.value : this.gapKey,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      answeredMessageId: data.answeredMessageId.present
          ? data.answeredMessageId.value
          : this.answeredMessageId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewPrompt(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('promptMessageId: $promptMessageId, ')
          ..write('gapKey: $gapKey, ')
          ..write('templateId: $templateId, ')
          ..write('outcome: $outcome, ')
          ..write('answeredMessageId: $answeredMessageId')
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
    reviewDate,
    promptMessageId,
    gapKey,
    templateId,
    outcome,
    answeredMessageId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewPrompt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.createdOnDevice == this.createdOnDevice &&
          other.version == this.version &&
          other.changeSeq == this.changeSeq &&
          other.deletedAt == this.deletedAt &&
          other.reviewDate == this.reviewDate &&
          other.promptMessageId == this.promptMessageId &&
          other.gapKey == this.gapKey &&
          other.templateId == this.templateId &&
          other.outcome == this.outcome &&
          other.answeredMessageId == this.answeredMessageId);
}

class ReviewPromptsCompanion extends UpdateCompanion<ReviewPrompt> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> createdAt;
  final Value<String> createdOnDevice;
  final Value<int> version;
  final Value<int?> changeSeq;
  final Value<int?> deletedAt;
  final Value<String> reviewDate;
  final Value<String> promptMessageId;
  final Value<String> gapKey;
  final Value<String> templateId;
  final Value<ReviewOutcome?> outcome;
  final Value<String?> answeredMessageId;
  final Value<int> rowid;
  const ReviewPromptsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOnDevice = const Value.absent(),
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.promptMessageId = const Value.absent(),
    this.gapKey = const Value.absent(),
    this.templateId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.answeredMessageId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewPromptsCompanion.insert({
    required String id,
    required String userId,
    required int createdAt,
    required String createdOnDevice,
    this.version = const Value.absent(),
    this.changeSeq = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String reviewDate,
    required String promptMessageId,
    required String gapKey,
    required String templateId,
    this.outcome = const Value.absent(),
    this.answeredMessageId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       createdOnDevice = Value(createdOnDevice),
       reviewDate = Value(reviewDate),
       promptMessageId = Value(promptMessageId),
       gapKey = Value(gapKey),
       templateId = Value(templateId);
  static Insertable<ReviewPrompt> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? createdAt,
    Expression<String>? createdOnDevice,
    Expression<int>? version,
    Expression<int>? changeSeq,
    Expression<int>? deletedAt,
    Expression<String>? reviewDate,
    Expression<String>? promptMessageId,
    Expression<String>? gapKey,
    Expression<String>? templateId,
    Expression<String>? outcome,
    Expression<String>? answeredMessageId,
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
      if (reviewDate != null) 'review_date': reviewDate,
      if (promptMessageId != null) 'prompt_message_id': promptMessageId,
      if (gapKey != null) 'gap_key': gapKey,
      if (templateId != null) 'template_id': templateId,
      if (outcome != null) 'outcome': outcome,
      if (answeredMessageId != null) 'answered_message_id': answeredMessageId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewPromptsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? createdAt,
    Value<String>? createdOnDevice,
    Value<int>? version,
    Value<int?>? changeSeq,
    Value<int?>? deletedAt,
    Value<String>? reviewDate,
    Value<String>? promptMessageId,
    Value<String>? gapKey,
    Value<String>? templateId,
    Value<ReviewOutcome?>? outcome,
    Value<String?>? answeredMessageId,
    Value<int>? rowid,
  }) {
    return ReviewPromptsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      createdOnDevice: createdOnDevice ?? this.createdOnDevice,
      version: version ?? this.version,
      changeSeq: changeSeq ?? this.changeSeq,
      deletedAt: deletedAt ?? this.deletedAt,
      reviewDate: reviewDate ?? this.reviewDate,
      promptMessageId: promptMessageId ?? this.promptMessageId,
      gapKey: gapKey ?? this.gapKey,
      templateId: templateId ?? this.templateId,
      outcome: outcome ?? this.outcome,
      answeredMessageId: answeredMessageId ?? this.answeredMessageId,
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
    if (reviewDate.present) {
      map['review_date'] = Variable<String>(reviewDate.value);
    }
    if (promptMessageId.present) {
      map['prompt_message_id'] = Variable<String>(promptMessageId.value);
    }
    if (gapKey.present) {
      map['gap_key'] = Variable<String>(gapKey.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $ReviewPromptsTable.$converteroutcomen.toSql(outcome.value),
      );
    }
    if (answeredMessageId.present) {
      map['answered_message_id'] = Variable<String>(answeredMessageId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewPromptsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOnDevice: $createdOnDevice, ')
          ..write('version: $version, ')
          ..write('changeSeq: $changeSeq, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('promptMessageId: $promptMessageId, ')
          ..write('gapKey: $gapKey, ')
          ..write('templateId: $templateId, ')
          ..write('outcome: $outcome, ')
          ..write('answeredMessageId: $answeredMessageId, ')
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
  late final $HealthSamplesTable healthSamples = $HealthSamplesTable(this);
  late final $HealthAnchorsTable healthAnchors = $HealthAnchorsTable(this);
  late final $HealthDailyTable healthDaily = $HealthDailyTable(this);
  late final $OrganizeRunsTable organizeRuns = $OrganizeRunsTable(this);
  late final $OrganizeRunItemsTable organizeRunItems = $OrganizeRunItemsTable(
    this,
  );
  late final $ModelCallsTable modelCalls = $ModelCallsTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $RecordRevisionsTable recordRevisions = $RecordRevisionsTable(
    this,
  );
  late final $RecordSourcesTable recordSources = $RecordSourcesTable(this);
  late final $ModelConfigsTable modelConfigs = $ModelConfigsTable(this);
  late final $ReviewPromptsTable reviewPrompts = $ReviewPromptsTable(this);
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
    healthSamples,
    healthAnchors,
    healthDaily,
    organizeRuns,
    organizeRunItems,
    modelCalls,
    records,
    recordRevisions,
    recordSources,
    modelConfigs,
    reviewPrompts,
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
typedef $$HealthSamplesTableCreateCompanionBuilder =
    HealthSamplesCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String platformUuid,
      required HealthSampleType sampleType,
      required int startUtc,
      required int endUtc,
      required String tz,
      Value<bool> tzInferred,
      Value<String?> sourceBundleId,
      Value<SleepStage?> sleepStage,
      Value<String?> workoutType,
      Value<double?> energyKcal,
      Value<double?> distanceM,
      required String sourceName,
      required int fetchedAt,
      Value<int?> removedInSourceAt,
      Value<int> rowid,
    });
typedef $$HealthSamplesTableUpdateCompanionBuilder =
    HealthSamplesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> platformUuid,
      Value<HealthSampleType> sampleType,
      Value<int> startUtc,
      Value<int> endUtc,
      Value<String> tz,
      Value<bool> tzInferred,
      Value<String?> sourceBundleId,
      Value<SleepStage?> sleepStage,
      Value<String?> workoutType,
      Value<double?> energyKcal,
      Value<double?> distanceM,
      Value<String> sourceName,
      Value<int> fetchedAt,
      Value<int?> removedInSourceAt,
      Value<int> rowid,
    });

class $$HealthSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableFilterComposer({
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

  ColumnFilters<String> get platformUuid => $composableBuilder(
    column: $table.platformUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HealthSampleType, HealthSampleType, String>
  get sampleType => $composableBuilder(
    column: $table.sampleType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tzInferred => $composableBuilder(
    column: $table.tzInferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceBundleId => $composableBuilder(
    column: $table.sourceBundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SleepStage?, SleepStage, String>
  get sleepStage => $composableBuilder(
    column: $table.sleepStage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removedInSourceAt => $composableBuilder(
    column: $table.removedInSourceAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableOrderingComposer({
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

  ColumnOrderings<String> get platformUuid => $composableBuilder(
    column: $table.platformUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleType => $composableBuilder(
    column: $table.sampleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tzInferred => $composableBuilder(
    column: $table.tzInferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceBundleId => $composableBuilder(
    column: $table.sourceBundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sleepStage => $composableBuilder(
    column: $table.sleepStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removedInSourceAt => $composableBuilder(
    column: $table.removedInSourceAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthSamplesTable> {
  $$HealthSamplesTableAnnotationComposer({
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

  GeneratedColumn<String> get platformUuid => $composableBuilder(
    column: $table.platformUuid,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HealthSampleType, String> get sampleType =>
      $composableBuilder(
        column: $table.sampleType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<bool> get tzInferred => $composableBuilder(
    column: $table.tzInferred,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceBundleId => $composableBuilder(
    column: $table.sourceBundleId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SleepStage?, String> get sleepStage =>
      $composableBuilder(
        column: $table.sleepStage,
        builder: (column) => column,
      );

  GeneratedColumn<String> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get removedInSourceAt => $composableBuilder(
    column: $table.removedInSourceAt,
    builder: (column) => column,
  );
}

class $$HealthSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthSamplesTable,
          HealthSample,
          $$HealthSamplesTableFilterComposer,
          $$HealthSamplesTableOrderingComposer,
          $$HealthSamplesTableAnnotationComposer,
          $$HealthSamplesTableCreateCompanionBuilder,
          $$HealthSamplesTableUpdateCompanionBuilder,
          (
            HealthSample,
            BaseReferences<_$AppDatabase, $HealthSamplesTable, HealthSample>,
          ),
          HealthSample,
          PrefetchHooks Function()
        > {
  $$HealthSamplesTableTableManager(_$AppDatabase db, $HealthSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> platformUuid = const Value.absent(),
                Value<HealthSampleType> sampleType = const Value.absent(),
                Value<int> startUtc = const Value.absent(),
                Value<int> endUtc = const Value.absent(),
                Value<String> tz = const Value.absent(),
                Value<bool> tzInferred = const Value.absent(),
                Value<String?> sourceBundleId = const Value.absent(),
                Value<SleepStage?> sleepStage = const Value.absent(),
                Value<String?> workoutType = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int?> removedInSourceAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthSamplesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                platformUuid: platformUuid,
                sampleType: sampleType,
                startUtc: startUtc,
                endUtc: endUtc,
                tz: tz,
                tzInferred: tzInferred,
                sourceBundleId: sourceBundleId,
                sleepStage: sleepStage,
                workoutType: workoutType,
                energyKcal: energyKcal,
                distanceM: distanceM,
                sourceName: sourceName,
                fetchedAt: fetchedAt,
                removedInSourceAt: removedInSourceAt,
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
                required String platformUuid,
                required HealthSampleType sampleType,
                required int startUtc,
                required int endUtc,
                required String tz,
                Value<bool> tzInferred = const Value.absent(),
                Value<String?> sourceBundleId = const Value.absent(),
                Value<SleepStage?> sleepStage = const Value.absent(),
                Value<String?> workoutType = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                required String sourceName,
                required int fetchedAt,
                Value<int?> removedInSourceAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthSamplesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                platformUuid: platformUuid,
                sampleType: sampleType,
                startUtc: startUtc,
                endUtc: endUtc,
                tz: tz,
                tzInferred: tzInferred,
                sourceBundleId: sourceBundleId,
                sleepStage: sleepStage,
                workoutType: workoutType,
                energyKcal: energyKcal,
                distanceM: distanceM,
                sourceName: sourceName,
                fetchedAt: fetchedAt,
                removedInSourceAt: removedInSourceAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthSamplesTable,
      HealthSample,
      $$HealthSamplesTableFilterComposer,
      $$HealthSamplesTableOrderingComposer,
      $$HealthSamplesTableAnnotationComposer,
      $$HealthSamplesTableCreateCompanionBuilder,
      $$HealthSamplesTableUpdateCompanionBuilder,
      (
        HealthSample,
        BaseReferences<_$AppDatabase, $HealthSamplesTable, HealthSample>,
      ),
      HealthSample,
      PrefetchHooks Function()
    >;
typedef $$HealthAnchorsTableCreateCompanionBuilder =
    HealthAnchorsCompanion Function({
      required HealthSampleType sampleType,
      required Uint8List anchor,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$HealthAnchorsTableUpdateCompanionBuilder =
    HealthAnchorsCompanion Function({
      Value<HealthSampleType> sampleType,
      Value<Uint8List> anchor,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$HealthAnchorsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthAnchorsTable> {
  $$HealthAnchorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<HealthSampleType, HealthSampleType, String>
  get sampleType => $composableBuilder(
    column: $table.sampleType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<Uint8List> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthAnchorsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthAnchorsTable> {
  $$HealthAnchorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sampleType => $composableBuilder(
    column: $table.sampleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthAnchorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthAnchorsTable> {
  $$HealthAnchorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<HealthSampleType, String> get sampleType =>
      $composableBuilder(
        column: $table.sampleType,
        builder: (column) => column,
      );

  GeneratedColumn<Uint8List> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HealthAnchorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthAnchorsTable,
          HealthAnchor,
          $$HealthAnchorsTableFilterComposer,
          $$HealthAnchorsTableOrderingComposer,
          $$HealthAnchorsTableAnnotationComposer,
          $$HealthAnchorsTableCreateCompanionBuilder,
          $$HealthAnchorsTableUpdateCompanionBuilder,
          (
            HealthAnchor,
            BaseReferences<_$AppDatabase, $HealthAnchorsTable, HealthAnchor>,
          ),
          HealthAnchor,
          PrefetchHooks Function()
        > {
  $$HealthAnchorsTableTableManager(_$AppDatabase db, $HealthAnchorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthAnchorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthAnchorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthAnchorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<HealthSampleType> sampleType = const Value.absent(),
                Value<Uint8List> anchor = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthAnchorsCompanion(
                sampleType: sampleType,
                anchor: anchor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required HealthSampleType sampleType,
                required Uint8List anchor,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HealthAnchorsCompanion.insert(
                sampleType: sampleType,
                anchor: anchor,
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

typedef $$HealthAnchorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthAnchorsTable,
      HealthAnchor,
      $$HealthAnchorsTableFilterComposer,
      $$HealthAnchorsTableOrderingComposer,
      $$HealthAnchorsTableAnnotationComposer,
      $$HealthAnchorsTableCreateCompanionBuilder,
      $$HealthAnchorsTableUpdateCompanionBuilder,
      (
        HealthAnchor,
        BaseReferences<_$AppDatabase, $HealthAnchorsTable, HealthAnchor>,
      ),
      HealthAnchor,
      PrefetchHooks Function()
    >;
typedef $$HealthDailyTableCreateCompanionBuilder =
    HealthDailyCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String localDate,
      required String aggTz,
      required int intervalStartUtc,
      required int intervalEndUtc,
      required HealthMetric metric,
      required double value,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$HealthDailyTableUpdateCompanionBuilder =
    HealthDailyCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> localDate,
      Value<String> aggTz,
      Value<int> intervalStartUtc,
      Value<int> intervalEndUtc,
      Value<HealthMetric> metric,
      Value<double> value,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$HealthDailyTableFilterComposer
    extends Composer<_$AppDatabase, $HealthDailyTable> {
  $$HealthDailyTableFilterComposer({
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

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggTz => $composableBuilder(
    column: $table.aggTz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalStartUtc => $composableBuilder(
    column: $table.intervalStartUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalEndUtc => $composableBuilder(
    column: $table.intervalEndUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HealthMetric, HealthMetric, String>
  get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthDailyTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthDailyTable> {
  $$HealthDailyTableOrderingComposer({
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

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggTz => $composableBuilder(
    column: $table.aggTz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalStartUtc => $composableBuilder(
    column: $table.intervalStartUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalEndUtc => $composableBuilder(
    column: $table.intervalEndUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthDailyTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthDailyTable> {
  $$HealthDailyTableAnnotationComposer({
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

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get aggTz =>
      $composableBuilder(column: $table.aggTz, builder: (column) => column);

  GeneratedColumn<int> get intervalStartUtc => $composableBuilder(
    column: $table.intervalStartUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalEndUtc => $composableBuilder(
    column: $table.intervalEndUtc,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HealthMetric, String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$HealthDailyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthDailyTable,
          HealthDailyData,
          $$HealthDailyTableFilterComposer,
          $$HealthDailyTableOrderingComposer,
          $$HealthDailyTableAnnotationComposer,
          $$HealthDailyTableCreateCompanionBuilder,
          $$HealthDailyTableUpdateCompanionBuilder,
          (
            HealthDailyData,
            BaseReferences<_$AppDatabase, $HealthDailyTable, HealthDailyData>,
          ),
          HealthDailyData,
          PrefetchHooks Function()
        > {
  $$HealthDailyTableTableManager(_$AppDatabase db, $HealthDailyTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthDailyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> aggTz = const Value.absent(),
                Value<int> intervalStartUtc = const Value.absent(),
                Value<int> intervalEndUtc = const Value.absent(),
                Value<HealthMetric> metric = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthDailyCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                localDate: localDate,
                aggTz: aggTz,
                intervalStartUtc: intervalStartUtc,
                intervalEndUtc: intervalEndUtc,
                metric: metric,
                value: value,
                fetchedAt: fetchedAt,
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
                required String localDate,
                required String aggTz,
                required int intervalStartUtc,
                required int intervalEndUtc,
                required HealthMetric metric,
                required double value,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => HealthDailyCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                localDate: localDate,
                aggTz: aggTz,
                intervalStartUtc: intervalStartUtc,
                intervalEndUtc: intervalEndUtc,
                metric: metric,
                value: value,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthDailyTable,
      HealthDailyData,
      $$HealthDailyTableFilterComposer,
      $$HealthDailyTableOrderingComposer,
      $$HealthDailyTableAnnotationComposer,
      $$HealthDailyTableCreateCompanionBuilder,
      $$HealthDailyTableUpdateCompanionBuilder,
      (
        HealthDailyData,
        BaseReferences<_$AppDatabase, $HealthDailyTable, HealthDailyData>,
      ),
      HealthDailyData,
      PrefetchHooks Function()
    >;
typedef $$OrganizeRunsTableCreateCompanionBuilder =
    OrganizeRunsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required OrganizeTrigger trigger,
      required String inputSnapshot,
      Value<String?> modelConfigId,
      Value<String?> modelSnapshot,
      required OrganizeRunStatus status,
      Value<String?> error,
      Value<int?> startedAt,
      Value<int?> finishedAt,
      Value<int> rowid,
    });
typedef $$OrganizeRunsTableUpdateCompanionBuilder =
    OrganizeRunsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<OrganizeTrigger> trigger,
      Value<String> inputSnapshot,
      Value<String?> modelConfigId,
      Value<String?> modelSnapshot,
      Value<OrganizeRunStatus> status,
      Value<String?> error,
      Value<int?> startedAt,
      Value<int?> finishedAt,
      Value<int> rowid,
    });

class $$OrganizeRunsTableFilterComposer
    extends Composer<_$AppDatabase, $OrganizeRunsTable> {
  $$OrganizeRunsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<OrganizeTrigger, OrganizeTrigger, String>
  get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get inputSnapshot => $composableBuilder(
    column: $table.inputSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelSnapshot => $composableBuilder(
    column: $table.modelSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OrganizeRunStatus, OrganizeRunStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrganizeRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrganizeRunsTable> {
  $$OrganizeRunsTableOrderingComposer({
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

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputSnapshot => $composableBuilder(
    column: $table.inputSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelSnapshot => $composableBuilder(
    column: $table.modelSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrganizeRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrganizeRunsTable> {
  $$OrganizeRunsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<OrganizeTrigger, String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get inputSnapshot => $composableBuilder(
    column: $table.inputSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelSnapshot => $composableBuilder(
    column: $table.modelSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OrganizeRunStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$OrganizeRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrganizeRunsTable,
          OrganizeRun,
          $$OrganizeRunsTableFilterComposer,
          $$OrganizeRunsTableOrderingComposer,
          $$OrganizeRunsTableAnnotationComposer,
          $$OrganizeRunsTableCreateCompanionBuilder,
          $$OrganizeRunsTableUpdateCompanionBuilder,
          (
            OrganizeRun,
            BaseReferences<_$AppDatabase, $OrganizeRunsTable, OrganizeRun>,
          ),
          OrganizeRun,
          PrefetchHooks Function()
        > {
  $$OrganizeRunsTableTableManager(_$AppDatabase db, $OrganizeRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizeRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizeRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizeRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<OrganizeTrigger> trigger = const Value.absent(),
                Value<String> inputSnapshot = const Value.absent(),
                Value<String?> modelConfigId = const Value.absent(),
                Value<String?> modelSnapshot = const Value.absent(),
                Value<OrganizeRunStatus> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizeRunsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                trigger: trigger,
                inputSnapshot: inputSnapshot,
                modelConfigId: modelConfigId,
                modelSnapshot: modelSnapshot,
                status: status,
                error: error,
                startedAt: startedAt,
                finishedAt: finishedAt,
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
                required OrganizeTrigger trigger,
                required String inputSnapshot,
                Value<String?> modelConfigId = const Value.absent(),
                Value<String?> modelSnapshot = const Value.absent(),
                required OrganizeRunStatus status,
                Value<String?> error = const Value.absent(),
                Value<int?> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizeRunsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                trigger: trigger,
                inputSnapshot: inputSnapshot,
                modelConfigId: modelConfigId,
                modelSnapshot: modelSnapshot,
                status: status,
                error: error,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrganizeRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrganizeRunsTable,
      OrganizeRun,
      $$OrganizeRunsTableFilterComposer,
      $$OrganizeRunsTableOrderingComposer,
      $$OrganizeRunsTableAnnotationComposer,
      $$OrganizeRunsTableCreateCompanionBuilder,
      $$OrganizeRunsTableUpdateCompanionBuilder,
      (
        OrganizeRun,
        BaseReferences<_$AppDatabase, $OrganizeRunsTable, OrganizeRun>,
      ),
      OrganizeRun,
      PrefetchHooks Function()
    >;
typedef $$OrganizeRunItemsTableCreateCompanionBuilder =
    OrganizeRunItemsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String organizeRunId,
      required String recordId,
      required OrganizeItemStatus status,
      Value<int> retryCount,
      Value<String?> correctionSuggestionId,
      Value<int> rowid,
    });
typedef $$OrganizeRunItemsTableUpdateCompanionBuilder =
    OrganizeRunItemsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> organizeRunId,
      Value<String> recordId,
      Value<OrganizeItemStatus> status,
      Value<int> retryCount,
      Value<String?> correctionSuggestionId,
      Value<int> rowid,
    });

class $$OrganizeRunItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrganizeRunItemsTable> {
  $$OrganizeRunItemsTableFilterComposer({
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

  ColumnFilters<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OrganizeItemStatus, OrganizeItemStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctionSuggestionId => $composableBuilder(
    column: $table.correctionSuggestionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrganizeRunItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrganizeRunItemsTable> {
  $$OrganizeRunItemsTableOrderingComposer({
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

  ColumnOrderings<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionSuggestionId => $composableBuilder(
    column: $table.correctionSuggestionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrganizeRunItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrganizeRunItemsTable> {
  $$OrganizeRunItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OrganizeItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctionSuggestionId => $composableBuilder(
    column: $table.correctionSuggestionId,
    builder: (column) => column,
  );
}

class $$OrganizeRunItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrganizeRunItemsTable,
          OrganizeRunItem,
          $$OrganizeRunItemsTableFilterComposer,
          $$OrganizeRunItemsTableOrderingComposer,
          $$OrganizeRunItemsTableAnnotationComposer,
          $$OrganizeRunItemsTableCreateCompanionBuilder,
          $$OrganizeRunItemsTableUpdateCompanionBuilder,
          (
            OrganizeRunItem,
            BaseReferences<
              _$AppDatabase,
              $OrganizeRunItemsTable,
              OrganizeRunItem
            >,
          ),
          OrganizeRunItem,
          PrefetchHooks Function()
        > {
  $$OrganizeRunItemsTableTableManager(
    _$AppDatabase db,
    $OrganizeRunItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizeRunItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizeRunItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizeRunItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> organizeRunId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<OrganizeItemStatus> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> correctionSuggestionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizeRunItemsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                organizeRunId: organizeRunId,
                recordId: recordId,
                status: status,
                retryCount: retryCount,
                correctionSuggestionId: correctionSuggestionId,
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
                required String organizeRunId,
                required String recordId,
                required OrganizeItemStatus status,
                Value<int> retryCount = const Value.absent(),
                Value<String?> correctionSuggestionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizeRunItemsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                organizeRunId: organizeRunId,
                recordId: recordId,
                status: status,
                retryCount: retryCount,
                correctionSuggestionId: correctionSuggestionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrganizeRunItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrganizeRunItemsTable,
      OrganizeRunItem,
      $$OrganizeRunItemsTableFilterComposer,
      $$OrganizeRunItemsTableOrderingComposer,
      $$OrganizeRunItemsTableAnnotationComposer,
      $$OrganizeRunItemsTableCreateCompanionBuilder,
      $$OrganizeRunItemsTableUpdateCompanionBuilder,
      (
        OrganizeRunItem,
        BaseReferences<_$AppDatabase, $OrganizeRunItemsTable, OrganizeRunItem>,
      ),
      OrganizeRunItem,
      PrefetchHooks Function()
    >;
typedef $$ModelCallsTableCreateCompanionBuilder =
    ModelCallsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String?> organizeRunId,
      required String modelConfigId,
      required DataBoundary dataBoundary,
      required String sentMessageIds,
      required String sentAttachmentIds,
      required int requestAt,
      Value<int?> responseAt,
      required ModelCallStatus status,
      Value<int?> tokensIn,
      Value<int?> tokensOut,
      Value<String?> responseText,
      required ModelCaller caller,
      Value<int> rowid,
    });
typedef $$ModelCallsTableUpdateCompanionBuilder =
    ModelCallsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String?> organizeRunId,
      Value<String> modelConfigId,
      Value<DataBoundary> dataBoundary,
      Value<String> sentMessageIds,
      Value<String> sentAttachmentIds,
      Value<int> requestAt,
      Value<int?> responseAt,
      Value<ModelCallStatus> status,
      Value<int?> tokensIn,
      Value<int?> tokensOut,
      Value<String?> responseText,
      Value<ModelCaller> caller,
      Value<int> rowid,
    });

class $$ModelCallsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelCallsTable> {
  $$ModelCallsTableFilterComposer({
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

  ColumnFilters<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DataBoundary, DataBoundary, String>
  get dataBoundary => $composableBuilder(
    column: $table.dataBoundary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sentMessageIds => $composableBuilder(
    column: $table.sentMessageIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentAttachmentIds => $composableBuilder(
    column: $table.sentAttachmentIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestAt => $composableBuilder(
    column: $table.requestAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseAt => $composableBuilder(
    column: $table.responseAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ModelCallStatus, ModelCallStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ModelCaller, ModelCaller, String> get caller =>
      $composableBuilder(
        column: $table.caller,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ModelCallsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelCallsTable> {
  $$ModelCallsTableOrderingComposer({
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

  ColumnOrderings<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataBoundary => $composableBuilder(
    column: $table.dataBoundary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentMessageIds => $composableBuilder(
    column: $table.sentMessageIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentAttachmentIds => $composableBuilder(
    column: $table.sentAttachmentIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestAt => $composableBuilder(
    column: $table.requestAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseAt => $composableBuilder(
    column: $table.responseAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensIn => $composableBuilder(
    column: $table.tokensIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOut => $composableBuilder(
    column: $table.tokensOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caller => $composableBuilder(
    column: $table.caller,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelCallsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelCallsTable> {
  $$ModelCallsTableAnnotationComposer({
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

  GeneratedColumn<String> get organizeRunId => $composableBuilder(
    column: $table.organizeRunId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelConfigId => $composableBuilder(
    column: $table.modelConfigId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DataBoundary, String> get dataBoundary =>
      $composableBuilder(
        column: $table.dataBoundary,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sentMessageIds => $composableBuilder(
    column: $table.sentMessageIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sentAttachmentIds => $composableBuilder(
    column: $table.sentAttachmentIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requestAt =>
      $composableBuilder(column: $table.requestAt, builder: (column) => column);

  GeneratedColumn<int> get responseAt => $composableBuilder(
    column: $table.responseAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ModelCallStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get tokensIn =>
      $composableBuilder(column: $table.tokensIn, builder: (column) => column);

  GeneratedColumn<int> get tokensOut =>
      $composableBuilder(column: $table.tokensOut, builder: (column) => column);

  GeneratedColumn<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ModelCaller, String> get caller =>
      $composableBuilder(column: $table.caller, builder: (column) => column);
}

class $$ModelCallsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelCallsTable,
          ModelCall,
          $$ModelCallsTableFilterComposer,
          $$ModelCallsTableOrderingComposer,
          $$ModelCallsTableAnnotationComposer,
          $$ModelCallsTableCreateCompanionBuilder,
          $$ModelCallsTableUpdateCompanionBuilder,
          (
            ModelCall,
            BaseReferences<_$AppDatabase, $ModelCallsTable, ModelCall>,
          ),
          ModelCall,
          PrefetchHooks Function()
        > {
  $$ModelCallsTableTableManager(_$AppDatabase db, $ModelCallsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelCallsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelCallsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelCallsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> organizeRunId = const Value.absent(),
                Value<String> modelConfigId = const Value.absent(),
                Value<DataBoundary> dataBoundary = const Value.absent(),
                Value<String> sentMessageIds = const Value.absent(),
                Value<String> sentAttachmentIds = const Value.absent(),
                Value<int> requestAt = const Value.absent(),
                Value<int?> responseAt = const Value.absent(),
                Value<ModelCallStatus> status = const Value.absent(),
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                Value<String?> responseText = const Value.absent(),
                Value<ModelCaller> caller = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelCallsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                organizeRunId: organizeRunId,
                modelConfigId: modelConfigId,
                dataBoundary: dataBoundary,
                sentMessageIds: sentMessageIds,
                sentAttachmentIds: sentAttachmentIds,
                requestAt: requestAt,
                responseAt: responseAt,
                status: status,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                responseText: responseText,
                caller: caller,
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
                Value<String?> organizeRunId = const Value.absent(),
                required String modelConfigId,
                required DataBoundary dataBoundary,
                required String sentMessageIds,
                required String sentAttachmentIds,
                required int requestAt,
                Value<int?> responseAt = const Value.absent(),
                required ModelCallStatus status,
                Value<int?> tokensIn = const Value.absent(),
                Value<int?> tokensOut = const Value.absent(),
                Value<String?> responseText = const Value.absent(),
                required ModelCaller caller,
                Value<int> rowid = const Value.absent(),
              }) => ModelCallsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                organizeRunId: organizeRunId,
                modelConfigId: modelConfigId,
                dataBoundary: dataBoundary,
                sentMessageIds: sentMessageIds,
                sentAttachmentIds: sentAttachmentIds,
                requestAt: requestAt,
                responseAt: responseAt,
                status: status,
                tokensIn: tokensIn,
                tokensOut: tokensOut,
                responseText: responseText,
                caller: caller,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModelCallsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelCallsTable,
      ModelCall,
      $$ModelCallsTableFilterComposer,
      $$ModelCallsTableOrderingComposer,
      $$ModelCallsTableAnnotationComposer,
      $$ModelCallsTableCreateCompanionBuilder,
      $$ModelCallsTableUpdateCompanionBuilder,
      (ModelCall, BaseReferences<_$AppDatabase, $ModelCallsTable, ModelCall>),
      ModelCall,
      PrefetchHooks Function()
    >;
typedef $$RecordsTableCreateCompanionBuilder =
    RecordsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required RecordType recordType,
      Value<String?> currentRevisionId,
      Value<String?> localDate,
      Value<int> rowid,
    });
typedef $$RecordsTableUpdateCompanionBuilder =
    RecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<RecordType> recordType,
      Value<String?> currentRevisionId,
      Value<String?> localDate,
      Value<int> rowid,
    });

class $$RecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<RecordType, RecordType, String>
  get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
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

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<RecordType, String> get recordType =>
      $composableBuilder(
        column: $table.recordType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);
}

class $$RecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordsTable,
          RecordRow,
          $$RecordsTableFilterComposer,
          $$RecordsTableOrderingComposer,
          $$RecordsTableAnnotationComposer,
          $$RecordsTableCreateCompanionBuilder,
          $$RecordsTableUpdateCompanionBuilder,
          (RecordRow, BaseReferences<_$AppDatabase, $RecordsTable, RecordRow>),
          RecordRow,
          PrefetchHooks Function()
        > {
  $$RecordsTableTableManager(_$AppDatabase db, $RecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<RecordType> recordType = const Value.absent(),
                Value<String?> currentRevisionId = const Value.absent(),
                Value<String?> localDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordType: recordType,
                currentRevisionId: currentRevisionId,
                localDate: localDate,
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
                required RecordType recordType,
                Value<String?> currentRevisionId = const Value.absent(),
                Value<String?> localDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordType: recordType,
                currentRevisionId: currentRevisionId,
                localDate: localDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordsTable,
      RecordRow,
      $$RecordsTableFilterComposer,
      $$RecordsTableOrderingComposer,
      $$RecordsTableAnnotationComposer,
      $$RecordsTableCreateCompanionBuilder,
      $$RecordsTableUpdateCompanionBuilder,
      (RecordRow, BaseReferences<_$AppDatabase, $RecordsTable, RecordRow>),
      RecordRow,
      PrefetchHooks Function()
    >;
typedef $$RecordRevisionsTableCreateCompanionBuilder =
    RecordRevisionsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String recordId,
      required int recordVersion,
      Value<int?> baseVersion,
      required String occurred,
      Value<String?> occurredEnd,
      required String data,
      required String producedBy,
      required String fieldMeta,
      Value<int> rowid,
    });
typedef $$RecordRevisionsTableUpdateCompanionBuilder =
    RecordRevisionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> recordId,
      Value<int> recordVersion,
      Value<int?> baseVersion,
      Value<String> occurred,
      Value<String?> occurredEnd,
      Value<String> data,
      Value<String> producedBy,
      Value<String> fieldMeta,
      Value<int> rowid,
    });

class $$RecordRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordRevisionsTable> {
  $$RecordRevisionsTableFilterComposer({
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

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordVersion => $composableBuilder(
    column: $table.recordVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurred => $composableBuilder(
    column: $table.occurred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredEnd => $composableBuilder(
    column: $table.occurredEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get producedBy => $composableBuilder(
    column: $table.producedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldMeta => $composableBuilder(
    column: $table.fieldMeta,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordRevisionsTable> {
  $$RecordRevisionsTableOrderingComposer({
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

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordVersion => $composableBuilder(
    column: $table.recordVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurred => $composableBuilder(
    column: $table.occurred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredEnd => $composableBuilder(
    column: $table.occurredEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get producedBy => $composableBuilder(
    column: $table.producedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldMeta => $composableBuilder(
    column: $table.fieldMeta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordRevisionsTable> {
  $$RecordRevisionsTableAnnotationComposer({
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

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get recordVersion => $composableBuilder(
    column: $table.recordVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurred =>
      $composableBuilder(column: $table.occurred, builder: (column) => column);

  GeneratedColumn<String> get occurredEnd => $composableBuilder(
    column: $table.occurredEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get producedBy => $composableBuilder(
    column: $table.producedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldMeta =>
      $composableBuilder(column: $table.fieldMeta, builder: (column) => column);
}

class $$RecordRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordRevisionsTable,
          RecordRevision,
          $$RecordRevisionsTableFilterComposer,
          $$RecordRevisionsTableOrderingComposer,
          $$RecordRevisionsTableAnnotationComposer,
          $$RecordRevisionsTableCreateCompanionBuilder,
          $$RecordRevisionsTableUpdateCompanionBuilder,
          (
            RecordRevision,
            BaseReferences<
              _$AppDatabase,
              $RecordRevisionsTable,
              RecordRevision
            >,
          ),
          RecordRevision,
          PrefetchHooks Function()
        > {
  $$RecordRevisionsTableTableManager(
    _$AppDatabase db,
    $RecordRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> recordVersion = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String> occurred = const Value.absent(),
                Value<String?> occurredEnd = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> producedBy = const Value.absent(),
                Value<String> fieldMeta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordRevisionsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordId: recordId,
                recordVersion: recordVersion,
                baseVersion: baseVersion,
                occurred: occurred,
                occurredEnd: occurredEnd,
                data: data,
                producedBy: producedBy,
                fieldMeta: fieldMeta,
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
                required String recordId,
                required int recordVersion,
                Value<int?> baseVersion = const Value.absent(),
                required String occurred,
                Value<String?> occurredEnd = const Value.absent(),
                required String data,
                required String producedBy,
                required String fieldMeta,
                Value<int> rowid = const Value.absent(),
              }) => RecordRevisionsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordId: recordId,
                recordVersion: recordVersion,
                baseVersion: baseVersion,
                occurred: occurred,
                occurredEnd: occurredEnd,
                data: data,
                producedBy: producedBy,
                fieldMeta: fieldMeta,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordRevisionsTable,
      RecordRevision,
      $$RecordRevisionsTableFilterComposer,
      $$RecordRevisionsTableOrderingComposer,
      $$RecordRevisionsTableAnnotationComposer,
      $$RecordRevisionsTableCreateCompanionBuilder,
      $$RecordRevisionsTableUpdateCompanionBuilder,
      (
        RecordRevision,
        BaseReferences<_$AppDatabase, $RecordRevisionsTable, RecordRevision>,
      ),
      RecordRevision,
      PrefetchHooks Function()
    >;
typedef $$RecordSourcesTableCreateCompanionBuilder =
    RecordSourcesCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String recordRevisionId,
      Value<String?> fieldPath,
      required RecordSourceKind sourceKind,
      required String sourceId,
      Value<int?> messageRevisionNo,
      Value<String?> span,
      Value<int> rowid,
    });
typedef $$RecordSourcesTableUpdateCompanionBuilder =
    RecordSourcesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> recordRevisionId,
      Value<String?> fieldPath,
      Value<RecordSourceKind> sourceKind,
      Value<String> sourceId,
      Value<int?> messageRevisionNo,
      Value<String?> span,
      Value<int> rowid,
    });

class $$RecordSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $RecordSourcesTable> {
  $$RecordSourcesTableFilterComposer({
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

  ColumnFilters<String> get recordRevisionId => $composableBuilder(
    column: $table.recordRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldPath => $composableBuilder(
    column: $table.fieldPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecordSourceKind, RecordSourceKind, String>
  get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageRevisionNo => $composableBuilder(
    column: $table.messageRevisionNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get span => $composableBuilder(
    column: $table.span,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordSourcesTable> {
  $$RecordSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get recordRevisionId => $composableBuilder(
    column: $table.recordRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldPath => $composableBuilder(
    column: $table.fieldPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageRevisionNo => $composableBuilder(
    column: $table.messageRevisionNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get span => $composableBuilder(
    column: $table.span,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordSourcesTable> {
  $$RecordSourcesTableAnnotationComposer({
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

  GeneratedColumn<String> get recordRevisionId => $composableBuilder(
    column: $table.recordRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldPath =>
      $composableBuilder(column: $table.fieldPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecordSourceKind, String> get sourceKind =>
      $composableBuilder(
        column: $table.sourceKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get messageRevisionNo => $composableBuilder(
    column: $table.messageRevisionNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get span =>
      $composableBuilder(column: $table.span, builder: (column) => column);
}

class $$RecordSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordSourcesTable,
          RecordSource,
          $$RecordSourcesTableFilterComposer,
          $$RecordSourcesTableOrderingComposer,
          $$RecordSourcesTableAnnotationComposer,
          $$RecordSourcesTableCreateCompanionBuilder,
          $$RecordSourcesTableUpdateCompanionBuilder,
          (
            RecordSource,
            BaseReferences<_$AppDatabase, $RecordSourcesTable, RecordSource>,
          ),
          RecordSource,
          PrefetchHooks Function()
        > {
  $$RecordSourcesTableTableManager(_$AppDatabase db, $RecordSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> recordRevisionId = const Value.absent(),
                Value<String?> fieldPath = const Value.absent(),
                Value<RecordSourceKind> sourceKind = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int?> messageRevisionNo = const Value.absent(),
                Value<String?> span = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordSourcesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordRevisionId: recordRevisionId,
                fieldPath: fieldPath,
                sourceKind: sourceKind,
                sourceId: sourceId,
                messageRevisionNo: messageRevisionNo,
                span: span,
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
                required String recordRevisionId,
                Value<String?> fieldPath = const Value.absent(),
                required RecordSourceKind sourceKind,
                required String sourceId,
                Value<int?> messageRevisionNo = const Value.absent(),
                Value<String?> span = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordSourcesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                recordRevisionId: recordRevisionId,
                fieldPath: fieldPath,
                sourceKind: sourceKind,
                sourceId: sourceId,
                messageRevisionNo: messageRevisionNo,
                span: span,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordSourcesTable,
      RecordSource,
      $$RecordSourcesTableFilterComposer,
      $$RecordSourcesTableOrderingComposer,
      $$RecordSourcesTableAnnotationComposer,
      $$RecordSourcesTableCreateCompanionBuilder,
      $$RecordSourcesTableUpdateCompanionBuilder,
      (
        RecordSource,
        BaseReferences<_$AppDatabase, $RecordSourcesTable, RecordSource>,
      ),
      RecordSource,
      PrefetchHooks Function()
    >;
typedef $$ModelConfigsTableCreateCompanionBuilder =
    ModelConfigsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required ModelPreset preset,
      required ModelProtocol protocol,
      required String baseUrl,
      required String model,
      Value<String> capabilities,
      required DataBoundary dataBoundary,
      required String keychainRef,
      Value<bool> isDefault,
      Value<int?> lastTestAt,
      Value<String?> lastTestResult,
      Value<int> rowid,
    });
typedef $$ModelConfigsTableUpdateCompanionBuilder =
    ModelConfigsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<ModelPreset> preset,
      Value<ModelProtocol> protocol,
      Value<String> baseUrl,
      Value<String> model,
      Value<String> capabilities,
      Value<DataBoundary> dataBoundary,
      Value<String> keychainRef,
      Value<bool> isDefault,
      Value<int?> lastTestAt,
      Value<String?> lastTestResult,
      Value<int> rowid,
    });

class $$ModelConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ModelConfigsTable> {
  $$ModelConfigsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ModelPreset, ModelPreset, String> get preset =>
      $composableBuilder(
        column: $table.preset,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ModelProtocol, ModelProtocol, String>
  get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DataBoundary, DataBoundary, String>
  get dataBoundary => $composableBuilder(
    column: $table.dataBoundary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTestResult => $composableBuilder(
    column: $table.lastTestResult,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModelConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelConfigsTable> {
  $$ModelConfigsTableOrderingComposer({
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

  ColumnOrderings<String> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataBoundary => $composableBuilder(
    column: $table.dataBoundary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTestResult => $composableBuilder(
    column: $table.lastTestResult,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelConfigsTable> {
  $$ModelConfigsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<ModelPreset, String> get preset =>
      $composableBuilder(column: $table.preset, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ModelProtocol, String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DataBoundary, String> get dataBoundary =>
      $composableBuilder(
        column: $table.dataBoundary,
        builder: (column) => column,
      );

  GeneratedColumn<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTestResult => $composableBuilder(
    column: $table.lastTestResult,
    builder: (column) => column,
  );
}

class $$ModelConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelConfigsTable,
          ModelConfig,
          $$ModelConfigsTableFilterComposer,
          $$ModelConfigsTableOrderingComposer,
          $$ModelConfigsTableAnnotationComposer,
          $$ModelConfigsTableCreateCompanionBuilder,
          $$ModelConfigsTableUpdateCompanionBuilder,
          (
            ModelConfig,
            BaseReferences<_$AppDatabase, $ModelConfigsTable, ModelConfig>,
          ),
          ModelConfig,
          PrefetchHooks Function()
        > {
  $$ModelConfigsTableTableManager(_$AppDatabase db, $ModelConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<ModelPreset> preset = const Value.absent(),
                Value<ModelProtocol> protocol = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> capabilities = const Value.absent(),
                Value<DataBoundary> dataBoundary = const Value.absent(),
                Value<String> keychainRef = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int?> lastTestAt = const Value.absent(),
                Value<String?> lastTestResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelConfigsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                preset: preset,
                protocol: protocol,
                baseUrl: baseUrl,
                model: model,
                capabilities: capabilities,
                dataBoundary: dataBoundary,
                keychainRef: keychainRef,
                isDefault: isDefault,
                lastTestAt: lastTestAt,
                lastTestResult: lastTestResult,
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
                required ModelPreset preset,
                required ModelProtocol protocol,
                required String baseUrl,
                required String model,
                Value<String> capabilities = const Value.absent(),
                required DataBoundary dataBoundary,
                required String keychainRef,
                Value<bool> isDefault = const Value.absent(),
                Value<int?> lastTestAt = const Value.absent(),
                Value<String?> lastTestResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelConfigsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                preset: preset,
                protocol: protocol,
                baseUrl: baseUrl,
                model: model,
                capabilities: capabilities,
                dataBoundary: dataBoundary,
                keychainRef: keychainRef,
                isDefault: isDefault,
                lastTestAt: lastTestAt,
                lastTestResult: lastTestResult,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModelConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelConfigsTable,
      ModelConfig,
      $$ModelConfigsTableFilterComposer,
      $$ModelConfigsTableOrderingComposer,
      $$ModelConfigsTableAnnotationComposer,
      $$ModelConfigsTableCreateCompanionBuilder,
      $$ModelConfigsTableUpdateCompanionBuilder,
      (
        ModelConfig,
        BaseReferences<_$AppDatabase, $ModelConfigsTable, ModelConfig>,
      ),
      ModelConfig,
      PrefetchHooks Function()
    >;
typedef $$ReviewPromptsTableCreateCompanionBuilder =
    ReviewPromptsCompanion Function({
      required String id,
      required String userId,
      required int createdAt,
      required String createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      required String reviewDate,
      required String promptMessageId,
      required String gapKey,
      required String templateId,
      Value<ReviewOutcome?> outcome,
      Value<String?> answeredMessageId,
      Value<int> rowid,
    });
typedef $$ReviewPromptsTableUpdateCompanionBuilder =
    ReviewPromptsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> createdAt,
      Value<String> createdOnDevice,
      Value<int> version,
      Value<int?> changeSeq,
      Value<int?> deletedAt,
      Value<String> reviewDate,
      Value<String> promptMessageId,
      Value<String> gapKey,
      Value<String> templateId,
      Value<ReviewOutcome?> outcome,
      Value<String?> answeredMessageId,
      Value<int> rowid,
    });

class $$ReviewPromptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewPromptsTable> {
  $$ReviewPromptsTableFilterComposer({
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

  ColumnFilters<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptMessageId => $composableBuilder(
    column: $table.promptMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gapKey => $composableBuilder(
    column: $table.gapKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewOutcome?, ReviewOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get answeredMessageId => $composableBuilder(
    column: $table.answeredMessageId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewPromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewPromptsTable> {
  $$ReviewPromptsTableOrderingComposer({
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

  ColumnOrderings<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptMessageId => $composableBuilder(
    column: $table.promptMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gapKey => $composableBuilder(
    column: $table.gapKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answeredMessageId => $composableBuilder(
    column: $table.answeredMessageId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewPromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewPromptsTable> {
  $$ReviewPromptsTableAnnotationComposer({
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

  GeneratedColumn<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promptMessageId => $composableBuilder(
    column: $table.promptMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gapKey =>
      $composableBuilder(column: $table.gapKey, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReviewOutcome?, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get answeredMessageId => $composableBuilder(
    column: $table.answeredMessageId,
    builder: (column) => column,
  );
}

class $$ReviewPromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewPromptsTable,
          ReviewPrompt,
          $$ReviewPromptsTableFilterComposer,
          $$ReviewPromptsTableOrderingComposer,
          $$ReviewPromptsTableAnnotationComposer,
          $$ReviewPromptsTableCreateCompanionBuilder,
          $$ReviewPromptsTableUpdateCompanionBuilder,
          (
            ReviewPrompt,
            BaseReferences<_$AppDatabase, $ReviewPromptsTable, ReviewPrompt>,
          ),
          ReviewPrompt,
          PrefetchHooks Function()
        > {
  $$ReviewPromptsTableTableManager(_$AppDatabase db, $ReviewPromptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewPromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewPromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewPromptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> createdOnDevice = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int?> changeSeq = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> reviewDate = const Value.absent(),
                Value<String> promptMessageId = const Value.absent(),
                Value<String> gapKey = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<ReviewOutcome?> outcome = const Value.absent(),
                Value<String?> answeredMessageId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewPromptsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                reviewDate: reviewDate,
                promptMessageId: promptMessageId,
                gapKey: gapKey,
                templateId: templateId,
                outcome: outcome,
                answeredMessageId: answeredMessageId,
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
                required String reviewDate,
                required String promptMessageId,
                required String gapKey,
                required String templateId,
                Value<ReviewOutcome?> outcome = const Value.absent(),
                Value<String?> answeredMessageId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewPromptsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                createdOnDevice: createdOnDevice,
                version: version,
                changeSeq: changeSeq,
                deletedAt: deletedAt,
                reviewDate: reviewDate,
                promptMessageId: promptMessageId,
                gapKey: gapKey,
                templateId: templateId,
                outcome: outcome,
                answeredMessageId: answeredMessageId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewPromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewPromptsTable,
      ReviewPrompt,
      $$ReviewPromptsTableFilterComposer,
      $$ReviewPromptsTableOrderingComposer,
      $$ReviewPromptsTableAnnotationComposer,
      $$ReviewPromptsTableCreateCompanionBuilder,
      $$ReviewPromptsTableUpdateCompanionBuilder,
      (
        ReviewPrompt,
        BaseReferences<_$AppDatabase, $ReviewPromptsTable, ReviewPrompt>,
      ),
      ReviewPrompt,
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
  $$HealthSamplesTableTableManager get healthSamples =>
      $$HealthSamplesTableTableManager(_db, _db.healthSamples);
  $$HealthAnchorsTableTableManager get healthAnchors =>
      $$HealthAnchorsTableTableManager(_db, _db.healthAnchors);
  $$HealthDailyTableTableManager get healthDaily =>
      $$HealthDailyTableTableManager(_db, _db.healthDaily);
  $$OrganizeRunsTableTableManager get organizeRuns =>
      $$OrganizeRunsTableTableManager(_db, _db.organizeRuns);
  $$OrganizeRunItemsTableTableManager get organizeRunItems =>
      $$OrganizeRunItemsTableTableManager(_db, _db.organizeRunItems);
  $$ModelCallsTableTableManager get modelCalls =>
      $$ModelCallsTableTableManager(_db, _db.modelCalls);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$RecordRevisionsTableTableManager get recordRevisions =>
      $$RecordRevisionsTableTableManager(_db, _db.recordRevisions);
  $$RecordSourcesTableTableManager get recordSources =>
      $$RecordSourcesTableTableManager(_db, _db.recordSources);
  $$ModelConfigsTableTableManager get modelConfigs =>
      $$ModelConfigsTableTableManager(_db, _db.modelConfigs);
  $$ReviewPromptsTableTableManager get reviewPrompts =>
      $$ReviewPromptsTableTableManager(_db, _db.reviewPrompts);
}
