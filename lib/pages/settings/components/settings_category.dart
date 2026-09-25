import 'package:material_ui/material_ui.dart';

/// The settings categories mirroring Sharva.
enum SettingsCategory {
  profile,
  appearance,
  typography,
  weather,
  notifications,
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
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.appearance,
    label: 'Appearance',
    description: 'Theme, colors, motion, and density',
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.typography,
    label: 'Typography',
    description: 'Flex fonts & per-role variable axes',
    icon: Icons.text_fields_outlined,
    selectedIcon: Icons.text_fields_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.weather,
    label: 'Weather',
    description: 'Location and current conditions',
    icon: Icons.wb_sunny_outlined,
    selectedIcon: Icons.wb_sunny_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.notifications,
    label: 'Notifications',
    description: 'Reminders and sound feedback',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.syncAndData,
    label: 'Sync & Data',
    description: 'Cloud sync, backups, and storage',
    icon: Icons.sync_alt_outlined,
    selectedIcon: Icons.sync_alt_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.crossDevice,
    label: 'Cross-Device',
    description: 'Instant handoff between phone & PC',
    icon: Icons.devices_outlined,
    selectedIcon: Icons.devices_rounded,
  ),
  SettingsCategoryItem(
    id: SettingsCategory.updates,
    label: 'Updates',
    description: 'Version, changelog, and downloads',
    icon: Icons.system_update_outlined,
    selectedIcon: Icons.system_update_rounded,
  ),
];
