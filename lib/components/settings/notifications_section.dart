import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';

class NotificationsSyncSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const NotificationsSyncSection({super.key, this.onToast});

  @override
  State<NotificationsSyncSection> createState() =>
      _NotificationsSyncSectionState();
}

class _NotificationsSyncSectionState extends State<NotificationsSyncSection> {
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  bool _systemNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.hasPermission();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _permissionChecked = true;
      });
    }
  }

  Future<void> _handleRequestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) {
      setState(() => _permissionGranted = granted);
      widget.onToast?.call(
        granted
            ? 'System notifications enabled'
            : 'Permission denied — enable in system settings',
      );
    }
  }

  void _handleTestNotification(ThemeProvider themeProvider) {
    // In-app sound & haptics
    themeProvider.playAlert();

    // Real system notification
    NotificationService.instance.showNow(
      id: 88888,
      title: 'Zeta — Test Notification',
      body: 'Sound, haptics & system banner working correctly.',
    );

    M3ESnackbar.show(
      context,
      message: 'System notification sent — check your notification tray.',
      actionLabel: 'Dismiss',
      onAction: () {},
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── System Notifications ────────────────────────────────────────
            Text(
              'System Notifications',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Enable system notifications toggle
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_rounded,
                  title: 'System Notifications',
                  subtitle: 'Task due times, overdue alerts & Pomodoro',
                  value: _systemNotificationsEnabled,
                  selectedIcon: const Icon(Icons.notifications_rounded),
                  unselectedIcon: const Icon(Icons.notifications_off_rounded),
                  onChanged: (val) {
                    setState(() => _systemNotificationsEnabled = val);
                    notifProvider.setEnabled(val);
                    widget.onToast?.call(
                      val
                          ? 'System notifications enabled'
                          : 'System notifications disabled',
                    );
                  },
                ),

                // Permission request
                if (_permissionChecked && !_permissionGranted)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 22,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permission Required',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.error,
                                ),
                              ),
                              Text(
                                'Grant permission to receive system alerts',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        M3EButton.icon(
                          icon: const Icon(Icons.lock_open_rounded, size: 14),
                          label: const Text('Allow'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          onPressed: _handleRequestPermission,
                        ),
                      ],
                    ),
                  ),

                // Test notification
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.science_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test System Notification',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Sends a real system banner to verify setup',
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
                        label: const Text('Send'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: () =>
                            _handleTestNotification(themeProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─── In-App Reminders ────────────────────────────────────────────
            Text(
              'Reminders',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
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
                  subtitle: 'Show alerts when tasks hit their deadline',
                  value: themeProvider.notifications,
                  selectedIcon: const Icon(Icons.notifications_active_rounded),
                  unselectedIcon: const Icon(Icons.notifications_off_rounded),
                  onChanged: (val) {
                    themeProvider.setNotifications(val);
                    widget.onToast?.call(
                      val
                          ? 'In-app reminders enabled'
                          : 'In-app reminders disabled',
                    );
                  },
                ),

                // Sound feedback
                _buildSwitchTile(
                  context,
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Feedback & Chimes',
                  subtitle: 'Audio feedback on task & timer events',
                  value: themeProvider.soundEffects,
                  selectedIcon: const Icon(Icons.volume_up_rounded),
                  unselectedIcon: const Icon(Icons.volume_off_rounded),
                  onChanged: (val) {
                    themeProvider.setSoundEffects(val);
                    widget.onToast?.call(
                      val
                          ? 'Sound feedback enabled'
                          : 'Sound feedback muted',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? selectedIcon,
    Widget? unselectedIcon,
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
            selectedIcon: selectedIcon ?? const Icon(Icons.check_rounded),
            unselectedIcon: unselectedIcon ?? const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
