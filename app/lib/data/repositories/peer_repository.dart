import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../ids.dart';

/// 已配对设备（schema §7.1）。密钥本体在系统安全存储，
/// 这里只存 SHA-256 指纹与元数据。
class PeerRepository {
  PeerRepository(this._db, {this.ids = const IdGenerator()});

  final AppDatabase _db;
  final IdGenerator ids;

  Future<Peer> pair({
    required String peerDeviceId,
    required String displayName,
    required String certFingerprint,
    String? lastSeenAddr,
  }) async {
    await _db.into(_db.peers).insertOnConflictUpdate(PeersCompanion.insert(
          peerDeviceId: peerDeviceId,
          displayName: displayName,
          certFingerprint: certFingerprint,
          pairedAt: ids.nowMs(),
          lastSeenAddr: Value(lastSeenAddr),
          revokedAt: const Value(null),
        ));
    return (_db.select(_db.peers)
          ..where((t) => t.peerDeviceId.equals(peerDeviceId)))
        .getSingle();
  }

  /// 有效的（未解除的）配对设备。
  Future<Peer?> active(String peerDeviceId) async {
    final peer = await (_db.select(_db.peers)
          ..where((t) => t.peerDeviceId.equals(peerDeviceId)))
        .getSingleOrNull();
    if (peer == null || peer.revokedAt != null) return null;
    return peer;
  }

  Future<List<Peer>> all() => (_db.select(_db.peers)
        ..where((t) => t.revokedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.pairedAt)]))
      .get();

  Future<void> updateLastSeen(String peerDeviceId, String addr) =>
      (_db.update(_db.peers)
            ..where((t) => t.peerDeviceId.equals(peerDeviceId)))
          .write(PeersCompanion(lastSeenAddr: Value(addr)));

  Future<void> revoke(String peerDeviceId) => (_db.update(_db.peers)
        ..where((t) => t.peerDeviceId.equals(peerDeviceId)))
      .write(PeersCompanion(revokedAt: Value(ids.nowMs())));
}
