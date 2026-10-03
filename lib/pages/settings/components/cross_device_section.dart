import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../features/auth/presentation/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/cross_device_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/windows_tray_service.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/haptics.dart';

class CrossDeviceSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const CrossDeviceSection({super.key, this.onToast});

  @override
  State<CrossDeviceSection> createState() => _CrossDeviceSectionState();
}

class _CrossDeviceSectionState extends State<CrossDeviceSection> {
  final _prefs = PreferencesService.instance;
  final _crossDevice = CrossDeviceService.instance;

  late bool _enabled;
  late String _role;
  late bool _showToasts;
  late String _deviceName;

  // Windows tray / startup state
  late bool _minimizeToTray;
  bool _startupEnabled = false;
  bool _startupLoading = true;

  @override
  void initState() {
    super.initState();
    _enabled = _prefs.isCrossDeviceEnabled;
    _role = _prefs.crossDeviceRole;
    _showToasts = _prefs.crossDeviceShowToasts;
    _deviceName = _crossDevice.effectiveDeviceName;

    _minimizeToTray = WindowsTrayService.instance.minimizeToTray;

    if (!kIsWeb && Platform.isWindows) {
      _loadStartupState();
    } else {
      _startupLoading = false;
    }
  }

  Future<void> _loadStartupState() async {
    final enabled = await WindowsTrayService.instance.isStartupEnabled();
    if (mounted) {
      setState(() {
        _startupEnabled = enabled;
        _startupLoading = false;
      });
    }
  }

  void _toggleMaster(bool value) {
    ZetaHaptics.light();
    setState(() => _enabled = value);
    _prefs.setCrossDeviceEnabled(value);
    widget.onToast?.call(
      value ? 'Cross-device handoff enabled' : 'Cross-device handoff disabled',
    );
  }

  void _setRole(String newRole) {
    ZetaHaptics.light();
    setState(() => _role = newRole);
    _prefs.setCrossDeviceRole(newRole);
    widget.onToast?.call('Handoff mode updated');
  }

  void _toggleToasts(bool value) {
    ZetaHaptics.light();
    setState(() => _showToasts = value);
    _prefs.setCrossDeviceShowToasts(value);
  }

  Future<void> _toggleMinimizeToTray(bool value) async {
    ZetaHaptics.light();
    setState(() => _minimizeToTray = value);
    await WindowsTrayService.instance.setMinimizeToTray(value);
    widget.onToast?.call(
      value ? 'Close minimizes to tray' : 'Close will quit the app',
    );
  }

  Future<void> _toggleStartupOnBoot(bool value) async {
    ZetaHaptics.light();
    setState(() => _startupEnabled = value);
    final success = await WindowsTrayService.instance.setStartupEnabled(value);
    if (!success && mounted) {
      setState(() => _startupEnabled = !value);
      widget.onToast?.call('Failed to update startup setting');
    } else {
      widget.onToast?.call(
        value ? 'Zeta will start with Windows' : 'Startup on boot disabled',
      );
    }
  }

  Future<void> _handleEditDeviceName() async {
    ZetaHaptics.light();
    final controller = TextEditingController(text: _deviceName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Device Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Work Laptop, Android Phone',
              labelText: 'Device Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final name = controller.text.trim();
      setState(() => _deviceName = name);
      await _prefs.setCrossDeviceDeviceName(name);
      widget.onToast?.call('Device name saved');
    }
  }

