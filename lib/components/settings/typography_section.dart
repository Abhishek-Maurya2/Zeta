import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class TypographySection extends StatelessWidget {
  final void Function(String message)? onToast;

  const TypographySection({super.key, this.onToast});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fontScaleLabel = themeProvider.fontScale == 'compact'
        ? 'Compact (92%)'
        : themeProvider.fontScale == 'large'
            ? 'Large (108%)'
            : 'Standard (100%)';

    final fontScaleValue = themeProvider.fontScale == 'compact'
        ? 0.0
        : themeProvider.fontScale == 'large'
            ? 2.0
            : 1.0;

    final cornerStyleLabel = themeProvider.cornerStyle == 'sharp'
        ? 'Sharp (8px)'
        : themeProvider.cornerStyle == 'classic'
            ? 'Classic (16px)'
            : 'Expressive (28px)';

    final cornerStyleValue = themeProvider.cornerStyle == 'sharp'
        ? 0.0
        : themeProvider.cornerStyle == 'classic'
            ? 1.0
            : 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TYPOGRAPHY & FONTS',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Google Sans Flex',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Font Choice Cards ──────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 540;
            return Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              children: [
                _buildFontCard(
                  context,
                  id: 'google-sans',
                  name: 'Google Sans Flex',
                  description: 'Material 3 Expressive variable typography',
                  fontFamily: GoogleFonts.inter().fontFamily,
                  isSelected: themeProvider.fontChoice == 'google-sans',
                  onTap: () {
                    themeProvider.setFontChoice('google-sans');
                    onToast?.call('Applied typography: Google Sans Flex');
                  },
                ),
                SizedBox(width: isNarrow ? 0 : 10, height: isNarrow ? 10 : 0),
                _buildFontCard(
                  context,
                  id: 'roboto',
                  name: 'Roboto Standard',
                  description: 'Classic Material Design geometric neo-grotesque',
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  isSelected: themeProvider.fontChoice == 'roboto',
                  onTap: () {
                    themeProvider.setFontChoice('roboto');
                    onToast?.call('Applied typography: Roboto Standard');
                  },
                ),
                SizedBox(width: isNarrow ? 0 : 10, height: isNarrow ? 10 : 0),
                _buildFontCard(
                  context,
                  id: 'system',
                  name: 'System Default',
                  description: 'Native operating system typography',
                  fontFamily: null,
                  isSelected: themeProvider.fontChoice == 'system',
                  onTap: () {
                    themeProvider.setFontChoice('system');
                    onToast?.call('Applied typography: System Default');
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // ─── Variable Font Axes & Geometry ──────────────────────────────
        Text(
          'OPTICAL AXES & SHAPE GEOMETRY',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainer,
          children: [
            // Roundness
            _buildSliderTile(
              context,
              icon: Icons.panorama_fish_eye_rounded,
              title: 'Font Roundness (ROND)',
              subtitle:
                  '${themeProvider.fontRoundness.round()} • Terminal curvature & curve softness',
              value: themeProvider.fontRoundness,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (val) => themeProvider.setFontRoundness(val),
              minLabel: '0 (Sharp)',
              midLabel: '50 (Soft)',
              maxLabel: '100 (Round)',
            ),

            // Weight
            _buildSliderTile(
              context,
              icon: Icons.format_bold_rounded,
              title: 'Font Weight (wght)',
              subtitle:
                  '${themeProvider.fontWeight.round()} • Continuous stroke weight',
              value: themeProvider.fontWeight,
              min: 100,
              max: 900,
              divisions: 16,
              onChanged: (val) => themeProvider.setFontWeight(val),
              minLabel: '100 (Thin)',
              midLabel: '400 (Regular)',
              maxLabel: '900 (Black)',
            ),

            // Width
            _buildSliderTile(
              context,
              icon: Icons.settings_ethernet_rounded,
              title: 'Font Width (wdth)',
              subtitle:
                  '${themeProvider.fontWidth.round()}% • Optical glyph expansion',
              value: themeProvider.fontWidth,
              min: 50,
              max: 150,
              divisions: 20,
              onChanged: (val) => themeProvider.setFontWidth(val),
              minLabel: '50% (Condensed)',
              midLabel: '100% (Normal)',
              maxLabel: '150% (Expanded)',
            ),

            // Text Size Scaling
            _buildSliderTile(
              context,
              icon: Icons.format_size_rounded,
              title: 'Text Size Scaling',
              subtitle:
                  '$fontScaleLabel • Adjust typography scaling workspace-wide',
              value: fontScaleValue,
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: (val) {
                final scale =
                    val == 0.0 ? 'compact' : (val == 2.0 ? 'large' : 'standard');
                themeProvider.setFontScale(scale);
                onToast?.call('Text scale set to $fontScaleLabel');
              },
              minLabel: 'Compact (92%)',
              midLabel: 'Standard (100%)',
              maxLabel: 'Large (108%)',
            ),

            // Corner Shape Geometry
            _buildSliderTile(
              context,
              icon: Icons.rounded_corner_rounded,
              title: 'Corner Shape Geometry',
              subtitle:
                  '$cornerStyleLabel • Control expressiveness of component corner radii',
              value: cornerStyleValue,
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: (val) {
                final style =
                    val == 0.0 ? 'sharp' : (val == 2.0 ? 'expressive' : 'classic');
                themeProvider.setCornerStyle(style);
                onToast?.call('Corner shape set to $cornerStyleLabel');
              },
              minLabel: 'Sharp (8px)',
              midLabel: 'Classic (16px)',
              maxLabel: 'Expressive (28px)',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Live Typography Preview Card ────────────────────────────────
        Text(
          'LIVE TYPOGRAPHY PREVIEW',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(
              AppTheme.getCornerRadius(themeProvider.cornerStyle),
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Previewing: ${themeProvider.fontChoice}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Radius: ${AppTheme.getCornerRadius(themeProvider.cornerStyle).round()}px',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Sphinx of black quartz, judge my vow.',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.values[(themeProvider.fontWeight / 100).round().clamp(1, 9) - 1],
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Material 3 Expressive blends flexible typography with adaptive layout algorithms to deliver state-of-the-art experiences.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontCard(
    BuildContext context, {
    required String id,
    required String name,
    required String description,
    required String? fontFamily,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.font_download_outlined,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String minLabel,
    required String midLabel,
    required String maxLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  midLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  maxLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
