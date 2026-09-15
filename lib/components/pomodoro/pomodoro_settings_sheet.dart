import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
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
                // ─── 1. Cycle Durations (M3ESegmentedColumn) ───
                Text(
                  'CYCLE DURATIONS',
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
                    // Focus Duration
                    _buildSliderTile(
                      context,
                      icon: Icons.psychology_rounded,
                      title: 'Focus Duration',
                      currentLabel: '${settings.focusDuration} minutes',
                      value: settings.focusDuration.toDouble(),
                      min: 5,
                      max: 90,
                      divisions: 17,
                      label: '${settings.focusDuration}m',
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(focusDuration: val),
                        );
                      },
                    ),

                    // Short Break Duration
                    _buildSliderTile(
                      context,
                      icon: Icons.coffee_rounded,
                      title: 'Short Break Duration',
                      currentLabel: '${settings.shortBreakDuration} minutes',
                      value: settings.shortBreakDuration.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${settings.shortBreakDuration}m',
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(shortBreakDuration: val),
                        );
                      },
                    ),

                    // Long Break Duration
                    _buildSliderTile(
                      context,
                      icon: Icons.hotel_rounded,
                      title: 'Long Break Duration',
                      currentLabel: '${settings.longBreakDuration} minutes',
                      value: settings.longBreakDuration.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '${settings.longBreakDuration}m',
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(longBreakDuration: val),
                        );
                      },
                    ),

                    // Long Break Interval
                    _buildSliderTile(
                      context,
                      icon: Icons.repeat_rounded,
                      title: 'Long Break Interval',
                      currentLabel:
                          'Every ${settings.longBreakInterval} focus sessions',
                      value: settings.longBreakInterval.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${settings.longBreakInterval} cycles',
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(longBreakInterval: val),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── 2. Automation & Sound (M3ESegmentedColumn) ───
                Text(
                  'AUTOMATION & SOUND',
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
                    _buildSwitchTile(
                      context,
                      icon: Icons.play_arrow_rounded,
                      title: 'Auto-start breaks',
                      subtitle:
                          'Automatically start break timer when focus session finishes',
                      value: settings.autoStartBreaks,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(autoStartBreaks: val),
                        );
                      },
                    ),

                    _buildSwitchTile(
                      context,
                      icon: Icons.fast_forward_rounded,
                      title: 'Auto-start focus sessions',
                      subtitle:
                          'Automatically start focus timer when break finishes',
                      value: settings.autoStartFocus,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(autoStartFocus: val),
                        );
                      },
                    ),

                    _buildSwitchTile(
                      context,
                      icon: Icons.all_inclusive_rounded,
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
                      icon: Icons.skip_next_rounded,
                      title: 'Skip breaks',
                      subtitle:
                          'Omit breaks to cycle continuously through focus intervals',
                      value: settings.skipBreaks,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(skipBreaks: val),
                        );
                      },
                    ),

                    _buildSwitchTile(
                      context,
                      icon: Icons.volume_up_rounded,
                      title: 'Sound alerts',
                      subtitle:
                          'Play audio chime and vibration when session completes',
                      value: settings.soundNotification,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(soundNotification: val),
                        );
                      },
                    ),
                  ],
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

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String currentLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                currentLabel,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: (newVal) => onChanged(newVal.round()),
          ),
        ],
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
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
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
