import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:zeta/core/core.dart';

import '../../components/user_avatar.dart';
import '../../components/glass_surface.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/breakpoints.dart';
import '../../theme/motion_tokens.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/haptics.dart';

/// Interactive Profile Avatar Component:
/// - Animates and expands from the compact avatar pill into a rich GlassSurface card,
///   matching the expressive container transform used in the home screen workload pills.
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
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _tapRegionGroupId = Object();
  late final AnimationController _transformController;
  Timer? _closeTimer;
  bool _isExpanded = false;
  bool _popupVisible = false;
  bool _isHoveringAvatar = false;
  bool _isHoveringPopup = false;
  Size _closedSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _transformController = AnimationController(
      vsync: this,
      duration: M3MotionDuration.medium3, // 350ms expressive container transform
      reverseDuration: M3MotionDuration.short4, // 200ms clean reverse
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  void _openPopup(BuildContext triggerContext) {
    _closeTimer?.cancel();
    final renderObject = triggerContext.findRenderObject();
    if (renderObject is RenderBox) {
      _closedSize = renderObject.size;
    }
    if (!_popupVisible) {
      setState(() {
        _popupVisible = true;
        _isExpanded = false;
      });
      _overlayController.show();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _popupVisible) {
        setState(() => _isExpanded = true);
        _transformController.forward();
      }
    });
  }

  void _closePopup() {
    _closeTimer?.cancel();
    if (!_popupVisible) return;
    setState(() => _isExpanded = false);
    _transformController.reverse().then((_) {
      if (mounted && !_isExpanded) {
        setState(() => _popupVisible = false);
        _overlayController.hide();
      }
    });
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (!_isHoveringAvatar && !_isHoveringPopup) {
        _closePopup();
      }
    });
  }

  void _handleAvatarHoverEnter(BuildContext context) {
    _isHoveringAvatar = true;
    _closeTimer?.cancel();
    if (!_popupVisible) {
      _openPopup(context);
    }
  }

  void _handleAvatarHoverExit() {
    _isHoveringAvatar = false;
    _scheduleClose();
  }

  void _handlePopupHoverEnter() {
    _isHoveringPopup = true;
    _closeTimer?.cancel();
  }

  void _handlePopupHoverExit() {
    _isHoveringPopup = false;
    _scheduleClose();
  }

  Color _resolveSyncRingColor(BuildContext context) {
    if (widget.syncRingColor != null) {
      return widget.syncRingColor!;
    }
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final colorScheme = context.colorScheme;

    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        profileProvider.syncError;
    final isSyncing =
        taskProvider.isSyncing ||
        pomodoroProvider.isSyncing ||
        profileProvider.isSyncing;
    final allSynced =
        taskProvider.lastSyncedAt != null &&
        pomodoroProvider.lastSyncedAt != null &&
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

  Widget _buildAvatarPill(
    BuildContext context, {
    required Color syncRingColor,
    required bool hasError,
  }) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: UserAvatar(
        radius: 20,
        ringColor: syncRingColor,
        hasError: hasError,
        shape: UserAvatarShape.gem,
        showGlow: true,
        showRing: false,
      ),
    );
  }

  Widget _buildPopup(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final maxWidth = math.min(320.0, MediaQuery.sizeOf(context).width - 24);
    final closedWidth = _closedSize.width > 0 ? _closedSize.width : 48.0;
    final closedHeight = _closedSize.height > 0 ? _closedSize.height : 48.0;

    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        profileProvider.syncError;
    final syncRingColor = _resolveSyncRingColor(context);

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topRight,
        followerAnchor: Alignment.topRight,
        offset: Offset.zero,
        child: MouseRegion(
          onEnter: (_) => _handlePopupHoverEnter(),
          onExit: (_) => _handlePopupHoverExit(),
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _closePopup();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TapRegion(
              groupId: _tapRegionGroupId,
              onTapOutside: (_) => _closePopup(),
              child: AnimatedContainer(
                duration: M3MotionDuration.medium3,
                curve: M3MotionEasing.emphasizedDecelerate,
                width: _isExpanded ? maxWidth : closedWidth,
                constraints: BoxConstraints(
                  minHeight: closedHeight,
                  maxHeight: 650,
                ),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(_isExpanded ? 24 : 16),
                  blurSigma: 12,
                  color: colorScheme.tertiaryContainer.withValues(
                    alpha: isDark ? 0.65 : 0.45,
                  ),
                  child: AnimatedSize(
                    duration: M3MotionDuration.medium3,
                    reverseDuration: M3MotionDuration.short4,
                    curve: M3MotionEasing.emphasizedDecelerate,
                    alignment: Alignment.topRight,
                    child: AnimatedSwitcher(
                      duration: M3MotionDuration.medium2,
                      switchInCurve: M3MotionEasing.emphasizedDecelerate,
                      switchOutCurve: M3MotionEasing.emphasizedAccelerate,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topRight,
                          child: child,
                        ),
                      ),
                      child: _isExpanded
                          ? _ProfileCardContent(
                              key: const ValueKey('expanded-profile'),
                              onDismiss: _closePopup,
                              syncRingColor: syncRingColor,
                            )
                          : KeyedSubtree(
                              key: const ValueKey('closed-profile'),
                              child: _buildAvatarPill(
                                context,
                                syncRingColor: syncRingColor,
                                hasError: syncError != null,
                              ),
                            ),
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

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final syncError =
        taskProvider.syncError ??
        pomodoroProvider.syncError ??
        profileProvider.syncError;

    final syncRingColor = _resolveSyncRingColor(context);
    final isTouch =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final avatarWidget = _buildAvatarPill(
      context,
      syncRingColor: syncRingColor,
      hasError: syncError != null,
    );

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildPopup,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onEnter: isTouch ? null : (_) => _handleAvatarHoverEnter(context),
          onExit: isTouch ? null : (_) => _handleAvatarHoverExit(),
          child: TapRegion(
            groupId: _tapRegionGroupId,
            child: Tooltip(
              message: widget.tooltipMessage ?? '',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (_popupVisible) {
                    _closePopup();
                  } else {
                    _openPopup(context);
                  }
                },
                child: AnimatedOpacity(
                  duration: M3MotionDuration.short4,
                  opacity: _popupVisible ? 0.0 : 1.0,
                  child: avatarWidget,
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
    super.key,
    required this.onDismiss,
    required this.syncRingColor,
  });

  Future<void> _triggerRefresh(BuildContext context) async {
    ZetaHaptics.light();
    final taskProvider = context.read<TaskProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final themeProvider = context.read<ThemeProvider>();

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
      ]);
      if (context.mounted) {
        final anyError =
            taskProvider.syncError ??
            pomodoroProvider.syncError ??
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
    final colorScheme = context.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = context.textTheme;
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
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
    if (taskProvider.syncError != null &&
        taskProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((
        source: 'Tasks',
        error: taskProvider.syncError!.trim(),
      ));
    }
    if (pomodoroProvider.syncError != null &&
        pomodoroProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((
        source: 'Pomodoro',
        error: pomodoroProvider.syncError!.trim(),
      ));
    }
    if (profileProvider.syncError != null &&
        profileProvider.syncError!.trim().isNotEmpty) {
      activeErrors.add((
        source: 'Profile',
        error: profileProvider.syncError!.trim(),
      ));
    }

    final bool hasSyncError = activeErrors.isNotEmpty;
    final primaryError = hasSyncError ? activeErrors.first : null;

    final isSyncing =
        taskProvider.isSyncing ||
        pomodoroProvider.isSyncing ||
        profileProvider.isSyncing;

    final allSynced =
        !hasSyncError &&
        taskProvider.lastSyncedAt != null &&
        pomodoroProvider.lastSyncedAt != null &&
        profileProvider.lastSyncedAt != null;

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (hasSyncError) {
      statusColor = colorScheme.error;
      statusIcon = Symbols.cloud_off_rounded;
      statusLabel = 'SYNC ERROR';
    } else if (isSyncing) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Symbols.sync_rounded;
      statusLabel = 'SYNCING';
    } else if (allSynced) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Symbols.cloud_done_rounded;
      statusLabel = 'SYNCED';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Symbols.cloud_queue_rounded;
      statusLabel = 'LOCAL';
    }

    return Padding(
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
                      showGlow: true,
                      showRing: false,
                      ringColor: hasSyncError
                          ? colorScheme.error
                          : syncRingColor,
                      hasError: hasSyncError,
                      shape: UserAvatarShape.bun,
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
                                Icon(statusIcon, size: 11, color: statusColor),
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
                            Symbols.sync_problem_rounded,
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
                                      Symbols.content_copy_rounded,
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
                            ? Symbols.sync_problem_rounded
                            : (isSyncing
                                  ? Symbols.sync_rounded
                                  : Symbols.refresh_rounded),
                        fill: 1,
                        weight: 700,
                        color: hasSyncError
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      headline: hasSyncError
                          ? 'Retry Sync'
                          : (isSyncing ? 'Syncing…' : 'Refresh'),
                      supportingText: hasSyncError
                          ? 'Tap to retry failed sync'
                          : (isSyncing ? 'Syncing with cloud…' : null),
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
                          Symbols.delete_rounded,
                          fill: 1,
                          weight: 700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        headline: 'Bin',
                        trailing: Icon(
                          Symbols.chevron_right_rounded,
                          weight: 700,

                          color: colorScheme.onSurfaceVariant,
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
                        Symbols.settings_rounded,
                        fill: 1,
                        weight: 700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      headline: 'Settings',
                      trailing: Icon(
                        Symbols.chevron_right_rounded,
                        weight: 700,

                        color: colorScheme.onSurfaceVariant,
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
        );
  }
}
