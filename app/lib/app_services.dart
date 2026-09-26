import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/app_context.dart';
import 'data/db/app_database.dart';
import 'data/repositories/attachment_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/settings_repository.dart';

/// 应用级服务：数据库与各仓库。
/// 数据库和附件都放 Application Support 下（docs/plan-v0.1.md §2），
/// 覆盖安装后保留（A-07），不出现在用户可见的文档目录里。
class AppServices {
  AppServices._({
    required this.db,
    required this.ctx,
    required this.messages,
    required this.attachments,
    required this.profile,
    required this.settings,
    required this.filesDir,
  });

  final AppDatabase db;
  final AppContext ctx;
  final MessageRepository messages;
  final AttachmentRepository attachments;
  final ProfileRepository profile;
  final SettingsRepository settings;
  final Directory filesDir;

  static Future<AppServices> init() async {
    final support = await getApplicationSupportDirectory();
    final dbFile = File(p.join(support.path, 'db', 'app.sqlite'));
    await dbFile.parent.create(recursive: true);
    final filesDir = Directory(p.join(support.path, 'files'));

    final db = AppDatabase(NativeDatabase.createInBackground(dbFile));
    final settings = SettingsRepository(db);
    final ctx = await AppContext.load(settings);
    return AppServices._(
      db: db,
      ctx: ctx,
      messages: MessageRepository(db, ctx),
      attachments: AttachmentRepository(db, ctx, filesDir: filesDir),
      profile: ProfileRepository(db, ctx),
      settings: settings,
      filesDir: filesDir,
    );
  }
}
