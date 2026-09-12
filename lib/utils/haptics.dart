import 'package:flutter/services.dart';

/// Centralized haptic feedback utility for Zeta.
/// Provides safe cross-platform haptic execution on Android, iOS, and other supported platforms.
class ZetaHaptics {
  ZetaHaptics._();

  /// Subtle click feedback for selections, tabs, segmented controls, navigation items, and chips.
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light tactile impact for standard buttons, icons, and toggles.
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium tactile impact for action buttons, FABs, saves, resets, and primary interactions.
  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy tactile impact for timer completions, alerts, and destructive actions.
  static void heavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Standard vibration alert.
  static void vibrate() {
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }
}
