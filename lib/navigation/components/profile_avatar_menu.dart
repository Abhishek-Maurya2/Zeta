import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/segmented_column.dart';
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
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = widget.isCompact ?? sizeClass.isCompact;
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.topRight,
        offset: Offset(40, isCompact ? -33 : -35),
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
                    maxWidth: 300,
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
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = widget.isCompact ?? sizeClass.isCompact;
    final syncRingColor = _resolveSyncRingColor(context);

    final isTouch =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

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
              message: widget.tooltipMessage ?? '',
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
        AppSnackbar.show(
          context,
          message: 'Refreshed',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Refreshed',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode(context);
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Card(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: [Name, Email] + Photo ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 1, 4, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 23,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userEmail,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      UserAvatar(
                        radius: 21,
                        showRing: true,
                        ringWidth: 2,
                        ringColor: syncRingColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ─── Segmented List: Refresh, Settings, Bin ─────────────────
                M3ESegmentedColumn(
                  decoration: const M3ESegmentedListDecoration(
                    padding: EdgeInsets.all(0),
                    outerRadius: 14.0,
                    innerRadius: 6.0,
                    gap: 2.0,
                  ),
                  color: isDark
                      ? colorScheme.secondary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerLowest.withValues(
                          alpha: 0.5,
                        ),
                  children: [
                    // 1. Refresh Tile
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Refresh',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          onDismiss();
                          _triggerRefresh(context);
                        },
                      ),
                    ),

                    // 2. Bin Tile (if Android or compact)
                    if (isAndroid || isCompact)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            'Bin',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          onTap: () {
                            onDismiss();
                            ZetaHaptics.selection();
                            navProvider.setActivePage(PageId.bin);
                          },
                        ),
                      ),

                    // 3. Settings Tile
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Settings',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        onTap: () {
                          onDismiss();
                          ZetaHaptics.selection();
                          navProvider.setActivePage(PageId.settings);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
