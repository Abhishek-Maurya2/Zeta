import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../utils/haptics.dart';

import '../providers/pomodoro_provider.dart';
import '../components/pomodoro/pomodoro_timer_pane.dart';
import '../components/pomodoro/pomodoro_queue_pane.dart';
import '../components/pomodoro/pomodoro_analysis_pane.dart';
import '../components/pomodoro/m3_pane_divider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pomodoro_ambient_page.dart';

enum PomodoroTab {
  timer,
  queue,
  analysis;

  String get label {
    switch (this) {
      case PomodoroTab.timer:
        return 'Timer';
      case PomodoroTab.queue:
        return 'Up next';
      case PomodoroTab.analysis:
        return 'Analysis';
    }
  }
}

enum SecondaryPaneTab {
  queue,
  analysis;

  String get label {
    switch (this) {
      case SecondaryPaneTab.queue:
        return 'Up next';
      case SecondaryPaneTab.analysis:
        return 'Analysis';
    }
  }
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const double _defaultSupportingPaneWidth = 360.0;
  static const double _largeSupportingPaneWidth = 412.0;
  static const double _minSupportingPaneWidth = 300.0;
  static const double _minFocusPaneWidth = 400.0;
  static const double _collapseThreshold = 180.0;
  static const String _prefKeyPaneWidth = 'pomodoro_supporting_pane_width';
  static const String _prefKeyPaneCollapsed = 'pomodoro_supporting_pane_collapsed';

