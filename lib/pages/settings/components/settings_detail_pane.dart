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
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SizedBox(height: 20), detailContent],
        ),
      );
    }

    return detailContent;
  }
}
