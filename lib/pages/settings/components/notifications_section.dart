import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../providers/theme_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/notification_service.dart';
import '../../../utils/haptics.dart';
import '../../../utils/app_snackbar.dart';

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
            ? 'System notifications permitted'
            : 'Permission denied — enable in system settings',
      );
    }
  }

  Future<void> _handleTestNotification(ThemeProvider themeProvider) async {
    ZetaHaptics.medium();

    // In-app sound & haptics
    themeProvider.playAlert();

    // Real system notification banner
    final sent = await NotificationService.instance.showNow(
      id: 88888,
      title: 'Zeta — Test Notification',
      body: 'Sound, haptics & system banner working correctly.',
    );

    if (!mounted) return;

    if (sent) {
      AppSnackbar.show(
        context,
        message: 'System notification sent — check your notification tray.',
        actionLabel: 'Dismiss',
        onAction: () {},
        duration: const Duration(seconds: 4),
      );
    } else {
      AppSnackbar.show(
        context,
        message: 'System notification failed. Since local_notifier was newly added, a full app restart/rebuild is required.',
        actionLabel: 'Dismiss',
        onAction: () {},
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isMasterOn = notifProvider.notificationsEnabled;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Master Toggle Card (Android M3 Expressive pill) ───────────
            M3EList(
              outerRadius: 50,
              innerRadius: 50,
              color: isMasterOn
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              itemCount: 1,
              itemBuilder: (context, index) {
                return M3EListItem(
                  headline: 'Use notifications',
                  trailing: M3ESwitch(
                    value: isMasterOn,
                    selectedIcon: const Icon(
                      Icons.notifications_active_rounded,
                      size: 16,
                    ),
                    unselectedIcon: const Icon(
                      Icons.notifications_off_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      notifProvider.setEnabled(val);
                      widget.onToast?.call(
                        val
                            ? 'Notifications turned on'
                            : 'Notifications turned off',
                      );
                    },
                  ),
                  onTap: () {
                    ZetaHaptics.light();
                    final newVal = !isMasterOn;
                    notifProvider.setEnabled(newVal);
                    widget.onToast?.call(
                      newVal
                          ? 'Notifications turned on'
                          : 'Notifications turned off',
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 50),

            // ─── 2. Grouped Sub-Settings (M3E Segmented Column) ───────────────
            Builder(
              builder: (context) {
                final items = <Widget>[
                  // Task due reminders (bell / alarm icon in thumb)
                  _buildSwitchTile(
                    context,
                    title: 'Task due time reminders',
                    subtitle: 'Alert when a task reaches its deadline',
                    value: notifProvider.taskRemindersEnabled,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.alarm_on_rounded, size: 16),
                    unselectedIcon: const Icon(
                      Icons.alarm_off_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      notifProvider.setTaskRemindersEnabled(val);
                    },
                  ),

                  // Overdue task alerts (clock / warning icon in thumb)
                  _buildSwitchTile(
                    context,
                    title: 'Overdue task alerts',
                    subtitle: 'Daily summary for tasks past deadline',
                    value: notifProvider.overdueAlertsEnabled,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.schedule_rounded, size: 16),
                    unselectedIcon: const Icon(
                      Icons.history_toggle_off_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      notifProvider.setOverdueAlertsEnabled(val);
                    },
                  ),

                  // Focus timer alerts (timer / hourglass icon in thumb)
                  _buildSwitchTile(
                    context,
                    title: 'Focus timer alerts',
                    subtitle: 'Notify on focus and break completion',
                    value: notifProvider.pomodoroAlertsEnabled,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.timer_rounded, size: 16),
                    unselectedIcon: const Icon(
                      Icons.timer_off_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      notifProvider.setPomodoroAlertsEnabled(val);
                    },
                  ),

                  // Live timer progress (ongoing progress in notification shade & Action Center)
                  _buildSwitchTile(
                    context,
                    title: 'Live timer progress',
                    subtitle: 'Ongoing progress in notification shade & Action Center',
                    value: notifProvider.pomodoroLiveEnabled,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.timelapse_rounded, size: 16),
                    unselectedIcon: const Icon(Icons.timer_outlined, size: 16),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      notifProvider.setPomodoroLiveEnabled(val);
                    },
                  ),

                  // Sound effects & chimes (speaker icon in thumb)
                  _buildSwitchTile(
                    context,
                    title: 'Sound effects & chimes',
                    subtitle: 'Audio chime on alerts and timer ends',
                    value: themeProvider.soundEffects,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.volume_up_rounded, size: 16),
                    unselectedIcon: const Icon(
                      Icons.volume_off_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      themeProvider.setSoundEffects(val);
                    },
                  ),

                  // In-app notifications (chat / banner icon in thumb)
                  _buildSwitchTile(
                    context,
                    title: 'In-app notifications',
                    subtitle: 'Display in-app toasts and snackbars',
                    value: themeProvider.notifications,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.campaign_rounded, size: 16),
                    unselectedIcon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      themeProvider.setNotifications(val);
                    },
                  ),

                  // System permission tile (Device name style)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System permission',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isMasterOn
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.38,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _permissionGranted
                                    ? 'Allowed on this device'
                                    : 'Required to display system alerts',
                                style: textTheme.bodySmall?.copyWith(
                                  color: !isMasterOn
                                      ? colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.38,
                                        )
                                      : (_permissionGranted
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_permissionChecked && !_permissionGranted)
                          M3EButton.icon(
                            icon: const Icon(Icons.lock_open_rounded, size: 14),
                            label: const Text('Allow'),
                            style: M3EButtonStyle.filled,
                            size: M3EButtonSize.sm,
                            onPressed: isMasterOn
                                ? _handleRequestPermission
                                : null,
                          )
                        else if (_permissionGranted)
                          Icon(
                            Icons.check_circle_rounded,
                            color: isMasterOn
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.38),
                            size: 20,
                          ),
                      ],
                    ),
                  ),

                  M3EListItem(
                    enabled: isMasterOn,
                    leading: Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: isMasterOn
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    headline: 'Send test notification',
                    onTap: isMasterOn
                        ? () => _handleTestNotification(themeProvider)
                        : null,
                  ),
                ];
                return M3EList(
                  outerRadius: 28.0,
                  innerRadius: 6.0,
                  gap: 3.0,
                  color: colorScheme.surfaceContainerLowest,
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── 3. Explanatory Footer with Info Icon ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When notifications are on, Zeta can alert you about upcoming task deadlines, overdue tasks, and completed Pomodoro sessions. Features like exact alarms, audio feedback, and system banners help keep you on schedule.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Widget? selectedIcon,
    Widget? unselectedIcon,
  }) {
    return M3EListItem(
      enabled: enabled,
      headline: title,
      supportingText: subtitle,
      trailing: M3ESwitch(
        value: value,
        selectedIcon: selectedIcon,
        unselectedIcon: unselectedIcon,
        onChanged: enabled ? onChanged : null,
      ),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }
}
