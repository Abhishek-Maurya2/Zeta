import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';

class NotificationsSyncSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const NotificationsSyncSection({super.key, this.onToast});

  @override
  State<NotificationsSyncSection> createState() =>
      _NotificationsSyncSectionState();
}

class _NotificationsSyncSectionState extends State<NotificationsSyncSection> {
  bool _isSyncing = false;

  Future<void> _handleManualSync(
    ThemeProvider themeProvider,
    TaskProvider taskProvider,
    PomodoroProvider pomodoroProvider,
  ) async {
    setState(() => _isSyncing = true);
    await taskProvider.syncWithCloud(force: true);
    if (!mounted) return;

    await themeProvider.performCloudSync(
      taskProvider.totalCount,
      pomodoroProvider.sessionLog.length,
    );

    setState(() => _isSyncing = false);
    widget.onToast?.call(
      'Cloud synced: ${taskProvider.totalCount} tasks synchronized with Supabase.',
    );
  }

  void _handleTestNotification(ThemeProvider themeProvider) {
    // Cross-platform sound and haptic alert (Web, Android, Windows)
    themeProvider.playAlert();

    // Expressive Material 3 SnackBar
    M3ESnackbar.show(
      context,
      message: 'Zeta Reminder: Notification test sent with chime & haptics.',
      actionLabel: 'Dismiss',
      onAction: () {},
      duration: const Duration(seconds: 4),
    );
  }

  String _formatLastSyncTime(DateTime? time) {
    if (time == null) return 'Never synced';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final syncTimeStr = _formatLastSyncTime(themeProvider.lastCloudSyncTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SMART REMINDERS & DEADLINES',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Receive proactive alerts when scheduled tasks reach their due time across Web, Windows, and Android.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // ─── Alerts & Sound Switches ──────────────────────────────────────
        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            // Due time alerts
            _buildSwitchTile(
              context,
              icon: Icons.notifications_active_rounded,
              title: 'In-App Due Time Alerts',
              subtitle: 'Display high-priority notifications when tasks reach their scheduled deadline',
              value: themeProvider.notifications,
              onChanged: (val) {
                themeProvider.setNotifications(val);
                widget.onToast?.call(
                  val
                      ? 'In-app reminders enabled'
                      : 'In-app reminders disabled',
                );
              },
            ),

            // Cross-Platform OS Notifications Test
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.desktop_windows_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Notification & Sound',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Play system alert tone, trigger haptic impact, and show reminder banner',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3EButton.icon(
                    icon: const Icon(Icons.volume_up_rounded, size: 14),
                    label: const Text('Test'),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    onPressed: () => _handleTestNotification(themeProvider),
                  ),
                ],
              ),
            ),

            // Sound feedback
            _buildSwitchTile(
              context,
              icon: Icons.volume_up_rounded,
              title: 'Sound Feedback & Chimes',
              subtitle: 'Play audio clicks and chimes on task completion and timer events',
              value: themeProvider.soundEffects,
              onChanged: (val) {
                themeProvider.setSoundEffects(val);
                widget.onToast?.call(
                  val ? 'Sound feedback enabled' : 'Sound feedback muted',
                );
              },
            ),

            // Auto-save changes
            _buildSwitchTile(
              context,
              icon: Icons.save_rounded,
              title: 'Auto-Save Workspace Changes',
              subtitle: 'Automatically persist tasks and settings to local storage immediately',
              value: themeProvider.autoSave,
              onChanged: (val) {
                themeProvider.setAutoSave(val);
                if (val) {
                  taskProvider.saveTasks();
                }
                widget.onToast?.call(
                  val ? 'Auto-save enabled' : 'Auto-save disabled',
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Cloud Sync Status Card ──────────────────────────────────────
        Text(
          'CLOUD & STORAGE BACKUP',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workspace Database Snapshot',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Status: Up to date • Last synced: $syncTimeStr (${taskProvider.totalCount} tasks, ${pomodoroProvider.sessionLog.length} sessions)',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  M3EButton.icon(
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync Now'),
                    style: M3EButtonStyle.filled,
                    size: M3EButtonSize.sm,
                    onPressed: _isSyncing
                        ? null
                        : () => _handleManualSync(
                            themeProvider,
                            taskProvider,
                            pomodoroProvider,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          M3ESwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
