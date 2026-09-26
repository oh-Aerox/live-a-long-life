import 'package:drift/native.dart';
import 'package:live_a_long_life/data/app_context.dart';
import 'package:live_a_long_life/data/db/app_database.dart';

class TestEnv {
  TestEnv._(this.db, this.ctx);

  final AppDatabase db;
  final AppContext ctx;

  static Future<TestEnv> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    final ctx = AppContext(userId: 'test-user', deviceId: 'test-device');
    return TestEnv._(db, ctx);
  }

  Future<void> dispose() => db.close();
}
