import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';
import '../pages/pomodoro/components/pomodoro_exit_dialog.dart';
import 'app_exit_stub.dart'
    if (dart.library.js_interop) 'app_exit_web.dart'
    if (dart.library.io) 'app_exit_io.dart';

/// Centralized service handling application exit confirmations across Web, Windows, and Android.
///
/// - **Web**: Intercepts `beforeunload` when a Pomodoro timer is running.
/// - **Windows**: Coordinates with native title bar close (`WM_CLOSE`) and system tray quit events.
/// - **Android & In-App**: Intercepts predictive back / PopScope / `didRequestAppExit` when at root.
class AppExitService with WidgetsBindingObserver {
  AppExitService._();
  static final AppExitService instance = AppExitService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'AppRootNavigator');

  bool _initialized = false;
  late final AppExitPlatformAdapter _platformAdapter;
  bool Function()? _customRunningChecker;

  void setCustomRunningChecker(bool Function()? checker) {
    _customRunningChecker = checker;
  }

  /// Whether a Pomodoro session is currently active and requires confirmation to exit.
  bool get isPomodoroRunning {
    if (_customRunningChecker != null) {
      return _customRunningChecker!();
    }
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      try {
        final provider = context.read<PomodoroProvider>();
        return provider.isRunning;
      } catch (_) {}
    }
    return false;
  }

  /// Initialize the app exit interception service.
  void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    _platformAdapter = getAppExitPlatformAdapter();
    _platformAdapter.init(() => isPomodoroRunning);
  }

  /// Prompts the user with the confirmation dialog if a Pomodoro session is running.
  /// Returns `true` if exit is confirmed or no session is running, `false` otherwise.
  Future<bool> confirmExit({BuildContext? context}) async {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) {
      return !isPomodoroRunning;
    }
    return await confirmExitIfPomodoroRunning(ctx);
  }

  @override
  Future<ui.AppExitResponse> didRequestAppExit() async {
    if (!isPomodoroRunning) {
      return ui.AppExitResponse.exit;
    }
    final confirmed = await confirmExit();
    return confirmed ? ui.AppExitResponse.exit : ui.AppExitResponse.cancel;
  }

  /// Exits the application cleanly across all platforms.
  Future<void> exitApp() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
