import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/app_context.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/data/repositories/profile_repository.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';

import 'test_helpers.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() => env.dispose());

  group('用户资料（schema §4.1，D-18）', () {
    test('修改追加新版本，历史全部保留', () async {
      final repo = ProfileRepository(env.db, env.ctx);

      final v1 = await repo.setField('height_cm', value: 175);
      expect(v1.version, 1);

      final v2 = await repo.setField('height_cm', value: 176);
      expect(v2.version, 2);

      final current = await repo.current('height_cm');
      expect(current!.$2, 176);

      final history = await repo.history('height_cm');
      expect(history.length, 2);
      expect(history.first.version, 1);
    });

    test('可跳过与不愿透露的状态', () async {
      final repo = ProfileRepository(env.db, env.ctx);
      await repo.setField('smoking', state: ProfileFieldState.skipped);
      final current = await repo.current('smoking');
      expect(current!.$1.state, ProfileFieldState.skipped);
      expect(await repo.current('alcohol'), isNull);
    });
  });

  group('设置（schema §4.2）', () {
    test('未设置时返回默认值', () async {
      final repo = SettingsRepository(env.db);
      expect(await repo.get('review_times'), ['21:30']);
      expect(await repo.get('review_enabled'), true);
      expect(await repo.get('day_view_start'), '00:00');
      expect(await repo.get('home_tz'), isNull);
    });

    test('写入后读回，覆盖默认值', () async {
      final repo = SettingsRepository(env.db);
      await repo.set('review_times', ['08:00', '21:30']);
      expect(await repo.get('review_times'), ['08:00', '21:30']);

      final all = await repo.getAll();
      expect(all['review_times'], ['08:00', '21:30']);
      expect(all['review_enabled'], true);
    });
  });

  group('用户与设备标识', () {
    test('首次生成后保持不变', () async {
      final settings = SettingsRepository(env.db);
      final first = await AppContext.load(settings);
      final second = await AppContext.load(settings);
      expect(second.userId, first.userId);
      expect(second.deviceId, first.deviceId);
    });
  });
}
