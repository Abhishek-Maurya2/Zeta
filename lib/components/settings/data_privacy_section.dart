import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';

class DataPrivacySection extends StatelessWidget {
  final void Function(String message)? onToast;

  const DataPrivacySection({super.key, this.onToast});

  void _exportConfiguration(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final configData = {
      'app': 'Zeta',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'userName': themeProvider.userName,
      'themeMode': themeProvider.themeMode.name,
      'seedColor':
          '#${themeProvider.seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'variant': themeProvider.variant.name,
      'highContrast': themeProvider.highContrast,
      'animations': themeProvider.animations,
      'compactDensity': themeProvider.compactDensity,
      'fontChoice': themeProvider.fontChoice,
      'fontScale': themeProvider.fontScale,
      'cornerStyle': themeProvider.cornerStyle,
      'fontRoundness': themeProvider.fontRoundness,
      'fontWeight': themeProvider.fontWeight,
      'fontWidth': themeProvider.fontWidth,
      'fontSlant': themeProvider.fontSlant,
      'fontGrade': themeProvider.fontGrade,
      'notifications': themeProvider.notifications,
      'soundEffects': themeProvider.soundEffects,
      'autoSave': themeProvider.autoSave,
      'telemetry': themeProvider.telemetry,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(configData);
    Clipboard.setData(ClipboardData(text: jsonStr));
    onToast?.call('Configuration JSON copied to clipboard!');
  }

  void _showResetDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Workspace Configuration?'),
          content: const Text(
            'This will reset all theme preferences, typography optical axes, and system settings to their initial defaults.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            M3EButton(
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                themeProvider.resetDefaults();
                onToast?.call('All preferences reset to factory defaults.');
              },
              child: const Text('Reset Defaults'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA & STORAGE MANAGEMENT',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Export your preferences, inspect storage quotas, and maintain workspace data.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainer,
          children: [
            // Export Configuration
            InkWell(
              onTap: () => _exportConfiguration(context, themeProvider),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Workspace Configuration',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Copy JSON backup of current theme and workspace preferences',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    M3EButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Export JSON'),
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      onPressed: () =>
                          _exportConfiguration(context, themeProvider),
                    ),
                  ],
                ),
              ),
            ),

            // Storage Breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Storage Usage',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${taskProvider.totalCount} tasks • ${pomodoroProvider.sessionLog.length} pomodoro sessions • SharedPreferences active',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '~1.4 MB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reset Workspace Defaults
            InkWell(
              onTap: () => _showResetDialog(context, themeProvider),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.restore_page_rounded,
                      size: 22,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset All Preferences',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                          Text(
                            'Restore colors, typography, and controls to defaults',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    M3EButton(
                      style: M3EButtonStyle.outlined,
                      size: M3EButtonSize.sm,
                      onPressed: () =>
                          _showResetDialog(context, themeProvider),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Privacy & Diagnostics ───────────────────────────────────────
        Text(
          'PRIVACY & DIAGNOSTICS',
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
          color: colorScheme.surfaceContainer,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anonymous Diagnostics & Metrics',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Share performance and error telemetry to help optimize component loading times',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: themeProvider.telemetry,
                    onChanged: (val) {
                      themeProvider.setTelemetry(val);
                      onToast?.call(
                        val ? 'Telemetry enabled' : 'Telemetry disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
