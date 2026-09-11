import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/pomodoro_provider.dart';

class PomodoroSettingsSheet extends StatelessWidget {
  const PomodoroSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PomodoroSettingsSheet(),
    );
  }

  static const List<int> focusPresets = [15, 20, 25, 30, 45, 50];
  static const List<int> shortBreakPresets = [3, 5, 8, 10];
  static const List<int> longBreakPresets = [10, 15, 20, 30];
  static const List<int> intervalPresets = [2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final settings = provider.settings;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 600,
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pomodoro Settings',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure session durations, intervals, and automation',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Settings Content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ─── 1. Focus Session Duration ───
                _buildSectionTitle(
                  context,
                  title: 'Focus Duration',
                  subtitle: '${settings.focusDuration} minutes',
                  icon: Icons.psychology_rounded,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: focusPresets.map((mins) {
                      final isSelected = settings.focusDuration == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${mins}m'),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.updateSettings(
                              settings.copyWith(focusDuration: mins),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 2. Short Break Duration ───
                _buildSectionTitle(
                  context,
                  title: 'Short Break Duration',
                  subtitle: '${settings.shortBreakDuration} minutes',
                  icon: Icons.coffee_rounded,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: shortBreakPresets.map((mins) {
                      final isSelected = settings.shortBreakDuration == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${mins}m'),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.updateSettings(
                              settings.copyWith(shortBreakDuration: mins),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 3. Long Break Duration ───
                _buildSectionTitle(
                  context,
                  title: 'Long Break Duration',
                  subtitle: '${settings.longBreakDuration} minutes',
                  icon: Icons.hotel_rounded,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: longBreakPresets.map((mins) {
                      final isSelected = settings.longBreakDuration == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${mins}m'),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.updateSettings(
                              settings.copyWith(longBreakDuration: mins),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 4. Long Break Interval ───
                _buildSectionTitle(
                  context,
                  title: 'Long Break Interval',
                  subtitle: 'Every ${settings.longBreakInterval} focus sessions',
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: intervalPresets.map((count) {
                      final isSelected = settings.longBreakInterval == count;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$count sessions'),
                          selected: isSelected,
                          onSelected: (_) {
                            provider.updateSettings(
                              settings.copyWith(longBreakInterval: count),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // ─── 5. Automation & Preferences ───
                Text(
                  'AUTOMATION & SOUND',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSwitchTile(
                  context,
                  title: 'Auto-start breaks',
                  subtitle: 'Automatically start break timer when focus session finishes',
                  value: settings.autoStartBreaks,
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(autoStartBreaks: val),
                    );
                  },
                ),

                _buildSwitchTile(
                  context,
                  title: 'Auto-start focus sessions',
                  subtitle: 'Automatically start focus timer when break finishes',
                  value: settings.autoStartFocus,
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(autoStartFocus: val),
                    );
                  },
                ),

                _buildSwitchTile(
                  context,
                  title: 'Continuous auto-run',
                  subtitle: 'Auto-start every queue item continuously',
                  value: settings.autoStartNext,
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(autoStartNext: val),
                    );
                  },
                ),

                _buildSwitchTile(
                  context,
                  title: 'Skip breaks',
                  subtitle: 'Omit breaks to cycle continuously through focus intervals',
                  value: settings.skipBreaks,
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(skipBreaks: val),
                    );
                  },
                ),

                _buildSwitchTile(
                  context,
                  title: 'Sound alerts',
                  subtitle: 'Play audio chime and vibration when session completes',
                  value: settings.soundNotification,
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(soundNotification: val),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Reset to defaults
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => provider.resetToDefaultSettings(),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Reset to Defaults'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
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
