import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../theme/breakpoints.dart';
import 'profile_avatar_menu.dart';

class TopBarAvatar extends StatelessWidget {
  const TopBarAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        context.select<ProfileProvider, String>((p) => p.userName);
    final profileSyncError =
        context.select<ProfileProvider, String?>((p) => p.syncError);
    final profileIsSyncing =
        context.select<ProfileProvider, bool>((p) => p.isSyncing);
    final profileHasSynced =
        context.select<ProfileProvider, bool>((p) => p.lastSyncedAt != null);

    final taskSyncError =
        context.select<TaskProvider, String?>((p) => p.syncError);
    final taskIsSyncing =
        context.select<TaskProvider, bool>((p) => p.isSyncing);
    final taskHasSynced =
        context.select<TaskProvider, bool>((p) => p.lastSyncedAt != null);

    final pomodoroSyncError =
        context.select<PomodoroProvider, String?>((p) => p.syncError);
    final pomodoroIsSyncing =
        context.select<PomodoroProvider, bool>((p) => p.isSyncing);
    final pomodoroHasSynced =
        context.select<PomodoroProvider, bool>((p) => p.lastSyncedAt != null);

    final isCompact = ZetaWindowSizeClass.of(context).isCompact;

    // Map sync state → ring color
    final Color syncRingColor;
    final syncError = taskSyncError ?? pomodoroSyncError ?? profileSyncError;
    final isSyncing = taskIsSyncing || pomodoroIsSyncing || profileIsSyncing;
    final allSynced = taskHasSynced && pomodoroHasSynced && profileHasSynced;
    final String tooltipMessage;

    if (syncError != null) {
      syncRingColor = context.colorScheme.error;
      tooltipMessage = '$userName • Sync Error: $syncError';
    } else if (isSyncing) {
      syncRingColor = const Color(0xFFF59E0B); // amber — syncing
      tooltipMessage = '$userName • Syncing…';
    } else if (allSynced) {
      syncRingColor = const Color.fromARGB(255, 8, 227, 74); // green — synced
      tooltipMessage = '$userName • Synced';
    } else {
      syncRingColor = const Color(0xFFF59E0B); // amber — pending sync
      tooltipMessage = '$userName • Waiting to sync';
    }

    return ProfileAvatarMenu(
      syncRingColor: syncRingColor,
      tooltipMessage: tooltipMessage,
      isCompact: isCompact,
    );
  }
}