  PomodoroTab _activeTab = PomodoroTab.timer;
  SecondaryPaneTab _secondaryTab = SecondaryPaneTab.queue;
  double _supportingPaneWidth = _largeSupportingPaneWidth;
  bool _hasCustomWidth = false;
  bool _isSupportingPaneCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPaneSettings();
  }

  Future<void> _loadSavedPaneSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWidth = prefs.getDouble(_prefKeyPaneWidth);
      final savedCollapsed = prefs.getBool(_prefKeyPaneCollapsed);
      if (mounted) {
        setState(() {
          if (savedWidth != null && savedWidth >= _minSupportingPaneWidth) {
            _supportingPaneWidth = savedWidth;
            _hasCustomWidth = true;
          }
          if (savedCollapsed != null) {
            _isSupportingPaneCollapsed = savedCollapsed;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _persistPaneSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyPaneWidth, _supportingPaneWidth);
      await prefs.setBool(_prefKeyPaneCollapsed, _isSupportingPaneCollapsed);
    } catch (_) {}
  }

  void _handlePaneDrag(double delta, double totalWidth) {
    final maxAllowedWidth = (totalWidth - _minFocusPaneWidth - 16.0)
        .clamp(_minSupportingPaneWidth, totalWidth * 0.75);

    // Dragging left (delta < 0) widens right pane; dragging right (delta > 0) narrows it.
    var targetWidth = (_hasCustomWidth
            ? _supportingPaneWidth
            : (totalWidth >= 1200 ? _largeSupportingPaneWidth : _defaultSupportingPaneWidth)) -
        delta;

    // Check canonical snap points: 360, 412, and 50% split
    final snapPoints = <double>[
      _defaultSupportingPaneWidth,
      _largeSupportingPaneWidth,
      totalWidth * 0.5,
    ];

    const double snapThreshold = 12.0;
    for (final snap in snapPoints) {
      if ((targetWidth - snap).abs() <= snapThreshold) {
        targetWidth = snap;
        break;
      }
    }

    // Collapse check if dragged past collapse threshold
    if (targetWidth < _collapseThreshold) {
      setState(() {
        _isSupportingPaneCollapsed = true;
        _hasCustomWidth = true;
      });
      HapticFeedback.lightImpact();
      return;
    }

    final clampedWidth = targetWidth.clamp(_minSupportingPaneWidth, maxAllowedWidth);
    if (clampedWidth != _supportingPaneWidth || !_hasCustomWidth) {
      setState(() {
        _supportingPaneWidth = clampedWidth;
        _hasCustomWidth = true;
        _isSupportingPaneCollapsed = false;
      });
    }
  }

  void _handlePaneDoubleTap(double totalWidth) {
    final maxAllowed = (totalWidth - _minFocusPaneWidth - 16.0)
        .clamp(_minSupportingPaneWidth, totalWidth * 0.75);
    final currentWidth = _hasCustomWidth
        ? _supportingPaneWidth
        : (totalWidth >= 1200 ? _largeSupportingPaneWidth : _defaultSupportingPaneWidth);
    final isNearStandard = (currentWidth - _defaultSupportingPaneWidth).abs() < 10.0;

    setState(() {
      _isSupportingPaneCollapsed = false;
      _hasCustomWidth = true;
      if (isNearStandard) {
        // Toggle to 50% split if already at canonical 360
        _supportingPaneWidth = (totalWidth * 0.5).clamp(_minSupportingPaneWidth, maxAllowed);
      } else {
        // Reset to canonical standard 360
        _supportingPaneWidth = _defaultSupportingPaneWidth;
      }
    });
    HapticFeedback.mediumImpact();
    _persistPaneSettings();
  }

  void _enterAodMode() {
    PomodoroAmbientPage.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTwoPane = width >= 840;
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isTwoPane
          ? _buildTwoPaneLayout(context, provider, colorScheme, textTheme)
          : _buildSinglePaneLayout(
              context,
              provider,
              colorScheme,
              textTheme,
            ),
    );
  }

  // ─── Desktop / Wide (≥ 840px) Material 3 Supporting Pane Layout ──────────
  Widget _buildTwoPaneLayout(
    BuildContext context,
    PomodoroProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        if (_isSupportingPaneCollapsed) {
          return Row(
            children: [
              Expanded(
                child: PomodoroTimerPane(onToggleAod: _enterAodMode),
              ),
              _buildCollapsedExpandAffordance(colorScheme),
            ],
          );
        }

        final maxAllowedWidth = (totalWidth - _minFocusPaneWidth - 16.0)
            .clamp(_minSupportingPaneWidth, totalWidth * 0.75);
        final currentWidth = _hasCustomWidth
            ? _supportingPaneWidth
            : (totalWidth >= 1200 ? _largeSupportingPaneWidth : _defaultSupportingPaneWidth);
        final effectiveWidth =
            currentWidth.clamp(_minSupportingPaneWidth, maxAllowedWidth);

        return Row(
          children: [
            // Left Pane: Primary Focus Pane (Timer)
            Expanded(
              child: PomodoroTimerPane(onToggleAod: _enterAodMode),
            ),

            // Material 3 Draggable Pane Divider
            M3PaneDivider(
              onDragUpdate: (delta) => _handlePaneDrag(delta, totalWidth),
              onDragEnd: _persistPaneSettings,
              onDoubleTap: () => _handlePaneDoubleTap(totalWidth),
            ),

            // Right Pane: Secondary Supporting Pane (Up next or Analysis)
            SizedBox(
              width: effectiveWidth,
              child: Container(
                color: colorScheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Secondary Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: M3EButtonGroup(
                                type: M3EButtonGroupType.connected,
                                size: M3EButtonSize.sm,
                                style: M3EButtonStyle.tonal,
                                selectedIndex: _secondaryTab.index,
                                onSelectedIndexChanged: (idx) {
                                  if (idx != null) {
                                    ZetaHaptics.selection();
                                    setState(() {
                                      _secondaryTab =
                                          SecondaryPaneTab.values[idx];
                                    });
                                  }
                                },
                                actions: [
                                  M3EButtonGroupAction(
                                    icon: const Icon(
                                      Icons.checklist_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Up next (${provider.queue.length})',
                                    ),
                                  ),
                                  const M3EButtonGroupAction(
                                    icon: Icon(
                                      Icons.insights_rounded,
                                      size: 16,
                                    ),
                                    label: Text('Analysis'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Collapse Button
                          IconButton(
                            icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                            tooltip: 'Collapse supporting pane',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              setState(() => _isSupportingPaneCollapsed = true);
                              _persistPaneSettings();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Pane Body
                    Expanded(
                      child: _secondaryTab == SecondaryPaneTab.queue
                          ? const PomodoroQueuePane(isSplitPane: true)
                          : const PomodoroAnalysisPane(isSplitPane: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Compact vertical strip affordance on the edge to re-expand the supporting pane
  Widget _buildCollapsedExpandAffordance(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Expand ${_secondaryTab.label} pane',
      child: InkWell(
        onTap: () {
          setState(() {
            _isSupportingPaneCollapsed = false;
            if (_supportingPaneWidth < _minSupportingPaneWidth) {
              _supportingPaneWidth = _defaultSupportingPaneWidth;
            }
          });
          HapticFeedback.lightImpact();
          _persistPaneSettings();
        },
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              left: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Compact (< 840px) Tabbed Single-Pane Layout ─────────────────────────
  Widget _buildSinglePaneLayout(
    BuildContext context,
    PomodoroProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Top Connected Tab Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: M3EButtonGroup(
              type: M3EButtonGroupType.connected,
              size: M3EButtonSize.sm,
              style: M3EButtonStyle.tonal,
              selectedIndex: _activeTab.index,
              onSelectedIndexChanged: (idx) {
                if (idx != null) {
                  ZetaHaptics.selection();
                  setState(() {
                    _activeTab = PomodoroTab.values[idx];
                  });
                }
              },
              actions: [
                const M3EButtonGroupAction(label: Text('Timer')),
                M3EButtonGroupAction(
                  label: Text('Up next (${provider.queue.length})'),
                ),
                const M3EButtonGroupAction(label: Text('Analysis')),
              ],
            ),
          ),
        ),

        // Active Tab View
        Expanded(
          child: IndexedStack(
            index: _activeTab.index,
            children: [
              PomodoroTimerPane(onToggleAod: _enterAodMode),
              const PomodoroQueuePane(),
              const PomodoroAnalysisPane(),
            ],
          ),
        ),
      ],
    );
  }
}
