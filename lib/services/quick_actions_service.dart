import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:quick_actions/quick_actions.dart';
import '../providers/navigation_provider.dart';

/// Manages OS-level App Launcher Shortcuts (App Shortcuts on Android/iOS and Taskbar Jump List Shortcuts on Windows).
class QuickActionsService {
  static final QuickActionsService instance = QuickActionsService._();
  QuickActionsService._();

  static const MethodChannel _windowsChannel =
      MethodChannel('zeta/windows_shortcuts');
  static const MethodChannel _androidChannel =
      MethodChannel('zeta/android_shortcuts');

  final QuickActions _quickActions = const QuickActions();
  NavigationProvider? _navProvider;
  String? _pendingShortcut;

  /// Captures initial command-line arguments passed to main(args) upon cold start.
  void setInitialArgs(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('--route=')) {
        _pendingShortcut = arg.substring(8).trim();
        break;
      } else if (arg.startsWith('/route:')) {
        _pendingShortcut = arg.substring(7).trim();
        break;
      } else if (arg == 'action_pomodoro' ||
          arg == 'action_tasks' ||
          arg == 'action_calendar' ||
          arg == 'action_revision') {
        _pendingShortcut = arg;
        break;
      }
    }
  }

  void init(NavigationProvider navProvider) {
    if (kIsWeb) return;
    _navProvider = navProvider;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      _initWindows();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      _initAndroid();
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

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

    if (_pendingShortcut != null) {
      final shortcut = _pendingShortcut!;
      _pendingShortcut = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleShortcut(shortcut);
      });
    }
  }

  void _initAndroid() {
    _androidChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcut') {
        final shortcutType = call.arguments?.toString();
        if (shortcutType != null) {
          handleShortcut(shortcutType);
        }
      }
    });

    // Check if app was launched via static shortcut intent
    _androidChannel.invokeMethod<String>('getInitialShortcut').then((shortcut) {
      if (shortcut != null && shortcut.isNotEmpty) {
        handleShortcut(shortcut);
      }
    }).catchError((_) {});
  }

  void _initWindows() {
    _windowsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcut') {
        final shortcutType = call.arguments?.toString();
        if (shortcutType != null) {
          handleShortcut(shortcutType);
        }
      }
    });

    // Ensure native Jump List is initialized
    try {
      _windowsChannel.invokeMethod('setupJumpList').catchError((_) {});
    } catch (_) {}

    // Dispatch any cold-start shortcut queued from main(args)
    if (_pendingShortcut != null) {
      final shortcut = _pendingShortcut!;
      _pendingShortcut = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleShortcut(shortcut);
      });
    }
  }

  void handleShortcut(String shortcutType) {
    if (_navProvider == null) {
      _pendingShortcut = shortcutType;
      return;
    }

    // Clean up shortcut string in case of flag prefix
    var cleanType = shortcutType.trim();
    if (cleanType.startsWith('--route=')) {
      cleanType = cleanType.substring(8);
    } else if (cleanType.startsWith('/route:')) {
      cleanType = cleanType.substring(7);
    }

    PageId? targetPage;
    switch (cleanType) {
      case 'action_pomodoro':
      case 'pomodoro':
        targetPage = PageId.pomodoro;
        break;
      case 'action_tasks':
      case 'tasks':
        targetPage = PageId.tasks;
        break;
      case 'action_calendar':
      case 'calendar':
      case 'home':
        targetPage = PageId.home;
        break;
      case 'action_revision':
      case 'revision':
        targetPage = PageId.revision;
        break;
      case 'bin':
        targetPage = PageId.bin;
        break;
      case 'settings':
        targetPage = PageId.settings;
        break;
    }

    if (targetPage != null) {
      _navProvider!.setActivePage(targetPage);
    }
  }
}
