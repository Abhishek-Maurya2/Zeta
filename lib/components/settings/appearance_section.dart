import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../theme/color_variant.dart';
import '../../widgets/segmented_column.dart';
import '../../utils/haptics.dart';
import '../../providers/theme_provider.dart';
import '../../pages/splash_screen.dart';

class AppearanceSection extends StatelessWidget {
  final void Function(String message)? onToast;

  const AppearanceSection({super.key, this.onToast});

  void _showColorSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            maxWidth: 580,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.color_lens_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Palette Seed Presets',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Select a color to derive tonal roles in real-time',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Presets List
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: kSeedPresets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final preset = kSeedPresets[index];
                    final isSelected =
                        themeProvider.seedColor.toARGB32() ==
                        preset.color.toARGB32();

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        themeProvider.setSeedColor(preset.color);
                        Navigator.of(sheetContext).pop();
                        onToast?.call('Applied ${preset.name} (${preset.hex})');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: preset.color.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? colorScheme.onSecondaryContainer
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${preset.desc} • ${preset.hex}',
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
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final themeModeIndex = themeProvider.themeMode == ThemeMode.light
        ? 0
        : themeProvider.themeMode == ThemeMode.dark
        ? 1
        : 2;

    final variantIndex = themeProvider.variant == M3EColorVariant.expressive
        ? 0
        : themeProvider.variant == M3EColorVariant.tonalSpot
        ? 1
        : 2;

    final currentPreset = kSeedPresets.firstWhere(
      (p) => p.color.toARGB32() == themeProvider.seedColor.toARGB32(),
      orElse: () => SeedPreset(
        id: 'custom',
        name: 'Custom Palette',
        color: themeProvider.seedColor,
        hex:
            '#${themeProvider.seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        desc: 'Custom tone',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPEARANCE & DYNAMIC THEME',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // ─── Theme & Scheme Selection ─────────────────────────────────────
        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            // Theme Mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_6_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Mode',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Light, dark, or system preference',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: M3EButtonGroup(
                      type: M3EButtonGroupType.connected,
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.tonal,
                      selectedIndex: themeModeIndex,
                      onSelectedIndexChanged: (index) {
                        if (index != null) ZetaHaptics.selection();
                        if (index == 0) {
                          themeProvider.setThemeMode(ThemeMode.light);
                          onToast?.call('Theme set to Light');
                        } else if (index == 1) {
                          themeProvider.setThemeMode(ThemeMode.dark);
                          onToast?.call('Theme set to Dark');
                        } else if (index == 2) {
                          themeProvider.setThemeMode(ThemeMode.system);
                          onToast?.call(
                            'Theme set to Auto (System preference)',
                          );
                        }
                      },
                      actions: const [
                        M3EButtonGroupAction(
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                          label: Text('Light'),
                        ),
                        M3EButtonGroupAction(
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                          label: Text('Dark'),
                        ),
                        M3EButtonGroupAction(
                          icon: Icon(Icons.brightness_auto_outlined, size: 16),
                          label: Text('Auto'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Color Scheme Algorithm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color Scheme Algorithm',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Select tonal palettes derived from seed color',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: M3EButtonGroup(
                      type: M3EButtonGroupType.connected,
                      size: M3EButtonSize.sm,
                      style: M3EButtonStyle.tonal,
                      selectedIndex: variantIndex,
                      onSelectedIndexChanged: (index) {
                        if (index != null) ZetaHaptics.selection();
                        if (index == 0) {
                          themeProvider.setVariant(M3EColorVariant.expressive);
                          onToast?.call('Applied Expressive algorithm');
                        } else if (index == 1) {
                          themeProvider.setVariant(M3EColorVariant.tonalSpot);
                          onToast?.call('Applied Tonal Spot algorithm');
                        } else if (index == 2) {
                          themeProvider.setVariant(M3EColorVariant.vibrant);
                          onToast?.call('Applied Vibrant algorithm');
                        }
                      },
                      actions: const [
                        M3EButtonGroupAction(label: Text('Expressive')),
                        M3EButtonGroupAction(label: Text('Tonal Spot')),
                        M3EButtonGroupAction(label: Text('Vibrant')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Palette Seed Preset
            InkWell(
              onTap: () => _showColorSheet(context, themeProvider),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.color_lens_rounded,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Palette Seed Preset',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${currentPreset.name} • ${currentPreset.desc}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: themeProvider.seedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.seedColor.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ─── Display & Visual Effects Switches ───────────────────────────
        Text(
          'DISPLAY & MOTION',
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
          color: colorScheme.surfaceContainerLowest,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.motion_photos_on_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motion & Fluid Animations',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Enable Material 3 spring curves and transitions',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: themeProvider.animations,
                    onChanged: (val) {
                      themeProvider.setAnimations(val);
                      onToast?.call(
                        val ? 'Animations enabled' : 'Animations disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.contrast_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Contrast Mode',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Increase contrast distinction for borders and indicators',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: themeProvider.highContrast,
                    onChanged: (val) {
                      themeProvider.setHighContrast(val);
                      onToast?.call(
                        val
                            ? 'High contrast enabled'
                            : 'High contrast disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.density_medium_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compact Density Layout',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Decrease row heights for high-density information',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  M3ESwitch(
                    value: themeProvider.compactDensity,
                    onChanged: (val) {
                      themeProvider.setCompactDensity(val);
                      onToast?.call(
                        val
                            ? 'Compact density enabled'
                            : 'Compact density disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'LAUNCH & SPLASH SCREEN',
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
          color: colorScheme.surfaceContainerLowest,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ZetaHaptics.light();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, _, _) =>
                        const SplashScreen(isPreview: true),
                    transitionsBuilder: (_, animation, _, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview Splash Screen',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Replay the Gmail & YouTube style launch animation',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
