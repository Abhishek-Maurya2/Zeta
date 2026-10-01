import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/revision_provider.dart';
import '../../services/preferences_service.dart';
import 'components/topic_edit_dialog.dart';
import 'components/revision_notes_pane.dart';
import '../../theme/breakpoints.dart';
import '../../theme/motion_tokens.dart';
import '../../utils/haptics.dart';
import '../../components/m3e_split_pane.dart';
import '../../components/m3e_page_transition.dart';
import '../../models/revision.dart';
import 'revision_pane1.dart';
import 'revision_pane2.dart';

enum RevisionRightPaneMode { topics, notes }

class RevisionPage extends StatefulWidget {
  const RevisionPage({super.key});

  @override
  State<RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<RevisionPage> {
  // ─── Pane sizing (mirrors settings pattern) ────────────────────────────────
  static const double _defaultPaneWidth =
      ZetaBreakpoints.paneFixedExpanded; // 360[cite: 1]
  static const double _largePaneWidth =
      ZetaBreakpoints.paneFixedLarge; // 412[cite: 1]
  static const double _minPaneWidth =
      ZetaBreakpoints.paneMinList; // 240[cite: 1]
  static const double _minContentPaneWidth =
      ZetaBreakpoints.paneMinContent; // 360[cite: 1]
  static const double _collapseThreshold = 180.0; //[cite: 1]
  static const String _prefKeyPaneWidth = 'revision_pane_width'; //[cite: 1]
  static const String _prefKeyPaneCollapsed =
      'revision_pane_collapsed'; //[cite: 1]

  double _paneWidth = _defaultPaneWidth;
  bool _hasCustomWidth = false;
  bool _isPaneCollapsed = false;

  // ─── Pane Switching State ──────────────────────────────────────────────────
  RevisionRightPaneMode _rightPaneMode = RevisionRightPaneMode.topics;
  ChapterTopic? _activeTopicForNotes;

  // ─── Compact mobile hierarchical navigation state ──────────────────────────
  String? _selectedSubjectForMobile;
  bool _isMobileNotesOpen = false;
  String? _lastSubjectId;
  int _previousSubjectIndex = 0;
  RevisionProvider? _revProvider;

  @override
  void initState() {
    super.initState();
    _selectedSubjectForMobile = null;
    _isMobileNotesOpen = false;
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
    _isMobileNotesOpen = false;
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
    _isMobileNotesOpen = false;
    final rev = _revProvider;
    if (rev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rev.selectSubject(null);
      });
    }
    super.dispose();
  }

  void _loadSavedPaneSettings() {
    try {
      final prefs = PreferencesService.instance;
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
      final prefs = PreferencesService.instance;
      await prefs.setDouble(_prefKeyPaneWidth, _paneWidth);
      await prefs.setBool(_prefKeyPaneCollapsed, _isPaneCollapsed);
    } catch (_) {}
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

  void _openNotes({ChapterTopic? topic}) {
    ZetaHaptics.light();
    setState(() {
      _activeTopicForNotes = topic;
      _rightPaneMode = RevisionRightPaneMode.notes;
      _isMobileNotesOpen = true;
    });
  }

  void _closeNotes() {
    ZetaHaptics.light();
    setState(() {
      _rightPaneMode = RevisionRightPaneMode.topics;
      _isMobileNotesOpen = false;
    });
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

  // ─── Single Pane (Mobile Android / Tablet Portrait) ────────────────────────
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

    int currentSubjectIndex = 0;
    if (_isMobileNotesOpen && selectedSubject != null) {
      currentSubjectIndex = 2;
    } else if (selectedSubject != null) {
      currentSubjectIndex = 1;
    }

    final int prevIdx = _previousSubjectIndex;
    if (_lastSubjectId != '${selectedSubject?.id}_$_isMobileNotesOpen') {
      _previousSubjectIndex = currentSubjectIndex;
      _lastSubjectId = '${selectedSubject?.id}_$_isMobileNotesOpen';
    }

    return PopScope(
      canPop: selectedSubject == null && !_isMobileNotesOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMobileNotesOpen) {
          _closeNotes();
          return;
        }
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
        child: currentSubjectIndex == 2 && selectedSubject != null
            ? Scaffold(
                key: ValueKey<String>(
                  'revision_mobile_notes_${selectedSubject.id}_${_activeTopicForNotes?.id}',
                ),
                backgroundColor: colorScheme.surface,
                body: SafeArea(
                  child: RevisionNotesPane(
                    subject: selectedSubject,
                    initialTopic: _activeTopicForNotes,
                    onBack: _closeNotes,
                  ),
                ),
              )
            : currentSubjectIndex == 1 && selectedSubject != null
            ? CustomScrollView(
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
                      M3EIconButton(
                        variant: M3EIconButtonVariant.tonal,
                        size: M3EIconButtonSize.sm,
                        width: M3EIconButtonWidth.wide,
                        icon: const Icon(Icons.description_outlined, size: 19),
                        tooltip: 'Notes',
                        onPressed: () => _openNotes(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8, left: 4),
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
                    sliver: SliverToBoxAdapter(
                      child: RevisionPane2(
                        isSplitPane: false,
                        onOpenNotes: (topic) => _openNotes(topic: topic),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
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
                  onOpenNotes: (sub) {
                    setState(() {
                      _selectedSubjectForMobile = sub.id;
                      revProvider.selectSubject(sub.id);
                    });
                    _openNotes();
                  },
                ),
              ),
      ),
    );
  }

  // ─── Two-Pane Layout (Desktop & Tablets ≥ 840dp) ───────────────────────────
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
        final selectedSubject = revProvider.selectedSubject;

        if (_isPaneCollapsed) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCollapsedExpandAffordance(colorScheme),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _rightPaneMode == RevisionRightPaneMode.notes &&
                            selectedSubject != null
                        ? RevisionNotesPane(
                            key: ValueKey(
                              'notes_pane_${selectedSubject.id}_${_activeTopicForNotes?.id}',
                            ),
                            subject: selectedSubject,
                            initialTopic: _activeTopicForNotes,
                            onBack: _closeNotes,
                          )
                        : CustomScrollView(
                            key: ValueKey<String>(
                              'revision_topics_${selectedSubject?.id ?? "none"}',
                            ),
                            slivers: [
                              SliverAppBar.large(
                                backgroundColor: isDark
                                    ? colorScheme.surfaceContainerHigh
                                    : colorScheme.surfaceContainer,
                                pinned: true,
                                automaticallyImplyLeading: false,
                                scrolledUnderElevation: 2,
                                title: Text(selectedSubject?.name ?? 'Topics'),
                                actions: [
                                  if (selectedSubject != null) ...[
                                    M3EIconButton(
                                      variant: M3EIconButtonVariant.tonal,
                                      size: M3EIconButtonSize.sm,
                                      width: M3EIconButtonWidth.wide,
                                      icon: const Icon(
                                        Icons.description_outlined,
                                        size: 19,
                                      ),
                                      tooltip: 'Notes & Resources',
                                      onPressed: () => _openNotes(),
                                    ),
                                    const SizedBox(width: 6),
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
                                ],
                              ),
                              if (selectedSubject == null)
                                const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: RevisionPane2(isSplitPane: true),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    80,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: RevisionPane2(
                                      isSplitPane: true,
                                      onOpenNotes: (topic) =>
                                          _openNotes(topic: topic),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        }

        final currentPercentage = (effectiveWidth / totalWidth) * 100;
        final minPercent = (_minPaneWidth / totalWidth) * 100;
        final maxPercent = (maxAllowedWidth / totalWidth) * 100;

        final snapPointsPercent = <double>[
          (240.0 / totalWidth) * 100,
          (_defaultPaneWidth / totalWidth) * 100,
          (_largePaneWidth / totalWidth) * 100,
          (totalWidth * 0.5 / totalWidth) * 100,
        ];

        return M3ESplitPane(
          value: currentPercentage.clamp(minPercent, maxPercent),
          min: minPercent,
          max: maxPercent,
          detents: snapPointsPercent,
          label: 'Drag to resize · Double-tap to reset (${(_hasCustomWidth ? _paneWidth : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth)).toInt()}dp)',
          onChanged: (val) {
             final newWidth = totalWidth * (val / 100);
             if (newWidth < _collapseThreshold) {
                setState(() {
                  _isPaneCollapsed = true;
                  _hasCustomWidth = true;
                });
                ZetaHaptics.light();
             } else {
                setState(() {
                  _paneWidth = newWidth;
                  _hasCustomWidth = true;
                  _isPaneCollapsed = false;
                });
             }
          },
          onChangeEnd: (val) => _persistPaneSettings(),
          onDoubleTap: () => _handlePaneDoubleTap(totalWidth),
          start: SingleChildScrollView(
            key: const PageStorageKey<String>('revision_subjects_pane'),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            child: RevisionPane1(
              isSplitPane: true,
              onOpenNotes: (sub) {
                revProvider.selectSubject(sub.id);
                _openNotes();
              },
            ),
          ),
          end: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 6),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _rightPaneMode == RevisionRightPaneMode.notes &&
                      selectedSubject != null
                  ? RevisionNotesPane(
                      key: ValueKey(
                        'notes_pane_${selectedSubject.id}_${_activeTopicForNotes?.id}',
                      ),
                      subject: selectedSubject,
                      initialTopic: _activeTopicForNotes,
                      onBack: _closeNotes,
                    )
                  : CustomScrollView(
                      key: ValueKey<String>(
                        'revision_topics_${selectedSubject?.id ?? "none"}',
                      ),
                      slivers: [
                        SliverAppBar.large(
                          backgroundColor: isDark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainer,
                          pinned: true,
                          automaticallyImplyLeading: false,
                          scrolledUnderElevation: 2,
                          title: Text(selectedSubject?.name ?? 'Topics'),
                          actions: [
                            if (selectedSubject != null) ...[
                              M3EIconButton(
                                variant: M3EIconButtonVariant.tonal,
                                size: M3EIconButtonSize.sm,
                                width: M3EIconButtonWidth.wide,
                                icon: const Icon(
                                  Icons.description_outlined,
                                  size: 19,
                                ),
                                tooltip: 'Notes & Resources',
                                onPressed: () => _openNotes(),
                              ),
                              const SizedBox(width: 6),
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
                          ],
                        ),
                        if (selectedSubject == null)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: RevisionPane2(isSplitPane: true),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              80,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: RevisionPane2(
                                isSplitPane: true,
                                onOpenNotes: (topic) =>
                                    _openNotes(topic: topic),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
