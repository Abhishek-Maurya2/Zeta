import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum SettingsSwitchTileLayout { listItem, inline }

/// Reusable settings row with consistent switch, subtitle, and tap behavior.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final Widget? selectedIcon;
  final Widget? unselectedIcon;
  final SettingsSwitchTileLayout layout;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.selectedIcon,
    this.unselectedIcon,
    this.layout = SettingsSwitchTileLayout.listItem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final disabledAlpha = enabled ? 1.0 : 0.38;
    final resolvedLeading = leading ??
        (icon == null
            ? null
            : Icon(
                icon,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: disabledAlpha,
                ),
              ));

    final toggle = M3ESwitch(
      value: value,
      selectedIcon: selectedIcon,
      unselectedIcon: unselectedIcon,
      onChanged: enabled ? onChanged : null,
    );

    if (layout == SettingsSwitchTileLayout.listItem) {
      return M3EListItem(
        enabled: enabled,
        leading: resolvedLeading,
        headline: title,
        supportingText: subtitle,
        trailing: toggle,
        onTap: enabled ? () => onChanged(!value) : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (resolvedLeading != null) ...[
            resolvedLeading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(
                      alpha: disabledAlpha,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: disabledAlpha,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          toggle,
        ],
      ),
    );
  }
}
