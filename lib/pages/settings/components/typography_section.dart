import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../theme/typography_config.dart';
import '../../../utils/haptics.dart';

class TypographySection extends StatefulWidget {
  final void Function(String message)? onToast;

  const TypographySection({super.key, this.onToast});

  @override
  State<TypographySection> createState() => _TypographySectionState();
}

class _TypographySectionState extends State<TypographySection> {
  TypographyRole _selectedRole = TypographyRole.headings;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentConfig = themeProvider.getTypographyConfigForRole(_selectedRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section Header ───────────────────────────────────────────────
        Text(
          'Typography',
          style: textTheme.labelMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // ─── Quick Presets Row ────────────────────────────────────────────
        Text(
          'QUICK STYLE PRESETS',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kTypographyPresets.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: M3EButton(
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  onPressed: () {
                    themeProvider.applyTypographyPreset(preset);
                    widget.onToast?.call('Applied "${preset.name}" preset');
                  },
                  child: Text(preset.name),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Role Switcher ────────────────────────────────────────────────
        Text(
          'SELECT TYPOGRAPHIC ROLE',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: M3EButtonGroup(
            type: M3EButtonGroupType.connected,
            size: M3EButtonSize.sm,
            style: M3EButtonStyle.tonal,
            selectedIndex: _selectedRole.index,
            onSelectedIndexChanged: (index) {
              if (index != null && index >= 0 && index < TypographyRole.values.length) {
                ZetaHaptics.selection();
                setState(() {
                  _selectedRole = TypographyRole.values[index];
                });
              }
            },
            actions: TypographyRole.values.map((role) {
              IconData icon;
              switch (role) {
                case TypographyRole.headings:
                  icon = Icons.title_rounded;
                  break;
                case TypographyRole.titles:
                  icon = Icons.subtitles_rounded;
                  break;
                case TypographyRole.body:
                  icon = Icons.article_outlined;
                  break;
                case TypographyRole.labels:
                  icon = Icons.smart_button_outlined;
                  break;
              }
              return M3EButtonGroupAction(
                icon: Icon(icon, size: 16),
                label: Text(role.label.split(' ').first),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // ─── Live Specimen Preview Card ───────────────────────────────────
        _buildSpecimenCard(context, currentConfig, colorScheme),
        const SizedBox(height: 20),

        // ─── Font Selection ───────────────────────────────────────────────
        Text(
          'FONT FAMILY FOR ${_selectedRole.label.toUpperCase()}',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        M3EList(
          itemCount: kSupportedFonts.length,
          itemBuilder: (context, index) {
            final font = kSupportedFonts[index];
            final isSelected = currentConfig.fontId == font.id;
            return InkWell(
              onTap: () {
                final updated = currentConfig.copyWith(fontId: font.id);
                themeProvider.updateRoleTypography(_selectedRole, updated);
                widget.onToast?.call('Selected ${font.name}');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                font.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  font.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (font.sampleText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              font.sampleText!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: font.supportedAxes.map((axis) {
                              final isRond = axis == 'ROND';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isRond
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isRond ? '★ ROND (Roundness)' : axis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isRond
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ─── Variable Axis Sliders ────────────────────────────────────────
        Text(
          'VARIABLE AXIS CONTROLS (${_selectedRole.label})',
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        M3EList(
          itemCount: 5,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildAxisSliderRow(
                  context: context,
                  icon: Icons.format_bold_rounded,
                  title: 'Weight (wght)',
                  subtitle: _weightLabel(currentConfig.weight),
                  value: currentConfig.weight,
                  min: 100,
                  max: 900,
                  divisions: 80,
                  badgeText: currentConfig.weight.round().toString(),
                  isSupported: currentConfig.supportedFont.supportsAxis('wght'),
                  onChanged: (val) {
                    final updated = currentConfig.copyWith(weight: val);
                    themeProvider.updateRoleTypography(_selectedRole, updated);
                  },
                );
              case 1:
                return _buildAxisSliderRow(
                  context: context,
                  icon: Icons.unfold_more_rounded,
                  title: 'Width (wdth)',
                  subtitle:
                      '${currentConfig.width.round()}% ${currentConfig.width < 100 ? 'Condensed' : currentConfig.width > 100 ? 'Expanded' : 'Standard'}',
                  value: currentConfig.width,
                  min: 50,
                  max: 151,
                  divisions: 101,
                  badgeText: '${currentConfig.width.round()}%',
                  isSupported: currentConfig.supportedFont.supportsAxis('wdth'),
                  unsupportedReason:
                      'Width axis is not variable in ${currentConfig.supportedFont.name}',
                  helperLabel: 'Switch to Google Sans Flex',
                  onEnableHelper: () {
                    themeProvider.updateRoleTypography(
                      _selectedRole,
                      currentConfig.copyWith(fontId: 'google-sans-flex'),
                    );
                    widget.onToast?.call('Switched to Google Sans Flex');
                  },
                  onChanged: (val) {
                    final updated = currentConfig.copyWith(width: val);
                    themeProvider.updateRoleTypography(_selectedRole, updated);
                  },
                );
              case 2:
                return _buildAxisSliderRow(
                  context: context,
                  icon: Icons.format_italic_rounded,
                  title: 'Slant (slnt)',
                  subtitle: currentConfig.slant == 0
                      ? 'Upright (0°)'
                      : 'Italic slant (${currentConfig.slant.toStringAsFixed(1)}°)',
                  value: currentConfig.slant,
                  min: -10,
                  max: 0,
                  divisions: 20,
                  badgeText: '${currentConfig.slant.toStringAsFixed(1)}°',
                  isSupported: currentConfig.supportedFont.supportsAxis('slnt'),
                  unsupportedReason:
                      'Slant axis is not variable in ${currentConfig.supportedFont.name}',
                  helperLabel: 'Switch to Google Sans Flex',
                  onEnableHelper: () {
                    themeProvider.updateRoleTypography(
                      _selectedRole,
                      currentConfig.copyWith(fontId: 'google-sans-flex'),
                    );
                    widget.onToast?.call('Switched to Google Sans Flex');
                  },
                  onChanged: (val) {
                    final updated = currentConfig.copyWith(slant: val);
                    themeProvider.updateRoleTypography(_selectedRole, updated);
                  },
                );
              case 3:
                return _buildAxisSliderRow(
                  context: context,
                  icon: Icons.rounded_corner_rounded,
                  title: 'Roundness (ROND)',
                  subtitle: currentConfig.roundness == 0
                      ? 'Geometric / Crisp'
                      : currentConfig.roundness >= 70
                          ? 'Fully Rounded Soft'
                          : 'Subtle Corner Softness',
                  value: currentConfig.roundness,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  badgeText: currentConfig.roundness.round().toString(),
                  isSupported: currentConfig.supportedFont.supportsAxis('ROND'),
                  unsupportedReason:
                      'Roundness (ROND) is exclusively available in Google Sans Flex',
                  helperLabel: 'Switch to Google Sans Flex',
                  onEnableHelper: () {
                    themeProvider.updateRoleTypography(
                      _selectedRole,
                      currentConfig.copyWith(fontId: 'google-sans-flex'),
                    );
                    widget.onToast?.call(
                        'Switched to Google Sans Flex with roundness');
                  },
                  onChanged: (val) {
                    final updated = currentConfig.copyWith(roundness: val);
                    themeProvider.updateRoleTypography(_selectedRole, updated);
                  },
                );
              case 4:
              default:
                return _buildAxisSliderRow(
                  context: context,
                  icon: Icons.line_weight_rounded,
                  title: 'Grade (GRAD)',
                  subtitle:
                      'Fine-tune stroke density without altering text width',
                  value: currentConfig.grade,
                  min: -200,
                  max: 150,
                  divisions: 70,
                  badgeText: currentConfig.grade >= 0
                      ? '+${currentConfig.grade.round()}'
                      : currentConfig.grade.round().toString(),
                  isSupported: currentConfig.supportedFont.supportsAxis('GRAD'),
                  unsupportedReason:
                      'Grade (GRAD) is not variable in ${currentConfig.supportedFont.name}',
                  helperLabel: 'Switch to Google Sans Flex',
                  onEnableHelper: () {
                    themeProvider.updateRoleTypography(
                      _selectedRole,
                      currentConfig.copyWith(fontId: 'google-sans-flex'),
                    );
                    widget.onToast?.call('Switched to Google Sans Flex');
                  },
                  onChanged: (val) {
                    final updated = currentConfig.copyWith(grade: val);
                    themeProvider.updateRoleTypography(_selectedRole, updated);
                  },
                );
            }
          },
        ),

        const SizedBox(height: 18),

        // ─── Role Reset & Global Reset Actions ────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            M3EButton(
              style: M3EButtonStyle.outlined,
              size: M3EButtonSize.sm,
              onPressed: () {
                themeProvider.resetRoleTypography(_selectedRole);
                widget.onToast?.call('Reset ${_selectedRole.label} to default');
              },
              child: Text('Reset ${_selectedRole.label}'),
            ),
            M3EButton(
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              onPressed: () {
                themeProvider.resetAllTypography();
                widget.onToast?.call('Reset all typography to factory defaults');
              },
              child: const Text('Reset All Roles'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecimenCard(
    BuildContext context,
    RoleTypographyConfig config,
    ColorScheme colorScheme,
  ) {
    String sampleTitle;
    String sampleBody;
    double sampleFontSize;

    switch (_selectedRole) {
      case TypographyRole.headings:
        sampleTitle = 'Good morning, Abhishek';
        sampleBody = 'Focus Timer • 25:00 Session in Progress';
        sampleFontSize = 24;
        break;
      case TypographyRole.titles:
        sampleTitle = 'Design System Sprint';
        sampleBody = 'Card & Subheading Hierarchy in Material 3 Expressive';
        sampleFontSize = 18;
        break;
      case TypographyRole.body:
        sampleTitle = 'Review weekly telemetry and sprint deliverables';
        sampleBody =
            'Flex variable typography seamlessly adapts weights, widths, and rounded curves across all task cards, notes, and detailed descriptions.';
        sampleFontSize = 14;
        break;
      case TypographyRole.labels:
        sampleTitle = 'START FOCUS  •  SAVE TASK  •  HIGH PRIORITY';
        sampleBody = 'Oct 14, 2026 • 2h Remaining';
        sampleFontSize = 13;
        break;
    }

    final renderedStyle = config.toTextStyle(
      TextStyle(
        fontSize: sampleFontSize,
        color: colorScheme.onSurface,
      ),
    );

    final subStyle = config.toTextStyle(
      TextStyle(
        fontSize: (sampleFontSize * 0.75).clamp(11.0, 16.0),
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE PREVIEW: ${_selectedRole.label.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                '${config.supportedFont.name} • ${config.weight.round()}w • ${config.width.round()}%wd • ${config.roundness.round()}rond',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(sampleTitle, style: renderedStyle),
          const SizedBox(height: 6),
          Text(sampleBody, style: subStyle),
        ],
      ),
    );
  }

  Widget _buildAxisSliderRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String badgeText,
    required ValueChanged<double> onChanged,
    bool isSupported = true,
    String? unsupportedReason,
    VoidCallback? onEnableHelper,
    String? helperLabel,
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
              Icon(
                icon,
                size: 20,
                color: isSupported ? colorScheme.onSurfaceVariant : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSupported
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (!isSupported) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Font Unsupported',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isSupported ? subtitle : (unsupportedReason ?? subtitle),
                      style: textTheme.bodySmall?.copyWith(
                        color: isSupported
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSupported)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else if (onEnableHelper != null && helperLabel != null)
                M3EButton(
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  onPressed: onEnableHelper,
                  child: Text(helperLabel),
                ),
            ],
          ),
          const SizedBox(height: 8),
          M3ESlider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            // divisions: divisions,
            label: badgeText,
            onChanged: isSupported ? onChanged : null,
          ),
        ],
      ),
    );
  }

  String _weightLabel(double weight) {
    if (weight <= 150) return '100 • Thin';
    if (weight <= 250) return '200 • Extra Light';
    if (weight <= 350) return '300 • Light';
    if (weight <= 450) return '400 • Regular';
    if (weight <= 550) return '500 • Medium';
    if (weight <= 650) return '600 • Semi-Bold';
    if (weight <= 750) return '700 • Bold';
    if (weight <= 850) return '800 • Extra Bold';
    return '900 • Black';
  }
}
