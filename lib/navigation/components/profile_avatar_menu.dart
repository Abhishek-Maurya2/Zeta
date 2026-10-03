import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import '../../components/user_avatar.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/revision_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/haptics.dart';

/// Interactive Profile Avatar Component:
/// - Hovering or clicking on avatar opens a Card with [surfaceContainerLowest] background.
/// - Inside the Card:
///   - Header Row: photo + Column[name, email]
///   - Segmented list (M3ESegmentedColumn): Refresh, Settings, and Bin (if on Android)
/// - Closes when mouse is no longer hovering over avatar or card (with a smooth grace timer).
/// - Scales in and out anchored from the avatar in the top app bar.
/// - In compact mode, this Card acts as a Dialog.
class ProfileAvatarMenu extends StatefulWidget {
  final Color? syncRingColor;
  final String? tooltipMessage;
  final bool? isCompact;

  const ProfileAvatarMenu({
    super.key,
    this.syncRingColor,
    this.tooltipMessage,
    this.isCompact,
  });

  @override
  State<ProfileAvatarMenu> createState() => _ProfileAvatarMenuState();
}

class _ProfileAvatarMenuState extends State<ProfileAvatarMenu>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _closeTimer;
  bool _isHoveringAvatar = false;
  bool _isHoveringCard = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _openMenu() {
    _closeTimer?.cancel();
    if (!_isOpen) {
      _isOpen = true;
      _overlayController.show();
    }
    _animController.forward();
  }

  void _closeMenu() {
    if (!_isOpen) return;
    _closeTimer?.cancel();
    _isOpen = false;
    _animController.reverse().then((_) {
      if (mounted && !_isOpen) {
        _overlayController.hide();
      }
    });
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (!_isHoveringAvatar && !_isHoveringCard) {
        _closeMenu();
      }
    });
  }

  void _handleAvatarHoverEnter() {
    _isHoveringAvatar = true;
    _closeTimer?.cancel();
    if (!_isOpen) {
      _openMenu();
    }
  }

  void _handleAvatarHoverExit() {
    _isHoveringAvatar = false;
    _startCloseTimer();
  }

  void _handleCardHoverEnter() {
    _isHoveringCard = true;
    _closeTimer?.cancel();
  }

  void _handleCardHoverExit() {
    _isHoveringCard = false;
    _startCloseTimer();
  }

  void _handleAvatarTap(BuildContext context, bool isCompact) {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  Color _resolveSyncRingColor(BuildContext context) {
    if (widget.syncRingColor != null) {
      return widget.syncRingColor!;
    }
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        revisionProvider.syncError ??
        profileProvider.syncError;
    final isSyncing =
        taskProvider.isSyncing ||
        pomodoroProvider.isSyncing ||
        revisionProvider.isSyncing ||
        profileProvider.isSyncing;
    final allSynced =
        taskProvider.lastSyncedAt != null &&
        pomodoroProvider.lastSyncedAt != null &&
        revisionProvider.lastSyncedAt != null &&
        profileProvider.lastSyncedAt != null;

    if (syncError != null) {
      return colorScheme.error;
    } else if (isSyncing) {
      return const Color(0xFFF59E0B);
    } else if (allSynced) {
      return const Color(0xFF10B981);
    } else {
      return const Color(0xFFF59E0B);
    }
  }

  Widget _buildOverlayChild(BuildContext overlayContext) {
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.topRight,
        offset: const Offset(28, -27),
        child: TapRegion(
          groupId: _tapRegionGroupId,
          onTapOutside: (_) => _closeMenu(),
          child: MouseRegion(
            onEnter: (_) => _handleCardHoverEnter(),
            onExit: (_) => _handleCardHoverExit(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topRight,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 280,
                    maxWidth: 320,
                  ),
                  child: _ProfileCardContent(
                    onDismiss: _closeMenu,
                    syncRingColor: _resolveSyncRingColor(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        revisionProvider.syncError ??
        profileProvider.syncError;

    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = widget.isCompact ?? sizeClass.isCompact;
    final syncRingColor = _resolveSyncRingColor(context);

    final isTouch =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final tooltipMsg = widget.tooltipMessage ??
        (syncError != null
            ? '${profileProvider.userName} • Sync Error: $syncError'
            : profileProvider.userName);

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlayChild,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TapRegion(
          groupId: _tapRegionGroupId,
          child: MouseRegion(
            onEnter: isTouch ? null : (_) => _handleAvatarHoverEnter(),
            onExit: isTouch ? null : (_) => _handleAvatarHoverExit(),
            child: Tooltip(
              message: tooltipMsg,
              triggerMode: TooltipTriggerMode.longPress,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _handleAvatarTap(context, isCompact),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: UserAvatar(
                      radius: 20,
                      ringWidth: 2,
                      ringColor: syncRingColor,
                      hasError: syncError != null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCardContent extends StatelessWidget {
  final VoidCallback onDismiss;
  final Color syncRingColor;

  const _ProfileCardContent({
    required this.onDismiss,
    required this.syncRingColor,
  });

  Future<void> _triggerRefresh(BuildContext context) async {
    ZetaHaptics.light();
    final taskProvider = context.read<TaskProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final revisionProvider = context.read<RevisionProvider>();

    AppSnackbar.show(
      context,
      message: 'Syncing…',
      duration: const Duration(seconds: 1),
    );

    try {
      await Future.wait([
        taskProvider.syncWithCloud(force: true),
        pomodoroProvider.syncWithCloud(force: true),
        profileProvider.syncProfileWithDb(),
        themeProvider.refreshWeather(),
        revisionProvider.refreshData(),
      ]);
      if (context.mounted) {
        final anyError = taskProvider.syncError ??
            pomodoroProvider.syncError ??
            revisionProvider.syncError ??
            profileProvider.syncError;
        if (anyError != null) {
          AppSnackbar.show(
            context,
            message: 'Sync error: $anyError',
            duration: const Duration(seconds: 4),
          );
        } else {
          AppSnackbar.show(
            context,
            message: 'Refreshed',
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Sync error: $e',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final navProvider = context.read<NavigationProvider>();

    final userName = profileProvider.userName.trim().isNotEmpty
        ? profileProvider.userName.trim()
        : 'User';
    final userEmail = profileProvider.userEmail.trim().isNotEmpty
        ? profileProvider.userEmail.trim()
        : 'No email set';

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final isDark = themeProvider.isDarkMode(context);

    // Collect all active sync errors
    final List<({String source, String error})> activeErrors = [];
    if (taskProvider.syncError != null && taskProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((source: 'Tasks', error: taskProvider.syncError!.trim()));
    }
    if (pomodoroProvider.syncError != null && pomodoroProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((source: 'Pomodoro', error: pomodoroProvider.syncError!.trim()));
    }
    if (revisionProvider.syncError != null && revisionProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((source: 'Revision', error: revisionProvider.syncError!.trim()));
    }
    if (profileProvider.syncError != null && profileProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((source: 'Profile', error: profileProvider.syncError!.trim()));
    }

    final bool hasSyncError = activeErrors.isNotEmpty;
    final primaryError = hasSyncError ? activeErrors.first : null;

    final isSyncing = taskProvider.isSyncing ||
        pomodoroProvider.isSyncing ||
        revisionProvider.isSyncing ||
        profileProvider.isSyncing;

    final allSynced = !hasSyncError &&
        taskProvider.lastSyncedAt != null &&
        pomodoroProvider.lastSyncedAt != null &&
        revisionProvider.lastSyncedAt != null &&
        profileProvider.lastSyncedAt != null;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (hasSyncError) {
      statusColor = colorScheme.error;
      statusIcon = Icons.cloud_off_rounded;
      statusLabel = 'SYNC ERROR';
    } else if (isSyncing) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.sync_rounded;
      statusLabel = 'SYNCING';
    } else if (allSynced) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.cloud_done_rounded;
      statusLabel = 'SYNCED';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.cloud_queue_rounded;
      statusLabel = 'LOCAL';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Card(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: [Name, Email] + Photo ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        radius: 28,
                        showRing: true,
                        ringWidth: 2,
                        ringColor: hasSyncError ? colorScheme.error : syncRingColor,
                        hasError: hasSyncError,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 11,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Sync Error Card (if any active error) ───────────────────
                if (hasSyncError && primaryError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(
                        alpha: isDark ? 0.35 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sync_problem_rounded,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                activeErrors.length > 1
                                    ? 'Sync Error (${activeErrors.map((e) => e.source).join(', ')})'
                                    : '${primaryError.source} Sync Error',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Tooltip(
                              message: 'Copy error message',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () async {
                                  ZetaHaptics.light();
                                  await Clipboard.setData(
                                    ClipboardData(text: primaryError.error),
                                  );
                                  if (context.mounted) {
                                    AppSnackbar.show(
                                      context,
                                      message: 'Error copied to clipboard',
                                      duration: const Duration(seconds: 2),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 13,
                                        color: colorScheme.error,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Copy',
                                        style: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Tooltip(
                          message: primaryError.error,
                          child: Text(
                            primaryError.error,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                // ─── Segmented List: Refresh, Settings, Bin ─────────────────
                Builder(
                  builder: (context) {
                    final menuItems = <Widget>[];
                    final menuActions = <VoidCallback>[];

                    // 1. Refresh Tile
                    menuItems.add(
                      M3EListItem(
                        leading: Icon(
                          hasSyncError
                              ? Icons.sync_problem_rounded
                              : (isSyncing
                                  ? Icons.sync_rounded
                                  : Icons.refresh_rounded),
                          size: 20,
                          color: hasSyncError
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        headline: hasSyncError
                            ? 'Retry Sync'
                            : (isSyncing ? 'Syncing…' : 'Refresh'),
                        supportingText: hasSyncError
                            ? 'Tap to retry failed sync'
                            : (isSyncing
                                ? 'Syncing with cloud…'
                                : null),
                      ),
                    );
                    menuActions.add(() {
                      onDismiss();
                      _triggerRefresh(context);
                    });

                    // 2. Bin Tile (if Android or compact)
                    if (isAndroid || isCompact) {
                      menuItems.add(
                        M3EListItem(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          headline: 'Bin',
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      );
                      menuActions.add(() {
                        onDismiss();
                        ZetaHaptics.selection();
                        navProvider.setActivePage(PageId.bin);
                      });
                    }

                    // 3. Settings Tile
                    menuItems.add(
                      M3EListItem(
                        leading: Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        headline: 'Settings',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    );
                    menuActions.add(() {
                      onDismiss();
                      ZetaHaptics.selection();
                      navProvider.setActivePage(PageId.settings);
                    });

                    return M3EList(
                      color: isDark
                          ? colorScheme.tertiary.withValues(alpha: 0.3)
                          : colorScheme.tertiaryFixedDim.withValues(alpha: 0.5),
                      itemCount: menuItems.length,
                      onTap: (index) => menuActions[index](),
                      itemBuilder: (context, index) => menuItems[index],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
