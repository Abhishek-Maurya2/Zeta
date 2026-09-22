import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/revision_provider.dart';
import 'components/revision_settings_sheet.dart';
import 'components/topic_edit_dialog.dart';
import '../../theme/breakpoints.dart';
import '../../theme/motion_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/m3_pane_divider.dart';
import '../../widgets/m3e_page_transition.dart';
import '../../widgets/segmented_column.dart';
import 'revision_pane1.dart';
import 'revision_pane2.dart';

class RevisionPage extends StatefulWidget {
  const RevisionPage({super.key});

  @override
  State<RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<RevisionPage> {
  // ─── Pane sizing (mirrors settings pattern) ────────────────────────────────
  static const double _defaultPaneWidth =
      ZetaBreakpoints.paneFixedExpanded; // 360
  static const double _largePaneWidth = ZetaBreakpoints.paneFixedLarge; // 412
  static const double _minPaneWidth = ZetaBreakpoints.paneMinList; // 240
  static const double _minContentPaneWidth =
      ZetaBreakpoints.paneMinContent; // 360
  static const double _collapseThreshold = 180.0;
  static const String _prefKeyPaneWidth = 'revision_pane_width';
  static const String _prefKeyPaneCollapsed = 'revision_pane_collapsed';

  double _paneWidth = _defaultPaneWidth;
  bool _hasCustomWidth = false;
  bool _isPaneCollapsed = false;

  // ─── Compact mobile hierarchical navigation state ──────────────────────────
  String? _selectedSubjectForMobile;
  String? _lastSubjectId;
  int _previousSubjectIndex = 0;
  RevisionProvider? _revProvider;

  @override
  void initState() {
    super.initState();
    _selectedSubjectForMobile = null;
    _loadSavedPaneSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RevisionProvider>().selectSubject(null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revProvider = Provider.of<RevisionProvider>(context, listen: false);
  }

  @override
  void deactivate() {
    _selectedSubjectForMobile = null;
    final rev = _revProvider;
    if (rev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rev.selectSubject(null);
      });
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _selectedSubjectForMobile = null;
    final rev = _revProvider;
    if (rev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rev.selectSubject(null);
      });
    }
    super.dispose();
  }

  Future<void> _loadSavedPaneSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWidth = prefs.getDouble(_prefKeyPaneWidth);
      final savedCollapsed = prefs.getBool(_prefKeyPaneCollapsed);
      if (mounted) {
        setState(() {
          if (savedWidth != null && savedWidth >= _minPaneWidth) {
            _paneWidth = savedWidth;
            _hasCustomWidth = true;
          }
          if (savedCollapsed != null) {
            _isPaneCollapsed = savedCollapsed;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _persistPaneSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyPaneWidth, _paneWidth);
      await prefs.setBool(_prefKeyPaneCollapsed, _isPaneCollapsed);
    } catch (_) {}
  }

  void _handlePaneDrag(double delta, double totalWidth) {
    final maxAllowedWidth = (totalWidth - _minContentPaneWidth - 16.0).clamp(
      _minPaneWidth,
      totalWidth * 0.6,
    );

    var targetWidth =
        (_hasCustomWidth
            ? _paneWidth
            : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth)) +
        delta;

    // Snap points
    final snapPoints = <double>[
      240.0,
      _defaultPaneWidth,
      _largePaneWidth,
      totalWidth * 0.5,
    ];
    const double snapThreshold = 12.0;
    for (final snap in snapPoints) {
      if ((targetWidth - snap).abs() <= snapThreshold) {
        targetWidth = snap;
        break;
      }
    }

    if (targetWidth < _collapseThreshold) {
      setState(() {
        _isPaneCollapsed = true;
        _hasCustomWidth = true;
      });
      ZetaHaptics.light();
      return;
    }

    final clampedWidth = targetWidth.clamp(_minPaneWidth, maxAllowedWidth);
    if (clampedWidth != _paneWidth || !_hasCustomWidth) {
      setState(() {
        _paneWidth = clampedWidth;
        _hasCustomWidth = true;
        _isPaneCollapsed = false;
      });
    }
  }

  void _handlePaneDoubleTap(double totalWidth) {
    final maxAllowed = (totalWidth - _minContentPaneWidth - 16.0).clamp(
      _minPaneWidth,
      totalWidth * 0.6,
    );
    final currentWidth = _hasCustomWidth
        ? _paneWidth
        : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth);
    final isNearStandard = (currentWidth - _defaultPaneWidth).abs() < 10.0;

    setState(() {
      _isPaneCollapsed = false;
      _hasCustomWidth = true;
      if (isNearStandard) {
        _paneWidth = (totalWidth * 0.5).clamp(_minPaneWidth, maxAllowed);
      } else {
        _paneWidth = _defaultPaneWidth;
      }
    });
    ZetaHaptics.medium();
    _persistPaneSettings();
  }

  /// Collapsed expand affordance (chevron strip on left edge)
  Widget _buildCollapsedExpandAffordance(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Expand subjects pane',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _isPaneCollapsed = false;
            if (_paneWidth < _minPaneWidth) _paneWidth = _defaultPaneWidth;
          });
          ZetaHaptics.light();
          _persistPaneSettings();
        },
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isTwoPane = sizeClass.isMultiPane;
    final colorScheme = Theme.of(context).colorScheme;

    final revProvider = context.watch<RevisionProvider>();

    if (revProvider.isLoading) {
      return const Center(child: M3EProgressIndicator.circular(value: null));
    }

    if (!isTwoPane) {
      return _buildSinglePaneLayout(
        context,
        revProvider,
        colorScheme,
        sizeClass,
      );
    }

    return _buildTwoPaneLayout(context, revProvider, colorScheme);
  }

  // ─── Single Pane (mobile/tablet portrait) ─────────────────────────────────
  Widget _buildSinglePaneLayout(
    BuildContext context,
    RevisionProvider revProvider,
    ColorScheme colorScheme,
    ZetaWindowSizeClass sizeClass,
  ) {
    final isCompact = sizeClass.isCompact;
    final selectedSubject = _selectedSubjectForMobile != null
        ? revProvider.subjects
              .where((s) => s.id == _selectedSubjectForMobile)
              .firstOrNull
        : null;

    final int currentSubjectIndex = selectedSubject != null ? 1 : 0;
    final int prevIdx = _previousSubjectIndex;
    if (_lastSubjectId != selectedSubject?.id) {
      _previousSubjectIndex = currentSubjectIndex;
      _lastSubjectId = selectedSubject?.id;
    }

    return PopScope(
      canPop: selectedSubject == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedSubjectForMobile != null) {
          ZetaHaptics.light();
          setState(() {
            _selectedSubjectForMobile = null;
            revProvider.selectSubject(null);
          });
        }
      },
      child: M3EPageTransition(
        currentIndex: currentSubjectIndex,
        previousIndex: prevIdx,
        transitionType: M3EPageTransitionType.sharedAxisX,
        duration: M3MotionDuration.medium2,
        child: selectedSubject == null
            ? SingleChildScrollView(
                key: const ValueKey<String>('revision_compact_subjects'),
                padding: EdgeInsets.fromLTRB(
                  isCompact
                      ? ZetaBreakpoints.marginCompact
                      : ZetaBreakpoints.marginExpanded,
                  16,
                  isCompact
                      ? ZetaBreakpoints.marginCompact
                      : ZetaBreakpoints.marginExpanded,
                  80,
                ),
                child: RevisionPane1(
                  isSplitPane: false,
                  onSubjectSelected: (sub) {
                    setState(() {
                      _selectedSubjectForMobile = sub.id;
                    });
                  },
                ),
              )
            : CustomScrollView(
                key: ValueKey<String>(
                  'revision_compact_topics_${selectedSubject.id}',
                ),
                slivers: [
                  SliverAppBar(
                    pinned: false,
                    automaticallyImplyLeading: false,
                    scrolledUnderElevation: 2,
                    leading: M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      size: M3EIconButtonSize.sm,
                      width: M3EIconButtonWidth.wide,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.onSurface,
                      ),
                      decoration: M3EIconButtonDecoration(
                        backgroundColor: WidgetStateProperty.all(
                          colorScheme.surfaceContainerLowest,
                        ),
                      ),
                      onPressed: () {
                        ZetaHaptics.light();
                        setState(() {
                          _selectedSubjectForMobile = null;
                          revProvider.selectSubject(null);
                        });
                      },
                      tooltip: 'Back',
                    ),
                    title: Text(selectedSubject.name),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: M3EIconButton(
                          onPressed: () {
                            ZetaHaptics.light();
                            AddTopicDialog.show(
                              context,
                              subjectId: selectedSubject.id,
                            );
                          },
                          variant: M3EIconButtonVariant.filled,
                          size: M3EIconButtonSize.sm,
                          width: M3EIconButtonWidth.wide,
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 23,
                            fontWeight: FontWeight.w600,
                          ),
                          tooltip: 'Add Topic',
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 24,
                      16,
                      isCompact ? 16 : 24,
                      80,
                    ),
                    sliver: const SliverToBoxAdapter(
                      child: RevisionPane2(isSplitPane: false),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Two-Pane Layout (≥ 840dp) ─────────────────────────────────────────────
  Widget _buildTwoPaneLayout(
    BuildContext context,
    RevisionProvider revProvider,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final maxAllowedWidth = (totalWidth - _minContentPaneWidth - 16.0)
            .clamp(_minPaneWidth, totalWidth * 0.6);
        final currentWidth = _hasCustomWidth
            ? _paneWidth
            : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth);
        final effectiveWidth = currentWidth.clamp(
          _minPaneWidth,
          maxAllowedWidth,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Left Pane: Subjects (Pane 1) ──────────────────────────
            if (_isPaneCollapsed)
              _buildCollapsedExpandAffordance(colorScheme)
            else
              SizedBox(
                width: effectiveWidth,
                child: const SingleChildScrollView(
                  key: PageStorageKey<String>('revision_subjects_pane'),
                  padding: EdgeInsets.fromLTRB(16, 40, 16, 24),
                  child: RevisionPane1(isSplitPane: true),
                ),
              ),

            // ─── Material 3 Draggable Pane Divider ─────────────────────
            M3EPaneDivider(
              onDragUpdate: (delta) => _handlePaneDrag(delta, totalWidth),
              onDragEnd: _persistPaneSettings,
              onDoubleTap: () => _handlePaneDoubleTap(totalWidth),
              tooltip:
                  'Drag to resize · Double-tap to reset (${(_hasCustomWidth ? _paneWidth : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth)).toInt()}dp)',
            ),

            // ─── Right Pane: Topics (Pane 2) ───────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 16, 16, 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomScrollView(
                  key: ValueKey<String>(
                    'revision_topics_${revProvider.selectedSubject?.id ?? "none"}',
                  ),
                  slivers: [
                    SliverAppBar.large(
                      backgroundColor: isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surfaceContainer,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      scrolledUnderElevation: 2,
                      title: Text(
                        revProvider.selectedSubject?.name ?? 'Topics',
                      ),
                      actions: [
                        if (revProvider.selectedSubject != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: M3EIconButton(
                              onPressed: () {
                                ZetaHaptics.light();
                                AddTopicDialog.show(
                                  context,
                                  subjectId: revProvider.selectedSubject!.id,
                                );
                              },
                              variant: M3EIconButtonVariant.filled,
                              size: M3EIconButtonSize.sm,
                              width: M3EIconButtonWidth.wide,
                              icon: const Icon(
                                Icons.add_rounded,
                                size: 23,
                                fontWeight: FontWeight.w600,
                              ),
                              tooltip: 'Add Topic',
                            ),
                          ),
                      ],
                    ),
                    if (revProvider.selectedSubject == null)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: RevisionPane2(isSplitPane: true),
                      )
                    else
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(20, 4, 20, 80),
                        sliver: SliverToBoxAdapter(
                          child: RevisionPane2(isSplitPane: true),
                        ),
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
}
