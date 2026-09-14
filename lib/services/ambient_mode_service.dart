import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ambient_platform_stub.dart'
    if (dart.library.js_interop) 'ambient_platform_web.dart'
    if (dart.library.io) 'ambient_platform_io.dart';

/// Central service coordinating true multi-platform fullscreen takeover
/// and keeping the device awake across Web, Windows, Android, iOS, macOS, and Linux.
class AmbientModeService {
  static final AmbientPlatformAdapter _adapter = getAmbientPlatformAdapter();
  static bool _isActive = false;

  static bool get isActive => _isActive;

  /// Register listener for platform-level fullscreen changes (e.g. user pressing Esc in browser).
  static void setPlatformFullscreenListener(
      void Function(bool isFullscreen)? callback) {
    _adapter.setFullscreenListener(callback);
  }

  /// Enter ambient mode:
  /// - Fullscreen takeover on platform:
  ///   - Web: HTML5 document.documentElement.requestFullscreen()
  ///   - Windows: Win32 borderless fullscreen covering taskbar and caption bar
  ///   - Android/iOS: immersiveSticky mode covering status bar and navigation bar
  /// - Prevent device from going to sleep:
  ///   - WakelockPlus.enable() (Android, iOS, Web, Desktop)
  ///   - Win32 SetThreadExecutionState (Windows native kernel power management)
  static Future<void> enter() async {
    if (_isActive) return;
    _isActive = true;

    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('AmbientModeService Wakelock enable error: $e');
    }

    try {
      await _adapter.enterFullscreen();
    } catch (e) {
      debugPrint('AmbientModeService Fullscreen enter error: $e');
    }
  }

  /// Exit ambient mode:
  /// - Restores platform window, taskbar, browser UI, or system status/navigation bars
  /// - Releases device wake lock
  static Future<void> exit() async {
    if (!_isActive) return;
    _isActive = false;

    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('AmbientModeService Wakelock disable error: $e');
    }

    try {
      await _adapter.exitFullscreen();
    } catch (e) {
      debugPrint('AmbientModeService Fullscreen exit error: $e');
    }
  }
}
