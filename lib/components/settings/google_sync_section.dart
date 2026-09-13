import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../services/supabase_service.dart';
import '../../services/google_calendar_service.dart';
import '../../providers/task_provider.dart';

class GoogleSyncSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const GoogleSyncSection({super.key, this.onToast});

  @override
  State<GoogleSyncSection> createState() => _GoogleSyncSectionState();
}

class _GoogleSyncSectionState extends State<GoogleSyncSection> {
  final SupabaseService _supabase = SupabaseService();
  final GoogleCalendarService _google = GoogleCalendarService();

  late bool _syncTasks;
  bool _isSyncing = false;
  bool _showConfig = false;

  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _syncTasks = _google.syncTasksEnabled;

    _clientIdController = TextEditingController(
      text: '834983932254-nphb7j3vaegpnpcsn5d97dbblhrsj14f.apps.googleusercontent.com',
    );
    _clientSecretController = TextEditingController(
      text: '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',
    );

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

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      await context.read<TaskProvider>().syncWithCloud(force: true);
      if (!mounted) return;
      widget.onToast?.call('Google Tasks and Supabase synchronized!');
    } catch (e) {
      if (!mounted) return;
      widget.onToast?.call('Sync warning: $e');
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
      widget.onToast?.call('Google Sign-In note: $e');
    }
  }

  Future<void> _handleDisconnect() async {
    try {
      await _supabase.signOut();
      if (mounted) {
        setState(() {});
      }
      widget.onToast?.call('Disconnected from Google account.');
    } catch (e) {
      widget.onToast?.call('Error disconnecting: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final clientId = _clientIdController.text.trim();
      final clientSecret = _clientSecretController.text.trim();
      if (_supabase.isInitialized) {
        final userId = _supabase.effectiveUserId;
        await _supabase.client.from('google_sync_tokens').upsert({
          'user_id': userId,
          'client_id': clientId,
          'client_secret': clientSecret,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      await _google.loadTokens(forceReload: true);
      widget.onToast?.call('Google OAuth credentials updated');
    } catch (e) {
      widget.onToast?.call('Error updating credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.watch<TaskProvider>();

    final isConnected = _google.isConnected || _supabase.isAuthenticated;
    final accountEmail = _google.accountEmail ??
        _supabase.currentUser?.email ??
        '208akmaurya@gmail.com';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOOGLE TASKS SYNC',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Two-way real-time synchronization between Zeta tasks, Supabase, and Google Tasks.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // ─── Connection Status Card ──────────────────────────────────────
        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Google & Supabase Sync',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
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
                                isConnected ? 'Active' : 'Disconnected',
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
                              ? 'Connected as $accountEmail'
                              : 'Connect to sync Google Tasks',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isConnected) ...[
                    M3EButton.icon(
                      icon: (_isSyncing || taskProvider.isSyncing)
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync'),
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      onPressed: (_isSyncing || taskProvider.isSyncing)
                          ? null
                          : _handleSync,
                    ),
                    const SizedBox(width: 6),
                    M3EButton(
                      style: M3EButtonStyle.outlined,
                      size: M3EButtonSize.sm,
                      onPressed: _handleDisconnect,
                      child: const Text('Disconnect'),
                    ),
                  ] else ...[
                    M3EButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Connect'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.sm,
                      onPressed: _handleConnect,
                    ),
                  ],
                ],
              ),
            ),

            // Toggle Tasks
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
                          'Bidirectional synchronizing for checklists and subtasks',
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

        const SizedBox(height: 20),

        // ─── OAuth Configuration Expansion ───────────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _showConfig = !_showConfig),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.key_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'OAUTH CLIENT CREDENTIALS',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showConfig
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        if (_showConfig) ...[
          const SizedBox(height: 8),
          M3ESegmentedColumn(
            decoration: const M3ESegmentedListDecoration(
              padding: EdgeInsets.all(1.0),
            ),
            color: colorScheme.surfaceContainer,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _clientIdController,
                      decoration: InputDecoration(
                        labelText: 'OAuth Client ID',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientSecretController,
                      obscureText: _obscureSecret,
                      decoration: InputDecoration(
                        labelText: 'OAuth Client Secret',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _obscureSecret = !_obscureSecret),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: M3EButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Save Credentials'),
                        style: M3EButtonStyle.filled,
                        size: M3EButtonSize.sm,
                        onPressed: _saveCredentials,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
