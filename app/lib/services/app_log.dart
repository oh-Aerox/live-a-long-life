import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warn, error }

const _levelNames = {
  LogLevel.debug: 'D',
  LogLevel.info: 'I',
  LogLevel.warn: 'W',
  LogLevel.error: 'E',
};

/// 应用运行日志（2026-09-28 补）。
///
/// - 级别：调试构建 debug 起，发布构建 info 起（低于阈值的丢弃）；
/// - 落点：控制台（debugPrint）+ Application Support/logs/app.log（滚动 1MB→app.1.log）
///   + 内存环形缓冲（应用内"查看日志"页用）；
/// - 脱敏：调用方负责不传 API key / Authorization 等机密；本服务不打印它们。
class AppLog {
  AppLog._(this.minLevel, this._file);

  final LogLevel minLevel;
  final File? _file;
  static const _maxFileBytes = 1024 * 1024;
  static const _memoryCap = 500;

  final Queue<String> _memory = Queue<String>();

  static AppLog? _instance;
  static AppLog get I => _instance ?? AppLog._(LogLevel.debug, null);

  static Future<void> init() async {
    final minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;
    File? file;
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory(p.join(dir.path, 'logs'));
      await logDir.create(recursive: true);
      file = File(p.join(logDir.path, 'app.log'));
    } catch (_) {
      // 拿不到目录也不影响运行，只是没有文件日志。
    }
    _instance = AppLog._(minLevel, file);
    I.i('app', '日志启动，级别 ${_levelNames[minLevel]}，'
        '文件 ${file?.path ?? "(无)"}');
  }

  void log(LogLevel level, String tag, String message) {
    if (level.index < minLevel.index) return;
    final ts = DateTime.now().toIso8601String();
    final line = '$ts ${_levelNames[level]}/$tag  $message';
    if (kDebugMode) debugPrint(line);
    _memory.addLast(line);
    while (_memory.length > _memoryCap) {
      _memory.removeFirst();
    }
    _appendFile(line);
  }

  void d(String tag, String m) => log(LogLevel.debug, tag, m);
  void i(String tag, String m) => log(LogLevel.info, tag, m);
  void w(String tag, String m) => log(LogLevel.warn, tag, m);
  void e(String tag, String m, [Object? err, StackTrace? st]) => log(
      LogLevel.error, tag, err == null ? m : '$m | $err${st == null ? '' : '\n$st'}');

  /// 最近的日志（新的在前），给应用内查看页。
  List<String> recent() => _memory.toList().reversed.toList();

  Future<void> clear() async {
    _memory.clear();
    try {
      if (await _file?.exists() == true) await _file!.writeAsString('');
    } catch (_) {}
  }

  String? get filePath => _file?.path;

  void _appendFile(String line) {
    final file = _file;
    if (file == null) return;
    try {
      if (file.existsSync() && file.lengthSync() > _maxFileBytes) {
        final rolled = File('${file.path.substring(0, file.path.length - 4)}.1.log');
        if (rolled.existsSync()) rolled.deleteSync();
        file.renameSync(rolled.path);
      }
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: false);
    } catch (_) {}
  }
}
