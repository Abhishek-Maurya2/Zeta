import 'package:material_ui/material_ui.dart';
import '../widgets/segmented_column.dart';

import '../components/settings/settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsCategory? _selectedCategory;

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

    return Container(
      color: colorScheme.surface,
      child: Column(
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
          ],

          // ─── Body Content ───────────────────────────────────────────────
          Expanded(
            child: isTwoPane
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane: Category Navigation
                        SizedBox(
                          width: 310,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildCategoryList(
                              context,
                              activeCategory: activeCategory,
                              isTwoPane: true,
                            ),
                          ),
                        ),

                        // Right Pane: Active Category Content
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(28),
                              child: _buildCategoryContent(activeCategory),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
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
          child: Text(
            'PREFERENCES',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        M3ESegmentedColumn(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
                              ? colorScheme.onSecondaryContainer
                                  .withValues(alpha: 0.8)
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
