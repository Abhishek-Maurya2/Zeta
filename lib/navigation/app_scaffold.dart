import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

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
import 'components/pull_to_refresh_container.dart';
import 'components/floating_bottom_nav.dart';
import 'components/navigation_rail_widget.dart';
import 'components/global_shortcuts_handler.dart';
import '../components/task_edit_pane.dart';
import '../components/task_selection_toolbar.dart';
import '../core/core.dart';

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
  final GlobalKey<NavigatorState> _bodyNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Root FocusNode — we return focus here after dismissing search so that
  /// subsequent shortcuts (N, R, /) work immediately without a click.
  final FocusNode _rootFocus = FocusNode(debugLabel: 'ScaffoldRoot');

  late final M3EToolbarVisibilityController _toolbarController;
  late final M3EToolbarScrollBehavior _toolbarBehavior;

  /// Width of the co-planar task editor on tablet and desktop layouts.
  final double _taskEditPaneWidth = 380.0;

  PageId? _lastPage;
  String _lastPomodoroTab = 'timer';

  static const double _refreshTargetHeight = 80;
  late final AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  final ValueNotifier<double> _refreshHeightNotifier = ValueNotifier<double>(0.0);
  double _dragOffset = 0;
  bool _isRefreshing = false;
  bool _isUserPulling = false;

  double get _refreshHeight => _refreshController.isAnimating
      ? _refreshAnimation.value
      : (_isRefreshing ? _refreshTargetHeight : _dragOffset);

  void _onNavigationChanged() {
    final nav = context.read<NavigationProvider>();
    if (_lastPage != nav.activePage) {
      _lastPage = nav.activePage;
      _toolbarController.show();
    }
  }

  void _onPomodoroChanged() {
    final pomodoro = context.read<PomodoroProvider>();
    if (_lastPomodoroTab != pomodoro.activeTab) {
      _lastPomodoroTab = pomodoro.activeTab;
      // Always ensure floating nav is visible when switching Pomodoro tabs,
      // particularly the timer pane which has no scrollable content.
      _toolbarController.show();
    }
  }

  late final NavigationProvider _navProvider;
  late final PomodoroProvider _pomodoroProvider;

  @override
  void initState() {
    super.initState();
    _toolbarController = M3EToolbarVisibilityController(exitExtent: 100.0);
    _toolbarBehavior = M3EToolbarScrollBehavior.exitAlways(
      exitDirection: M3EToolbarExitDirection.bottom,
      controller: _toolbarController,
    );
    _refreshController =
        AnimationController(vsync: this, duration: M3MotionDuration.medium2)
          ..addListener(() {
            _refreshHeightNotifier.value = _refreshHeight;
          });
    _refreshAnimation = Tween<double>(begin: 0, end: _refreshTargetHeight)
        .animate(
          CurvedAnimation(
            parent: _refreshController,
            curve: M3MotionEasing.emphasizedDecelerate,
          ),
        );

    _navProvider = context.read<NavigationProvider>();
    _pomodoroProvider = context.read<PomodoroProvider>();

    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final taskProvider = context.read<TaskProvider>();

        _lastPage = _navProvider.activePage;
        _lastPomodoroTab = _pomodoroProvider.activeTab;

        _navProvider.addListener(_onNavigationChanged);
        _pomodoroProvider.addListener(_onPomodoroChanged);

        QuickActionsService.instance.init(_navProvider);
        CrossDeviceService.instance.init(
          _navProvider,
          taskProvider: taskProvider,
          pomodoroProvider: _pomodoroProvider,
        );
        WindowsTrayService.instance.init();
        unawaited(AndroidTasksWidgetService.instance.initialize(context));
      }
    });
  }

  @override
  void dispose() {
    _navProvider.removeListener(_onNavigationChanged);
    _pomodoroProvider.removeListener(_onPomodoroChanged);

    AndroidTasksWidgetService.instance.dispose();
    _refreshController.dispose();
    _refreshHeightNotifier.dispose();
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
    _rootFocus.dispose();
    if (AppSnackbar.rootContext == context) {
      AppSnackbar.rootContext = null;
    }
    super.dispose();
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    final nav = context.read<NavigationProvider>();
    if (nav.activePage == PageId.settings || nav.activePage == PageId.bin) {
      return;
    }

    final initialOffset = _dragOffset;
    setState(() {
      _isRefreshing = true;
      _isUserPulling = false;
      _dragOffset = _refreshTargetHeight;
    });
    _refreshHeightNotifier.value = _refreshTargetHeight;
    ZetaHaptics.medium();

    final taskProvider = context.read<TaskProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final revisionProvider = context.read<RevisionProvider>();

    if (initialOffset < _refreshTargetHeight) {
      _refreshAnimation =
          Tween<double>(
            begin: initialOffset > 0 ? initialOffset : 0,
            end: _refreshTargetHeight,
          ).animate(
            CurvedAnimation(
              parent: _refreshController,
              curve: M3MotionEasing.emphasizedDecelerate,
            ),
          );
      await _refreshController.forward(from: 0);
    } else {
      _refreshController.value = 1;
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

    _refreshAnimation = Tween<double>(begin: _refreshTargetHeight, end: 0)
        .animate(
          CurvedAnimation(
            parent: _refreshController,
            curve: M3MotionEasing.emphasizedAccelerate,
          ),
        );
    await _refreshController.forward(from: 0);

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _dragOffset = 0;
      });
      _refreshHeightNotifier.value = 0;
      AppSnackbar.show(
        context,
        message: 'Refreshed',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _snapBackToZero() {
    if (_dragOffset <= 0) return;
    _refreshAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(
        parent: _refreshController,
        curve: M3MotionEasing.emphasizedDecelerate,
      ),
    );
    _refreshController.forward(from: 0).then((_) {
      _dragOffset = 0;
      _refreshHeightNotifier.value = 0;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // When at the top of the screen in compact mode, always show the floating nav bar
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels <= 10) {
      _toolbarController.show();
    }

    if (_isRefreshing ||
        context.read<NavigationProvider>().activePage == PageId.settings ||
        context.read<NavigationProvider>().activePage == PageId.bin ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _isUserPulling =
          notification.dragDetails != null && notification.metrics.pixels <= 1;
    }

    if (notification is OverscrollNotification) {
      if (notification.dragDetails != null && notification.overscroll < 0) {
        _isUserPulling = true;
        final newDrag = _dragOffset - notification.overscroll * 0.5;
        if (newDrag >= _refreshTargetHeight) {
          _dragOffset = _refreshTargetHeight;
          _refreshHeightNotifier.value = _refreshTargetHeight;
          unawaited(_triggerRefresh());
        } else {
          _dragOffset = newDrag.clamp(0.0, _refreshTargetHeight).toDouble();
          _refreshHeightNotifier.value = _dragOffset;
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        if (notification.metrics.pixels <= 0 &&
            (notification.scrollDelta ?? 0) < 0) {
          _isUserPulling = true;
          final newDrag = _dragOffset - (notification.scrollDelta ?? 0) * 0.5;
          if (newDrag >= _refreshTargetHeight) {
            _dragOffset = _refreshTargetHeight;
            _refreshHeightNotifier.value = _refreshTargetHeight;
            unawaited(_triggerRefresh());
          } else {
            _dragOffset = newDrag.clamp(0.0, _refreshTargetHeight).toDouble();
            _refreshHeightNotifier.value = _dragOffset;
          }
        } else if (_isUserPulling &&
            _dragOffset > 0 &&
            (notification.scrollDelta ?? 0) > 0) {
          _dragOffset = (_dragOffset - (notification.scrollDelta ?? 0) * 0.5)
              .clamp(0.0, _refreshTargetHeight)
              .toDouble();
          _refreshHeightNotifier.value = _dragOffset;
        }
      } else if (_isUserPulling || _dragOffset > 0) {
        _isUserPulling = false;
        _snapBackToZero();
      }
    } else if (notification is ScrollEndNotification) {
      final wasPulling = _isUserPulling;
      _isUserPulling = false;
      if (wasPulling && _dragOffset >= _refreshTargetHeight) {
        unawaited(_triggerRefresh());
      } else if (_dragOffset > 0) {
        _snapBackToZero();
      }
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        _dragOffset > 0) {
      _isUserPulling = false;
      _snapBackToZero();
    }
    return false;
  }

  bool _globalKeyHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    final logical = event.logicalKey;

    // ── Esc: dismiss search or task edit split pane or go back ──────
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

      final nav = context.read<NavigationProvider>();
      if (nav.canPop) {
        nav.pop();
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
      if (nav.activePage != PageId.settings && nav.activePage != PageId.bin) {
        unawaited(_triggerRefresh());
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
    AppSnackbar.rootContext = context;
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

    final isRevisionSubpage =
        navProvider.activePage == PageId.revision &&
        context.select<RevisionProvider, bool>((p) => p.isSubpageActive);
    final isSearchOpen = _topBarKey.currentState?.isSearchOpen ?? false;
    final hasActivePane =
        riverpod.ProviderScope.containerOf(context, listen: false).read(activePaneProvider) != null;
    final backHandledByScaffold =
        isEditPaneOpen ||
        hasActivePane ||
        isSelectionMode ||
        isSearchOpen ||
        isRevisionSubpage;

    // Top app bar visibility
    // Visible on tablet & desktop (width >= 600dp, where navigation rail is active).
    // On compact screens (< 600dp), Settings, Bin, Topics, and Notes provide their own dedicated top header with back navigation.
    final showTopAppBar =
        !isCompact ||
        (navProvider.activePage != PageId.settings &&
            navProvider.activePage != PageId.bin &&
            !isRevisionSubpage);

    final isDark = context.theme.brightness == Brightness.dark;
    final colorScheme = context.colorScheme;

    // Sync native Windows window title bar with theme colors safely via MethodChannel
    WindowsTitleBar.update(
      isDark: isDark,
      captionColor: colorScheme.surfaceContainerLow,
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
    final isPomodoroTimerTab = context.select<PomodoroProvider, bool>(
      (p) => p.activeTab == 'timer',
    );
    final isPomodoroTimerPane =
        navProvider.activePage == PageId.pomodoro && isPomodoroTimerTab;

    final canPop =
        !backHandledByScaffold &&
        (!isPomodoroRunning || navProvider.pageStack.length > 1);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Let root dialogs and sheets consume back before page state changes.
        if (Navigator.of(context, rootNavigator: true).canPop()) return;

        // 0. If task edit split side pane is open, close it first
        if (isEditPaneOpen) {
          ZetaHaptics.light();
          context.read<TaskProvider>().closeEditPane();
          return;
        }

        // 0.1. If an active contextual supporting pane is open, close it
        final activeCoord = riverpod.ProviderScope.containerOf(context, listen: false).read(activePaneProvider.notifier);
        if (activeCoord.isOpen) {
          ZetaHaptics.light();
          activeCoord.closePane();
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


        // 3.1. If in Revision and on Notes, pop back to Topics first
        if (navProvider.activePage == PageId.revision) {
          final revProvider = context.read<RevisionProvider>();
          if (revProvider.isNotesOpen) {
            ZetaHaptics.light();
            revProvider.closeNotes();
            return;
          }

          // 3.2. If in Revision and on Topics, pop back to Subjects first
          if (revProvider.selectedSubjectId != null) {
            ZetaHaptics.light();
            revProvider.selectSubject(null);
            return;
          }
        }

        // Destination routes and modal routes are popped by their Navigator.
        if (_bodyNavigatorKey.currentState?.canPop() == true) return;

        // 5. If on Pomodoro page and Pomodoro is actively running, ask before closing app / ending session
        if (navProvider.activePage == PageId.pomodoro && isPomodoroRunning) {
          final shouldExit = await confirmExitIfPomodoroRunning(context);
          if (shouldExit) {
            await AppExitService.instance.exitApp();
          }
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
                  if (navProvider.activePage != PageId.settings &&
                      navProvider.activePage != PageId.bin &&
                      !isRevisionSubpage)
                    ValueListenableBuilder<double>(
                      valueListenable: _refreshHeightNotifier,
                      builder: (context, height, _) {
                        return PullToRefreshContainer(
                          refreshHeight: height,
                          targetHeight: _refreshTargetHeight,
                          isRefreshing: _isRefreshing,
                        );
                      },
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
                            ? M3EToolbarScrollWrapper(
                                key: ValueKey(navProvider.activePage),
                                behavior: _toolbarBehavior,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: BodyPane(
                                        navigatorKey: _bodyNavigatorKey,
                                        backHandledByScaffold:
                                            backHandledByScaffold,
                                      ),
                                    ),
                                    FloatingBottomNav(
                                      navProvider: navProvider,
                                      isSelectionMode: isSelectionMode,
                                      scrollBehavior: _toolbarBehavior,
                                      keepVisible: isPomodoroTimerPane,
                                    ),
                                    TaskSelectionToolbar(
                                      taskProvider: context
                                          .read<TaskProvider>(),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  NavigationRailWidget(
                                    isExpanded: navProvider.isRailExpanded,
                                    navProvider: navProvider,
                                  ),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Consumer<TaskProvider>(
                                            builder: (context, taskProvider, _) {
                                              return riverpod.Consumer(
                                                builder: (context, ref, _) {
                                                  final activePane = ref.watch(activePaneProvider);
                                                  final hasTaskEdit = isEditPaneOpen;
                                                  final hasActivePane = activePane != null;
                                                  final showSupporting = hasTaskEdit || hasActivePane;

                                                  Widget? supportingContent;
                                                  if (hasTaskEdit) {
                                                    supportingContent = TaskEditFormContent(
                                                      key: ValueKey(
                                                        '${taskProvider.editingTask?.id ?? 'new_task'}_${taskProvider.editingInitialTitle ?? ''}_${taskProvider.editingInitialDescription ?? ''}',
                                                      ),
                                                      task: taskProvider.editingTask,
                                                      initialTitle: taskProvider.editingInitialTitle,
                                                      initialDescription: taskProvider.editingInitialDescription,
                                                      initialDueDate: taskProvider.editingInitialDueDate,
                                                      initialDueTime: taskProvider.editingInitialDueTime,
                                                      initialHasTime: taskProvider.editingInitialHasTime,
                                                      initialSubtasks: taskProvider.editingInitialSubtasks,
                                                      onClose: taskProvider.closeEditPane,
                                                    );
                                                  } else if (hasActivePane) {
                                                    supportingContent = activePane.child;
                                                  }

                                                  return SupportingPaneScaffold(
                                                    defaultPaneWidth: activePane?.width ?? _taskEditPaneWidth,
                                                    primaryPane: BodyPane(
                                                      navigatorKey: _bodyNavigatorKey,
                                                      backHandledByScaffold: backHandledByScaffold,
                                                    ),
                                                    supportingPane: !showSupporting || supportingContent == null
                                                        ? null
                                                        : Container(
                                                            margin: const EdgeInsets.fromLTRB(
                                                              0,
                                                              10,
                                                              10,
                                                              6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: colorScheme.surfaceContainerHigh,
                                                              borderRadius: BorderRadius.circular(
                                                                20,
                                                              ),
                                                            ),
                                                            clipBehavior: Clip.antiAlias,
                                                            child: SafeArea(
                                                              child: supportingContent,
                                                            ),
                                                          ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        TaskSelectionToolbar(
                                          taskProvider: context
                                              .read<TaskProvider>(),
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
