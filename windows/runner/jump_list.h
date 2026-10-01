#ifndef RUNNER_JUMP_LIST_H_
#define RUNNER_JUMP_LIST_H_

#include <windows.h>

namespace jump_list {

// Explicit AppUserModelID for Zeta application grouping and taskbar anchoring.
#ifdef NDEBUG
constexpr const wchar_t kAppUserModelID[] = L"com.abhishek.zeta";
#else
constexpr const wchar_t kAppUserModelID[] = L"com.abhishek.zeta.dev";
#endif

// Initializes or updates Windows Taskbar Jump List with shortcuts (User Tasks)
// for Pomodoro Timer, Tasks, Calendar, and Revision Notes.
bool SetupTaskbarJumpList();

}  // namespace jump_list

#endif  // RUNNER_JUMP_LIST_H_
