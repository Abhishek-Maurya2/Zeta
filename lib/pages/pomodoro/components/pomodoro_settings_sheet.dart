import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../components/glass_sheet.dart';
import '../../../components/glass_button.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../components/settings_slider_tile.dart';
import '../../../components/settings_switch_tile.dart';

class PomodoroSettingsSheet extends StatelessWidget {
  const PomodoroSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => const PomodoroSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final settings = provider.settings;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(
                alpha: 0.60,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pomodoro Settings',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
              GlassButton.icon(
                icon: const Icon(Icons.close_rounded),
                iconButtonWidth: M3EIconButtonWidth.wide,
                iconButtonVariant: M3EIconButtonVariant.standard,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Scrollable Settings Content
        Flexible(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            children: [
              // ─── 1. Cycle Durations (M3ESegmentedColumn) ───
              Text(
                'Cycle Durations',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              M3EList(
                color: colorScheme.surfaceContainerLowest
                    .withValues(alpha: 0.45),
                itemCount: 4,
                itemBuilder: (context, index) => switch (index) {
                  0 => _buildSliderTile(
                      icon: Icons.psychology_rounded,
                      title: 'Focus Duration',
                      currentLabel:
                          '${settings.focusDuration} minutes',
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
                  1 => _buildSliderTile(
                      icon: Icons.coffee_rounded,
                      title: 'Short Break Duration',
                      currentLabel:
                          '${settings.shortBreakDuration} minutes',
                      value: settings.shortBreakDuration.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${settings.shortBreakDuration}m',
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(
                            shortBreakDuration: val,
                          ),
                        );
                      },
                    ),
                  2 => _buildSliderTile(
                      icon: Icons.hotel_rounded,
                      title: 'Long Break Duration',
                      currentLabel:
                          '${settings.longBreakDuration} minutes',
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
                  _ => _buildSliderTile(
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
                },
              ),

              const SizedBox(height: 24),

              // ─── 2. Timer Display (M3EList) ───
              Text(
                'Timer Display',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              M3EList(
                color: colorScheme.surfaceContainerLowest
                    .withValues(alpha: 0.45),
                itemCount: 1,
                itemBuilder: (context, index) => _buildSwitchTile(
                  icon: Icons.timer_outlined,
                  title: 'Count up timer',
                  subtitle: 'Count up elapsed time instead of counting down',
                  value: settings.countUp,
                  selectedIcon: const Icon(
                    Icons.arrow_upward_rounded,
                  ),
                  unselectedIcon: const Icon(
                    Icons.arrow_downward_rounded,
                  ),
                  onChanged: (val) {
                    provider.updateSettings(
                      settings.copyWith(countUp: val),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ─── 3. Automation & Sound (M3EList) ───
              Text(
                'Automation & Sound',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              M3EList(
                color: colorScheme.surfaceContainerLowest
                    .withValues(alpha: 0.45),
                itemCount: 3,
                itemBuilder: (context, index) => switch (index) {
                  0 => _buildSwitchTile(
                      icon: Icons.play_arrow_rounded,
                      title: 'Auto-start breaks',
                      subtitle: 'Automatically start break timer when focus session finishes',
                      value: settings.autoStartBreaks,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(autoStartBreaks: val),
                        );
                      },
                    ),
                  1 => _buildSwitchTile(
                      icon: Icons.fast_forward_rounded,
                      title: 'Auto-start focus sessions',
                      subtitle: 'Automatically start focus timer when break finishes',
                      value: settings.autoStartFocus,
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(autoStartFocus: val),
                        );
                      },
                    ),
                  _ => _buildSwitchTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound alerts',
                      subtitle: 'Play audio chime and vibration when session completes',
                      value: settings.soundNotification,
                      selectedIcon: const Icon(
                        Icons.volume_up_rounded,
                      ),
                      unselectedIcon: const Icon(
                        Icons.volume_off_rounded,
                      ),
                      onChanged: (val) {
                        provider.updateSettings(
                          settings.copyWith(soundNotification: val),
                        );
                      },
                    ),
                },
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: M3EButton(
                  size: M3EButtonSize.sm,
                  style: M3EButtonStyle.tonal,
                  icon: Icon(
                    Icons.restore_rounded,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  onPressed: () =>
                      provider.resetToDefaultSettings(),
                  label: Text(
                    'Reset to Defaults',
                    style: textTheme.labelMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
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
    return SettingsSliderTile(
      icon: icon,
      title: title,
      currentLabel: currentLabel,
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? selectedIcon,
    Widget? unselectedIcon,
  }) {
    return SettingsSwitchTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      selectedIcon: selectedIcon ?? const Icon(Icons.check_rounded),
      unselectedIcon: unselectedIcon ?? const Icon(Icons.close_rounded),
    );
  }
}
