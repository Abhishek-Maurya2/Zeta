#include "jump_list.h"
#include "resource.h"

#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>
#include <wrl/client.h>
#include <string>
#include <vector>

using Microsoft::WRL::ComPtr;

namespace jump_list {

namespace {

struct ShortcutTask {
  const wchar_t* title;
  const wchar_t* description;
  const wchar_t* arguments;
  int icon_resource_id;
};

const std::vector<ShortcutTask> kTasks = {
  {
    L"Pomodoro Timer",
    L"Focus session and timer",
    L"--route=action_pomodoro",
    IDI_POMODORO
  },
  {
    L"Tasks",
    L"View and organize tasks",
    L"--route=action_tasks",
    IDI_TASKS
  },
  {
    L"Calendar",
    L"View calendar and schedule",
    L"--route=action_calendar",
    IDI_CALENDAR
  },
  {
    L"Revision Notes",
    L"Spaced repetition and notes",
    L"--route=action_revision",
    IDI_REVISION
  }
};

HRESULT CreateShellLink(const wchar_t* exe_path, const ShortcutTask& task,
                        IShellLinkW** pp_link) {
  ComPtr<IShellLinkW> link;
  HRESULT hr = CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&link));
  if (FAILED(hr)) return hr;

  hr = link->SetPath(exe_path);
  if (FAILED(hr)) return hr;

  hr = link->SetArguments(task.arguments);
  if (FAILED(hr)) return hr;

  if (task.description && wcslen(task.description) > 0) {
    link->SetDescription(task.description);
  }

  // Set the icon location using the negative resource ID embedded in the binary
  link->SetIconLocation(exe_path, -task.icon_resource_id);

  // Set Title and AppUserModelID in the property store
  ComPtr<IPropertyStore> prop_store;
  hr = link.As(&prop_store);
  if (SUCCEEDED(hr)) {
    PROPVARIANT pv;
    if (SUCCEEDED(InitPropVariantFromString(task.title, &pv))) {
      prop_store->SetValue(PKEY_Title, pv);
      PropVariantClear(&pv);
    }
    if (SUCCEEDED(InitPropVariantFromString(kAppUserModelID, &pv))) {
      prop_store->SetValue(PKEY_AppUserModel_ID, pv);
      PropVariantClear(&pv);
    }
    prop_store->Commit();
  }

  *pp_link = link.Detach();
  return S_OK;
}

}  // namespace

bool SetupTaskbarJumpList() {
  wchar_t exe_path[MAX_PATH];
  if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) {
    return false;
  }

  ComPtr<ICustomDestinationList> dest_list;
  HRESULT hr = CoCreateInstance(CLSID_DestinationList, nullptr,
                                CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dest_list));
  if (FAILED(hr)) return false;

  dest_list->SetAppID(kAppUserModelID);

  UINT min_slots = 0;
  ComPtr<IObjectArray> removed_array;
  hr = dest_list->BeginList(&min_slots, IID_PPV_ARGS(&removed_array));
  if (FAILED(hr)) return false;

  ComPtr<IObjectCollection> obj_collection;
  hr = CoCreateInstance(CLSID_EnumerableObjectCollection, nullptr,
                        CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&obj_collection));
  if (FAILED(hr)) {
    dest_list->AbortList();
    return false;
  }

  for (const auto& task : kTasks) {
    ComPtr<IShellLinkW> link;
    if (SUCCEEDED(CreateShellLink(exe_path, task, &link))) {
      obj_collection->AddObject(link.Get());
    }
  }

  ComPtr<IObjectArray> tasks_array;
  hr = obj_collection.As(&tasks_array);
  if (SUCCEEDED(hr)) {
    dest_list->AddUserTasks(tasks_array.Get());
  }

  hr = dest_list->CommitList();
  return SUCCEEDED(hr);
}

}  // namespace jump_list
