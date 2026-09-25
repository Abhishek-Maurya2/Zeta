import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../pages/settings/components/settings_category.dart';
import '../models/task.dart';
import 'preferences_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'windows_tray_service.dart';

/// Models an incoming cross-device handoff event from another device.
class CrossDeviceResumeEvent {
  final String deviceId;
  final String deviceName;
  final String platform;
  final PageId page;
  final String? itemId;
  final String title;
  final String? detail;
  final Map<String, dynamic>? contextData;
  final DateTime timestamp;

  const CrossDeviceResumeEvent({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.page,
    this.itemId,
    required this.title,
    this.detail,
    this.contextData,
    required this.timestamp,
  });

  factory CrossDeviceResumeEvent.fromMap(Map<String, dynamic> map) {
    final pageStr = map['page'] as String? ?? 'home';
    final matchedPage = PageId.values.firstWhere(
      (p) => p.name == pageStr,
      orElse: () => PageId.home,
    );

    return CrossDeviceResumeEvent(
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Another Device',
      platform: map['platform'] as String? ?? 'unknown',
      page: matchedPage,
      itemId: map['itemId'] as String?,
      title: map['title'] as String? ?? 'Recent Activity',
      detail: map['detail'] as String?,
      contextData: map['contextData'] != null
          ? Map<String, dynamic>.from(map['contextData'] as Map)
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'page': page.name,
      'itemId': itemId,
      'title': title,
      'detail': detail,
      if (contextData != null) 'contextData': contextData,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Service that coordinates ephemeral cross-device state resume using
/// Supabase Realtime Broadcast channels (0 database row writes) and Windows toasts.
class CrossDeviceService with WidgetsBindingObserver {
  CrossDeviceService._();
  static final CrossDeviceService instance = CrossDeviceService._();

  static const String _broadcastEventName = 'resume_activity';
  static const int _notificationId = 77777;

  late final String _deviceId;
  String get deviceId => _deviceId;

  /// Tracks whether the app is currently in the foreground
  bool _isAppInForeground = true;
  bool get isAppInForeground => _isAppInForeground;

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  NavigationProvider? _navigationProvider;
  TaskProvider? _taskProvider;
  PomodoroProvider? _pomodoroProvider;

  /// Holds the most recent incoming resume request for in-app banners/dialogs
  final ValueNotifier<CrossDeviceResumeEvent?> activeResumeEvent =
      ValueNotifier<CrossDeviceResumeEvent?>(null);

  /// Holds the latest pending resume event received while Windows was hidden in tray.
  CrossDeviceResumeEvent? _latestPendingResumeEvent;
  CrossDeviceResumeEvent? get latestPendingResumeEvent => _latestPendingResumeEvent;

  /// Ensures only one toast notification is sent per background/tray session.
  bool _hasShownBackgroundNotification = false;

  /// Connection state of the Realtime Broadcast channel
  final ValueNotifier<bool> isChannelConnected = ValueNotifier<bool>(false);

  /// Inactivity duration after which outgoing broadcasts are paused to protect Supabase Free Tier quotas.
  static const Duration inactivityCutoffDuration = Duration(minutes: 3);

  Timer? _inactivityCutoffTimer;
  Timer? _backgroundDisconnectTimer;

  /// Whether the quota saver is currently active (broadcasting paused due to 3+ minutes of user inactivity).
  final ValueNotifier<bool> isQuotaSaverActive = ValueNotifier<bool>(false);

  DateTime? _lastBroadcastTime;
  String? _lastBroadcastSignature;
  Timer? _idleDebounceTimer;
  Timer? _draftDebounceTimer;

  bool _initialized = false;

  /// Records any user action (navigation, typing, app resume) to reset the 3-minute inactivity timer.
  void recordUserActivity() {
    final wasActive = isQuotaSaverActive.value;
    if (wasActive) {
      isQuotaSaverActive.value = false;
      if (kDebugMode) {
        debugPrint(
            '[CrossDeviceService] User activity detected: Quota Saver exited, broadcasts resumed.');
      }
      _ensureConnected();
    }

    _inactivityCutoffTimer?.cancel();
    _inactivityCutoffTimer = Timer(inactivityCutoffDuration, () {
      isQuotaSaverActive.value = true;
      if (kDebugMode) {
        debugPrint(
            '[CrossDeviceService] Quota Saver activated: No activity for 3 minutes. Pausing active broadcasts to preserve free tier quota.');
      }
    });
  }

  void _ensureConnected() {
    if (_channel == null && PreferencesService.instance.isCrossDeviceEnabled) {
      final user = SupabaseService().currentUser;
      if (user != null) {
        _subscribeToUserChannel(user.id);
      }
    }
  }

  void init(
    NavigationProvider navigationProvider, {
    TaskProvider? taskProvider,
    PomodoroProvider? pomodoroProvider,
  }) {
    _taskProvider = taskProvider ?? _taskProvider;
    _pomodoroProvider = pomodoroProvider ?? _pomodoroProvider;
    if (_initialized) {
      _navigationProvider = navigationProvider;
      return;
    }
    _initialized = true;
    _navigationProvider = navigationProvider;

    _deviceId = _getOrCreateDeviceId();

    // Start 3-minute inactivity timer
    recordUserActivity();

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // Register callback for when window is restored (tray click, tray menu, or app icon click)
    WindowsTrayService.instance.onWindowRestored = () {
      consumeLatestResume();
    };

    WindowsTrayService.instance.onWindowEnteredTray = () {
      onWindowEnteredTray();
    };

    // Register notification callback for when the user clicks the toast on Windows / Android
    NotificationService.instance.onResumeAction = (pageStr, itemId) {
      consumeLatestResume(fallbackPage: pageStr, fallbackItemId: itemId);
    };

    // Listen to page changes to broadcast active page with smart throttling
    _navigationProvider?.addListener(_onNavigationChanged);

    // Watch authentication state changes to subscribe or unsubscribe from Realtime
    _watchAuthAndConnect();
  }

  /// Triggers a debounced broadcast when task form draft changes
  void notifyDraftActivity() {
    recordUserActivity();
    _draftDebounceTimer?.cancel();
    _draftDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (_navigationProvider != null) {
        final activePage = _navigationProvider!.activePage;
        final draftTitle = _taskProvider?.taskFormDraft?['title'] as String?;
        final title = (draftTitle != null && draftTitle.trim().isNotEmpty)
            ? 'Drafting: $draftTitle'
            : _getTitleForPage(activePage);
        notifyActivity(
          page: activePage,
          title: title,
          immediate: true,
        );
      }
    });
  }

  void _onNavigationChanged() {
    if (_navigationProvider == null) return;
    final activePage = _navigationProvider!.activePage;
    final itemId = _navigationProvider!.resumeItemId;
    final title = _getTitleForPage(activePage);
    notifyActivity(
      page: activePage,
      itemId: itemId,
      title: title,
    );
  }

  String _getOrCreateDeviceId() {
    final prefs = PreferencesService.instance;
    var id = prefs.getString('zeta_cross_device_device_id');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      unawaited(prefs.setString('zeta_cross_device_device_id', id));
    }
    return id;
  }

