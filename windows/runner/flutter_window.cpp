#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "jump_list.h"
#include "utils.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  title_bar_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "zeta/windows_title_bar",
          &flutter::StandardMethodCodec::GetInstance());

  title_bar_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "updateTitleBar") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            HWND hwnd = GetHandle();
            if (hwnd && IsWindow(hwnd)) {
              auto dark_it = args->find(flutter::EncodableValue("isDark"));
              if (dark_it != args->end()) {
                if (const auto* val = std::get_if<bool>(&dark_it->second)) {
                  BOOL dark = *val ? TRUE : FALSE;
                  DwmSetWindowAttribute(hwnd, 20, &dark, sizeof(dark));
                }
              }

              auto color_it = args->find(flutter::EncodableValue("color"));
              if (color_it != args->end()) {
                COLORREF cref = 0;
                bool has_color = false;
                if (const auto* val = std::get_if<int32_t>(&color_it->second)) {
                  int32_t c = *val;
                  cref = RGB((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF);
                  has_color = true;
                } else if (const auto* val64 = std::get_if<int64_t>(&color_it->second)) {
                  int64_t c = *val64;
                  cref = RGB((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF);
                  has_color = true;
                }
                if (has_color) {
                  DwmSetWindowAttribute(hwnd, 35, &cref, sizeof(cref));
                }
              }

              auto text_it = args->find(flutter::EncodableValue("textColor"));
              if (text_it != args->end()) {
                COLORREF text_cref = 0;
                bool has_text = false;
                if (const auto* val = std::get_if<int32_t>(&text_it->second)) {
                  int32_t c = *val;
                  text_cref = RGB((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF);
                  has_text = true;
                } else if (const auto* val64 = std::get_if<int64_t>(&text_it->second)) {
                  int64_t c = *val64;
                  text_cref = RGB((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF);
                  has_text = true;
                }
                if (has_text) {
                  DwmSetWindowAttribute(hwnd, 36, &text_cref, sizeof(text_cref));
                }
              }
            }
          }
          result->Success();
        } else if (call.method_name() == "setFullscreen") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it = args->find(flutter::EncodableValue("fullscreen"));
            if (it != args->end()) {
              if (const auto* val = std::get_if<bool>(&it->second)) {
                SetFullscreen(*val);
              }
            }
          }
          result->Success();
        } else if (call.method_name() == "setWakeLock") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it = args->find(flutter::EncodableValue("enable"));
            if (it != args->end()) {
              if (const auto* val = std::get_if<bool>(&it->second)) {
                if (*val) {
                  SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED);
                } else {
                  SetThreadExecutionState(ES_CONTINUOUS);
                }
              }
            }
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  shortcuts_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "zeta/windows_shortcuts",
          &flutter::StandardMethodCodec::GetInstance());

  shortcuts_channel_->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() == "setupJumpList") {
          bool ok = jump_list::SetupTaskbarJumpList();
          result->Success(flutter::EncodableValue(ok));
        } else {
          result->NotImplemented();
        }
      });

  jump_list::SetupTaskbarJumpList();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::SetFullscreen(bool fullscreen) {
  HWND hwnd = GetHandle();
  if (!hwnd || !IsWindow(hwnd)) return;

  if (fullscreen && !is_fullscreen_) {
    dw_prev_style_ = GetWindowLong(hwnd, GWL_STYLE);
    dw_prev_ex_style_ = GetWindowLong(hwnd, GWL_EXSTYLE);
    GetWindowPlacement(hwnd, &wp_prev_);

    HMONITOR hmon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO mi = { sizeof(mi) };
    if (GetMonitorInfo(hmon, &mi)) {
      SetWindowLong(hwnd, GWL_STYLE, dw_prev_style_ & ~WS_OVERLAPPEDWINDOW);
      SetWindowPos(hwnd, HWND_TOP,
                   mi.rcMonitor.left, mi.rcMonitor.top,
                   mi.rcMonitor.right - mi.rcMonitor.left,
                   mi.rcMonitor.bottom - mi.rcMonitor.top,
                   SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
      is_fullscreen_ = true;
    }
  } else if (!fullscreen && is_fullscreen_) {
    SetWindowLong(hwnd, GWL_STYLE, dw_prev_style_);
    SetWindowLong(hwnd, GWL_EXSTYLE, dw_prev_ex_style_);
    SetWindowPlacement(hwnd, &wp_prev_);
    SetWindowPos(hwnd, NULL, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                 SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    is_fullscreen_ = false;
  }
}

void FlutterWindow::OnDestroy() {
  if (is_fullscreen_) {
    SetFullscreen(false);
  }
  SetThreadExecutionState(ES_CONTINUOUS);
  title_bar_channel_ = nullptr;
  shortcuts_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_COPYDATA: {
      auto cds = reinterpret_cast<PCOPYDATASTRUCT>(lparam);
      if (cds && cds->dwData == 0x5A455441) {  // 'ZETA'
        const wchar_t* cmd = reinterpret_cast<const wchar_t*>(cds->lpData);
        if (cmd && shortcuts_channel_) {
          std::wstring wcmd(cmd);
          std::string route;
          size_t pos = wcmd.find(L"--route=");
          if (pos != std::wstring::npos) {
            std::wstring wroute = wcmd.substr(pos + 8);
            size_t space_pos = wroute.find(L' ');
            if (space_pos != std::wstring::npos) {
              wroute = wroute.substr(0, space_pos);
            }
            route = Utf8FromUtf16(wroute.c_str());
          } else {
            route = Utf8FromUtf16(wcmd.c_str());
          }

          if (!route.empty()) {
            shortcuts_channel_->InvokeMethod(
                "onShortcut",
                std::make_unique<flutter::EncodableValue>(route));
          }
        }
        return TRUE;
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
