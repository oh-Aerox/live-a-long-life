import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 导出目录与给用户看的位置说明（按平台，plan-android AN-M1）。
///
/// iOS：应用的 Documents，在"文件 App → 我的 iPhone → 长命百岁"里可见。
/// 安卓：应用私有目录用户看不到，放公共"下载"目录（Android 11 起应用可以
/// 直接在这里建自己的文件，卸载应用也不会删）；建不了时退回外部应用目录。
class ExportLocation {
  const ExportLocation._(this.dir, this._where);

  final Directory dir;
  final String _where;

  /// 给用户看的位置，[name] 是某次导出的文件夹名。
  String describe([String? name]) => name == null ? _where : '$_where → $name';

  static const _androidPublic = '/storage/emulated/0/Download/长命百岁/exports';

  static Future<ExportLocation> resolve() async {
    if (Platform.isAndroid) {
      final public = Directory(_androidPublic);
      try {
        await public.create(recursive: true);
        return ExportLocation._(public, '文件管理 → 下载 → 长命百岁 → exports');
      } on FileSystemException {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          return ExportLocation._(
            Directory(p.join(ext.path, 'exports')),
            p.join(ext.path, 'exports'),
          );
        }
      }
    }
    final docs = await getApplicationDocumentsDirectory();
    return ExportLocation._(
      Directory(p.join(docs.path, 'exports')),
      '文件 App → 我的 iPhone → 长命百岁 → exports',
    );
  }
}
