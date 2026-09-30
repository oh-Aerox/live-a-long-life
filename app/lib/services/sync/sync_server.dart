import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../../data/repositories/peer_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../key_store.dart';
import 'secure_channel.dart';

/// 同步范围内允许回灌的表（schema §7.4 手机 → Mac），防注入白名单。
const syncedTables = [
  'messages',
  'message_revisions',
  'attachments',
  'message_attachments',
  'profile_fields',
  'organize_runs',
  'organize_run_items',
  'records',
  'record_revisions',
  'record_sources',
  'model_calls',
  'health_samples',
  'health_daily',
  'correction_suggestions',
  'medical_documents',
];

/// 对方数据代次变了、等待用户确认重建的手机。
class PendingRebuild {
  PendingRebuild({
    required this.peerDeviceId,
    required this.displayName,
    required this.generation,
    required this.detectedAt,
  });

  final String peerDeviceId;
  final String displayName;
  final String generation;
  final DateTime detectedAt;
}

/// 默认监听端口。固定下来手机才能在 Mac 重启后按原地址重连；
/// 被占用时向后顺延（最多 10 个）。
const syncBasePort = 47856;

/// Mac 端同步服务（V3-M2 配对、V3-M3 接收）。
///
/// - `POST /pair`：配对（一次性窗口）；`POST /ping`：连通性检查；
/// - `POST /changes`：接收一条变更并按 payload 回灌副本表。接收不经仓库、
///   不产生本机变更日志（schema §7.2：接收不回传）；
/// - `POST /blob`：接收附件文件，SHA-256 校验通过才落盘；
/// - 没有有效密钥的请求解不开信封，一律 401（D-13）。
class SyncServer {
  SyncServer({
    required this.deviceId,
    required this.displayName,
    required AppDatabase db,
    required Directory filesDir,
    required PeerRepository peers,
    required KeyStore keyStore,
    RecordRepository? records,
  })  : _db = db,
        _filesDir = filesDir,
        _peers = peers,
        _keyStore = keyStore,
        _records = records;

  final String deviceId;
  final String displayName;
  final AppDatabase _db;
  final Directory _filesDir;
  final PeerRepository _peers;
  final KeyStore _keyStore;

  /// 收到记录后维护检验项目索引（派生、不同步，各端自建，D-27）。
  final RecordRepository? _records;

  HttpServer? _server;
  SecureChannel? _pendingPairing;
  final _channels = <String, SecureChannel>{};

  /// 副本有更新时通知界面刷新。
  void Function()? onReplicaChanged;

  /// 配对成功时通知界面（收起二维码等）。
  void Function()? onPaired;

  int? get port => _server?.port;
  bool get running => _server != null;

  /// 启动常驻服务（配对过的手机随时可以推送）。
  Future<void> start() async {
    if (_server != null) return;
    Object? lastError;
    for (var port = syncBasePort; port < syncBasePort + 10; port++) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
        _server!.listen(_handle);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('无法监听同步端口：$lastError');
  }

  /// 生成配对二维码内容（服务未启动会先启动）。
  Future<PairingInfo> startPairing() async {
    await start();
    final key = await SecureChannel.newKey();
    _pendingPairing = SecureChannel(key);
    return PairingInfo(
      macDeviceId: deviceId,
      displayName: displayName,
      hosts: await lanAddresses(),
      port: _server!.port,
      key: key,
    );
  }

