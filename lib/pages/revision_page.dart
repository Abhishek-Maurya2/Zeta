import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/revision.dart';
import '../providers/revision_provider.dart';
import '../providers/task_provider.dart';
import '../components/revision/revision_subject_card.dart';
import '../components/revision/revision_topic_tile.dart';
import '../components/revision/topic_edit_dialog.dart';
import '../theme/breakpoints.dart';
import '../utils/haptics.dart';
import '../widgets/m3_pane_divider.dart';
import '../widgets/segmented_column.dart';

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

  // ─── Compact mobile tab state ──────────────────────────────────────────────
  int _mobileTab = 0;

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
    final textTheme = Theme.of(context).textTheme;

    final revProvider = context.watch<RevisionProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (revProvider.isLoading) {
      return const Center(child: M3EProgressIndicator.circular(value: null));
    }

    if (!isTwoPane) {
      return _buildSinglePaneLayout(
        context,
        revProvider,
        taskProvider,
        colorScheme,
        textTheme,
        sizeClass,
      );
    }

    return _buildTwoPaneLayout(
      context,
      revProvider,
      taskProvider,
      colorScheme,
      textTheme,
    );
  }

  // ─── Single Pane (mobile/tablet portrait) ─────────────────────────────────
  Widget _buildSinglePaneLayout(
    BuildContext context,
    RevisionProvider revProvider,
    TaskProvider taskProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ZetaWindowSizeClass sizeClass,
  ) {
    final selectedSubject = revProvider.selectedSubject;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          pinned: true,
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 2,
          title: const Text('Revision'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: M3EButtonGroup(
                      type: M3EButtonGroupType.connected,
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.tonal,
                      selectedIndex: _mobileTab,
                      onSelectedIndexChanged: (idx) {
                        if (idx == null) return;
                        ZetaHaptics.selection();
                        setState(() => _mobileTab = idx);
                      },
                      actions: [
                        const M3EButtonGroupAction(label: Text('Subjects')),
                        M3EButtonGroupAction(
                          label: Text(
                            'Topics · ${selectedSubject?.name ?? 'None'}',
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
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            sizeClass.isCompact
                ? ZetaBreakpoints.marginCompact
                : ZetaBreakpoints.marginExpanded,
            16,
            sizeClass.isCompact
                ? ZetaBreakpoints.marginCompact
                : ZetaBreakpoints.marginExpanded,
            80,
          ),
          sliver: SliverToBoxAdapter(
            child: _mobileTab == 0
                ? _buildSubjectsPane(
                    context,
                    revProvider,
                    colorScheme,
                    textTheme,
                    isSplitPane: false,
                  )
                : _buildTopicsPane(
                    context,
                    revProvider,
                    taskProvider,
                    colorScheme,
                    textTheme,
                    isSplitPane: false,
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Two-Pane Layout (≥ 840dp) ─────────────────────────────────────────────
  Widget _buildTwoPaneLayout(
    BuildContext context,
    RevisionProvider revProvider,
    TaskProvider taskProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Left Pane: Subjects ────────────────────────────────────
            if (_isPaneCollapsed)
              _buildCollapsedExpandAffordance(colorScheme)
            else
              SizedBox(
                width: effectiveWidth,
                child: CustomScrollView(
                  key: const PageStorageKey<String>('revision_subjects_pane'),
                  slivers: [
                    SliverAppBar.large(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      scrolledUnderElevation: 2,
                      title: const Text('Subjects'),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: M3EButton.icon(
                            onPressed: () {
                              ZetaHaptics.light();
                              AddSubjectDialog.show(context);
                            },
                            style: M3EButtonStyle.tonal,
                            size: M3EButtonSize.sm,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildSubjectsPane(
                          context,
                          revProvider,
                          colorScheme,
                          textTheme,
                          isSplitPane: true,
                        ),
                      ),
                    ),
                  ],
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

            // ─── Right Pane: Topics ─────────────────────────────────────
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainer,
                child: CustomScrollView(
                  key: ValueKey<String>(
                    'revision_topics_${revProvider.selectedSubject?.id ?? "none"}',
                  ),
                  slivers: [
                    SliverAppBar.large(
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
                            child: M3EButton.icon(
                              onPressed: () {
                                ZetaHaptics.light();
                                AddTopicDialog.show(
                                  context,
                                  subjectId: revProvider.selectedSubject!.id,
                                );
                              },
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.sm,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Topic'),
                            ),
                          ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                      sliver: SliverToBoxAdapter(
                        child: _buildTopicsPane(
                          context,
                          revProvider,
                          taskProvider,
                          colorScheme,
                          textTheme,
                          isSplitPane: true,
                        ),
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

  // ─── Summary stats strip ───────────────────────────────────────────────────
  Widget _buildSummaryStrip(
    BuildContext context,
    RevisionProvider revProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            label: 'Topics',
            value: '${revProvider.totalTopicsCount}',
            icon: Icons.topic_rounded,
            color: colorScheme.primary,
          ),
          _buildStatItem(
            context,
            label: 'Due Today',
            value: '${revProvider.dueRevisionsCount}',
            icon: Icons.notifications_active_rounded,
            color: revProvider.dueRevisionsCount > 0
                ? colorScheme.error
                : colorScheme.onPrimaryContainer,
          ),
          _buildStatItem(
            context,
            label: 'Mastered',
            value: '${revProvider.masteredTopicsCount}',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  // ─── Subjects pane content ─────────────────────────────────────────────────
  Widget _buildSubjectsPane(
    BuildContext context,
    RevisionProvider revProvider,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool isSplitPane,
  }) {
    final subjects = revProvider.subjects;
    final selectedSubject = revProvider.selectedSubject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryStrip(context, revProvider, colorScheme, textTheme),
        const SizedBox(height: 20),

        if (!isSplitPane)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subjects',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                M3EButton.icon(
                  onPressed: () {
                    ZetaHaptics.light();
                    AddSubjectDialog.show(context);
                  },
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
          ),

        if (subjects.isEmpty)
          ZetaEmptyState.revision(
            icon: Icons.auto_stories_rounded,
            shapeKind: M3EShapeKind.cookie4Sided,
            title: 'No subjects yet',
            subtitle: 'Tap "+ Add" to create your first subject and start your study schedule.',
            size: isSplitPane
                ? ZetaEmptyStateSize.compact
                : ZetaEmptyStateSize.standard,
            actionLabel: 'Add Subject',
            actionIcon: Icons.add_rounded,
            onAction: () => AddSubjectDialog.show(context),
          )
        else
          M3ESegmentedColumn(
            padding: EdgeInsets.zero,
            color: colorScheme.surfaceContainerLowest,
            selectedIndex: selectedSubject != null
                ? subjects.indexWhere((s) => s.id == selectedSubject.id)
                : null,
            onTap: (index) {
              if (index < 0 || index >= subjects.length) return;
              final sub = subjects[index];
              ZetaHaptics.selection();
              revProvider.selectSubject(sub.id);
              if (!isSplitPane) setState(() => _mobileTab = 1);
            },
            colorBuilder: (index) {
              if (index < 0 || index >= subjects.length) return null;
              final sub = subjects[index];
              if (selectedSubject?.id == sub.id) {
                return colorScheme.secondaryContainer;
              }
              return null;
            },
            borderRadiusBuilder: (index, position) {
              if (index < 0 || index >= subjects.length) return null;
              final sub = subjects[index];
              if (selectedSubject?.id == sub.id) {
                return BorderRadius.circular(52);
              }
              return null;
            },
            children: subjects.asMap().entries.map((entry) {
              final sub = entry.value;
              final isSelected = selectedSubject?.id == sub.id;
              final subTopics = revProvider.topics
                  .where((t) => t.subjectId == sub.id)
                  .toList();
              final completedCount = subTopics
                  .where((t) => t.isCompleted || t.isMastered)
                  .length;
              final dueCount = subTopics
                  .where((t) => t.status == RevisionStatus.overdue)
                  .length;

              return RevisionSubjectCard(
                key: ValueKey(sub.id),
                subject: sub,
                isSelected: isSelected,
                totalTopics: subTopics.length,
                completedTopics: completedCount,
                dueCount: dueCount,
                onDelete: () => revProvider.deleteSubject(sub.id),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ─── Topics pane content ───────────────────────────────────────────────────
  Widget _buildTopicsPane(
    BuildContext context,
    RevisionProvider revProvider,
    TaskProvider taskProvider,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool isSplitPane,
  }) {
    final selectedSubject = revProvider.selectedSubject;
    final topics = revProvider.topicsForSelectedSubject;

    if (selectedSubject == null) {
      return ZetaEmptyState(
        icon: Icons.touch_app_rounded,
        shapeKind: M3EShapeKind.ghostish,
        title: 'Select a subject',
        subtitle: isSplitPane
            ? 'Choose a subject from the left pane to view and track topics.'
            : 'Select a subject to view and track topics.',
        size: ZetaEmptyStateSize.standard,
      );
    }

    if (topics.isEmpty) {
      return ZetaEmptyState.revision(
        icon: Icons.library_books_rounded,
        shapeKind: M3EShapeKind.cookie9Sided,
        title: 'No topics yet',
        subtitle:
            'Add chapters or topics to start tracking spaced repetition reviews.',
        size: ZetaEmptyStateSize.standard,
        actionLabel: 'Add First Topic',
        actionIcon: Icons.add_rounded,
        onAction: () =>
            AddTopicDialog.show(context, subjectId: selectedSubject.id),
      );
    }

    return M3ESegmentedColumn(
      padding: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLowest,
      children: topics.map((topic) {
        return RevisionTopicTile(
          key: ValueKey(topic.id),
          topic: topic,
          onComplete: () {
            ZetaHaptics.medium();
            revProvider.completeTopic(topic.id, taskProvider);
          },
          onDelete: () => revProvider.deleteTopic(topic.id),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
