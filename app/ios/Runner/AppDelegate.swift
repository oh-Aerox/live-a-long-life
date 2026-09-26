import Flutter
import UIKit

// UIScene 生命周期（iOS 27 上不采用会在正常启动时被系统终止）。
// 场景由 Info.plist 里的 FlutterSceneDelegate 处理，插件注册移到
// didInitializeImplicitFlutterEngine（官方 UIScene 迁移指南）。
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