  String get effectiveDeviceName {
    final custom = PreferencesService.instance.crossDeviceDeviceName;
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Phone';
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isLinux) return 'Linux PC';
    return 'Zeta Device';
  }

  String get currentPlatformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'other';
  }

  void _watchAuthAndConnect() {
    final supa = SupabaseService();
    if (!supa.isInitialized) {
      // Retry when initialized
      Future.delayed(const Duration(milliseconds: 800), _watchAuthAndConnect);
      return;
    }

    _authSubscription?.cancel();
    _authSubscription = supa.authStateChanges?.listen((state) {
      final user = state.session?.user;
      if (user != null) {
        _subscribeToUserChannel(user.id);
      } else {
        _unsubscribeFromChannel();
      }
    });

    final currentUser = supa.currentUser;
    if (currentUser != null) {
      _subscribeToUserChannel(currentUser.id);
    }
  }

  Future<void> _subscribeToUserChannel(String userId) async {
    final prefs = PreferencesService.instance;
    if (!prefs.isCrossDeviceEnabled) return;

    final client = SupabaseService().client;
    final channelName = 'user_activity:$userId';

    if (_channel != null) {
      await _unsubscribeFromChannel();
    }

    _channel = client.channel(
      channelName,
      opts: const RealtimeChannelConfig(ack: false),
    );

    _channel!.onBroadcast(
      event: _broadcastEventName,
      callback: (payload) {
        _handleIncomingBroadcast(payload);
      },
    );

    _channel!.subscribe((status, error) {
      isChannelConnected.value = (status == RealtimeSubscribeStatus.subscribed);
      if (kDebugMode) {
        debugPrint('[CrossDeviceService] Channel status: $status');
      }
    });
  }

  Future<void> _unsubscribeFromChannel() async {
    if (_channel != null) {
      try {
        final client = SupabaseService().client;
        await client.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
      isChannelConnected.value = false;
    }
  }

  /// Handles incoming broadcast from other linked devices.
  ///
  /// Implements:
  /// - Case 1: App is already in focus / opened / on desktop -> Strictly DO NOTHING.
  /// - Case 2: App is closed / in system tray -> Send toast once.
  /// - Case 3: App is in system tray -> User ignores toast and keeps working on phone
  ///           -> Keep updating state silently (no toast spam).
  void _handleIncomingBroadcast(Map<String, dynamic> payload) {
    final prefs = PreferencesService.instance;
    if (!prefs.isCrossDeviceEnabled) return;

    final role = prefs.crossDeviceRole;
    if (role == 'send_only') return;

    final incomingDeviceId = payload['deviceId'] as String?;
    if (incomingDeviceId == _deviceId) {
      // Ignore broadcast packets emitted by self
      return;
    }

    final event = CrossDeviceResumeEvent.fromMap(payload);

    if (!kIsWeb && Platform.isWindows) {
      final isHiddenInTray = WindowsTrayService.instance.isWindowInTray;

      if (!isHiddenInTray) {
        // CASE 1: App is ALREADY IN FOCUS / OPENED / MINIMIZED ON TASKBAR.
        // DO NOTHING!
        // Do NOT navigate, do NOT send toasts, do NOT disrupt user on desktop.
        if (kDebugMode) {
          debugPrint(
              '[CrossDeviceService] Case 1: Windows app is open/on desktop. Ignored incoming broadcast for ${event.title}');
        }
        return;
      }

      // CASE 2 & 3: Windows app is CLOSED / RUNNING IN SYSTEM TRAY.
      // Update latest pending resume state silently.
      _latestPendingResumeEvent = event;

      if (!_hasShownBackgroundNotification) {
        // CASE 2: First event in this tray session -> send 1 toast!
        if (prefs.crossDeviceShowToasts) {
          _showWindowsResumeToast(event);
        }
        _hasShownBackgroundNotification = true;
        if (kDebugMode) {
          debugPrint(
              '[CrossDeviceService] Case 2: Sent initial background resume toast: ${event.title}');
        }
      } else {
        // CASE 3: User ignored previous toast and continues working on Android.
        // Keep updating state silently (done above) without sending toast spam.
        if (kDebugMode) {
          debugPrint(
              '[CrossDeviceService] Case 3: Silently updated latest state to ${event.title} without toast spam.');
        }
      }
      return;
    }

    // On Android / other platforms: store event for in-app banner
    activeResumeEvent.value = event;
  }

  /// Resets the notification sent flag when window enters system tray.
  void onWindowEnteredTray() {
    _hasShownBackgroundNotification = false;
    if (kDebugMode) {
      debugPrint('[CrossDeviceService] Window entered tray. Reset notification state.');
    }
  }

  /// Consumes the latest pending resume event and navigates to it.
  /// Called when the user opens/restores the app from Notification, System Tray,
  /// or App Icon / Taskbar.
  void consumeLatestResume({String? fallbackPage, String? fallbackItemId}) {
    if (!kIsWeb && Platform.isWindows) {
      WindowsTrayService.instance.setWindowInTray(false);
    }
    _hasShownBackgroundNotification = false;

    final event = _latestPendingResumeEvent;
    _latestPendingResumeEvent = null;

    if (event != null) {
      final context = event.contextData;

      // 1. Settings Category Resume
      SettingsCategory? category;
      final categoryStr = context?['settingsCategory'] as String?;
      if (categoryStr != null) {
        category = SettingsCategory.values.firstWhere(
          (c) => c.name == categoryStr,
          orElse: () => SettingsCategory.profile,
        );
      }

      // 2. Navigate to page & settings category
      _navigationProvider?.resumeTo(
        page: event.page,
        itemId: event.itemId,
        category: category,
      );

      // 3. Pomodoro Pane / Tab Resume
      final pomodoroTab = context?['pomodoroTab'] as String?;
      if (pomodoroTab != null && _pomodoroProvider != null) {
        _pomodoroProvider!.setActiveTab(pomodoroTab);
      }

      // 4. Task Form / Edit Pane Resume
      final taskDraft = context?['taskDraft'] as Map<String, dynamic>?;
      final openedTaskId = context?['openedTaskId'] as String? ?? event.itemId;

      if (_taskProvider != null && (taskDraft != null || openedTaskId != null)) {
        Task? taskToEdit;
        if (openedTaskId != null) {
          try {
            taskToEdit =
                _taskProvider!.allTasks.firstWhere((t) => t.id == openedTaskId);
          } catch (_) {}
        }

        final initialTitle =
            taskDraft?['title'] as String? ?? taskToEdit?.title;
        final initialDesc =
            taskDraft?['description'] as String? ?? taskToEdit?.description;
        final initialDueDate = taskDraft?['dueDate'] as String?;
        final initialDueTime = taskDraft?['dueTime'] as String?;
        final initialHasTime = taskDraft?['hasTime'] as bool?;
        final subtaskTitles = (taskDraft?['subtasks'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        final initialSubtasks = subtaskTitles != null
            ? subtaskTitles
                .map((st) => Subtask(
                      id: 'st-${DateTime.now().millisecondsSinceEpoch}',
                      title: st,
                      completed: false,
                    ))
                .toList()
            : taskToEdit?.subtasks;

        _taskProvider!.openEditPane(
          task: taskToEdit,
          initialTitle: initialTitle,
          initialDescription: initialDesc,
          initialDueDate: initialDueDate,
          initialDueTime: initialDueTime,
          initialHasTime: initialHasTime,
          initialSubtasks: initialSubtasks,
        );
      }

      if (kDebugMode) {
        debugPrint(
            '[CrossDeviceService] Consumed latest resume with context: page=${event.page.name}, itemId=${event.itemId}, context=${event.contextData}');
      }
      activeResumeEvent.value = null;
    } else if (fallbackPage != null) {
      final page = PageId.values.firstWhere(
        (p) => p.name == fallbackPage,
        orElse: () => PageId.home,
      );
      _navigationProvider?.resumeTo(page: page, itemId: fallbackItemId);
      activeResumeEvent.value = null;
    }
  }

  Future<void> _showWindowsResumeToast(CrossDeviceResumeEvent event) async {
    final payloadString = 'resume:${event.page.name}|${event.itemId ?? ''}';
    const title = 'Continue on Zeta';
    String body = 'Resume "${event.title}" from ${event.deviceName}';

    final taskDraft = event.contextData?['taskDraft'] as Map<String, dynamic>?;
    if (taskDraft != null) {
      final draftTitle = taskDraft['title'] as String?;
      if (draftTitle != null && draftTitle.trim().isNotEmpty) {
        body = 'Resume drafting "$draftTitle" from ${event.deviceName}';
      } else {
        body = 'Resume creating task from ${event.deviceName}';
      }
    } else if (event.contextData?['pomodoroTab'] != null) {
      final tab = event.contextData!['pomodoroTab'] as String;
      final tabName = tab == 'analysis'
          ? 'Analysis'
          : (tab == 'queue' ? 'Up Next' : 'Timer');
      body = 'Resume Pomodoro $tabName from ${event.deviceName}';
    } else if (event.contextData?['settingsCategory'] != null) {
      final cat = event.contextData!['settingsCategory'] as String;
      body = 'Resume Settings ($cat) from ${event.deviceName}';
    }

    await NotificationService.instance.showNow(
      id: _notificationId,
      title: title,
      body: body,
      payload: payloadString,
    );
  }

  /// Dismisses the active in-app resume prompt banner
  void dismissActiveResumePrompt() {
    activeResumeEvent.value = null;
  }

  /// Accepts the active resume prompt and navigates
  void acceptActiveResumePrompt() {
    final event = activeResumeEvent.value;
    if (event != null && _navigationProvider != null) {
      _navigationProvider!.resumeTo(page: event.page, itemId: event.itemId);
      activeResumeEvent.value = null;
    }
  }

  /// Broadcasts the current device's activity with throttling
  void notifyActivity({
    required PageId page,
    String? itemId,
    required String title,
    String? detail,
    bool immediate = false,
  }) {
    recordUserActivity();

    final prefs = PreferencesService.instance;
    if (!prefs.isCrossDeviceEnabled) return;

    final role = prefs.crossDeviceRole;
    if (role == 'receive_only') return;

    final signature = '${page.name}_${itemId ?? ''}';

    // Cancel pending idle debounce timer
    _idleDebounceTimer?.cancel();

    if (immediate) {
      _performBroadcast(
        page: page,
        itemId: itemId,
        title: title,
        detail: detail,
        immediate: true,
      );
      return;
    }

    // Check throttle cooldown
    final now = DateTime.now();
    final cooldownSec = prefs.crossDeviceCooldownSec;
    if (_lastBroadcastTime != null && _lastBroadcastSignature == signature) {
      final elapsed = now.difference(_lastBroadcastTime!).inSeconds;
      if (elapsed < cooldownSec) {
        return; // Throttled
      }
    }

    // Debounce to ensure user is settled on the screen (3 seconds)
    _idleDebounceTimer = Timer(const Duration(seconds: 3), () {
      _performBroadcast(
        page: page,
        itemId: itemId,
        title: title,
        detail: detail,
      );
    });
  }

  Future<void> _performBroadcast({
    required PageId page,
    String? itemId,
    required String title,
    String? detail,
    bool immediate = false,
  }) async {
    if (_channel == null) return;

    // Check if Quota Saver is active and user didn't explicitly trigger an immediate action
    if (isQuotaSaverActive.value && !immediate) {
      if (kDebugMode) {
        debugPrint('[CrossDeviceService] Broadcast skipped: Quota Saver active.');
      }
      return;
    }

    final Map<String, dynamic> contextData = {};

    // 1. Settings Context
    if (page == PageId.settings) {
      final cat = _navigationProvider?.selectedSettingsCategory;
      if (cat != null) {
        contextData['settingsCategory'] = cat.name;
      }
    }

    // 2. Pomodoro Context
    if (page == PageId.pomodoro && _pomodoroProvider != null) {
      contextData['pomodoroTab'] = _pomodoroProvider!.activeTab;
    }

    // 3. Task Context with payload compression
    if (page == PageId.tasks && _taskProvider != null) {
      if (_taskProvider!.taskFormDraft != null) {
        final draftCopy =
            Map<String, dynamic>.from(_taskProvider!.taskFormDraft!);
        final desc = draftCopy['description'] as String?;
        if (desc != null && desc.length > 300) {
          draftCopy['description'] = '${desc.substring(0, 300)}...';
        }
        contextData['taskDraft'] = draftCopy;
      }
      if (_taskProvider!.editingTask != null) {
        contextData['openedTaskId'] = _taskProvider!.editingTask!.id;
      }
    }

    final event = CrossDeviceResumeEvent(
      deviceId: _deviceId,
      deviceName: effectiveDeviceName,
      platform: currentPlatformName,
      page: page,
      itemId: itemId,
      title: title,
      detail: detail,
      contextData: contextData.isNotEmpty ? contextData : null,
      timestamp: DateTime.now(),
    );

    try {
      await _channel!.sendBroadcastMessage(
        event: _broadcastEventName,
        payload: event.toMap(),
      );
      _lastBroadcastTime = DateTime.now();
      _lastBroadcastSignature = '${page.name}_${itemId ?? ''}';
      if (kDebugMode) {
        debugPrint('[CrossDeviceService] Sent resume broadcast: ${event.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrossDeviceService] Error sending broadcast: $e');
      }
    }
  }

  /// Sends a simulated test resume event (e.g. from the settings screen)
  Future<bool> sendTestResume() async {
    final testEvent = CrossDeviceResumeEvent(
      deviceId: 'test_simulator_${const Uuid().v4()}',
      deviceName: 'Simulated Phone',
      platform: 'android',
      page: PageId.tasks,
      itemId: null,
      title: 'Chemistry Revision Notes',
      detail: 'Focus session completed',
      timestamp: DateTime.now(),
    );

    activeResumeEvent.value = testEvent;

    if (!kIsWeb &&
        Platform.isWindows &&
        PreferencesService.instance.crossDeviceShowToasts) {
      await _showWindowsResumeToast(testEvent);
    }
    return true;
  }

  // --- WidgetsBindingObserver Lifecycle Triggers ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      _backgroundDisconnectTimer?.cancel();
      recordUserActivity();
      _ensureConnected();
      if (!kIsWeb && Platform.isWindows && WindowsTrayService.instance.isWindowInTray) {
        consumeLatestResume();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      // User minimized or left Zeta on this device: immediately flush current page state!
      if (_navigationProvider != null) {
        final activePage = _navigationProvider!.activePage;
        final title = _getTitleForPage(activePage);
        notifyActivity(
          page: activePage,
          itemId: _navigationProvider!.resumeItemId,
          title: title,
          immediate: true,
        );
      }

      // On mobile / web, disconnect Realtime channel after 2 minutes in background
      // to avoid burning free-tier WebSocket connection minutes when app is backgrounded.
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _backgroundDisconnectTimer?.cancel();
        _backgroundDisconnectTimer = Timer(const Duration(minutes: 2), () {
          if (!_isAppInForeground) {
            if (kDebugMode) {
              debugPrint(
                  '[CrossDeviceService] Phone in background for >2 min. Disconnecting Realtime to save Supabase quota.');
            }
            _unsubscribeFromChannel();
          }
        });
      }
    }
  }

  String _getTitleForPage(PageId page) {
    switch (page) {
      case PageId.home:
        return 'Overview & Dashboard';
      case PageId.tasks:
        return 'Task List';
      case PageId.revision:
        return 'Revision Cards';
      case PageId.pomodoro:
        return 'Pomodoro Timer';
      case PageId.bin:
        return 'Recycle Bin';
      case PageId.settings:
        return 'Settings';
    }
  }

  void dispose() {
    _inactivityCutoffTimer?.cancel();
    _backgroundDisconnectTimer?.cancel();
    _idleDebounceTimer?.cancel();
    _draftDebounceTimer?.cancel();
    _authSubscription?.cancel();
    _unsubscribeFromChannel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }
}
