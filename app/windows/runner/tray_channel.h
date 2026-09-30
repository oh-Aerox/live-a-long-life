#ifndef RUNNER_TRAY_CHANNEL_H_
#define RUNNER_TRAY_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <shellapi.h>

#include <memory>
#include <optional>
#include <string>

// 单实例（P-34）：第二次打开应用时，新进程广播这条消息叫回已有窗口后退出。
constexpr wchar_t kShowWindowMessageName[] = L"LiveALongLife.ShowWindow";
constexpr wchar_t kSingleInstanceMutexName[] = L"Local\\LiveALongLife.Desktop";

// 常驻系统托盘（P-34）：关窗只隐藏，Dart 侧的同步服务照常运行；托盘图标的
// 菜单显示同步状态，可以重新打开窗口或退出。与 macOS 的 MenuBarChannel
// （macos/Runner/MainFlutterWindow.swift）对应，共用通道 life.long/menu_bar。
// Dart 侧见 lib/services/menu_bar.dart。
class TrayChannel {
 public:
  // 菜单里的"退出"：发给主窗口，由主窗口销毁自己并结束消息循环。
  static constexpr UINT kQuitMessage = WM_APP + 2;

  TrayChannel(HWND window, flutter::BinaryMessenger* messenger);
  ~TrayChannel();

  TrayChannel(const TrayChannel&) = delete;
  TrayChannel& operator=(const TrayChannel&) = delete;

  // 处理托盘相关的窗口消息；不是托盘的消息返回 nullopt。
  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam,
                                       LPARAM lparam);

  // 主窗口被关掉（隐藏）时调用：第一次弹一条提示，说明应用还在托盘里。
  void OnWindowHidden();

  // 显示并激活主窗口。
  static void ShowMainWindow(HWND window);

 private:
  void AddIcon();
  void ShowMenu();

  HWND window_;
  NOTIFYICONDATAW icon_{};
  std::wstring status_ = L"同步：等待手机";
  bool hint_shown_ = false;
  UINT taskbar_created_message_;
  UINT show_window_message_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_TRAY_CHANNEL_H_
