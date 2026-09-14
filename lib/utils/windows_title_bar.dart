import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Helper to synchronize the native Windows window title bar (caption bar and buttons)
/// with the application theme.
class WindowsTitleBar {
  static const MethodChannel _channel = MethodChannel('zeta/windows_title_bar');

  /// Update native title bar colors and dark mode style.
  /// Uses purely asynchronous Flutter MethodChannel - 100% safe against FFI crashes.
  static void update({
    required bool isDark,
    required Color captionColor,
    required Color textColor,
  }) {
    if (kIsWeb || !Platform.isWindows) return;

    final int c = captionColor.toARGB32();
    final int r = (c >> 16) & 0xFF;
    final int g = (c >> 8) & 0xFF;
    final int b = c & 0xFF;

    final int tc = textColor.toARGB32();
    final int tr = (tc >> 16) & 0xFF;
    final int tg = (tc >> 8) & 0xFF;
    final int tb = tc & 0xFF;

    try {
      _channel.invokeMethod('updateTitleBar', {
        'isDark': isDark,
        'color': (r << 16) | (g << 8) | b,
        'textColor': (tr << 16) | (tg << 8) | tb,
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Toggle true borderless fullscreen on Windows covering taskbar and window frame.
  static Future<void> setFullscreen(bool fullscreen) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _channel.invokeMethod('setFullscreen', {'fullscreen': fullscreen});
    } catch (_) {}
  }

  /// Keep Windows awake and display on using native Win32 SetThreadExecutionState.
  static Future<void> setWakeLock(bool enable) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _channel.invokeMethod('setWakeLock', {'enable': enable});
    } catch (_) {}
  }
}
