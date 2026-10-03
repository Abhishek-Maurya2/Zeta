import 'package:flutter/material.dart';

import 'settings_category.dart';
import 'profile_section.dart';
import 'appearance_section.dart';
import 'typography_section.dart';
import 'weather_section.dart';
import 'notifications_section.dart';
import 'sync_data_section.dart';
import 'cross_device_section.dart';
import 'updates_section.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

class SettingsDetailPane extends StatelessWidget {
  final SettingsCategory? activeCategory;
  final SettingsCategoryItem? activeCategoryMeta;
  final bool isTwoPane;
  final bool isCompact;
  final VoidCallback? onBack;
  final void Function(String message) onToast;

  const SettingsDetailPane({
    super.key,
    required this.activeCategory,
    this.activeCategoryMeta,
    this.isTwoPane = false,
    this.isCompact = false,
    this.onBack,
    required this.onToast,
  });


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget detailContent;
    switch (activeCategory) {
      case SettingsCategory.profile:
        detailContent = ProfileSection(onToast: onToast);
        break;
      case SettingsCategory.appearance:
        detailContent = AppearanceSection(onToast: onToast);
        break;
      case SettingsCategory.typography:
        detailContent = TypographySection(onToast: onToast);
        break;
      case SettingsCategory.weather:
        detailContent = WeatherSection(onToast: onToast);
        break;
      case SettingsCategory.notifications:
        detailContent = NotificationsSyncSection(onToast: onToast);
        break;
      case SettingsCategory.syncAndData:
        detailContent = SyncDataSection(onToast: onToast);
        break;
      case SettingsCategory.crossDevice:
        detailContent = CrossDeviceSection(onToast: onToast);
        break;
      case SettingsCategory.updates:
        detailContent = UpdatesSection(onToast: onToast);
        break;
      case null:
        detailContent = const SizedBox.shrink();
        break;
    }

    if (isTwoPane) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
            child: Text(
              activeCategoryMeta?.label ?? 'Settings',
              style: textTheme.displaySmall?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey<String>(
                'settings_wide_detail_${activeCategory?.name ?? "default"}',
              ),
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const SizedBox(height: 20), detailContent],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 24,
            16,
            isCompact ? 12 : 24,
            16,
          ),
          child: Row(
            children: [
              if (onBack != null)
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
                activeCategoryMeta?.label ?? 'Settings',
                style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey<String>(
              'settings_compact_${activeCategory?.name ?? "default"}',
            ),
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 24,
              12,
              isCompact ? 12 : 24,
              isCompact ? 90 : 24,
            ),
            child: detailContent,
          ),
        ),
      ],
    );
  }
}
