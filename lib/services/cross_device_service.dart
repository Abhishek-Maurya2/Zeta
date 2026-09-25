import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../providers/navigation_provider.dart';
import 'preferences_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

/// Models an incoming cross-device handoff event from another device.
class CrossDeviceResumeEvent {
  final String deviceId;
  final String deviceName;
  final String platform;
  final PageId page;
  final String? itemId;
  final String title;
  final String? detail;
  final DateTime timestamp;

  const CrossDeviceResumeEvent({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.page,
    this.itemId,
    required this.title,
    this.detail,
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

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  NavigationProvider? _navigationProvider;

  /// Holds the most recent incoming resume request for in-app banners/dialogs
  final ValueNotifier<CrossDeviceResumeEvent?> activeResumeEvent =
      ValueNotifier<CrossDeviceResumeEvent?>(null);

  /// Connection state of the Realtime Broadcast channel
  final ValueNotifier<bool> isChannelConnected = ValueNotifier<bool>(false);

  DateTime? _lastBroadcastTime;
  String? _lastBroadcastSignature;
  Timer? _idleDebounceTimer;

  bool _initialized = false;

  void init(NavigationProvider navigationProvider) {
    if (_initialized) {
      _navigationProvider = navigationProvider;
      return;
    }
    _initialized = true;
    _navigationProvider = navigationProvider;

    _deviceId = _getOrCreateDeviceId();

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // Register notification callback for when the user clicks the toast on Windows / Android
    NotificationService.instance.onResumeAction = (pageStr, itemId) {
      final page = PageId.values.firstWhere(
        (p) => p.name == pageStr,
        orElse: () => PageId.home,
      );
      _navigationProvider?.resumeTo(page: page, itemId: itemId);
      activeResumeEvent.value = null;
    };

    // Listen to page changes to broadcast active page with smart throttling
    _navigationProvider?.addListener(_onNavigationChanged);

    // Watch authentication state changes to subscribe or unsubscribe from Realtime
    _watchAuthAndConnect();
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

  /// Handles incoming broadcast from other linked devices
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
    activeResumeEvent.value = event;

    // Show native desktop notification on Windows
    if (!kIsWeb && Platform.isWindows && prefs.crossDeviceShowToasts) {
      _showWindowsResumeToast(event);
    }
  }

  Future<void> _showWindowsResumeToast(CrossDeviceResumeEvent event) async {
    final payloadString = 'resume:${event.page.name}|${event.itemId ?? ''}';
    const title = 'Continue on Zeta';
    final body = 'Resume "${event.title}" from ${event.deviceName}';

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
  }) async {
    if (_channel == null) return;

    final event = CrossDeviceResumeEvent(
      deviceId: _deviceId,
      deviceName: effectiveDeviceName,
      platform: currentPlatformName,
      page: page,
      itemId: itemId,
      title: title,
      detail: detail,
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
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
    _idleDebounceTimer?.cancel();
    _authSubscription?.cancel();
    _unsubscribeFromChannel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }
}
