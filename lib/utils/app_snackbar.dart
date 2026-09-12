import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Centralized utility for presenting Material 3 Expressive snackbars across Zeta.
class AppSnackbar {
  AppSnackbar._();

  /// Presents a Material 3 Expressive snackbar over the nearest [Overlay].
  ///
  /// [message] is the text displayed on the snackbar.
  /// [actionLabel] and [onAction] configure an optional action button.
  /// [duration] customizes the auto-dismiss duration (defaults to theme duration, typically 4 seconds).
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    M3ESnackbar.show(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}
