import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Reusable settings row with a title, current value, and expressive slider.
class SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String currentLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<int> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.currentLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                currentLabel,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ],
      ),
    );
  }
}
