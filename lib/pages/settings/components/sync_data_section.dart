import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/segmented_column.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../utils/haptics.dart';

class SyncDataSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const SyncDataSection({super.key, this.onToast});

  @override
  State<SyncDataSection> createState() => _SyncDataSectionState();
}

class _SyncDataSectionState extends State<SyncDataSection> {
  bool _masterSyncEnabled = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool('zeta_master_sync_enabled') ?? true;
    if (mounted) {
      setState(() {
        _masterSyncEnabled = master;
      });
    }
  }

  Future<void> _setMasterSyncEnabled(bool value) async {
    setState(() => _masterSyncEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zeta_master_sync_enabled', value);
    if (value) {
      _handleSync();
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final taskFuture = context.read<TaskProvider>().syncWithCloud(
        force: true,
      );
      final pomodoroFuture = context.read<PomodoroProvider>().syncWithCloud(
        force: true,
      );
      final profileFuture = context.read<ThemeProvider>().syncProfileWithDb();
      await Future.wait([taskFuture, pomodoroFuture, profileFuture]);
      if (!mounted) return;
      widget.onToast?.call('Cloud sync completed successfully!');
    } catch (e) {
      if (!mounted) return;
      widget.onToast?.call('Sync note: $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _exportAllData(
    BuildContext context,
    ThemeProvider themeProvider,
    TaskProvider taskProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    final fullBackup = {
      'app': 'Zeta',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'preferences': {
        'userName': themeProvider.userName,
        'userEmail': themeProvider.userEmail,
        'avatarPhoto': themeProvider.avatarPhoto,
        'themeMode': themeProvider.themeMode.name,
        'seedColor':
            '#${themeProvider.seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'useSystemColor': themeProvider.useSystemColor,
        'variant': themeProvider.variant.name,
        'highContrast': themeProvider.highContrast,
        'animations': themeProvider.animations,
        'compactDensity': themeProvider.compactDensity,
        'fontScale': themeProvider.fontScale,
        'cornerStyle': themeProvider.cornerStyle,
        'typography': {
          'headings': themeProvider.headingsTypography.toJson(),
          'titles': themeProvider.titlesTypography.toJson(),
          'body': themeProvider.bodyTypography.toJson(),
          'labels': themeProvider.labelsTypography.toJson(),
        },
        'notifications': themeProvider.notifications,
        'soundEffects': themeProvider.soundEffects,
        'autoSave': themeProvider.autoSave,
      },
      'tasks': taskProvider.allTasks.map((t) => t.toJson()).toList(),
      'binTasks': taskProvider.binTasks.map((t) => t.toJson()).toList(),
      'pomodoroSessions': pomodoroProvider.sessionLog
          .map((s) => s.toJson())
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(fullBackup);
    Clipboard.setData(ClipboardData(text: jsonStr));
    widget.onToast?.call(
      'Full backup copied to clipboard (${taskProvider.totalCount} tasks, ${pomodoroProvider.sessionLog.length} pomodoro sessions)!',
    );
  }

  void _showImportDialog(BuildContext context, ThemeProvider themeProvider) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Configuration JSON'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste a Zeta configuration JSON below to restore preferences and styling:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{\n  "userName": "...",\n  "themeMode": "dark",\n  ...\n}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            M3EButton(
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                try {
                  final parsed = jsonDecode(text) as Map<String, dynamic>;
                  final configMap =
                      parsed['preferences'] is Map<String, dynamic>
                      ? parsed['preferences'] as Map<String, dynamic>
                      : parsed;
                  final success = await themeProvider.importConfiguration(
                    configMap,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (success) {
                    widget.onToast?.call(
                      'Configuration imported successfully!',
                    );
                  } else {
                    widget.onToast?.call(
                      'Failed to parse configuration attributes',
                    );
                  }
                } catch (_) {
                  widget.onToast?.call('Invalid JSON format');
                }
              },
              child: const Text('Apply Configuration'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Workspace Configuration?'),
          content: const Text(
            'This will reset all theme preferences, appearance styling, and system settings to their initial defaults.',
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
                widget.onToast?.call(
                  'All preferences reset to factory defaults.',
                );
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final isSyncBusy =
        _isSyncing || taskProvider.isSyncing || pomodoroProvider.isSyncing;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Master Toggle Card (Android M3 Expressive pill) ───────────
            M3ESegmentedColumn(
              decoration: M3ESegmentedListDecoration(
                outerRadius: 50,
                innerRadius: 50,
                color: _masterSyncEnabled
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainer,
              ),
              onTap: (_) {
                ZetaHaptics.light();
                final newVal = !_masterSyncEnabled;
                _setMasterSyncEnabled(newVal);
                widget.onToast?.call(
                  newVal ? 'Sync turned on' : 'Sync turned off',
                );
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Use sync',
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _masterSyncEnabled
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      M3ESwitch(
                        value: _masterSyncEnabled,
                        selectedIcon: const Icon(Icons.sync_rounded, size: 16),
                        unselectedIcon: const Icon(
                          Icons.sync_disabled_rounded,
                          size: 16,
                        ),
                        onChanged: (val) {
                          ZetaHaptics.light();
                          _setMasterSyncEnabled(val);
                          widget.onToast?.call(
                            val ? 'Sync turned on' : 'Sync turned off',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // ─── 2. Grouped Sub-Settings (M3E Segmented Column) ───────────────
            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Status & Action Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final iconWidget = Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _masterSyncEnabled
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _masterSyncEnabled
                              ? Icons.sync_alt_rounded
                              : Icons.sync_disabled_rounded,
                          color: _masterSyncEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.38,
                                ),
                          size: 24,
                        ),
                      );

                      final infoWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Cloud Sync',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: _masterSyncEnabled ? 1.0 : 0.38,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: !_masterSyncEnabled
                                      ? colorScheme.surfaceContainerHighest
                                      : const Color(0xFF10B981)
                                            .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  !_masterSyncEnabled ? 'Paused' : 'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: !_masterSyncEnabled
                                        ? colorScheme.onSurfaceVariant
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !_masterSyncEnabled
                                ? 'Sync is paused. Turn on master switch to resume.'
                                : 'Auto-sync active',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: _masterSyncEnabled ? 1.0 : 0.38,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );

                      final buttonsWidget = Opacity(
                        opacity: _masterSyncEnabled ? 1.0 : 0.38,
                        child: IgnorePointer(
                          ignoring: !_masterSyncEnabled,
                          child: M3EButtonGroup(
                            type: M3EButtonGroupType.standard,
                            style: M3EButtonStyle.tonal,
                            size: M3EButtonSize.sm,
                            selectedIndex: null,
                            onSelectedIndexChanged: (index) {
                              if (!_masterSyncEnabled || isSyncBusy) return;
                              ZetaHaptics.light();
                              _handleSync();
                            },
                            actions: [
                              M3EButtonGroupAction(
                                icon: isSyncBusy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Sync'),
                                tooltip: isSyncBusy
                                    ? 'Syncing...'
                                    : 'Sync cloud data now',
                                decoration: M3EToggleButtonDecoration.styleFrom(
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor:
                                      colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      return Row(
                        children: [
                          iconWidget,
                          const SizedBox(width: 16),
                          Expanded(child: infoWidget),
                          const SizedBox(width: 8),
                          buttonsWidget,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── BACKUP & RESTORE ────────────────────────────────────────────
            Text(
              'Backup & Restore',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Export Workspace Backup (.json)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Backup',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Tasks, Sessions & Revisions',
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
                        label: const Text('JSON'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: () => _exportAllData(
                          context,
                          themeProvider,
                          taskProvider,
                          pomodoroProvider,
                        ),
                      ),
                    ],
                  ),
                ),

                // Import Configuration
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Configuration',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Restore preferences from backup',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      M3EButton.icon(
                        icon: const Icon(Icons.file_upload_outlined, size: 14),
                        label: const Text('Import'),
                        style: M3EButtonStyle.outlined,
                        size: M3EButtonSize.sm,
                        onPressed: () =>
                            _showImportDialog(context, themeProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── DATA & STORAGE ──────────────────────────────────────────────
            Text(
              'Data & Storage',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Local Storage Breakdown
                FutureBuilder<Map<String, dynamic>>(
                  future: themeProvider.calculateStorageUsage(
                    taskProvider.totalCount,
                    pomodoroProvider.sessionLog.length,
                  ),
                  builder: (context, snapshot) {
                    final storageStr =
                        snapshot.data?['formatted'] as String? ??
                        'Calculating...';
                    final keysCount = snapshot.data?['keysCount'] ?? 14;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                                  '${taskProvider.totalCount} tasks · ${pomodoroProvider.sessionLog.length} sessions · $keysCount prefs',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              storageStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Reset Preferences to Defaults
                InkWell(
                  onTap: () => _showResetDialog(context, themeProvider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                                'Resets all appearance & settings to defaults',
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
          ],
        ),
      ),
    );
  }
}
