import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/attachment_repository.dart';
import 'package:live_a_long_life/data/repositories/message_repository.dart';
import 'package:live_a_long_life/services/backup_service.dart';
import 'package:live_a_long_life/services/sync/sync_server.dart' show syncedTables;
import 'package:path/path.dart' as p;

import '../data/test_helpers.dart';

void main() {
  late TestEnv env;
  late Directory tempDir;
  late BackupService backup;

  setUp(() async {
    env = await TestEnv.create();
    tempDir = await Directory.systemTemp.createTemp('backup_test');
    backup = BackupService(
        db: env.db, filesDir: Directory(p.join(tempDir.path, 'files')));
  });

  tearDown(() async {
    await env.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<String> seed() async {
    final messages = MessageRepository(env.db, env.ctx);
    await messages.send(
      clientMsgId: 'c1',
      role: MessageRole.user,
      kind: MessageKind.text,
      text: '备份我',
      sentTz: 'Asia/Shanghai',
    );
    final attachments = AttachmentRepository(env.db, env.ctx,
        filesDir: Directory(p.join(tempDir.path, 'files')));
    final src = File(p.join(tempDir.path, 'a.jpg'));
    await src.writeAsBytes(List.generate(200, (i) => i % 251));
    final imported = await attachments.importFile(src, mimeType: 'image/jpeg');
    return imported.attachment.sha256;
  }

  test('备份 → 校验 published → 恢复演练全部通过（D-15）', () async {
    final sha = await seed();
    final target = Directory(p.join(tempDir.path, 'backups'));
    await target.create(recursive: true);

    final run =
        await backup.backup(targetRoot: target, passphrase: '正确的密码');
    expect(run.status, BackupStatus.published);
    expect(run.verifiedAt, isNotNull);
    expect(run.targetPath, contains('backup_2'));
    // 临时目录已改名，不残留。
    expect(
        await Directory(p.join(target.path, 'backup_building_${run.backupId}'))
            .exists(),
        isFalse);
    // 加密后没有明文：data.enc 不含原文。
    final enc =
        await File(p.join(run.targetPath, 'data.enc')).readAsBytes();
    expect(utf8.decode(enc, allowMalformed: true), isNot(contains('备份我')));

    final restoreTo = Directory(p.join(tempDir.path, 'restored'));
    final drill = await backup.restoreDrill(
      backupDir: Directory(run.targetPath),
      passphrase: '正确的密码',
      restoreTo: restoreTo,
    );
    expect(drill.ok, isTrue, reason: drill.error);
    expect(drill.tableRows['messages'], 1);
    expect(drill.tableRows['attachments'], 1);
    expect(drill.filesRestored, 1);
    expect(drill.missingFiles, isEmpty);
    // 附件明文恢复且内容正确。
    final restored =
        await File(p.join(restoreTo.path, 'files', sha)).readAsBytes();
    expect(restored.length, 200);
    // model_configs 不进备份。
    final data = jsonDecode(
            await File(p.join(restoreTo.path, 'data.json')).readAsString())
        as Map;
    expect((data['tables'] as Map).containsKey('model_configs'), isFalse);
  });

  test('密码不对：演练失败，不产出明文', () async {
    await seed();
    final target = Directory(p.join(tempDir.path, 'backups'));
    await target.create(recursive: true);
    final run = await backup.backup(targetRoot: target, passphrase: '正确的密码');

    final restoreTo = Directory(p.join(tempDir.path, 'restored2'));
    final drill = await backup.restoreDrill(
      backupDir: Directory(run.targetPath),
      passphrase: '错的密码',
      restoreTo: restoreTo,
    );
    expect(drill.ok, isFalse);
    expect(drill.error, contains('密码不对'));
    expect(await File(p.join(restoreTo.path, 'data.json')).exists(), isFalse);
  });

  test('备份被篡改：演练发现并失败', () async {
    await seed();
    final target = Directory(p.join(tempDir.path, 'backups'));
    await target.create(recursive: true);
    final run = await backup.backup(targetRoot: target, passphrase: 'p');

    final dataFile = File(p.join(run.targetPath, 'data.enc'));
    final bytes = await dataFile.readAsBytes();
    bytes[bytes.length ~/ 2] ^= 0xff;
    await dataFile.writeAsBytes(bytes);

    final drill = await backup.restoreDrill(
      backupDir: Directory(run.targetPath),
      passphrase: 'p',
      restoreTo: Directory(p.join(tempDir.path, 'restored3')),
    );
    expect(drill.ok, isFalse);
  });

  test('Mac 缺原件：列入清单 missing，不算业务删除', () async {
    final sha = await seed();
    // 删掉本机文件模拟缺件。
    await File(p.join(tempDir.path, 'files', sha)).delete();
    final target = Directory(p.join(tempDir.path, 'backups'));
    await target.create(recursive: true);

    final run = await backup.backup(targetRoot: target, passphrase: 'p');
    expect(run.status, BackupStatus.published);
    final manifest = jsonDecode(run.manifest) as Map;
    expect(manifest['missing_files'], [sha]);

    final drill = await backup.restoreDrill(
      backupDir: Directory(run.targetPath),
      passphrase: 'p',
      restoreTo: Directory(p.join(tempDir.path, 'restored4')),
    );
    expect(drill.ok, isTrue);
    expect(drill.missingFiles, [sha]);
    // 业务记录（attachments 行）仍在备份里。
    expect(drill.tableRows['attachments'], 1);
  });

  test('Mac 端备份截止点取手机的数据代次与接收游标（2026-09-29 联调）', () async {
    await seed();
    await env.db.into(env.db.syncStates).insert(SyncStatesCompanion.insert(
          peerDeviceId: 'phone-1',
          direction: SyncDirection.pull,
          generation: 'phone-generation',
          ackedContiguousSeq: const Value(597),
        ));
    final target = Directory(p.join(tempDir.path, 'backups'));
    await target.create(recursive: true);

    final run = await backup.backup(targetRoot: target, passphrase: 'p');
    expect(run.dataGeneration, 'phone-generation');
    expect(run.cutoffSeq, 597);
    final manifest = jsonDecode(run.manifest) as Map;
    expect(manifest['generation'], 'phone-generation');
    expect(manifest['cutoff_seq'], 597);
  });

  test('同步到 Mac 的表都在备份清单里（防新增表只加同步、漏加备份）', () {
    expect(backupTables, containsAll(syncedTables));
  });
}
