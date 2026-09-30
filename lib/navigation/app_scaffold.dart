import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/quick_actions_service.dart';
import '../services/cross_device_service.dart';
import '../services/android_tasks_widget_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/haptics.dart';
import '../utils/windows_title_bar.dart';
import '../services/windows_tray_service.dart';
import '../services/app_exit_service.dart';
import '../pages/pomodoro/components/pomodoro_exit_dialog.dart';

import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/revision_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import 'components/body_pane.dart';
import 'components/floating_bottom_nav.dart';
import 'components/navigation_rail_widget.dart';
import 'components/pull_to_refresh_container.dart';
import 'components/global_shortcuts_handler.dart';
import '../components/task_edit_pane.dart';
import '../components/task_selection_toolbar.dart';
import '../components/m3e_pane_divider.dart';
import '../theme/breakpoints.dart';
import '../theme/motion_tokens.dart';
import 'top_app_bar.dart';

import 'dart:ui';

/// Adaptive scaffold mirroring Sharva's layout:
/// - Compact (<600px): M3EToolbar from material_3_expressive at bottom + full-width body
/// - Medium / Expanded (≥600px): M3ENavigationRail from material_3_expressive + body
/// - Top App Bar: Contains rail toggle button (hidden in mobile view)
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with TickerProviderStateMixin {
  /// GlobalKey used to call openSearch() / closeSearch() on the TopAppBar.
  final GlobalKey<TopAppBarWidgetState> _topBarKey =
      GlobalKey<TopAppBarWidgetState>();

  /// Root FocusNode — we return focus here after dismissing search so that
  /// subsequent shortcuts (N, R, /) work immediately without a click.
  final FocusNode _rootFocus = FocusNode(debugLabel: 'ScaffoldRoot');

  late final AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isUserPulling = false;

  static const double _targetHeight = 80.0;

  double get _refreshHeight {
    if (_refreshController.isAnimating) {
      return _refreshAnimation.value;
    }
    if (_isRefreshing) {
      return _targetHeight;
    }
    return _dragOffset;
  }

  @override
  void initState() {
    super.initState();
    _refreshController =
        AnimationController(vsync: this, duration: M3MotionDuration.medium2)
          ..addListener(() {
            setState(() {});
          });
    _refreshAnimation = Tween<double>(begin: 0.0, end: _targetHeight).animate(
      CurvedAnimation(
        parent: _refreshController,
        curve: M3MotionEasing.emphasizedDecelerate,
      ),
    );

    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final nav = context.read<NavigationProvider>();
        final taskProvider = context.read<TaskProvider>();
        final pomodoroProvider = context.read<PomodoroProvider>();
        QuickActionsService.instance.init(nav);
        CrossDeviceService.instance.init(
          nav,
          taskProvider: taskProvider,
          pomodoroProvider: pomodoroProvider,
        );
        WindowsTrayService.instance.init();
        unawaited(AndroidTasksWidgetService.instance.initialize(context));
      }
    });
  }

  @override
  void dispose() {
    AndroidTasksWidgetService.instance.dispose();
    _refreshController.dispose();
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
    _rootFocus.dispose();
    super.dispose();
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    final nav = context.read<NavigationProvider>();
    if (nav.activePage == PageId.settings) return;

    final initialOffset = _dragOffset;
    setState(() {
      _isRefreshing = true;
      _isUserPulling = false;
      _dragOffset = _targetHeight;
    });
    ZetaHaptics.medium();

    final taskProvider = context.read<TaskProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final revisionProvider = context.read<RevisionProvider>();

    if (initialOffset < _targetHeight) {
      _refreshAnimation =
          Tween<double>(
            begin: initialOffset > 0 ? initialOffset : 0.0,
            end: _targetHeight,
          ).animate(
            CurvedAnimation(
              parent: _refreshController,
              curve: M3MotionEasing.emphasizedDecelerate,
            ),
          );
      await _refreshController.forward(from: 0.0);
    } else {
      _refreshController.value = 1.0;
    }

    try {
      final minDelay = Future.delayed(const Duration(milliseconds: 1400));
      await Future.wait([
        taskProvider.syncWithCloud(force: true),
        pomodoroProvider.syncWithCloud(force: true),
        profileProvider.syncProfileWithDb(),
        themeProvider.refreshWeather(),
        revisionProvider.refreshData(),
        minDelay,
      ]);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (!mounted) return;
    ZetaHaptics.light();

    _refreshAnimation = Tween<double>(begin: _targetHeight, end: 0.0).animate(
      CurvedAnimation(
        parent: _refreshController,
        curve: M3MotionEasing.emphasizedAccelerate,
      ),
    );
    await _refreshController.forward(from: 0.0);

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _dragOffset = 0.0;
      });
      AppSnackbar.show(
        context,
        message: 'Refreshed',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _snapBackToZero() {
    if (_dragOffset <= 0.0) return;
    _refreshAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _refreshController,
        curve: M3MotionEasing.emphasizedDecelerate,
      ),
    );
    _refreshController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;
    final nav = context.read<NavigationProvider>();
    if (nav.activePage == PageId.settings) return false;

    // 1. Only listen to primary vertical scroll notifications.
    // notification.depth != 0 ignores nested lists, dialogs, drawers, and split panes.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    // 2. ScrollStartNotification: only begin tracking pull-to-refresh if:
    //    - this is an active physical drag gesture (dragDetails != null)
    //    - the scroll view is already at or near the top edge (pixels <= 1.0)
    //    Mouse wheel, trackpad scrolling, ballistic flings, and window resizing
    //    always have dragDetails == null, so they will NEVER start a pull gesture.
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null &&
          notification.metrics.pixels <= 1.0) {
        _isUserPulling = true;
      } else {
        _isUserPulling = false;
      }
    }

    // 3. OverscrollNotification: fired when pulling past boundary (e.g. ClampingScrollPhysics)
    if (notification is OverscrollNotification) {
      if (notification.dragDetails != null && notification.overscroll < 0) {
        _isUserPulling = true;
        final newDrag = _dragOffset - notification.overscroll * 0.5;
        if (newDrag >= _targetHeight) {
          _dragOffset = _targetHeight;
          setState(() {});
          _triggerRefresh();
        } else {
          setState(() {
            _dragOffset = newDrag.clamp(0.0, _targetHeight);
          });
        }
      }
    }
    // 4. ScrollUpdateNotification: fired during scroll (e.g. BouncingScrollPhysics)
    else if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        if (notification.metrics.pixels <= 0 &&
            (notification.scrollDelta ?? 0) < 0) {
          _isUserPulling = true;
          final newDrag = _dragOffset - (notification.scrollDelta ?? 0) * 0.5;
          if (newDrag >= _targetHeight) {
            _dragOffset = _targetHeight;
            setState(() {});
            _triggerRefresh();
          } else {
            setState(() {
              _dragOffset = newDrag.clamp(0.0, _targetHeight);
            });
          }
        } else if (_isUserPulling &&
            _dragOffset > 0 &&
            (notification.scrollDelta ?? 0) > 0) {
          final newDrag = (_dragOffset - (notification.scrollDelta ?? 0) * 0.5)
              .clamp(0.0, _targetHeight);
          setState(() {
            _dragOffset = newDrag;
          });
        }
      } else if (notification.dragDetails == null) {
        // Non-drag event (mouse wheel tick, trackpad scroll, ballistic fling, or window resize)
        if (_isUserPulling || _dragOffset > 0) {
          _isUserPulling = false;
          if (_dragOffset > 0) {
            _snapBackToZero();
          }
        }
      }
    }
    // 5. ScrollEndNotification: user released pointer
    else if (notification is ScrollEndNotification) {
      final wasPulling = _isUserPulling;
      _isUserPulling = false;

      if (!_isRefreshing) {
        if (wasPulling && _dragOffset >= _targetHeight) {
          _triggerRefresh();
        } else if (_dragOffset > 0) {
          _snapBackToZero();
        }
      }
    }
    // 6. UserScrollNotification: if scroll direction becomes idle
    else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle &&
          !_isRefreshing &&
          _dragOffset > 0) {
        _isUserPulling = false;
        _snapBackToZero();
      }
    }

    return false;
  }

  /// Dynamic resizable width for the co-planar task edit split pane on Medium/Expanded+
  double _taskEditPaneWidth = 380.0;

  /// Global key handler — fires before any widget-level handlers.
  bool _globalKeyHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    final logical = event.logicalKey;

    // ── Esc: dismiss search or task edit split pane ──────
    if (logical == LogicalKeyboardKey.escape) {
      final topBar = _topBarKey.currentState;
      if (topBar != null && topBar.isSearchOpen) {
        topBar.closeSearch();
        // Defer so the search overlay finishes collapsing before we steal focus.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _rootFocus.requestFocus();
        });
        return true; // consumed
      }

      final taskProvider = context.read<TaskProvider>();
      if (taskProvider.isEditPaneOpen) {
        taskProvider.closeEditPane();
        return true;
      }
      return false;
    }

    // Never trigger shortcuts if Alt modifier key is held.
    if (HardwareKeyboard.instance.isAltPressed) return false;

    // Only fire shortcuts when the scaffold itself is the active, top-most route.
    // If a modal bottom sheet, dialog (e.g. TaskEditPane), or popup is showing,
    // the user is interacting with that modal — don't trigger page-level shortcuts.
    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null && !currentRoute.isCurrent) {
      return false;
    }

    // If search view is open, user is searching — do not fire other shortcuts.
    final topBar = _topBarKey.currentState;
    if (topBar != null && topBar.isSearchOpen) {
      return false;
    }

    // For all other shortcuts: only fire when NO text field or form input is focused.
    if (GlobalShortcutsHandler.isTyping()) return false;

    final isCtrlOrCmd =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // ── / or Ctrl+F : open search ───────────────────────────────────────────
    if ((logical == LogicalKeyboardKey.slash && !isCtrlOrCmd) ||
        (isCtrlOrCmd && logical == LogicalKeyboardKey.keyF)) {
      _topBarKey.currentState?.openSearch();
      return true;
    }

    // ── N or Ctrl+N : new task ───────────────────────────────────────────────
    if ((logical == LogicalKeyboardKey.keyN &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !isCtrlOrCmd) ||
        (isCtrlOrCmd && logical == LogicalKeyboardKey.keyN)) {
      TaskEditPane.show(context);
      return true;
    }

    // ── R or Ctrl+R : refresh / sync ────────────────────────────────────────
    if ((logical == LogicalKeyboardKey.keyR &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !isCtrlOrCmd) ||
        (isCtrlOrCmd && logical == LogicalKeyboardKey.keyR)) {
      final nav = context.read<NavigationProvider>();
      if (nav.activePage != PageId.settings) {
        _triggerRefresh();
        return true;
      }
    }

    // ── Space : toggle Pomodoro timer when on Pomodoro page ─────────────────
    if (logical == LogicalKeyboardKey.space && !isCtrlOrCmd) {
      final nav = context.read<NavigationProvider>();
      if (nav.activePage == PageId.pomodoro) {
        context.read<PomodoroProvider>().toggleTimer();
        return true;
      }
    }

    return false;
  }

  ZetaWindowSizeClass? _previousSizeClass;

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final isSelectionMode =
        context.select<TaskProvider, bool>((p) => p.isSelectionMode) &&
        navProvider.activePage == PageId.tasks;
    final isEditPaneOpen = context.select<TaskProvider, bool>(
      (p) => p.isEditPaneOpen,
    );
    final sizeClass = ZetaWindowSizeClass.of(context);

    if (_previousSizeClass != sizeClass) {
      final shouldExpand =
          sizeClass == ZetaWindowSizeClass.large ||
          sizeClass == ZetaWindowSizeClass.extraLarge;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NavigationProvider>().setRailExpanded(shouldExpand);
        }
      });
      _previousSizeClass = sizeClass;
    }

    final isCompact = sizeClass.isCompact;

    // Top app bar visibility
    // Visible on tablet & desktop (width >= 600dp, where navigation rail is active).
    // On compact screens (< 600dp), Settings provides its own dedicated top header with back navigation.
    final showTopAppBar =
        !isCompact || navProvider.activePage != PageId.settings;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Sync native Windows window title bar with theme colors safely via MethodChannel
    WindowsTitleBar.update(
      isDark: isDark,
      captionColor: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      textColor: colorScheme.onSurface,
    );

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );

    final isPomodoroRunning = context.select<PomodoroProvider, bool>(
      (p) => p.isRunning,
    );

    final canPop =
        !isPomodoroRunning &&
        !isSelectionMode &&
        !isEditPaneOpen &&
        navProvider.activePage == PageId.home &&
        (_topBarKey.currentState == null ||
            !_topBarKey.currentState!.isSearchOpen);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 0. If task edit split side pane is open, close it first
        if (isEditPaneOpen) {
          ZetaHaptics.light();
          context.read<TaskProvider>().closeEditPane();
          return;
        }

        // 1. If multi-selection mode is active, dismiss it first
        if (isSelectionMode) {
          ZetaHaptics.light();
          context.read<TaskProvider>().clearSelection();
          return;
        }

        // 2. If top app bar search view is open, close it
        final topBar = _topBarKey.currentState;
        if (topBar != null && topBar.isSearchOpen) {
          topBar.closeSearch();
          return;
        }

        // 3. If in Settings and inside a specific section, pop back to Settings main page first
        if (navProvider.activePage == PageId.settings &&
            navProvider.selectedSettingsCategory != null) {
          ZetaHaptics.light();
          navProvider.clearSettingsCategory();
          return;
        }

        // 4. If on Pomodoro page and Pomodoro is actively running, ask before closing app / ending session
        if (navProvider.activePage == PageId.pomodoro && isPomodoroRunning) {
          final shouldExit = await confirmExitIfPomodoroRunning(context);
          if (shouldExit) {
            await AppExitService.instance.exitApp();
          }
          return;
        }

        // 5. If on any other page (including Settings main page), return to Home page
        if (navProvider.activePage != PageId.home) {
          ZetaHaptics.light();
          if (navProvider.activePage == PageId.revision) {
            context.read<RevisionProvider>().selectSubject(null);
          }
          navProvider.setActivePage(PageId.home);
          return;
        }

        // 6. User is on Home page and attempting to exit the app while Pomodoro is running
        if (isPomodoroRunning) {
          final shouldExit = await confirmExitIfPomodoroRunning(context);
          if (shouldExit) {
            await AppExitService.instance.exitApp();
          }
          return;
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlayStyle,
        child: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  // 1. Top App Bar (contains rail toggle button, hidden on mobile)
                  if (showTopAppBar) TopAppBarWidget(key: _topBarKey),

                  // 2. Expandable Stretchable Refresh Container below topappbar
                  if (navProvider.activePage != PageId.settings)
                    PullToRefreshContainer(
                      refreshHeight: _refreshHeight,
                      targetHeight: _targetHeight,
                      isRefreshing: _isRefreshing,
                    ),

                  // 3. Main body: Rail (desktop/tablet) or Stack with Floating Toolbar (mobile)
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: ScrollConfiguration(
                        behavior: const MaterialScrollBehavior().copyWith(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: isCompact
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: BodyPane(
                                      activePage: navProvider.activePage,
                                    ),
                                  ),
                                  // Floating Bottom Navigation: moves down out of view when selecting
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 16,
                                    child: AnimatedSlide(
                                      offset: isSelectionMode
                                          ? const Offset(0, 2.0)
                                          : Offset.zero,
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeInOutCubicEmphasized,
                                      child: AnimatedOpacity(
                                        opacity: isSelectionMode ? 0.0 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        child: IgnorePointer(
                                          ignoring: isSelectionMode,
                                          child: Center(
                                            child: FloatingBottomNav(
                                              navProvider: navProvider,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Floating Selection Toolbar: moves up from bottom into position
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 16,
                                    child: AnimatedSlide(
                                      offset: isSelectionMode
                                          ? Offset.zero
                                          : const Offset(0, 2.0),
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeInOutCubicEmphasized,
                                      child: AnimatedOpacity(
                                        opacity: isSelectionMode ? 1.0 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: IgnorePointer(
                                          ignoring: !isSelectionMode,
                                          child: Consumer<TaskProvider>(
                                            builder: (context, tp, _) =>
                                                TaskSelectionToolbar(
                                                  taskProvider: tp,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // M3E Navigation Rail from material_3_expressive (no internal toggle button)
                                  NavigationRailWidget(
                                    isExpanded: navProvider.isRailExpanded,
                                    navProvider: navProvider,
                                  ),

                                  // Body content pane + optional temporary resizable task edit side pane + floating selection toolbar
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: BodyPane(
                                                  activePage:
                                                      navProvider.activePage,
                                                ),
                                              ),
                                              if (isEditPaneOpen) ...[
                                                M3EPaneDivider(
                                                  onDragUpdate: (delta) {
                                                    setState(() {
                                                      _taskEditPaneWidth =
                                                          (_taskEditPaneWidth -
                                                                  delta)
                                                              .clamp(
                                                                300.0,
                                                                600.0,
                                                              );
                                                    });
                                                  },
                                                  onDoubleTap: () {
                                                    setState(() {
                                                      _taskEditPaneWidth =
                                                          380.0;
                                                    });
                                                    ZetaHaptics.medium();
                                                  },
                                                  tooltip: 'Drag to resize task pane · Double-tap to reset (380dp)',
                                                ),
                                                SizedBox(
                                                  width: _taskEditPaneWidth,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.fromLTRB(
                                                          0,
                                                          16,
                                                          16,
                                                          6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? colorScheme
                                                                .surfaceContainerHigh
                                                          : colorScheme
                                                                .surfaceContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: colorScheme
                                                              .shadow
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          blurRadius: 16,
                                                          offset: const Offset(
                                                            0,
                                                            6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child: SafeArea(
                                                      child: Consumer<TaskProvider>(
                                                        builder: (context, tp, _) =>
                                                            TaskEditFormContent(
                                                              key: ValueKey(
                                                                '${tp.editingTask?.id ?? 'new_task'}_${tp.editingInitialTitle ?? ''}_${tp.editingInitialDescription ?? ''}',
                                                              ),
                                                              task: tp
                                                                  .editingTask,
                                                              initialTitle: tp
                                                                  .editingInitialTitle,
                                                              initialDescription: tp
                                                                  .editingInitialDescription,
                                                              initialDueDate: tp
                                                                  .editingInitialDueDate,
                                                              initialDueTime: tp
                                                                  .editingInitialDueTime,
                                                              initialHasTime: tp
                                                                  .editingInitialHasTime,
                                                              initialSubtasks: tp
                                                                  .editingInitialSubtasks,
                                                              onClose: () => tp
                                                                  .closeEditPane(),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 24,
                                          child: AnimatedSlide(
                                            offset: isSelectionMode
                                                ? Offset.zero
                                                : const Offset(0, 2.0),
                                            duration: const Duration(
                                              milliseconds: 320,
                                            ),
                                            curve:
                                                Curves.easeInOutCubicEmphasized,
                                            child: AnimatedOpacity(
                                              opacity: isSelectionMode
                                                  ? 1.0
                                                  : 0.0,
                                              duration: const Duration(
                                                milliseconds: 250,
                                              ),
                                              child: IgnorePointer(
                                                ignoring: !isSelectionMode,
                                                child: Consumer<TaskProvider>(
                                                  builder: (context, tp, _) =>
                                                      TaskSelectionToolbar(
                                                        taskProvider: tp,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
