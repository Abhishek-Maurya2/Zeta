import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_alert_dialog.dart';
import '../../../widgets/segmented_column.dart';
import '../../../providers/revision_provider.dart';

class RevisionSettingsSheet extends StatelessWidget {
  const RevisionSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) => const RevisionSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RevisionProvider>();
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
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.60),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                            color: colorScheme.outlineVariant.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Revision Settings',
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

                      // Scrollable content
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            // ─── Spaced Repetition Intervals ───
                            Text(
                              'Spaced Repetition Intervals',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                  

                            M3ESegmentedColumn(
                              decoration: M3ESegmentedListDecoration(
                                padding: const EdgeInsets.all(0),
                                border: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                                  width: 1.0,
                                ),
                              ),
                              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
                              children: [
                                // Stage 1
                                _buildSliderTile(
                                  context,
                                  icon: Icons.looks_one_rounded,
                                  title: 'Stage 1  ·  First Revision',
                                  currentLabel: '${settings.stage1Days} days',
                                  value: settings.stage1Days.toDouble(),
                                  min: 1,
                                  max: 30,
                                  divisions: 29,
                                  label: '${settings.stage1Days}d',
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(stage1Days: val),
                                    );
                                  },
                                ),

                                // Stage 2
                                _buildSliderTile(
                                  context,
                                  icon: Icons.looks_two_rounded,
                                  title: 'Stage 2  ·  Second Revision',
                                  currentLabel: '${settings.stage2Days} days',
                                  value: settings.stage2Days.toDouble(),
                                  min: 7,
                                  max: 30,
                                  divisions: 20,
                                  label: '${settings.stage2Days}d',
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(stage2Days: val),
                                    );
                                  },
                                ),

                                // Stage 3
                                _buildSliderTile(
                                  context,
                                  icon: Icons.looks_3_rounded,
                                  title: 'Stage 3  ·  Third Revision',
                                  currentLabel: '${settings.stage3Days} days',
                                  value: settings.stage3Days.toDouble(),
                                  min: 5,
                                  max: 90,
                                  divisions: 17,
                                  label: '${settings.stage3Days}d',
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(stage3Days: val),
                                    );
                                  },
                                ),

                                // Stage 4
                                _buildSliderTile(
                                  context,
                                  icon: Icons.looks_4_rounded,
                                  title: 'Stage 4  ·  Final Revision',
                                  currentLabel: '${settings.stage4Days} days',
                                  value: settings.stage4Days.toDouble(),
                                  min: 10,
                                  max: 180,
                                  divisions: 17,
                                  label: '${settings.stage4Days}d',
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(stage4Days: val),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ─── Automation & Tasks ───
                            Text(
                              'Automation & Tasks',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            M3ESegmentedColumn(
                              decoration: M3ESegmentedListDecoration(
                                padding: const EdgeInsets.all(1.0),
                                border: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                                  width: 1.0,
                                ),
                              ),
                              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
                              children: [
                                _buildSwitchTile(
                                  context,
                                  icon: Icons.task_alt_rounded,
                                  title: 'Sync to Tasks page',
                                  value: settings.autoCreateTasks,
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(autoCreateTasks: val),
                                    );
                                  },
                                ),
                                _buildSwitchTile(
                                  context,
                                  icon: Icons.vibration_rounded,
                                  title: 'Haptic feedback',
                                  value: settings.hapticFeedback,
                                  onChanged: (val) {
                                    provider.updateSettings(
                                      settings.copyWith(hapticFeedback: val),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Reset to defaults
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GlassButton(
                                size: M3EButtonSize.sm,
                                backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.45),
                                borderRadius: 12,
                                icon: Icon(
                                  Icons.restore_rounded,
                                  size: 20,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                onPressed: () {
                                  provider.resetToDefaultSettings();
                                },
                                child: Text(
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

  Widget _buildScheduleSummary(BuildContext context, RevisionSettings settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final stages = [
      ('Stage 1', settings.stage1Days),
      ('Stage 2', settings.stage2Days),
      ('Stage 3', settings.stage3Days),
      ('Stage 4', settings.stage4Days),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Schedule Preview',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: stages.asMap().entries.map((entry) {
              final isLast = entry.key == stages.length - 1;
              final (label, days) = entry.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${days}d',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.tertiary.withValues(alpha: 0.20),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, size: 14, color: colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  'Mastered after ${settings.stage1Days + settings.stage2Days + settings.stage3Days + settings.stage4Days} total days',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    String? subtitle,
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
                if (subtitle != null)
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
