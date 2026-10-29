import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// The settings categories mirroring Sharva.
enum SettingsCategory {
  profile,
  tasks,
  appearance,
  typography,
  weather,
  syncAndData,
  crossDevice,
  updates,
}

class SettingsCategoryItem {
  final SettingsCategory id;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;

  const SettingsCategoryItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<SettingsCategoryItem> kSettingsCategories = [
  SettingsCategoryItem(
    id: SettingsCategory.profile,
    label: 'Profile',
    description: 'Name and profile photo',
    icon: Symbols.person_outline_rounded,
    selectedIcon: Symbols.person_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.tasks,
    label: 'Tasks',
    description: 'Sorting, swipes, and behavior',
    icon: Symbols.fire_check_rounded,
    selectedIcon: Symbols.task_alt_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.appearance,
    label: 'Appearance',
    description: 'Theme, colors, motion, and density',
    icon: Symbols.format_paint_rounded,
    selectedIcon: Symbols.palette_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.typography,
    label: 'Typography',
    description: 'Flex fonts & per-role variable axes',
    icon: Symbols.slab_serif_rounded,
    selectedIcon: Symbols.text_fields_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.weather,
    label: 'Weather',
    description: 'Location and current conditions',
    icon: Symbols.partly_cloudy_day_rounded,
    selectedIcon: Symbols.partly_cloudy_day_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.syncAndData,
    label: 'Sync & Data',
    description: 'Cloud sync, backups, and storage',
    icon: Symbols.cloud_rounded,
    selectedIcon: Symbols.cloud_done_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.crossDevice,
    label: 'Cross-Device',
    description: 'Instant handoff between phone & PC',
    icon: Symbols.devices_rounded,
    selectedIcon: Symbols.devices_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.updates,
    label: 'Updates',
    description: 'Version, changelog, and downloads',
    icon: Symbols.mobile_arrow_down_rounded,
    selectedIcon: Symbols.mobile_menu_rounded,
  ),
];
