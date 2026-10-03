import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../components/m3e_split_pane.dart';
import '../../utils/haptics.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/update_provider.dart';
import '../../services/preferences_service.dart';
import '../../components/m3e_page_transition.dart';
import '../../theme/motion_tokens.dart';
import '../../theme/breakpoints.dart';

import 'components/settings_category.dart';

import 'components/settings_detail_pane.dart';

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

  // Transition tracking for compact mode
  SettingsCategory? _lastCategory;
  int _previousCategoryIndex = 0;

  // Transition tracking for wide mode
  SettingsCategory? _wideLastCategory;
  int _widePreviousIndex = 0;

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

    // Fix: Properly track indices for both compact and wide layouts to prevent transition freezing
    final int currentCompactIdx = selectedCategory != null ? 1 : 0;
    final int prevCompactIdx = _previousCategoryIndex;
    if (!isTwoPane && _lastCategory != selectedCategory) {
      _previousCategoryIndex = currentCompactIdx;
      _lastCategory = selectedCategory;
    }

    final int currentWideIdx = activeCategory?.index ?? 0;
    final int prevWideIdx = _widePreviousIndex;
    if (isTwoPane && _wideLastCategory != activeCategory) {
      _widePreviousIndex = currentWideIdx;
      _wideLastCategory = activeCategory;
    }

    if (!isTwoPane) {
      return M3EPageTransition(
        currentIndex: currentCompactIdx,
        previousIndex: prevCompactIdx,
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
                      child: SettingsDetailPane(
                        activeCategory: selectedCategory,
                        activeCategoryMeta: activeCategoryMeta,
                        isTwoPane: false,
                        isCompact: isCompact,
                        onToast: _showToast,
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final upperBound = math.max(_minPaneWidth, totalWidth * 0.6);
        final maxAllowedWidth = (totalWidth - _minContentPaneWidth - 16.0)
            .clamp(_minPaneWidth, upperBound);
        final currentWidth = _hasCustomWidth
            ? _paneWidth
            : (totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth);
        final effectiveWidth = currentWidth.clamp(
          _minPaneWidth,
          maxAllowedWidth,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;

        if (_isPaneCollapsed) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCollapsedExpandAffordance(colorScheme),
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
                    currentIndex: currentWideIdx,
                    previousIndex: prevWideIdx, // Fixed hardcoded 0
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
                            child: SettingsDetailPane(
                              activeCategory: activeCategory,
                              activeCategoryMeta: activeCategoryMeta,
                              isTwoPane: true,
                              onToast: _showToast,
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

        final currentPercentage = totalWidth > 0
            ? (effectiveWidth / totalWidth) * 100
            : 0.0;
        final minPercent = totalWidth > 0
            ? (_minPaneWidth / totalWidth) * 100
            : 0.0;
        final maxPercent = totalWidth > 0
            ? (maxAllowedWidth / totalWidth) * 100
            : 100.0;

        final snapPointsPercent = <double>[
          (280.0 / totalWidth) * 100,
          (_defaultPaneWidth / totalWidth) * 100,
          (_largePaneWidth / totalWidth) * 100,
          (412.0 / totalWidth) * 100,
          (totalWidth * 0.5 / totalWidth) * 100,
        ];

        return M3ESplitPane(
          value: currentPercentage.clamp(
            math.min(minPercent, maxPercent),
            math.max(minPercent, maxPercent),
          ),
          min: math.min(minPercent, maxPercent),
          max: math.max(minPercent, maxPercent),
          detents: snapPointsPercent,
          label:
              'Drag to resize navigation · Double-tap to reset (${(totalWidth >= 1200 ? _largePaneWidth : _defaultPaneWidth).toInt()}dp)',
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
          start: CustomScrollView(
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
          end: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 6),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: M3EPageTransition(
              currentIndex: currentWideIdx,
              previousIndex: prevWideIdx,
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
                      child: SettingsDetailPane(
                        activeCategory: activeCategory,
                        activeCategoryMeta: activeCategoryMeta,
                        isTwoPane: true,
                        onToast: _showToast,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 15),
          child: Text(
            'Preferences',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: colorScheme.primary,
            ),
          ),
        ),
        M3EList(
          itemCount: kSettingsCategories.length,
          gap: 4,
          colorBuilder: (index) {
            final category = kSettingsCategories[index];
            final isSelected = isTwoPane && activeCategory == category.id;
            return isSelected
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerLowest;
          },
          borderRadiusBuilder: (index, position) {
            final category = kSettingsCategories[index];
            final isSelected = isTwoPane && activeCategory == category.id;
            if (isSelected) {
              return BorderRadius.circular(100);
            }
            return calculateCardRadius(
              position: position,
              outerRadius: M3EListCardListTheme.defaultOuterRadius,
              innerRadius: M3EListCardListTheme.defaultInnerRadius,
            );
          },
          onTap: (index) {
            ZetaHaptics.selection();
            context.read<NavigationProvider>().setSettingsCategory(
              kSettingsCategories[index].id,
            );
          },
          itemBuilder: (context, index) {
            final category = kSettingsCategories[index];
            final isSelected = isTwoPane && activeCategory == category.id;

            return M3EListItem(
              selected: isSelected,
              leading: Icon(isSelected ? category.selectedIcon : category.icon),
              headline: category.label,
              supportingText: category.description,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (!isTwoPane) const Icon(Icons.chevron_right_rounded),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}
