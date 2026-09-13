#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

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
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  title_bar_channel_ = nullptr;
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
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
