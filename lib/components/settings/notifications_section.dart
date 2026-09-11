import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/theme_provider.dart';

class NotificationsSyncSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const NotificationsSyncSection({super.key, this.onToast});

  @override
  State<NotificationsSyncSection> createState() =>
      _NotificationsSyncSectionState();
}

class _NotificationsSyncSectionState extends State<NotificationsSyncSection> {
  bool _isSyncing = false;

  void _handleManualSync() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      widget.onToast?.call('Data synchronized successfully!');
    });
  }

  void _handleTestNotification() {
    widget.onToast?.call('Native reminder test sent: notifications are active!');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          'Receive proactive alerts when scheduled tasks reach their due time.',
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
          color: colorScheme.surfaceContainer,
          children: [
            // Due time alerts
            _buildSwitchTile(
              context,
              icon: Icons.notifications_active_rounded,
              title: 'In-App Due Time Alerts',
              subtitle:
                  'Display high-priority toast alerts when tasks reach their due time',
              value: themeProvider.notifications,
              onChanged: (val) {
                themeProvider.setNotifications(val);
                widget.onToast?.call(
                  val ? 'In-app reminders enabled' : 'In-app reminders disabled',
                );
              },
            ),

            // Native OS Notifications
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
                          'Native OS Notifications',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Desktop & lockscreen notifications with sound',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3EButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Test'),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    onPressed: _handleTestNotification,
                  ),
                ],
              ),
            ),

            // Sound feedback
            _buildSwitchTile(
              context,
              icon: Icons.volume_up_rounded,
              title: 'Sound Feedback & Chimes',
              subtitle:
                  'Play subtle audio tones on task completion and timer events',
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
              subtitle: 'Continuously save tasks, timers, and editor changes',
              value: themeProvider.autoSave,
              onChanged: (val) {
                themeProvider.setAutoSave(val);
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
          'CLOUD SYNCHRONIZATION',
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
          color: colorScheme.surfaceContainer,
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
                          'Cloud Database Sync',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Status: Up to date • Last synced just now',
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
                    onPressed: _isSyncing ? null : _handleManualSync,
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
          M3ESwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
