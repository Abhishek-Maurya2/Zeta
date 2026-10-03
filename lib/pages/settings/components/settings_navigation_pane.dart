import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../providers/navigation_provider.dart';
import '../../../providers/update_provider.dart';
import '../../../utils/haptics.dart';
import 'settings_category.dart';

class SettingsNavigationPane extends StatelessWidget {
  final SettingsCategory? activeCategory;
  final bool isTwoPane;
  final bool isCompact;
  final VoidCallback? onBack;

  const SettingsNavigationPane({
    super.key,
    required this.activeCategory,
    required this.isTwoPane,
    this.isCompact = false,
    this.onBack,
  });


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool isUpdateAvailable = false;
    try {
      isUpdateAvailable = context.watch<UpdateProvider>().isUpdateAvailable;
    } catch (_) {}

    final Widget listContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 15),
          child: Text(
            'Preferences',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: colorScheme.primary,
            ),
          ),
        ),
        ...kSettingsCategories.map((category) {
          final isSelected = isTwoPane && activeCategory == category.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(52),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ZetaHaptics.selection();
                    context.read<NavigationProvider>().setSettingsCategory(
                      category.id,
                    );
                  },
                  child: M3EListItem(
                    leading: Icon(
                      isSelected ? category.selectedIcon : category.icon,
                      size: 25,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
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
                        if (!isTwoPane)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: colorScheme.outlineVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 90),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Custom Pinned Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 24,
            isTwoPane ? 32 : 16,
            isCompact ? 12 : 24,
            16,
          ),
          child: Row(
            children: [
              if (!isTwoPane && isCompact && onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.sm,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colorScheme.onSurface,
                    ),
                    decoration: M3EIconButtonDecoration(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    onPressed: onBack,
                    tooltip: 'Back',
                  ),
                ),
              Text(
                'Settings',
                style: isTwoPane
                    ? textTheme.displaySmall?.copyWith(color: colorScheme.onSurface)
                    : textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            key: isTwoPane
                ? const PageStorageKey<String>('settings_wide_nav')
                : const ValueKey<String>('settings_compact_root'),
            padding: isTwoPane
                ? const EdgeInsets.fromLTRB(16, 4, 16, 24)
                : EdgeInsets.symmetric(
                    horizontal: isCompact ? 16.0 : 24.0,
                    vertical: 8,
                  ),
            child: listContent,
          ),
        ),
      ],
    );
  }
}
