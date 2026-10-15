import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_button.dart';
import '../../../components/glass_sheet.dart';
import '../../../components/settings_slider_tile.dart';
import '../../../components/settings_switch_tile.dart';
import '../../../providers/revision_provider.dart';

class RevisionSettingsSheet extends StatelessWidget {
  const RevisionSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => const RevisionSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RevisionProvider>();
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
              GlassButton.icon(
                icon: const Icon(Icons.close_rounded),
                iconButtonWidth: M3EIconButtonWidth.wide,
                iconButtonVariant: M3EIconButtonVariant.standard,
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

              M3EList(
                color: colorScheme.surfaceContainerLowest.withValues(
                  alpha: 0.45,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => switch (index) {
                  0 => _buildSliderTile(
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
                  1 => _buildSliderTile(
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
                  2 => _buildSliderTile(
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
                  _ => _buildSliderTile(
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
                },
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

              M3EList(
                color: colorScheme.surfaceContainerLowest.withValues(
                  alpha: 0.45,
                ),
                itemCount: 2,
                itemBuilder: (context, index) => index == 0
                    ? _buildSwitchTile(
                        icon: Icons.task_alt_rounded,
                        title: 'Sync to Tasks page',
                        value: settings.autoCreateTasks,
                        onChanged: (val) {
                          provider.updateSettings(
                            settings.copyWith(autoCreateTasks: val),
                          );
                        },
                      )
                    : _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        title: 'Haptic feedback',
                        value: settings.hapticFeedback,
                        onChanged: (val) {
                          provider.updateSettings(
                            settings.copyWith(hapticFeedback: val),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: M3EIconButton(
                  size: M3EIconButtonSize.md,
                  variant: M3EIconButtonVariant.filled,
                  width: M3EIconButtonWidth.wide,
                  icon: Icon(
                    Icons.restore_rounded,
                    size: 25,
                    color: colorScheme.onPrimary,
                  ),
                  haptic: M3EHapticFeedback.medium,
                  tooltip: 'Reset',
                  onPressed: () {
                    provider.resetToDefaultSettings();
                  },
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
    String? subtitle,
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
