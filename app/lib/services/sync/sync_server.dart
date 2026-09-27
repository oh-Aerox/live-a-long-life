import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../../data/repositories/peer_repository.dart';
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
];

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
  })  : _db = db,
        _filesDir = filesDir,
        _peers = peers,
        _keyStore = keyStore;

  final String deviceId;
  final String displayName;
  final AppDatabase _db;
  final Directory _filesDir;
  final PeerRepository _peers;
  final KeyStore _keyStore;

  HttpServer? _server;
  SecureChannel? _pendingPairing;
  final _channels = <String, SecureChannel>{};

  /// 副本有更新时通知界面刷新。
  void Function()? onReplicaChanged;

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
      hosts: await _lanAddresses(),
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

  static Future<List<String>> _lanAddresses() async {
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

    // 代次变化：完整重建是用户明确操作（schema §7.3），第一版先拒收提示。
    final state = await _pullState(peerId);
    if (state != null && state.generation != generation) {
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
      // 附件到位：给 Mac 自己记一行副本状态（不入变更日志）。
      if (table == 'attachments' && dependsOnBlob != null) {
        await _recordMacCopy(row, dependsOnBlob);
      }
      await _advancePull(peerId, generation, seq);
    });
    onReplicaChanged?.call();
    return {'status': 'applied', 'seq': seq};
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