  void cancelPairing() => _pendingPairing = null;

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _pendingPairing = null;
    _channels.clear();
  }

  /// 本机局域网 IPv4 地址（不含回环与 169.254 链路本地）：配对二维码与
  /// 局域网广播都带上它。
  static Future<List<String>> lanAddresses() async {
    final result = <String>[];
    for (final ni in await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: false)) {
      for (final addr in ni.addresses) {
        if (!addr.isLoopback) result.add(addr.address);
      }
    }
    return result;
  }

  Future<SecureChannel?> _channelFor(String peerDeviceId) async {
    final cached = _channels[peerDeviceId];
    if (cached != null) return cached;
    final peer = await _peers.active(peerDeviceId);
    if (peer == null) return null;
    final key = await _keyStore.read('sync_peer_$peerDeviceId');
    if (key == null) return null;
    final channel = SecureChannel(base64Decode(key));
    _channels[peerDeviceId] = channel;
    return channel;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final envelope = (jsonDecode(body) as Map).cast<String, Object?>();
      final from = envelope['from'] as String?;

      final SecureChannel channel;
      final Map<String, Object?> response;
      if (request.uri.path == '/pair') {
        final pending = _pendingPairing;
        if (pending == null) {
          _reject(request, HttpStatus.forbidden, '当前没有在等待配对');
          return;
        }
        channel = pending;
        final (peerId, payload) = await channel.open(envelope);
        await _peers.pair(
          peerDeviceId: peerId,
          displayName: payload['name'] as String? ?? peerId,
          certFingerprint: channel.fingerprint,
          lastSeenAddr: request.connectionInfo?.remoteAddress.address,
        );
        await _keyStore.saveRaw('sync_peer_$peerId', base64Encode(channel.key));
        _channels[peerId] = channel;
        _pendingPairing = null; // 密钥一次配对即绑定
        onPaired?.call();
        response = {'device_id': deviceId, 'name': displayName};
      } else {
        final c = from == null ? null : await _channelFor(from);
        if (c == null) {
          _reject(request, HttpStatus.unauthorized, '未配对的设备');
          return;
        }
        channel = c;
        final (peerId, payload) = await channel.open(envelope);
        response = switch (request.uri.path) {
          '/ping' => {'device_id': deviceId, 'ok': true},
          '/changes' => await _applyChange(peerId, payload),
          '/blob' => await _storeBlob(payload),
          '/blob_fetch' => await _serveBlob(payload),
          '/analysis' => await _latestAnalysis(),
          _ => {'error': '未知端点'},
        };
        await _peers.updateLastSeen(
            peerId, request.connectionInfo?.remoteAddress.address ?? '');
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.write(
          jsonEncode(await channel.seal(response, senderDeviceId: deviceId)));
      await request.response.close();
    } on ChannelException catch (e) {
      _reject(request, HttpStatus.unauthorized, e.message);
    } catch (e) {
      _reject(request, HttpStatus.badRequest, '请求无法处理：$e');
    }
  }

  /// 接收一条变更（V3-M3）。幂等：同序号重复应用是同内容 upsert。
  Future<Map<String, Object?>> _applyChange(
      String peerId, Map<String, Object?> payload) async {
    final change = (payload['change'] as Map).cast<String, Object?>();
    final generation = change['generation'] as String;
    final seq = change['seq'] as int;
    final table = change['entity_type'] as String;
    final row = (change['payload'] as Map).cast<String, Object?>();
    final dependsOnBlob = change['depends_on_blob'] as String?;

    if (!syncedTables.contains(table)) {
      return {'status': 'rejected', 'error': '表 $table 不在同步范围'};
    }

    // 代次变化：完整重建是用户明确操作（schema §7.3）。先拒收并记下
    // 待重建，Mac 首页提示用户确认，确认后按新代次从头接收。
    final state = await _pullState(peerId);
    if (state != null && state.generation != generation) {
      await _markRebuildPending(peerId, generation);
      return {'status': 'generation_changed'};
    }

    // 依赖的附件文件没到位：先要文件，本条不确认（schema §7.4）。
    if (dependsOnBlob != null) {
      final f = File(p.join(_filesDir.path, dependsOnBlob));
      if (!await f.exists()) {
        return {'status': 'need_blob', 'sha': dependsOnBlob};
      }
    }

    await _db.transaction(() async {
      final columns = row.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      await _db.customInsert(
        'INSERT OR REPLACE INTO $table (${columns.join(', ')}) '
        'VALUES ($placeholders)',
        variables: [for (final c in columns) _variableFor(row[c])],
      );
      // 附件到位：给 Mac 自己记一行副本状态（不入变更日志）。手机没有
      // 文件时不带依赖，但 Mac 可能早就收过同一个文件（重建副本时文件不删）。
      if (table == 'attachments') {
        final sha = dependsOnBlob ?? row['sha256'] as String?;
        if (sha != null &&
            (dependsOnBlob != null ||
                await File(p.join(_filesDir.path, sha)).exists())) {
          await _recordMacCopy(row, sha);
        }
      }
      // 记录与版本分两条变更到达，哪条后到都会补齐；lab_panel 以外只是空操作。
      final recordId = switch (table) {
        'records' => row['id'] as String?,
        'record_revisions' => row['record_id'] as String?,
        _ => null,
      };
      if (recordId != null) await _records?.reindexLabPanel(recordId);
      await _advancePull(peerId, generation, seq);
    });
    onReplicaChanged?.call();
    return {'status': 'applied', 'seq': seq};
  }

  static const _rebuildKeyPrefix = 'sync_rebuild_pending:';

  Future<void> _markRebuildPending(String peerId, String generation) async {
    final existing = await (_db.select(_db.settings)
          ..where((t) => t.key.equals('$_rebuildKeyPrefix$peerId')))
        .getSingleOrNull();
    if (existing != null &&
        (jsonDecode(existing.value) as Map)['generation'] == generation) {
      return;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: '$_rebuildKeyPrefix$peerId',
            value: jsonEncode({'generation': generation, 'detected_at': now}),
            updatedAt: now,
          ),
        );
    onReplicaChanged?.call();
  }

  /// 等待用户确认重建的手机（对方数据代次变了，schema §7.3）。
  Future<List<PendingRebuild>> pendingRebuilds() async {
    final rows = await (_db.select(_db.settings)
          ..where((t) => t.key.like('$_rebuildKeyPrefix%')))
        .get();
    final result = <PendingRebuild>[];
    for (final row in rows) {
      final peerId = row.key.substring(_rebuildKeyPrefix.length);
      final v = (jsonDecode(row.value) as Map).cast<String, Object?>();
      final peer = await _peers.active(peerId);
      result.add(PendingRebuild(
        peerDeviceId: peerId,
        displayName: peer?.displayName ?? peerId,
        generation: v['generation'] as String,
        detectedAt: DateTime.fromMillisecondsSinceEpoch(
            v['detected_at'] as int,
            isUtc: true),
      ));
    }
    return result;
  }

  /// 按手机的新代次重建副本（schema §7.3，用户在 Mac 上明确确认后执行）。
  ///
  /// 先清掉副本里这台手机的行，再把接收进度改到新代次、从第 1
  /// 条重新接收；手机新代次里有全部数据，不做跨代次版本比较。手机上已经
  /// 没有的内容随之从 Mac 消失——不提供"保留 Mac 多出的"：恢复后手机的
  /// 消息序号从导出时接着编，会和 Mac 上多出的消息撞号并把它们顶掉，
  /// 留不住（D-34）。Mac 自己产生的行（修正建议、周报、调用记录）、其他
  /// 已配对设备的行和已收到的附件文件保留；按 created_on_device 区分，
  /// 不认识的设备标识（换过手机、恢复前的旧标识）算这台手机的。
  /// 返回清掉的行数。
  Future<int> rebuildReplica(String peerId) async {
    final pending = await (_db.select(_db.settings)
          ..where((t) => t.key.equals('$_rebuildKeyPrefix$peerId')))
        .getSingleOrNull();
    if (pending == null) return 0;
    final generation =
        (jsonDecode(pending.value) as Map)['generation'] as String;
    final keep = [
      deviceId,
      for (final peer in await _peers.all())
        if (peer.peerDeviceId != peerId) peer.peerDeviceId,
    ];
    final placeholders = List.filled(keep.length, '?').join(', ');
    var cleared = 0;
    await _db.transaction(() async {
      for (final table in syncedTables) {
        cleared += await _db.customUpdate(
          'DELETE FROM $table WHERE created_on_device NOT IN ($placeholders)',
          variables: [for (final id in keep) Variable.withString(id)],
          updates: {},
        );
      }
      await _db.into(_db.syncStates).insertOnConflictUpdate(
            SyncStatesCompanion.insert(
              peerDeviceId: peerId,
              direction: SyncDirection.pull,
              generation: generation,
              ackedContiguousSeq: const Value(0),
              ackedRanges: const Value('[]'),
              pendingCount: const Value(0),
              lastError: const Value(null),
            ),
          );
      await (_db.delete(_db.settings)
            ..where((t) => t.key.equals('$_rebuildKeyPrefix$peerId')))
          .go();
    });
    await _records?.rebuildLabResultIndex();
    onReplicaChanged?.call();
    return cleared;
  }

  Future<SyncState?> _pullState(String peerId) => (_db.select(_db.syncStates)
        ..where((t) =>
            t.peerDeviceId.equals(peerId) &
            t.direction.equalsValue(SyncDirection.pull)))
      .getSingleOrNull();

  Future<void> _advancePull(String peerId, String generation, int seq) async {
    final state = await _pullState(peerId);
    var contiguous = state?.ackedContiguousSeq ?? 0;
    var ranges = state == null
        ? <List<int>>[]
        : (jsonDecode(state.ackedRanges) as List)
            .map((r) => (r as List).cast<int>().toList())
            .toList();
    if (seq == contiguous + 1) {
      contiguous = seq;
      // 吸收紧随其后的区间。
      ranges.sort((a, b) => a[0].compareTo(b[0]));
      while (ranges.isNotEmpty && ranges.first[0] <= contiguous + 1) {
        final r = ranges.removeAt(0);
        if (r[1] > contiguous) contiguous = r[1];
      }
    } else if (seq > contiguous + 1) {
      ranges.add([seq, seq]);
    }
    await _db.into(_db.syncStates).insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            peerDeviceId: peerId,
            direction: SyncDirection.pull,
            generation: generation,
            ackedContiguousSeq: Value(contiguous),
            ackedRanges: Value(jsonEncode(ranges)),
            lastSuccessAt:
                Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> _recordMacCopy(
      Map<String, Object?> attachmentRow, String sha) async {
    await _db.into(_db.attachmentCopies).insertOnConflictUpdate(
          AttachmentCopiesCompanion.insert(
            id: 'maccopy-${attachmentRow['id']}',
            userId: attachmentRow['user_id'] as String,
            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
            createdOnDevice: deviceId,
            attachmentId: attachmentRow['id'] as String,
            deviceId: deviceId,
            state: CopyState.present,
            localPath: Value(sha),
            verifiedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
  }

  /// 手机拉取最新周报（schema §7.4：分析结果 Mac → 手机）。
  Future<Map<String, Object?>> _latestAnalysis() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM analysis_artifacts WHERE deleted_at IS NULL '
          'ORDER BY generated_at DESC LIMIT 1',
        )
        .get();
    return {'artifact': rows.isEmpty ? null : rows.single.data};
  }

  /// 接收附件文件：SHA-256 校验通过才落盘并确认（schema §7.4）。
  Future<Map<String, Object?>> _storeBlob(Map<String, Object?> payload) async {
    final sha = payload['sha'] as String;
    final bytes = base64Decode(payload['bytes'] as String);
    if (crypto.sha256.convert(bytes).toString() != sha) {
      return {'status': 'rejected', 'error': '哈希不符'};
    }
    await _filesDir.create(recursive: true);
    await File(p.join(_filesDir.path, sha)).writeAsBytes(bytes);
    return {'status': 'stored', 'sha': sha};
  }

  /// 用户主动取回原件时下发文件（D-22/A-21）。普通同步不会推回
  /// 已清理的文件，只有手机显式请求才走到这里。
  Future<Map<String, Object?>> _serveBlob(Map<String, Object?> payload) async {
    final sha = payload['sha'] as String;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
      return {'status': 'rejected', 'error': 'sha 不合法'};
    }
    final f = File(p.join(_filesDir.path, sha));
    if (!await f.exists()) {
      return {'status': 'not_found', 'sha': sha};
    }
    return {
      'status': 'found',
      'sha': sha,
      'bytes': base64Encode(await f.readAsBytes()),
    };
  }

  static Variable _variableFor(Object? value) => switch (value) {
        null => const Variable(null),
        final int v => Variable.withInt(v),
        final double v => Variable.withReal(v),
        final bool v => Variable.withBool(v),
        final String v => Variable.withString(v),
        _ => throw StateError('不支持的值类型：$value'),
      };

  void _reject(HttpRequest request, int status, String message) {
    try {
      request.response.statusCode = status;
      request.response.write(jsonEncode({'error': message}));
      request.response.close();
    } catch (_) {}
  }
}
