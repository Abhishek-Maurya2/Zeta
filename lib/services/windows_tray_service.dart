import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'preferences_service.dart';

/// Manages the Windows system tray icon, minimize-to-tray behavior, and
/// startup-on-boot registration.
///
/// Uses the existing `zeta/windows_title_bar` MethodChannel to communicate
/// with the native C++ runner for window hide/show operations, and the Windows
/// registry for startup-on-boot via `reg` CLI commands.
class WindowsTrayService {
  WindowsTrayService._();
  static final WindowsTrayService instance = WindowsTrayService._();

  static const MethodChannel _channel = MethodChannel('zeta/windows_title_bar');
  static const String _startupRegKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _startupValueName = 'Zeta';

  bool _initialized = false;
  bool _isWindowInTray = false;

  /// Whether the window is currently minimized/hidden to the system tray.
  bool get isWindowInTray => _isWindowInTray;

  /// Callbacks for window state transitions
  VoidCallback? onWindowRestored;
  VoidCallback? onWindowEnteredTray;

  void setInitialTrayState(bool inTray) {
    _isWindowInTray = inTray;
  }

  void setWindowInTray(bool inTray) {
    if (_isWindowInTray != inTray) {
      _isWindowInTray = inTray;
      if (inTray) {
        onWindowEnteredTray?.call();
      } else {
        onWindowRestored?.call();
      }
    }
  }

  /// Whether close → minimize-to-tray is currently active.
  bool get minimizeToTray => !kIsWeb && Platform.isWindows
      ? (PreferencesService.instance.getBool('zeta_minimize_to_tray') ?? true)
      : false;

  Future<bool> setMinimizeToTray(bool value) async {
    final result = await PreferencesService.instance.setBool('zeta_minimize_to_tray', value);
    try {
      await _channel.invokeMethod('setMinimizeToTray', {'enable': value});
    } catch (_) {}
    return result;
  }

  /// Initialize system tray support on Windows.
  /// Should be called once from the app scaffold after the engine is ready.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || !Platform.isWindows) return;
    _initialized = true;

    try {
      await _channel.invokeMethod('initTray', {
        'minimizeToTray': minimizeToTray,
      });
    } catch (e) {
      debugPrint('[WindowsTrayService] initTray failed: $e');
    }

    try {
      final bool? visible = await _channel.invokeMethod<bool>('isWindowVisible');
      if (visible != null) {
        _isWindowInTray = !visible;
      }
    } catch (_) {}

    // Listen for method calls from the native side (tray menu actions)
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'trayShow':
        // Native tray "Show", tray click, or secondary instance launch
        _isWindowInTray = false;
        onWindowRestored?.call();
        break;
      case 'trayHide':
        // Window was hidden to tray (e.g. on close)
        _isWindowInTray = true;
        onWindowEnteredTray?.call();
        break;
      case 'trayQuit':
        // Native tray "Quit" was clicked — actually exit the app.
        exit(0);
      default:
        break;
    }
  }

  /// Shows the main window if it's hidden (e.g., after minimize-to-tray).
  Future<void> showWindow() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _channel.invokeMethod('showWindow');
      _isWindowInTray = false;
      onWindowRestored?.call();
    } catch (_) {}
  }

  /// Hides the main window to system tray.
  Future<void> hideToTray() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _channel.invokeMethod('hideToTray');
      _isWindowInTray = true;
      onWindowEnteredTray?.call();
    } catch (_) {}
  }

  // ─── Startup on Boot ────────────────────────────────────────────────────────

  /// Whether Zeta is registered to start on Windows boot.
  Future<bool> isStartupEnabled() async {
    if (kIsWeb || !Platform.isWindows) return false;
    try {
      final bool? nativeResult =
          await _channel.invokeMethod<bool>('isStartupLaunchEnabled');
      if (nativeResult != null) return nativeResult;
    } catch (_) {}

    try {
      final result = await Process.run('reg', [
        'query',
        _startupRegKey,
        '/v',
        _startupValueName,
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Register or unregister Zeta from Windows startup.
  Future<bool> setStartupEnabled(bool enable) async {
    if (kIsWeb || !Platform.isWindows) return false;

    // 1. Try native method channel (in-process Win32 API)
    try {
      final bool? nativeSuccess = await _channel
          .invokeMethod<bool>('setStartupLaunchEnabled', {'enabled': enable});
      if (nativeSuccess == true) {
        await PreferencesService.instance.setBool('zeta_startup_on_boot', enable);
        return true;
      }
    } catch (_) {}

    // 2. Fallback to reg CLI command
    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        // Register with --background flag so the app starts minimized to tray
        final result = await Process.run('reg', [
          'add',
          _startupRegKey,
          '/v',
          _startupValueName,
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath" --background',
          '/f',
        ]);
        if (result.exitCode == 0) {
          await PreferencesService.instance
              .setBool('zeta_startup_on_boot', true);
          return true;
        }
      } else {
        final result = await Process.run('reg', [
          'delete',
          _startupRegKey,
          '/v',
          _startupValueName,
          '/f',
        ]);
        if (result.exitCode == 0) {
          await PreferencesService.instance
              .setBool('zeta_startup_on_boot', false);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[WindowsTrayService] setStartupEnabled error: $e');
      return false;
    }
  }
}
