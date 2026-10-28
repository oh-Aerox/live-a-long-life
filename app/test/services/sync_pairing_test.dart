import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/repositories/peer_repository.dart';
import 'package:live_a_long_life/services/key_store.dart';
import 'package:live_a_long_life/services/sync/secure_channel.dart';
import 'package:live_a_long_life/services/sync/sync_client.dart';
import 'package:live_a_long_life/services/sync/sync_server.dart';

import '../data/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureChannel（D-13 加密与双向认证）', () {
    test('往返加解密，AAD 绑定发送方身份', () async {
      final key = await SecureChannel.newKey();
      final a = SecureChannel(key);
      final b = SecureChannel(key);

      final envelope =
          await a.seal({'hello': '世界'}, senderDeviceId: 'phone-1');
      final (from, body) = await b.open(envelope);
      expect(from, 'phone-1');
      expect(body['hello'], '世界');
    });

    test('密钥不同解不开；篡改身份或密文认证失败', () async {
      final k1 = await SecureChannel.newKey();
      final k2 = await SecureChannel.newKey();
      final sender = SecureChannel(k1);

      final envelope =
          await sender.seal({'x': 1}, senderDeviceId: 'phone-1');
      await expectLater(
          SecureChannel(k2).open(Map.of(envelope)),
          throwsA(isA<ChannelException>()));

      // 冒充身份：AAD 不符。
      final forged = Map<String, Object?>.of(envelope)..['from'] = '别人';
      await expectLater(SecureChannel(k1).open(forged),
          throwsA(isA<ChannelException>()));
    });

    test('重放同一信封被拒绝；过期消息被拒绝', () async {
      final key = await SecureChannel.newKey();
      final sender = SecureChannel(key);
      final receiver = SecureChannel(key);

      final envelope = await sender.seal({}, senderDeviceId: 'p');
      await receiver.open(Map.of(envelope));
      await expectLater(receiver.open(Map.of(envelope)),
          throwsA(isA<ChannelException>()));

      final stale = await sender.seal({}, senderDeviceId: 'p');
      stale['ts'] = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      await expectLater(receiver.open(stale),
          throwsA(isA<ChannelException>()));
    });

    test('配对二维码内容往返；别的二维码不误识别', () {
      final info = PairingInfo(
        macDeviceId: 'mac-1',
        displayName: 'Mac',
        hosts: ['192.168.1.2'],
        port: 4567,
        key: List.filled(32, 9),
      );
      final decoded = PairingInfo.decode(info.encode());
      expect(decoded!.macDeviceId, 'mac-1');
      expect(decoded.hosts, ['192.168.1.2']);
      expect(decoded.key, List.filled(32, 9));

      expect(PairingInfo.decode('https://example.com'), isNull);
      expect(PairingInfo.decode('{"app":"别的"}'), isNull);
    });
  });

  group('配对流程（回环网络）', () {
    late TestEnv macEnv;
    late TestEnv phoneEnv;
    late SyncServer server;

    setUp(() async {
      // 测试绑定默认把 HttpClient 换成假实现（一律 400）；
      // 这组测试要走真实回环网络。
      HttpOverrides.global = null;
      FlutterSecureStorage.setMockInitialValues({});
      macEnv = await TestEnv.create();
      phoneEnv = await TestEnv.create();
      final macFiles =
          await Directory.systemTemp.createTemp('sync_mac_files');
      addTearDown(() => macFiles.delete(recursive: true));
      server = SyncServer(
        deviceId: 'mac-1',
        displayName: 'Mac',
        db: macEnv.db,
        filesDir: macFiles,
        peers: PeerRepository(macEnv.db),
        keyStore: KeyStore(),
      );
    });

    tearDown(() async {
      await server.stop();
      await macEnv.dispose();
      await phoneEnv.dispose();
    });

    test('扫码配对：双端各记 peers、指纹一致；ping 连通', () async {
      final info = await server.startPairing();
      // 测试环境走回环地址。
      final loopInfo = PairingInfo(
        macDeviceId: info.macDeviceId,
        displayName: info.displayName,
        hosts: ['127.0.0.1'],
        port: info.port,
        key: info.key,
      );

      final client = SyncClient(
        deviceId: 'phone-1',
        displayName: 'iPhone',
        peers: PeerRepository(phoneEnv.db),
        keyStore: KeyStore(),
      );
      final peer = await client.pairWith(loopInfo);
      expect(peer.peerDeviceId, 'mac-1');

      final macSide =
          await PeerRepository(macEnv.db).active('phone-1');
      expect(macSide, isNotNull);
      // 双端指纹一致（同一把密钥）。
      expect(macSide!.certFingerprint, peer.certFingerprint);
      expect(peer.certFingerprint, SecureChannel.fingerprintOf(info.key));

      // 配对后 ping 通（带端口的地址）。
      await PeerRepository(phoneEnv.db)
          .updateLastSeen('mac-1', '127.0.0.1:${server.port}');
      final updated =
          await PeerRepository(phoneEnv.db).active('mac-1');
      expect(await client.ping(updated!), isTrue);
    });

    test('未配对（无密钥）的请求被拒绝；配对窗口一次有效', () async {
      final info = await server.startPairing();
      final loopInfo = PairingInfo(
        macDeviceId: info.macDeviceId,
        displayName: info.displayName,
        hosts: ['127.0.0.1'],
        port: info.port,
        key: info.key,
      );
      final client = SyncClient(
        deviceId: 'phone-1',
        displayName: 'iPhone',
        peers: PeerRepository(phoneEnv.db),
        keyStore: KeyStore(),
      );
      await client.pairWith(loopInfo);

      // 拿错密钥的"另一台手机"配对失败（窗口已关 + 密钥不符）。
      final rogue = SyncClient(
        deviceId: 'phone-2',
        displayName: '陌生手机',
        peers: PeerRepository(phoneEnv.db),
        keyStore: KeyStore(),
      );
      final rogueInfo = PairingInfo(
        macDeviceId: info.macDeviceId,
        displayName: info.displayName,
        hosts: ['127.0.0.1'],
        port: info.port,
        key: List.filled(32, 1), // 猜的密钥
      );
      await expectLater(rogue.pairWith(rogueInfo), throwsA(isA<StateError>()));
      expect(await PeerRepository(macEnv.db).active('phone-2'), isNull);

      // 未配对设备 ping 也被拒。
      await PeerRepository(phoneEnv.db).pair(
          peerDeviceId: 'mac-x',
          displayName: 'x',
          certFingerprint: 'f',
          lastSeenAddr: '127.0.0.1:${server.port}');
      await KeyStore()
          .saveRaw('sync_peer_mac-x', base64Encode(List.filled(32, 2)));
      final fake = await PeerRepository(phoneEnv.db).active('mac-x');
      expect(await rogue.ping(fake!), isFalse);
    });
  });
}
