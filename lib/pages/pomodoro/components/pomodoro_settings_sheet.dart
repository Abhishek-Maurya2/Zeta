import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../providers/pomodoro_provider.dart';

class PomodoroSettingsSheet extends StatelessWidget {
  const PomodoroSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) => const PomodoroSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final settings = provider.settings;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          maxWidth: 600,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.60,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.30),
                    width: 1.0,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
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
                            M3EIconButton(
                              icon: const Icon(Icons.close_rounded),
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
                                    context,
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
                                    context,
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
                                    context,
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
                                context,
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
                                    context,
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
                                    context,
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
                                    context,
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
                  ),
                ),
              ),
            ),
          ),
        ),
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
    Widget? selectedIcon,
    Widget? unselectedIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3EListItem(
      leading: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      headline: title,
      supportingText: subtitle,
      trailing: M3ESwitch(
        value: value,
        onChanged: onChanged,
        selectedIcon: selectedIcon ?? const Icon(Icons.check_rounded),
        unselectedIcon: unselectedIcon ?? const Icon(Icons.close_rounded),
      ),
      onTap: () => onChanged(!value),
    );
  }
}
