import 'dart:math' as math;

import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../components/m3e_split_pane.dart';
import '../../utils/haptics.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/update_provider.dart';
import '../../features/settings/presentation/state/settings_split_pane_provider.dart';
import '../../components/m3e_page_transition.dart';
import '../../theme/motion_tokens.dart';
import '../../theme/breakpoints.dart';

import 'components/settings_category.dart';
import 'components/settings_detail_pane.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Transition tracking for wide mode
  SettingsCategory? _wideLastCategory;
  int _widePreviousIndex = 0;

  Widget _buildCollapsedExpandAffordance(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Expand navigation pane',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref.read(settingsSplitPaneProvider.notifier).setCollapsed(false);
          ZetaHaptics.light();
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
    final splitPaneState = ref.watch(settingsSplitPaneProvider);
    final splitPaneNotifier = ref.read(settingsSplitPaneProvider.notifier);
    final colorScheme = context.colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isTwoPane = sizeClass.isMultiPane;

    final selectedCategory = navProvider.selectedSettingsCategory;
    final activeCategory = selectedCategory;

    final activeCategoryMeta = activeCategory != null
        ? kSettingsCategories.firstWhere((c) => c.id == activeCategory)
        : null;

    final int currentWideIdx = activeCategory?.index ?? 0;
    final int prevWideIdx = _widePreviousIndex;
    if (isTwoPane && _wideLastCategory != activeCategory) {
      _widePreviousIndex = currentWideIdx;
      _wideLastCategory = activeCategory;
    }

    // Compact mode: The category detail is presented as a separate route in BodyPane
    // so Android predictive back previews the Settings list cleanly underneath.
    if (!isTwoPane) {
      return CustomScrollView(
        key: const ValueKey<String>('settings_compact_root'),
        slivers: [
          M3EAppBar.sliver(
            backgroundColor: colorScheme.surfaceContainerLow,
            titleText: 'Settings',
            centerTitle: true,
            variant: M3EAppBarVariant.large,
            hideMode: M3EAppBarHideMode.actions,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: sizeClass.isCompact
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final upperBound = math.max(
          SettingsSplitPaneState.minPaneWidth,
          totalWidth * 0.6,
        );
        final maxAllowedWidth =
            (totalWidth - SettingsSplitPaneState.minContentPaneWidth - 16.0)
                .clamp(SettingsSplitPaneState.minPaneWidth, upperBound);

        final currentWidth = splitPaneState.hasCustomWidth
            ? splitPaneState.paneWidth
            : (totalWidth >= 1200
                  ? SettingsSplitPaneState.largePaneWidth
                  : SettingsSplitPaneState.defaultPaneWidth);
        final effectiveWidth = currentWidth.clamp(
          SettingsSplitPaneState.minPaneWidth,
          maxAllowedWidth,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textTheme = context.textTheme;

        if (splitPaneState.isPaneCollapsed) {
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
                    previousIndex: prevWideIdx,
                    transitionType: M3EPageTransitionType.fadeThrough,
                    duration: M3MotionDuration.medium2,
                    child: CustomScrollView(
                      key: ValueKey<String>(
                        'settings_wide_detail_${activeCategory?.name ?? "default"}',
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                            child: Text(
                              activeCategoryMeta?.label ?? 'Settings',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SettingsDetailPane(
                            activeCategory: activeCategory,
                            activeCategoryMeta: activeCategoryMeta,
                            isTwoPane: true,
                            onToast: _showToast,
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
            ? (SettingsSplitPaneState.minPaneWidth / totalWidth) * 100
            : 0.0;
        final maxPercent = totalWidth > 0
            ? (maxAllowedWidth / totalWidth) * 100
            : 100.0;

        final snapPointsPercent = <double>[
          (280.0 / totalWidth) * 100,
          (SettingsSplitPaneState.defaultPaneWidth / totalWidth) * 100,
          (SettingsSplitPaneState.largePaneWidth / totalWidth) * 100,
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
          label: 'Drag to resize navigation · Double-tap to reset',
          onChanged: (val) {
            final newWidth = totalWidth * (val / 100);
            splitPaneNotifier.setWidth(newWidth);
          },
          onChangeEnd: (val) {
            final finalWidth = totalWidth * (val / 100);
            splitPaneNotifier.onDragEnd(finalWidth, totalWidth);
          },
          onDoubleTap: () => splitPaneNotifier.handleDoubleTap(totalWidth),
          start: CustomScrollView(
            key: const PageStorageKey<String>('settings_wide_nav'),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Settings',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              color: colorScheme.surfaceContainerHigh,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text(
                        activeCategoryMeta?.label ?? 'Settings',
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SettingsDetailPane(
                      activeCategory: activeCategory,
                      activeCategoryMeta: activeCategoryMeta,
                      isTwoPane: true,
                      onToast: _showToast,
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

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
              leading: Icon(
                isSelected ? category.selectedIcon : category.icon,
                fill: isSelected ? 1 : 0,
                weight: 700,
                size: 23,
              ),
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
