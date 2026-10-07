import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Centralized utility for presenting Material 3 Expressive snackbars across Zeta.
class AppSnackbar {
  AppSnackbar._();

  /// Root scaffold messenger key for fallback toasts across any context/route.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'AppScaffoldMessenger');

  /// Persistent active overlay context set by AppScaffold.
  static BuildContext? rootContext;

  /// Presents a Material 3 Expressive snackbar over the nearest [Overlay].
  ///
  /// Falls back to [rootContext] or [scaffoldMessengerKey] if the provided
  /// [context] is null, unmounted, or lacks an overlay ancestor.
  static void show(
    BuildContext? context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final effectiveDuration = duration ?? const Duration(seconds: 4);

    // 1. Resolve a mounted BuildContext that has an Overlay ancestor
    BuildContext? targetContext;
    if (context != null && context.mounted) {
      if (Overlay.maybeOf(context) != null) {
        targetContext = context;
      }
    }
    if (targetContext == null && rootContext != null && rootContext!.mounted) {
      if (Overlay.maybeOf(rootContext!) != null) {
        targetContext = rootContext;
      }
    }

    if (targetContext != null) {
      try {
        M3ESnackbar.show(
          targetContext,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: effectiveDuration,
        );
        return;
      } catch (e) {
        debugPrint('AppSnackbar: M3ESnackbar.show failed: $e');
      }
    }

    // 2. Reliable fallback: Root ScaffoldMessenger (works globally without overlay dependency)
    final messenger = scaffoldMessengerKey.currentState ??
        (targetContext != null && targetContext.mounted
            ? ScaffoldMessenger.maybeOf(targetContext)
            : (context != null && context.mounted
                ? ScaffoldMessenger.maybeOf(context)
                : null));

    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: effectiveDuration,
          behavior: SnackBarBehavior.floating,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction,
                )
              : null,
        ),
      );
    }
  }
}

