import 'package:material_ui/material_ui.dart';

/// Font size presets matching standard scaling.
enum AppTextSize {
  xs(12),
  sm(14),
  md(16),
  lg(18),
  xl(20),
  xl2(24),
  xl3(30),
  xl4(36);

  final double value;
  const AppTextSize(this.value);
}

/// Font width presets for variable fonts (wdth axis).
enum AppTextWidth {
  narrow(75),
  normal(100),
  wide(125);

  final double value;
  const AppTextWidth(this.value);
}

/// Font weight presets.
enum AppTextWeight {
  light(FontWeight.w300),
  regular(FontWeight.w400),
  medium(FontWeight.w500),
  semibold(FontWeight.w600),
  bold(FontWeight.w700),
  extraBold(FontWeight.w800);

  final FontWeight value;
  const AppTextWeight(this.value);
}

/// Highly customizable Text component supporting font family, size presets,
/// weights, and variable font flex axes (slant, grade, optical size, roundness, width).
class AppText extends StatelessWidget {
  final String text;

  // Font family & styling
  final String? fontFamily;
  final Color? color;
  final double? fontSize;
  final AppTextSize? size;
  final FontWeight? fontWeight;
  final AppTextWeight? weight;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? height;

  // Variable font flex parameters
  final double? slant; // 'slnt' axis (-10..0)
  final double? grade; // 'GRAD' axis (-200..150)
  final double? opticalSize; // 'opsz' axis (6..72)
  final double? roundness; // 'ROND' axis (0..100)
  final double? flexWidth; // 'wdth' axis (25..151)
  final AppTextWidth? widthPreset; // preset wide/narrow/normal
  final List<FontVariation>? fontVariations;

  // Layout & rendering options
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final TextStyle? baseStyle;

  const AppText(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontSize,
    this.size,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  });

  // ─── Convenience Named Constructors ──────────────────────────────────────

  const AppText.xs(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.xs,
        fontSize = null;

  const AppText.sm(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.sm,
        fontSize = null;

  const AppText.md(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.md,
        fontSize = null;

  const AppText.lg(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.lg,
        fontSize = null;

  const AppText.xl(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.xl,
        fontSize = null;

  const AppText.xl2(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.xl2,
        fontSize = null;

  const AppText.xl3(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.xl3,
        fontSize = null;

  const AppText.xl4(
    this.text, {
    super.key,
    this.fontFamily,
    this.color,
    this.fontWeight,
    this.weight,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.slant,
    this.grade,
    this.opticalSize,
    this.roundness,
    this.flexWidth,
    this.widthPreset,
    this.fontVariations,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.baseStyle,
  })  : size = AppTextSize.xl4,
        fontSize = null;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? size?.value;
    final effectiveFontWeight = fontWeight ?? weight?.value;

    // Collect font variations using null-aware collection elements
    final variations = <FontVariation>[
      ...?fontVariations,
      if (slant != null) FontVariation('slnt', slant!),
      if (grade != null) FontVariation('GRAD', grade!),
      if (opticalSize != null)
        FontVariation('opsz', opticalSize!)
      else if (effectiveFontSize != null)
        FontVariation('opsz', effectiveFontSize),
      if (roundness != null) FontVariation('ROND', roundness!),
      if (flexWidth != null)
        FontVariation('wdth', flexWidth!)
      else if (widthPreset != null)
        FontVariation('wdth', widthPreset!.value),
    ];

    final defaultStyle = DefaultTextStyle.of(context).style;
    final resolvedStyle = (baseStyle ?? defaultStyle).copyWith(
      fontFamily: fontFamily,
      fontSize: effectiveFontSize,
      fontWeight: effectiveFontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      fontVariations: variations.isNotEmpty ? variations : null,
    );

    return Text(
      text,
      style: resolvedStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}
