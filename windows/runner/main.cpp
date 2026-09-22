#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shobjidl.h>

#include "flutter_window.h"
#include "jump_list.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Set explicit AppUserModelID for taskbar grouping and Jump List anchoring
  ::SetCurrentProcessExplicitAppUserModelID(jump_list::kAppUserModelID);

  // Single-instance management: forward command line arguments to running instance
  HANDLE single_instance_mutex =
      ::CreateMutexW(nullptr, TRUE, L"ZetaApp_SingleInstance_Mutex");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing_hwnd = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"zeta");
    if (existing_hwnd) {
      if (::IsIconic(existing_hwnd)) {
        ::ShowWindow(existing_hwnd, SW_RESTORE);
      }
      ::SetForegroundWindow(existing_hwnd);

      if (command_line && wcslen(command_line) > 0) {
        COPYDATASTRUCT cds;
        cds.dwData = 0x5A455441;  // 'ZETA'
        cds.cbData = static_cast<DWORD>((wcslen(command_line) + 1) * sizeof(wchar_t));
        cds.lpData = static_cast<void*>(command_line);
        ::SendMessageW(existing_hwnd, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
      }
    }
    if (single_instance_mutex) {
      ::CloseHandle(single_instance_mutex);
    }
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"zeta", origin, size)) {
    if (single_instance_mutex) {
      ::CloseHandle(single_instance_mutex);
    }
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (single_instance_mutex) {
    ::CloseHandle(single_instance_mutex);
  }
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
