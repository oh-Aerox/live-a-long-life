import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 常驻菜单栏（P-34）：关掉主窗口只是隐藏，应用继续接收手机同步；
  // 退出走菜单栏的"退出"或 ⌘Q。
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // 窗口隐藏时点 Dock 图标或 Finder 里再次打开应用：把窗口叫回来。
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag { MenuBarChannel.shared.showWindow() }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
