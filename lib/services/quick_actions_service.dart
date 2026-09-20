import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';
import '../providers/navigation_provider.dart';

/// Manages OS-level App Launcher Shortcuts (App Shortcuts on Android/iOS and Taskbar Shortcuts).
class QuickActionsService {
  static final QuickActionsService instance = QuickActionsService._();
  QuickActionsService._();

  final QuickActions _quickActions = const QuickActions();
  NavigationProvider? _navProvider;

  void init(NavigationProvider navProvider) {
    if (kIsWeb) return;
    _navProvider = navProvider;

    _quickActions.initialize((String shortcutType) {
      handleShortcut(shortcutType);
    });

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_pomodoro',
        localizedTitle: 'Pomodoro Timer',
        icon: 'ic_pomodoro',
      ),
      const ShortcutItem(
        type: 'action_tasks',
        localizedTitle: 'Tasks',
        icon: 'ic_tasks',
      ),
      const ShortcutItem(
        type: 'action_calendar',
        localizedTitle: 'Calendar',
        icon: 'ic_calendar',
      ),
      const ShortcutItem(
        type: 'action_revision',
        localizedTitle: 'Revision Notes',
        icon: 'ic_revision',
      ),
    ]);
  }

  void handleShortcut(String shortcutType) {
    if (_navProvider == null) return;
    switch (shortcutType) {
      case 'action_pomodoro':
      case 'pomodoro':
        _navProvider!.setActivePage(PageId.pomodoro);
        break;
      case 'action_tasks':
      case 'tasks':
        _navProvider!.setActivePage(PageId.tasks);
        break;
      case 'action_calendar':
      case 'calendar':
      case 'home':
        _navProvider!.setActivePage(PageId.home);
        break;
      case 'action_revision':
      case 'revision':
        _navProvider!.setActivePage(PageId.revision);
        break;
      case 'bin':
        _navProvider!.setActivePage(PageId.bin);
        break;
      case 'settings':
        _navProvider!.setActivePage(PageId.settings);
        break;
    }
  }
}