  Future<void> _handleTestResume() async {
    ZetaHaptics.medium();
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.playAlert();

    await _crossDevice.sendTestResume();
    if (!mounted) return;

    AppSnackbar.show(
      context,
      message: 'Test resume triggered — check your notification tray.',
      actionLabel: 'Dismiss',
      onAction: () {},
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final isSignedIn = authProvider.status == AuthStatus.signedIn;
    final isWindows = !kIsWeb && Platform.isWindows;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Master Toggle Pill ───────────────────────────────────────
            M3EList(
              color: _enabled
                  ? colorScheme.primaryContainer
                  : colorScheme.primaryContainer.withValues(alpha: 0.5),
              itemCount: 1,
              itemBuilder: (context, index) => M3EListItem(
                leading: Icon(
                  _enabled
                      ? Icons.devices_rounded
                      : Icons.devices_other_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
                headline: 'Cross-device resume',
                trailing: M3ESwitch(
                  value: _enabled,
                  selectedIcon: const Icon(Icons.check_rounded, size: 16),
                  unselectedIcon: const Icon(Icons.close_rounded, size: 16),
                  onChanged: _toggleMaster,
                ),
                onTap: () => _toggleMaster(!_enabled),
              ),
            ),

            const SizedBox(height: 24),

            // ─── 2. Status & Account Banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSignedIn
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSignedIn
                      ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                      : colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _crossDevice.isChannelConnected,
                    builder: (context, isConnected, _) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !isSignedIn
                              ? colorScheme.error
                              : (isConnected ? Colors.green : Colors.amber),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !isSignedIn
                              ? 'Sign in required'
                              : 'Realtime Link Active',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: !isSignedIn
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !isSignedIn
                              ? 'Sign in to Supabase to enable peer handoff between devices.'
                              : 'Handoff events are broadcast securely via WebSockets with zero database row storage.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── 3. Grouped Settings Column ──────────────────────────────────
            M3EList(
              color: colorScheme.surfaceContainerLowest,
              itemCount: 4 + (isWindows ? 1 : 0),
              itemBuilder: (context, index) {
                final items = <Widget>[
                  // Device Name Tile
                  M3EListItem(
                    leading: const Icon(Icons.badge_outlined),
                    headline: 'This Device Name',
                    supportingText: _deviceName,
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: _enabled ? _handleEditDeviceName : null,
                  ),

                  // Device Role Modes
                  M3EListItem(
                    leading: const Icon(Icons.sync_alt_rounded),
                    headline: 'Handoff Mode',
                    supportingText: _role == 'both'
                        ? 'Send & Receive (Automatic)'
                        : (_role == 'send_only'
                              ? 'Send Only (Broadcaster)'
                              : 'Receive Only (Listener)'),
                    trailing: PopupMenuButton<String>(
                      initialValue: _role,
                      enabled: _enabled,
                      onSelected: _setRole,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'both',
                          child: Text('Send & Receive (Default)'),
                        ),
                        const PopupMenuItem(
                          value: 'send_only',
                          child: Text('Send Only (Phone)'),
                        ),
                        const PopupMenuItem(
                          value: 'receive_only',
                          child: Text('Receive Only (Laptop)'),
                        ),
                      ],
                    ),
                  ),

                  // Windows Desktop Toast Toggle
                  if (isWindows)
                    M3EListItem(
                      leading: const Icon(Icons.desktop_windows_outlined),
                      headline: 'Windows Desktop Notifications',
                      supportingText: 'Show system toast banner when phone activity arrives',
                      trailing: M3ESwitch(
                        value: _showToasts,
                        onChanged: _enabled ? _toggleToasts : null,
                      ),
                      onTap: _enabled
                          ? () => _toggleToasts(!_showToasts)
                          : null,
                    ),

                  // Free-tier Efficiency Indicator with dynamic Quota Saver state
                  ValueListenableBuilder<bool>(
                    valueListenable: _crossDevice.isQuotaSaverActive,
                    builder: (context, isIdle, _) {
                      return M3EListItem(
                        leading: Icon(
                          isIdle
                              ? Icons.bedtime_outlined
                              : Icons.energy_savings_leaf_outlined,
                          color: isIdle ? Colors.amber : Colors.green,
                        ),
                        headline: isIdle
                            ? 'Quota Saver: Idle Sleep (Saving Quota)'
                            : 'Supabase Free Tier Efficiency Active',
                        supportingText: isIdle
                            ? 'Broadcasts suspended after 3m of inactivity. Tap any screen to resume instantly.'
                            : 'Zero DB writes • 3m inactivity cutoff • 2m background disconnect • 30s cooldown',
                        trailing: isIdle
                            ? TextButton(
                                onPressed: () {
                                  _crossDevice.recordUserActivity();
                                },
                                child: const Text('Wake Now'),
                              )
                            : null,
                      );
                    },
                  ),

                  // Test Action
                  M3EListItem(
                    leading: Icon(
                      Icons.bolt_rounded,
                      color: colorScheme.primary,
                    ),
                    headline: 'Send Test Resume Notification',
                    supportingText:
                        'Preview the exact toast & resume handoff behavior',
                    onTap: _enabled ? _handleTestResume : null,
                  ),
                ];
                return items[index];
              },
            ),

            // ─── 4. Windows Background Section ───────────────────────────────
            if (isWindows) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'WINDOWS BACKGROUND',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              M3EList(
                color: colorScheme.surfaceContainerLowest,
                itemCount: 2,
                itemBuilder: (context, index) => index == 0
                    ? M3EListItem(
                        leading: const Icon(Icons.visibility_off_outlined),
                        headline: 'Minimize to System Tray',
                        supportingText: 'Closing the window hides Zeta to the system tray instead of quitting',
                        trailing: M3ESwitch(
                          value: _minimizeToTray,
                          onChanged: _toggleMinimizeToTray,
                        ),
                        onTap: () => _toggleMinimizeToTray(!_minimizeToTray),
                      )
                    : M3EListItem(
                        leading: const Icon(Icons.power_settings_new_rounded),
                        headline: 'Start with Windows',
                        supportingText: 'Automatically launch Zeta in the background when you sign in',
                        trailing: _startupLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : M3ESwitch(
                                value: _startupEnabled,
                                onChanged: _toggleStartupOnBoot,
                              ),
                        onTap: _startupLoading
                            ? null
                            : () => _toggleStartupOnBoot(!_startupEnabled),
                      ),
              ),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
