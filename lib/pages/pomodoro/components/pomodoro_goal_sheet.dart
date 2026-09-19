import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../providers/pomodoro_provider.dart';
import '../../../utils/haptics.dart';

/// Modal bottom sheet for setting the single daily focus goal.
/// Live-computes the 1-Day, 7-Day (Week), and 31-Day (Month) projections.
class PomodoroGoalSheet extends StatelessWidget {
  final PomodoroProvider provider;

  const PomodoroGoalSheet({super.key, required this.provider});

  static Future<void> show(BuildContext context, PomodoroProvider provider) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PomodoroGoalSheet(provider: provider),
    );
  }

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StatefulBuilder(
      builder: (ctx, setModalState) {
        final settings = provider.settings;
        final dailyGoal = settings.dailyGoalMinutes;
        const minVal = 15;
        const maxVal = 480; // 8 hours
        const divisions = 31; // 15 min steps
        const presets = [60, 120, 180, 240, 300];

        void updateGoal(int newVal) {
          ZetaHaptics.selection();
          provider.updateSettings(
            settings.copyWith(dailyGoalMinutes: newVal),
          );
          setModalState(() {});
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            maxWidth: 580,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 1, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Target Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Daily Target',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatDuration(dailyGoal),
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          M3ESlider(
                            value: dailyGoal
                                .clamp(minVal, maxVal)
                                .toDouble(),
                            min: minVal.toDouble(),
                            max: maxVal.toDouble(),
                            divisions: divisions,
                            label: formatDuration(dailyGoal),
                            onChanged: (val) => updateGoal(val.round()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Calculated Projections Grid
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCalculatedGoalItem(
                            label: 'Day & Week',
                            formula: '1 Day',
                            value: formatDuration(dailyGoal),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          _buildCalculatedGoalItem(
                            label: 'Month View',
                            formula: '7 Days (Week)',
                            value: formatDuration(
                              settings.monthWeeklyGoalMinutes,
                            ),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          _buildCalculatedGoalItem(
                            label: 'Year View',
                            formula: '31 Days (Month)',
                            value: formatDuration(
                              settings.yearMonthlyGoalMinutes,
                            ),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Presets
                    Text(
                      'QUICK PRESETS',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((preset) {
                        final isCurrent = dailyGoal == preset;
                        return ChoiceChip(
                          label: Text(formatDuration(preset)),
                          selected: isCurrent,
                          onSelected: (_) => updateGoal(preset),
                          labelStyle: textTheme.labelSmall?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isCurrent
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          selectedColor: colorScheme.primaryContainer,
                          backgroundColor:
                              colorScheme.surfaceContainerLowest,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Done button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalculatedGoalItem({
    required String label,
    required String formula,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        Text(
          formula,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
