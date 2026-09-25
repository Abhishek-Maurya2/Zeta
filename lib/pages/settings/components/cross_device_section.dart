import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/segmented_column.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/cross_device_service.dart';
import '../../../services/preferences_service.dart';
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

  @override
  void initState() {
    super.initState();
    _enabled = _prefs.isCrossDeviceEnabled;
    _role = _prefs.crossDeviceRole;
    _showToasts = _prefs.crossDeviceShowToasts;
    _deviceName = _crossDevice.effectiveDeviceName;
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
      message: 'Test resume triggered — check your notification tray / banner.',
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

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Master Toggle Pill ───────────────────────────────────────
            M3ESegmentedColumn(
              decoration: M3ESegmentedListDecoration(
                outerRadius: 50,
                innerRadius: 50,
                color: _enabled
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainer,
              ),
              onTap: (_) => _toggleMaster(!_enabled),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _enabled
                            ? Icons.devices_rounded
                            : Icons.devices_other_rounded,
                        color: _enabled
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cross-device resume',
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _enabled
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      M3ESwitch(
                        value: _enabled,
                        selectedIcon: const Icon(
                          Icons.check_rounded,
                          size: 16,
                        ),
                        unselectedIcon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                        ),
                        onChanged: _toggleMaster,
                      ),
                    ],
                  ),
                ),
              ],
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
            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Device Name Tile
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('This Device Name'),
                  subtitle: Text(_deviceName),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  enabled: _enabled,
                  onTap: _enabled ? _handleEditDeviceName : null,
                ),

                // Device Role Modes
                ListTile(
                  leading: const Icon(Icons.sync_alt_rounded),
                  title: const Text('Handoff Mode'),
                  subtitle: Text(
                    _role == 'both'
                        ? 'Send & Receive (Automatic)'
                        : (_role == 'send_only'
                            ? 'Send Only (Broadcaster)'
                            : 'Receive Only (Listener)'),
                  ),
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
                if (!kIsWeb && Platform.isWindows)
                  ListTile(
                    leading: const Icon(Icons.desktop_windows_outlined),
                    title: const Text('Windows Desktop Notifications'),
                    subtitle: const Text(
                      'Show system toast banner when phone activity arrives',
                    ),
                    trailing: M3ESwitch(
                      value: _showToasts,
                      onChanged: _enabled ? _toggleToasts : null,
                    ),
                    enabled: _enabled,
                    onTap: _enabled ? () => _toggleToasts(!_showToasts) : null,
                  ),

                // Free-tier Efficiency Indicator
                const ListTile(
                  leading: Icon(Icons.energy_savings_leaf_outlined),
                  title: Text('Supabase Free Tier Efficiency'),
                  subtitle: Text(
                    'Zero database writes • 30s smart cooldown & 3s idle debounce enabled',
                  ),
                  enabled: false,
                ),

                // Test Action
                ListTile(
                  leading: Icon(
                    Icons.bolt_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    'Send Test Resume Notification',
                    style: TextStyle(
                      color: _enabled ? colorScheme.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Preview the exact toast banner & resume handoff behavior',
                  ),
                  enabled: _enabled,
                  onTap: _enabled ? _handleTestResume : null,
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
