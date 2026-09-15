import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';

import '../../providers/pomodoro_provider.dart';
import '../../providers/navigation_provider.dart';

class PomodoroSettingsSection extends StatelessWidget {
  final void Function(String message)? onToast;

  const PomodoroSettingsSection({super.key, this.onToast});

  @override
  Widget build(BuildContext context) {
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final navProvider = context.read<NavigationProvider>();
    final settings = pomodoroProvider.settings;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POMODORO TIMER SETTINGS',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Configure focus sessions, break lengths, automation, and audio chimes.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            M3EButton.icon(
              icon: const Icon(Icons.timer_rounded, size: 16),
              label: const Text('Go to Timer'),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              onPressed: () {
                navProvider.setActivePage(PageId.pomodoro);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ─── Durations Configuration ─────────────────────────────────────
        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            // Focus Duration
            _buildSliderRow(
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
                pomodoroProvider.updateSettings(
                  settings.copyWith(focusDuration: val),
                );
                onToast?.call('Focus duration set to $val minutes');
              },
            ),

            // Short Break Duration
            _buildSliderRow(
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
                pomodoroProvider.updateSettings(
                  settings.copyWith(shortBreakDuration: val),
                );
                onToast?.call('Short break set to $val minutes');
              },
            ),

            // Long Break Duration
            _buildSliderRow(
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
                pomodoroProvider.updateSettings(
                  settings.copyWith(longBreakDuration: val),
                );
                onToast?.call('Long break set to $val minutes');
              },
            ),

            // Long Break Interval
            _buildSliderRow(
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
                pomodoroProvider.updateSettings(
                  settings.copyWith(longBreakInterval: val),
                );
                onToast?.call('Long break interval set to $val sessions');
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Automation & Sound Switches ─────────────────────────────────
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
              subtitle: 'Automatically start break timer when focus completes',
              value: settings.autoStartBreaks,
              onChanged: (val) {
                pomodoroProvider.updateSettings(
                  settings.copyWith(autoStartBreaks: val),
                );
                onToast?.call(
                  val
                      ? 'Auto-start breaks enabled'
                      : 'Auto-start breaks disabled',
                );
              },
            ),
            _buildSwitchTile(
              context,
              icon: Icons.fast_forward_rounded,
              title: 'Auto-start focus sessions',
              subtitle: 'Automatically start focus timer when break completes',
              value: settings.autoStartFocus,
              onChanged: (val) {
                pomodoroProvider.updateSettings(
                  settings.copyWith(autoStartFocus: val),
                );
                onToast?.call(
                  val
                      ? 'Auto-start focus enabled'
                      : 'Auto-start focus disabled',
                );
              },
            ),
            _buildSwitchTile(
              context,
              icon: Icons.all_inclusive_rounded,
              title: 'Continuous auto-run',
              subtitle: 'Auto-start next queued items without manual trigger',
              value: settings.autoStartNext,
              onChanged: (val) {
                pomodoroProvider.updateSettings(
                  settings.copyWith(autoStartNext: val),
                );
                onToast?.call(
                  val ? 'Continuous run enabled' : 'Continuous run disabled',
                );
              },
            ),
            _buildSwitchTile(
              context,
              icon: Icons.skip_next_rounded,
              title: 'Skip breaks',
              subtitle:
                  'Cycle continuously through focus sessions without breaks',
              value: settings.skipBreaks,
              onChanged: (val) {
                pomodoroProvider.updateSettings(
                  settings.copyWith(skipBreaks: val),
                );
                onToast?.call(val ? 'Breaks omitted' : 'Breaks restored');
              },
            ),
            _buildSwitchTile(
              context,
              icon: Icons.volume_up_rounded,
              title: 'Sound alerts',
              subtitle: 'Play audio chime when session finishes',
              value: settings.soundNotification,
              onChanged: (val) {
                pomodoroProvider.updateSettings(
                  settings.copyWith(soundNotification: val),
                );
                onToast?.call(
                  val ? 'Sound alerts enabled' : 'Sound alerts disabled',
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text('Reset Pomodoro Defaults'),
            onPressed: () {
              pomodoroProvider.resetToDefaultSettings();
              onToast?.call('Pomodoro settings reset to defaults');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
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
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(width: 14),
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
