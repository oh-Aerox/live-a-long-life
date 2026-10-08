#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "bonjour_channel.h"
#include "tray_channel.h"
#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  // |start_hidden| 为真时（开机自启）首帧后不显示窗口，只留托盘图标。
  FlutterWindow(const flutter::DartProject& project, bool start_hidden);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  bool start_hidden_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // 局域网广播与托盘常驻（V4-M5、P-34），要在 flutter_controller_ 之前释放。
  std::unique_ptr<BonjourChannel> bonjour_;
  std::unique_ptr<TrayChannel> tray_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
