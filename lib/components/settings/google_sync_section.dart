import 'package:material_ui/material_ui.dart';

import '../../widgets/segmented_column.dart';

class GoogleSyncSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const GoogleSyncSection({super.key, this.onToast});

  @override
  State<GoogleSyncSection> createState() => _GoogleSyncSectionState();
}

class _GoogleSyncSectionState extends State<GoogleSyncSection> {
  bool _isConnected = true;
  bool _syncCalendar = true;
  bool _syncTasks = true;
  bool _isSyncing = false;
  bool _showConfig = false;

  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController(
      text: '891240182410-abc123zeta.apps.googleusercontent.com',
    );
    _clientSecretController = TextEditingController(
      text: 'GOCSPX-zetaSecretKeyMock99281',
    );
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  void _handleSync() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      widget.onToast?.call('Google Calendar and Tasks synchronized!');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOOGLE CALENDAR & TASKS SYNC',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Two-way real-time synchronization between Zeta tasks and your Google account.',
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
                      color: _isConnected
                          ? const Color(0xFF4285F4).withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: _isConnected
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
                              'Google Account Sync',
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
                                color: _isConnected
                                    ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.15)
                                    : colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isConnected ? 'Active' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isConnected
                                      ? const Color(0xFF10B981)
                                      : colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isConnected
                              ? 'Connected as abhishek@example.com'
                              : 'Connect to sync events and tasks',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isConnected) ...[
                    M3EButton.icon(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync'),
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      onPressed: _isSyncing ? null : _handleSync,
                    ),
                    const SizedBox(width: 6),
                    M3EButton(
                      style: M3EButtonStyle.outlined,
                      size: M3EButtonSize.sm,
                      onPressed: () {
                        setState(() => _isConnected = false);
                        widget.onToast?.call('Google account disconnected');
                      },
                      child: const Text('Disconnect'),
                    ),
                  ] else ...[
                    M3EButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Connect'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.sm,
                      onPressed: () {
                        setState(() => _isConnected = true);
                        widget.onToast?.call('Google account connected');
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Toggle Calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Google Calendar Events',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Mirror due dates and revisions into Google Calendar',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: _syncCalendar,
                    onChanged: (val) {
                      setState(() => _syncCalendar = val);
                      widget.onToast?.call(
                        val
                            ? 'Calendar sync enabled'
                            : 'Calendar sync disabled',
                      );
                    },
                  ),
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
                        onPressed: () {
                          widget.onToast?.call(
                            'Google OAuth credentials updated',
                          );
                        },
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
