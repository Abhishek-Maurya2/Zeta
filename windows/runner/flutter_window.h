#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
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

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Title bar channel for syncing color and theme
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> title_bar_channel_;

  // Shortcuts channel for Jump List tasks and argument forwarding
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> shortcuts_channel_;

  bool is_fullscreen_ = false;
  WINDOWPLACEMENT wp_prev_ = {sizeof(WINDOWPLACEMENT)};
  DWORD dw_prev_style_ = 0;
  DWORD dw_prev_ex_style_ = 0;

  void SetFullscreen(bool fullscreen);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
