#include "tray_channel.h"

#include <flutter/standard_method_codec.h>

#include <cwchar>

#include "resource.h"
#include "utils.h"

namespace {

constexpr UINT kTrayCallbackMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kMenuOpen = 1;
constexpr UINT kMenuQuit = 2;

}  // namespace

TrayChannel::TrayChannel(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window),
      // 资源管理器重启后任务栏重建，托盘图标要重新添加。
      taskbar_created_message_(::RegisterWindowMessageW(L"TaskbarCreated")),
      show_window_message_(::RegisterWindowMessageW(kShowWindowMessageName)),
      channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "life.long/menu_bar",
          &flutter::StandardMethodCodec::GetInstance())) {
  icon_.cbSize = sizeof(icon_);
  icon_.hWnd = window_;
  icon_.uID = kTrayIconId;
  icon_.uCallbackMessage = kTrayCallbackMessage;
  icon_.hIcon = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON), 0));
  wcscpy_s(icon_.szTip, L"长命百岁：接收手机同步");
  AddIcon();

  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "setStatus") {
      result->NotImplemented();
      return;
    }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      auto it = args->find(flutter::EncodableValue("text"));
      if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
        status_ = Utf16FromUtf8(std::get<std::string>(it->second));
      }
    }
    result->Success(flutter::EncodableValue(true));
  });
}

TrayChannel::~TrayChannel() {
  ::Shell_NotifyIconW(NIM_DELETE, &icon_);
  if (icon_.hIcon) {
    ::DestroyIcon(icon_.hIcon);
  }
}

void TrayChannel::AddIcon() {
  icon_.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP;
  ::Shell_NotifyIconW(NIM_ADD, &icon_);
  icon_.uVersion = NOTIFYICON_VERSION_4;
  ::Shell_NotifyIconW(NIM_SETVERSION, &icon_);
}

std::optional<LRESULT> TrayChannel::HandleMessage(UINT message, WPARAM wparam,
                                                  LPARAM lparam) {
  if (message == kTrayCallbackMessage) {
    // NOTIFYICON_VERSION_4：事件在 lparam 的低 16 位。
    switch (LOWORD(lparam)) {
      case NIN_SELECT:
      case NIN_KEYSELECT:
        ShowMainWindow(window_);
        break;
      case WM_CONTEXTMENU:
        ShowMenu();
        break;
    }
    return 0;
  }
  if (message == taskbar_created_message_) {
    AddIcon();
    return 0;
  }
  if (message == show_window_message_) {
    ShowMainWindow(window_);
    return 0;
  }
  return std::nullopt;
}

void TrayChannel::ShowMenu() {
  HMENU menu = ::CreatePopupMenu();
  ::AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, status_.c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, L"打开长命百岁");
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, L"退出（停止接收同步）");
  ::SetMenuDefaultItem(menu, kMenuOpen, FALSE);

  // 菜单的所属窗口必须在前台，否则点菜单外面菜单不会消失。
  POINT cursor;
  ::GetCursorPos(&cursor);
  ::SetForegroundWindow(window_);
  const UINT command = ::TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, cursor.x, cursor.y,
      0, window_, nullptr);
  ::PostMessageW(window_, WM_NULL, 0, 0);
  ::DestroyMenu(menu);

  if (command == kMenuOpen) {
    ShowMainWindow(window_);
  } else if (command == kMenuQuit) {
    ::PostMessageW(window_, kQuitMessage, 0, 0);
  }
}

void TrayChannel::OnWindowHidden() {
  if (hint_shown_) return;
  hint_shown_ = true;
  NOTIFYICONDATAW info = icon_;
  info.uFlags = NIF_INFO;
  info.dwInfoFlags = NIIF_INFO | NIIF_RESPECT_QUIET_TIME;
  wcscpy_s(info.szInfoTitle, L"长命百岁仍在接收同步");
  wcscpy_s(info.szInfo,
           L"窗口关掉后，应用留在任务栏右下角的托盘里继续接收手机同步。"
           L"点托盘图标重新打开，右键可以退出。");
  ::Shell_NotifyIconW(NIM_MODIFY, &info);
}

void TrayChannel::ShowMainWindow(HWND window) {
  ::ShowWindow(window, ::IsIconic(window) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(window);
}
