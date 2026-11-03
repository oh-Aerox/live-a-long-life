import 'dart:io';

import 'package:flutter/services.dart';

import 'cloud_vault.dart';

/// 用户在"文件"里选的文件夹。[bookmark] 是系统给的书签，存下来以后
/// 不用再选就能访问（卸载后失效）。
class PickedFolder {
  PickedFolder({
    required this.bookmark,
    required this.name,
    required this.inICloud,
  });

  final String bookmark;
  final String name;

  /// 在 iCloud 云盘里。选了"我的 iPhone"里的文件夹，换手机就恢复不了。
  final bool inICloud;
}

/// 打开书签得到的可访问路径。[bookmark] 不为 null 时系统换了新书签，要存回去。
class OpenedFolder {
  OpenedFolder({required this.path, this.bookmark});

  final String path;
  final String? bookmark;
}

/// 选文件夹、打开书签、保持后台运行；读写见 [FolderIO]。
abstract class CloudFolderAccess implements FolderIO {
  Future<PickedFolder?> pick();
  Future<OpenedFolder> open(String bookmark);
  Future<void> close(String path);

  /// 这些文件里还没上传到 iCloud 的。
  Future<List<String>> notUploaded(List<String> paths);

  /// 切到后台时向系统多要一点时间把备份写完。
  Future<void> beginBackground();
  Future<void> endBackground();
}

/// iOS 原生实现（AppDelegate.swift 的 CloudFolderChannel，D-51）：
/// 免费签名没有 iCloud 能力，只能让用户在系统文件选择器里选一个 iCloud
/// 云盘里的文件夹，凭书签反复访问；读写走 NSFileCoordinator。
class ChannelCloudFolder implements CloudFolderAccess {
  const ChannelCloudFolder();

  static const _channel = MethodChannel('life.long/cloud_folder');

  static bool get supported => Platform.isIOS;

  @override
  Future<PickedFolder?> pick() async {
    final r = await _channel.invokeMapMethod<String, Object?>('pick');
    if (r == null) return null;
    return PickedFolder(
      bookmark: r['bookmark'] as String,
      name: r['name'] as String,
      inICloud: r['icloud'] as bool,
    );
  }

  @override
  Future<OpenedFolder> open(String bookmark) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('open', {
        'bookmark': bookmark,
      });
      return OpenedFolder(
        path: r!['path'] as String,
        bookmark: r['bookmark'] as String?,
      );
    } on PlatformException catch (e) {
      throw StateError('打不开备份文件夹（${e.message}），请重新选择');
    }
  }

  @override
  Future<void> close(String path) =>
      _channel.invokeMethod('close', {'path': path});

  @override
  Future<List<String>> download(List<String> paths) async =>
      (await _channel.invokeListMethod<String>('download', {'paths': paths}))!;

  @override
  Future<void> put(File local, String dest) =>
      _channel.invokeMethod('put', {'from': local.path, 'to': dest});

  @override
  Future<void> move(String from, String to) =>
      _channel.invokeMethod('move', {'from': from, 'to': to});

  @override
  Future<void> delete(String path) =>
      _channel.invokeMethod('delete', {'path': path});

  @override
  Future<List<String>> notUploaded(List<String> paths) async => (await _channel
      .invokeListMethod<String>('notUploaded', {'paths': paths}))!;

  @override
  Future<void> beginBackground() => _channel.invokeMethod('beginBackground');

  @override
  Future<void> endBackground() => _channel.invokeMethod('endBackground');
}
