import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

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
  final colorScheme = Theme.of(context).colorScheme;

  try {
    final shouldExit = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Session in Progress'),
        content: const Text(
          'A Pomodoro timer is actively running. Are you sure you want to stop and exit?',
        ),
        actions: [
          M3EButton(
            size: M3EButtonSize.sm,
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          M3EButton(
            size: M3EButtonSize.sm,
            style: M3EButtonStyle.filled,
            decoration: M3EButtonDecoration(
              backgroundColor: WidgetStatePropertyAll(colorScheme.error),
              foregroundColor: WidgetStatePropertyAll(colorScheme.onError),
            ),
            onPressed: () {
              ZetaHaptics.medium();
              Navigator.of(ctx).pop(true);
            },
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
