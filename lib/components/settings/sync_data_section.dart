import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../services/supabase_service.dart';
import '../../services/google_calendar_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../utils/haptics.dart';

class SyncDataSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const SyncDataSection({super.key, this.onToast});

  @override
  State<SyncDataSection> createState() => _SyncDataSectionState();
}

class _SyncDataSectionState extends State<SyncDataSection> {
  final SupabaseService _supabase = SupabaseService();
  final GoogleCalendarService _google = GoogleCalendarService();

  late bool _syncTasks;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncTasks = _google.syncTasksEnabled;
    _loadState();
  }

  Future<void> _loadState() async {
    await _google.loadTokens();
    if (mounted) {
      setState(() {
        _syncTasks = _google.syncTasksEnabled;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final taskFuture = context.read<TaskProvider>().syncWithCloud(force: true);
      final pomodoroFuture = context.read<PomodoroProvider>().syncWithCloud(force: true);
      await Future.wait([taskFuture, pomodoroFuture]);
      if (!mounted) return;
      widget.onToast?.call('Cloud and Google sync completed successfully!');
    } catch (e) {
      if (!mounted) return;
      widget.onToast?.call('Sync note: $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleConnect() async {
    try {
      await _supabase.signInWithGoogle();
      widget.onToast?.call('Redirecting to Google Sign-In...');
    } catch (e) {
      widget.onToast?.call('Google Sign-In error: $e');
    }
  }

  Future<void> _handleDisconnect() async {
    try {
      await _supabase.signOut();
      if (mounted) setState(() {});
      widget.onToast?.call('Disconnected from Google account.');
    } catch (e) {
      widget.onToast?.call('Error disconnecting: $e');
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
      'pomodoroSessions': pomodoroProvider.sessionLog.map((s) => s.toJson()).toList(),
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
                  final configMap = parsed['preferences'] is Map<String, dynamic>
                      ? parsed['preferences'] as Map<String, dynamic>
                      : parsed;
                  final success = await themeProvider.importConfiguration(configMap);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (success) {
                    widget.onToast?.call('Configuration imported successfully!');
                  } else {
                    widget.onToast?.call('Failed to parse configuration attributes');
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
                widget.onToast?.call('All preferences reset to factory defaults.');
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

    final isConnected = _google.isConnected || _supabase.isAuthenticated;
    final accountEmail = _google.accountEmail ??
        _supabase.currentUser?.email ??
        '208akmaurya@gmail.com';
    final isSyncBusy = _isSyncing || taskProvider.isSyncing || pomodoroProvider.isSyncing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── CLOUD & GOOGLE SYNC ─────────────────────────────────────────
        Text(
          'CLOUD & GOOGLE SYNC',
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
            // Status & Action Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 450;

                  final iconWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: isConnected
                          ? const Color(0xFF4285F4)
                          : colorScheme.onSurfaceVariant,
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
                              'Cloud & Google Sync',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
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
                              color: isConnected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected
                            ? 'Synced with $accountEmail'
                            : 'Connect your Google account to sync tasks',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );

                  final buttonsWidget = M3EButtonGroup(
                    type: M3EButtonGroupType.standard,
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    selectedIndex: null,
                    onSelectedIndexChanged: (index) {
                      if (isConnected) {
                        if (index == 0) {
                          if (!isSyncBusy) {
                            ZetaHaptics.light();
                            _handleSync();
                          }
                        } else if (index == 1) {
                          ZetaHaptics.light();
                          _handleDisconnect();
                        }
                      } else {
                        if (index == 0) {
                          ZetaHaptics.light();
                          _handleConnect();
                        }
                      }
                    },
                    actions: [
                      if (isConnected) ...[
                        M3EButtonGroupAction(
                          icon: isSyncBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Sync Now'),
                          tooltip: isSyncBusy ? 'Syncing...' : 'Sync cloud data now',
                          decoration: M3EToggleButtonDecoration.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        M3EButtonGroupAction(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Disconnect',
                          decoration: M3EToggleButtonDecoration.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ] else ...[
                        M3EButtonGroupAction(
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Connect Account'),
                          decoration: M3EToggleButtonDecoration.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            iconWidget,
                            const SizedBox(width: 14),
                            Expanded(child: infoWidget),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buttonsWidget,
                      ],
                    );
                  }

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

            // Toggle Google Tasks Sync
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Google Tasks',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Bidirectional synchronization for tasks and subtasks',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: _syncTasks,
                    selectedIcon: const Icon(Icons.check_rounded),
                    unselectedIcon: const Icon(Icons.close_rounded),
                    onChanged: (val) {
                      setState(() => _syncTasks = val);
                      _google.updateSyncPreferences(tasks: val);
                      widget.onToast?.call(
                        val
                            ? 'Google Tasks sync enabled'
                            : 'Google Tasks sync disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ─── BACKUP & STORAGE MANAGEMENT ─────────────────────────────────
        Text(
          'BACKUP & STORAGE MANAGEMENT',
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
            // Export Workspace Backup (.json)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          'Export Workspace Backup (.json)',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Copy complete snapshot of tasks, pomodoro logs, and settings',
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
                    label: const Text('Export Backup'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          'Paste configuration JSON to restore preferences and colors',
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
                    onPressed: () => _showImportDialog(context, themeProvider),
                  ),
                ],
              ),
            ),

            // Local Storage Breakdown
            FutureBuilder<Map<String, dynamic>>(
              future: themeProvider.calculateStorageUsage(
                taskProvider.totalCount,
                pomodoroProvider.sessionLog.length,
              ),
              builder: (context, snapshot) {
                final storageStr =
                    snapshot.data?['formatted'] as String? ?? 'Calculating...';
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
                              '${taskProvider.totalCount} tasks • ${pomodoroProvider.sessionLog.length} pomodoro logs • $keysCount preferences active',
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
                            'Restore colors, appearance, and styling to initial defaults',
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
                      onPressed: () => _showResetDialog(context, themeProvider),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
