import 'package:flutter/foundation.dart';

/// Centralized structured logger for Zeta.
///
/// Replaces raw prints and silent catch blocks with tagged, level-aware logging.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'Zeta'}) {
    if (kDebugMode) {
      debugPrint('[$tag][DEBUG] $message');
    }
  }

  static void info(String message, {String tag = 'Zeta'}) {
    if (kDebugMode) {
      debugPrint('[$tag][INFO] $message');
    }
  }

  static void warning(String message, {String tag = 'Zeta', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$tag][WARN] $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  static void error(String message, {String tag = 'Zeta', Object? error, StackTrace? stackTrace}) {
    debugPrint('[$tag][ERROR] $message${error != null ? ' | Error: $error' : ''}');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }
}
