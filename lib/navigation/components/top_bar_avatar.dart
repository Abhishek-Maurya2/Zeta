import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/revision_provider.dart';
import '../../theme/breakpoints.dart';
import 'profile_avatar_menu.dart';

class TopBarAvatar extends StatelessWidget {
  const TopBarAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;

    // Map sync state → ring color
    final Color syncRingColor;
    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        revisionProvider.syncError ??
        profileProvider.syncError;
    final isSyncing =
        taskProvider.isSyncing ||
        pomodoroProvider.isSyncing ||
        revisionProvider.isSyncing ||
        profileProvider.isSyncing;
    final allSynced =
        taskProvider.lastSyncedAt != null &&
        pomodoroProvider.lastSyncedAt != null &&
        revisionProvider.lastSyncedAt != null &&
        profileProvider.lastSyncedAt != null;
    final String tooltipMessage;

    if (syncError != null) {
      syncRingColor = Theme.of(context).colorScheme.error;
      tooltipMessage = '${profileProvider.userName} • Sync Error: $syncError';
    } else if (isSyncing) {
      syncRingColor = const Color(0xFFF59E0B); // amber — syncing
      tooltipMessage = '${profileProvider.userName} • Syncing…';
    } else if (allSynced) {
      syncRingColor = const Color(0xFF10B981); // green — synced
      tooltipMessage = '${profileProvider.userName} • Synced';
    } else {
      syncRingColor = const Color(0xFFF59E0B); // amber — pending sync
      tooltipMessage = '${profileProvider.userName} • Waiting to sync';
    }

    return ProfileAvatarMenu(
      syncRingColor: syncRingColor,
      tooltipMessage: tooltipMessage,
      isCompact: isCompact,
    );
  }
}
