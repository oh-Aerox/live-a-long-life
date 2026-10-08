#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "tray_channel.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 只运行一个实例（P-34）：关窗后应用还在托盘里接收同步，再次打开时叫回
  // 已有的窗口，不起第二个（两个进程会抢同一个数据库和同步端口）。
  HANDLE instance_mutex =
      ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ::AllowSetForegroundWindow(ASFW_ANY);
    ::PostMessageW(HWND_BROADCAST,
                   ::RegisterWindowMessageW(kShowWindowMessageName), 0, 0);
    if (instance_mutex) {
      ::CloseHandle(instance_mutex);
    }
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // 开机自启（P-34）：安装程序写入的启动项带 --autostart，只在托盘里接收
  // 同步，不弹窗口；用户从托盘或再次打开应用时才显示。
  const bool start_hidden =
      command_line != nullptr && ::wcsstr(command_line, L"--autostart") != nullptr;
  FlutterWindow window(project, start_hidden);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"长命百岁", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex) {
    ::CloseHandle(instance_mutex);
  }
  return EXIT_SUCCESS;
}
