import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/segmented_column.dart';
import '../../components/m3e_pane_divider.dart';
import '../../utils/haptics.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/update_provider.dart';
import '../../services/preferences_service.dart';
import '../../components/m3e_page_transition.dart';
import '../../theme/motion_tokens.dart';
import '../../theme/breakpoints.dart';

import 'components/settings_category.dart';
import 'components/profile_section.dart';
import 'components/appearance_section.dart';
import 'components/typography_section.dart';
import 'components/weather_section.dart';
import 'components/notifications_section.dart';
import 'components/sync_data_section.dart';
import 'components/updates_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _defaultPaneWidth = ZetaBreakpoints.paneFixedExpanded;
  static const double _largePaneWidth = ZetaBreakpoints.paneFixedLarge;
  static const double _minPaneWidth = ZetaBreakpoints.paneMinList;
  static const double _minContentPaneWidth = ZetaBreakpoints.paneMinContent;
  static const double _collapseThreshold = 180.0;
  static const String _prefKeyPaneWidth = 'settings_pane_width';
  static const String _prefKeyPaneCollapsed = 'settings_pane_collapsed';
  static const ShapeBorder _appBarShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
  );

  double _paneWidth = _defaultPaneWidth;
  bool _hasCustomWidth = false;
  bool _isPaneCollapsed = false;
  SettingsCategory? _lastCategory;
  int _previousCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedPaneSettings();
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

  void _handlePaneDrag(double delta, double totalWidth) {
    final maxAllowedWidth = (totalWidth - _minContentPaneWidth - 16.0).clamp(
      _minPaneWidth,
      totalWidth * 0.6,
    );

    // In Settings, dragging right (delta > 0) widens the left pane;
    // dragging left (delta < 0) narrows the left pane.
    var targetWidth =
        (_hasCustomWidth
            ? _paneWidth
            : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth)) +
        delta;

    // Check canonical snap points: 280, 310, 360, 412, and 50% split
    final snapPoints = <double>[
      280.0,
      _defaultPaneWidth,
      _largePaneWidth,
      412.0,
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
        // Toggle to 50% split if already at canonical standard 310
        _paneWidth = (totalWidth * 0.5).clamp(_minPaneWidth, maxAllowed);
      } else {
        // Reset to canonical standard 310
        _paneWidth = _defaultPaneWidth;
      }
    });
    ZetaHaptics.medium();
    _persistPaneSettings();
  }

  /// Compact vertical strip affordance on the left edge to re-expand the navigation pane
  Widget _buildCollapsedExpandAffordance(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Expand navigation pane',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _isPaneCollapsed = false;
            if (_paneWidth < _minPaneWidth) {
              _paneWidth = _defaultPaneWidth;
            }
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

  void _showToast(String message) {
    if (!mounted) return;
    M3ESnackbar.show(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isTwoPane = sizeClass.isMultiPane;

    final isCompact = sizeClass.isCompact;

    final selectedCategory = navProvider.selectedSettingsCategory;
    final activeCategory = isTwoPane
        ? (selectedCategory ?? SettingsCategory.profile)
        : selectedCategory;

    final activeCategoryMeta = activeCategory != null
        ? kSettingsCategories.firstWhere((c) => c.id == activeCategory)
        : null;

    if (!isTwoPane) {
      // ─── Compact/Medium Single Pane Hierarchical Layout (<840px) ───────────
      final int currentCategoryIndex = selectedCategory != null ? 1 : 0;
      final int prevIdx = _previousCategoryIndex;
      if (_lastCategory != selectedCategory) {
        _previousCategoryIndex = currentCategoryIndex;
        _lastCategory = selectedCategory;
      }

      return M3EPageTransition(
        currentIndex: currentCategoryIndex,
        previousIndex: prevIdx,
        transitionType: M3EPageTransitionType.sharedAxisX,
        duration: M3MotionDuration.medium2,
        child: selectedCategory == null
            ? CustomScrollView(
                key: const ValueKey<String>('settings_compact_root'),
                slivers: [
                  SliverAppBar.large(
                    pinned: true,
                    scrolledUnderElevation: 2,
                    shape: _appBarShape,
                    leading: isCompact
                        ? M3EIconButton(
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
                              navProvider.setActivePage(PageId.home);
                            },
                            tooltip: 'Back',
                          )
                        : null,
                    title: const Text('Settings'),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact
                          ? ZetaBreakpoints.marginCompact
                          : ZetaBreakpoints.marginExpanded,
                      vertical: 8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryList(
                        context,
                        activeCategory: null,
                        isTwoPane: false,
                      ),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                key: ValueKey<String>(
                  'settings_compact_${selectedCategory.name}',
                ),
                slivers: [
                  SliverAppBar.large(
                    pinned: true,
                    scrolledUnderElevation: 2,
                    shape: _appBarShape,
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
                        navProvider.clearSettingsCategory();
                      },
                      tooltip: 'Back',
                    ),
                    title: Text(activeCategoryMeta?.label ?? 'Settings'),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 12 : 24,
                      12,
                      isCompact ? 12 : 24,
                      isCompact ? 90 : 24,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryContent(selectedCategory),
                    ),
                  ),
                ],
              ),
      );
    }

    // ─── Wide Screen Two-Pane Layout with Elevated Supporting Pane (≥640px) ─
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
        final textTheme = Theme.of(context).textTheme;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isPaneCollapsed) ...[
              _buildCollapsedExpandAffordance(colorScheme),
            ] else ...[
              // Left Pane: Primary Settings Navigation Pane
              SizedBox(
                width: effectiveWidth,
                child: CustomScrollView(
                  key: const PageStorageKey<String>('settings_wide_nav'),
                  slivers: [
                    SliverAppBar.large(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      scrolledUnderElevation: 2,
                      shape: _appBarShape,
                      title: Text('Settings', style: textTheme.displaySmall),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildCategoryList(
                          context,
                          activeCategory: activeCategory,
                          isTwoPane: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Material 3 Draggable Pane Divider
              M3EPaneDivider(
                onDragUpdate: (delta) => _handlePaneDrag(delta, totalWidth),
                onDragEnd: _persistPaneSettings,
                onDoubleTap: () => _handlePaneDoubleTap(totalWidth),
                tooltip:
                    'Drag to resize navigation · Double-tap to reset (${(totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth).toInt()}dp)',
              ),
            ],

            // Right Pane: Secondary Elevated Supporting Pane
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
                child: M3EPageTransition(
                  currentIndex: activeCategory?.index ?? 0,
                  previousIndex: 0,
                  transitionType: M3EPageTransitionType.fadeThrough,
                  duration: M3MotionDuration.medium2,
                  child: CustomScrollView(
                    key: ValueKey<String>(
                      'settings_wide_detail_${activeCategory?.name ?? "default"}',
                    ),
                    slivers: [
                      SliverAppBar.large(
                        backgroundColor: isDark
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surfaceContainer,
                        scrolledUnderElevation: 2,
                        title: Text(
                          activeCategoryMeta?.label ?? 'Settings',
                          style: textTheme.displaySmall,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
                        sliver: SliverToBoxAdapter(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildCategoryContent(activeCategory),
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
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(
    BuildContext context, {
    required SettingsCategory? activeCategory,
    required bool isTwoPane,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool isUpdateAvailable = false;
    try {
      isUpdateAvailable = context.watch<UpdateProvider>().isUpdateAvailable;
    } catch (_) {}

    final selectedCategoryIndex = isTwoPane && activeCategory != null
        ? kSettingsCategories.indexWhere((c) => c.id == activeCategory)
        : null;
    final selectedIndex =
        selectedCategoryIndex != null && selectedCategoryIndex >= 0
        ? selectedCategoryIndex
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 15),
          child: Text(
            'Prefrences',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: colorScheme.primary,
            ),
          ),
        ),
        M3ESegmentedColumn(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          color: colorScheme.surfaceContainerLowest,
          selectedIndex: selectedIndex,
          onTap: (index) {
            ZetaHaptics.selection();
            context.read<NavigationProvider>().setSettingsCategory(
              kSettingsCategories[index].id,
            );
          },
          children: kSettingsCategories.map((category) {
            final isSelected = isTwoPane && activeCategory == category.id;

            return Row(
              children: [
                Icon(
                  isSelected ? category.selectedIcon : category.icon,
                  size: 25,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onSecondaryContainer.withValues(
                                  alpha: 0.8,
                                )
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (category.id == SettingsCategory.updates &&
                    isUpdateAvailable)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEW',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                if (!isTwoPane)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _buildCategoryContent(SettingsCategory? category) {
    switch (category) {
      case SettingsCategory.profile:
        return ProfileSection(onToast: _showToast);
      case SettingsCategory.appearance:
        return AppearanceSection(onToast: _showToast);
      case SettingsCategory.typography:
        return TypographySection(onToast: _showToast);
      case SettingsCategory.weather:
        return WeatherSection(onToast: _showToast);
      case SettingsCategory.notifications:
        return NotificationsSyncSection(onToast: _showToast);
      case SettingsCategory.syncAndData:
        return SyncDataSection(onToast: _showToast);
      case SettingsCategory.updates:
        return UpdatesSection(onToast: _showToast);
      case null:
        return const SizedBox.shrink();
    }
  }
}
