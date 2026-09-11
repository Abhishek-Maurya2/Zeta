import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/segmented_column.dart';
import '../widgets/m3_pane_divider.dart';

import '../components/settings/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _defaultPaneWidth = 310.0;
  static const double _largePaneWidth = 360.0;
  static const double _minPaneWidth = 240.0;
  static const double _minContentPaneWidth = 380.0;
  static const double _collapseThreshold = 180.0;
  static const String _prefKeyPaneWidth = 'settings_pane_width';
  static const String _prefKeyPaneCollapsed = 'settings_pane_collapsed';

  SettingsCategory? _selectedCategory;
  double _paneWidth = _defaultPaneWidth;
  bool _hasCustomWidth = false;
  bool _isPaneCollapsed = false;

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
      HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
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
          HapticFeedback.lightImpact();
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
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final isTwoPane = width >= 640;

    final activeCategory = isTwoPane
        ? (_selectedCategory ?? SettingsCategory.profile)
        : _selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Header ─────────────────────────────────────────────────────
        if (!isTwoPane) ...[
          // Compact Header (shows back button when sub-section is active)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: [
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                  icon: Icon(
                    _selectedCategory != null
                        ? Icons.arrow_back_rounded
                        : Icons.settings_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    if (_selectedCategory != null) {
                      setState(() => _selectedCategory = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory != null
                      ? kSettingsCategories
                            .firstWhere((c) => c.id == _selectedCategory)
                            .label
                      : 'Settings',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Expanded Page Header
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 20, 36, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your workspace preferences, theme, and automation.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPaneCollapsed
                        ? Icons.view_sidebar_outlined
                        : Icons.view_sidebar_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: _isPaneCollapsed
                      ? 'Show navigation pane'
                      : 'Hide navigation pane',
                  onPressed: () {
                    setState(() {
                      _isPaneCollapsed = !_isPaneCollapsed;
                      if (!_isPaneCollapsed && _paneWidth < _minPaneWidth) {
                        _paneWidth = _defaultPaneWidth;
                      }
                    });
                    HapticFeedback.lightImpact();
                    _persistPaneSettings();
                  },
                ),
              ],
            ),
          ),
        ],

        // ─── Body Content ───────────────────────────────────────────────
        Expanded(
          child: isTwoPane
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.sizeOf(context).width;

                    final maxAllowedWidth =
                        (totalWidth - _minContentPaneWidth - 16.0).clamp(
                          _minPaneWidth,
                          totalWidth * 0.6,
                        );
                    final currentWidth = _hasCustomWidth
                        ? _paneWidth
                        : (totalWidth >= 1200
                              ? _largePaneWidth
                              : _defaultPaneWidth);
                    final effectiveWidth = currentWidth.clamp(
                      _minPaneWidth,
                      maxAllowedWidth,
                    );

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isPaneCollapsed) ...[
                            _buildCollapsedExpandAffordance(colorScheme),
                            const SizedBox(width: 12),
                          ] else ...[
                            // Left Pane: Category Navigation
                            SizedBox(
                              width: effectiveWidth,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildCategoryList(
                                  context,
                                  activeCategory: activeCategory,
                                  isTwoPane: true,
                                ),
                              ),
                            ),

                            // Material 3 Draggable Pane Divider
                            M3PaneDivider(
                              onDragUpdate: (delta) =>
                                  _handlePaneDrag(delta, totalWidth),
                              onDragEnd: _persistPaneSettings,
                              onDoubleTap: () =>
                                  _handlePaneDoubleTap(totalWidth),
                              tooltip: 'Drag to resize navigation · Double-tap to reset (310dp)',
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Right Pane: Active Category Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 28),
                              child: _buildCategoryContent(activeCategory),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: _selectedCategory != null
                      ? _buildCategoryContent(_selectedCategory)
                      : _buildCategoryList(
                          context,
                          activeCategory: null,
                          isTwoPane: false,
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
    BuildContext context, {
    required SettingsCategory? activeCategory,
    required bool isTwoPane,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Text(
                'PREFERENCES',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (isTwoPane) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                  tooltip: 'Collapse navigation pane',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    setState(() => _isPaneCollapsed = true);
                    HapticFeedback.lightImpact();
                    _persistPaneSettings();
                  },
                ),
              ],
            ],
          ),
        ),
        M3ESegmentedColumn(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: colorScheme.surfaceContainer,
          selectedIndex: selectedIndex,
          onTap: (index) {
            setState(() => _selectedCategory = kSettingsCategories[index].id);
          },
          children: kSettingsCategories.map((category) {
            final isSelected = isTwoPane && activeCategory == category.id;

            return Row(
              children: [
                Icon(
                  isSelected ? category.selectedIcon : category.icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        category.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.outlineVariant,
                ),
              ],
            );
          }).toList(),
        ),
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
      case SettingsCategory.pomodoro:
        return PomodoroSettingsSection(onToast: _showToast);
      case SettingsCategory.notifications:
        return NotificationsSyncSection(onToast: _showToast);
      case SettingsCategory.googleSync:
        return GoogleSyncSection(onToast: _showToast);
      case SettingsCategory.data:
        return DataPrivacySection(onToast: _showToast);
      case null:
        return const SizedBox.shrink();
    }
  }
}
