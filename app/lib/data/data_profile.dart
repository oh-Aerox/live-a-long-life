import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 开发用数据档案（plan-android AN-M6）。
///
/// Mac 把手机同步来的数据合进同一份副本；安卓验证机的测试数据不能混进
/// 日常在用的副本。用 `--dart-define=LLAL_PROFILE=android-test` 启动时，
/// 数据库、附件、日志、备份都放到独立目录，设备 ID 也随新数据库重新生成，
/// 在对方看来就是另一台设备。不传时与原来完全一样。
class DataProfile {
  static const name = String.fromEnvironment('LLAL_PROFILE');

  static bool get isDefault => name.isEmpty;

  /// 数据根目录：默认档案是 Application Support 本身，其它档案在
  /// `profiles/<name>` 下。
  static Future<Directory> supportDir() async {
    final base = await getApplicationSupportDirectory();
    return isDefault ? base : Directory(p.join(base.path, 'profiles', name));
  }

  /// 目录名加档案后缀（Mac 备份目录用）。
  static String suffixed(String dirName) =>
      isDefault ? dirName : '$dirName-$name';
}
