import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_alert_dialog.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../utils/haptics.dart';

bool _isDialogShowing = false;

/// Shows a confirmation dialog if a Pomodoro timer is currently running.
/// Returns `true` if the user confirms quitting, or if no timer is running.
Future<bool> confirmExitIfPomodoroRunning(BuildContext context) async {
  if (!context.mounted) return false;

  PomodoroProvider? provider;
  try {
    provider = context.read<PomodoroProvider>();
  } catch (_) {
    return true;
  }

  if (!provider.isRunning) {
    return true;
  }

  if (_isDialogShowing) {
    return false;
  }

  _isDialogShowing = true;
  ZetaHaptics.heavy();
  try {
    final shouldExit = await showGlassDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Session in Progress'),
        content: const Text(
          'A Pomodoro timer is actively running. Are you sure you want to stop and exit?',
        ),
        actions: [
          GlassButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          GlassButton(
            onPressed: () {
              ZetaHaptics.medium();
              Navigator.of(ctx).pop(true);
            },
            isDestructive: true,
            child: const Text('Exit Session'),
          ),
        ],
      ),
    );

    final confirmed = shouldExit ?? false;
    if (confirmed) {
      provider.pauseTimer();
    }
    return confirmed;
  } finally {
    _isDialogShowing = false;
  }
}
