import 'package:material_ui/material_ui.dart';

import 'color_variant.dart';
import 'success_colors.dart';
import 'typography_config.dart';

export 'breakpoints.dart';
export 'color_variant.dart';
export 'success_colors.dart';
export 'typography_config.dart';

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Material 3 Expressive theme configuration for Zeta.
class AppTheme {
  AppTheme._();

  static double getCornerRadius(String cornerStyle) {
    switch (cornerStyle) {
      case 'sharp':
        return 8.0;
      case 'classic':
        return 16.0;
      case 'expressive':
      default:
        return 28.0;
    }
  }

  static int? _lightCacheKey;
  static ThemeData? _cachedLightTheme;

  static int? _darkCacheKey;
  static ThemeData? _cachedDarkTheme;

  static ThemeData light(
    Color seedColor, [
    M3EColorVariant variant = M3EColorVariant.expressive,
    String cornerStyle = 'expressive',
    bool highContrast = false,
    bool compactDensity = false,
    bool animations = true,
    RoleTypographyConfig? headingsTypography,
    RoleTypographyConfig? titlesTypography,
    RoleTypographyConfig? bodyTypography,
    RoleTypographyConfig? labelsTypography,
  ]) {
    final cacheKey = Object.hash(
      seedColor.toARGB32(),
      variant,
      cornerStyle,
      highContrast,
      compactDensity,
      animations,
      headingsTypography,
      titlesTypography,
      bodyTypography,
      labelsTypography,
    );
    if (_lightCacheKey == cacheKey && _cachedLightTheme != null) {
      return _cachedLightTheme!;
    }

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    final theme = _buildTheme(
      colorScheme,
      seedColor: seedColor,
      cornerStyle: cornerStyle,
      highContrast: highContrast,
      compactDensity: compactDensity,
      animations: animations,
      headingsTypography: headingsTypography,
      titlesTypography: titlesTypography,
      bodyTypography: bodyTypography,
      labelsTypography: labelsTypography,
    );
    _lightCacheKey = cacheKey;
    _cachedLightTheme = theme;
    return theme;
  }

  static ThemeData dark(
    Color seedColor, [
    M3EColorVariant variant = M3EColorVariant.expressive,
    String cornerStyle = 'expressive',
    bool highContrast = false,
    bool compactDensity = false,
    bool animations = true,
    RoleTypographyConfig? headingsTypography,
    RoleTypographyConfig? titlesTypography,
    RoleTypographyConfig? bodyTypography,
    RoleTypographyConfig? labelsTypography,
  ]) {
    final cacheKey = Object.hash(
      seedColor.toARGB32(),
      variant,
      cornerStyle,
      highContrast,
      compactDensity,
      animations,
      headingsTypography,
      titlesTypography,
      bodyTypography,
      labelsTypography,
    );
    if (_darkCacheKey == cacheKey && _cachedDarkTheme != null) {
      return _cachedDarkTheme!;
    }

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    final theme = _buildTheme(
      colorScheme,
      seedColor: seedColor,
      cornerStyle: cornerStyle,
      highContrast: highContrast,
      compactDensity: compactDensity,
      animations: animations,
      headingsTypography: headingsTypography,
      titlesTypography: titlesTypography,
      bodyTypography: bodyTypography,
      labelsTypography: labelsTypography,
    );
    _darkCacheKey = cacheKey;
    _cachedDarkTheme = theme;
    return theme;
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required Color seedColor,
    required String cornerStyle,
    required bool highContrast,
    required bool compactDensity,
    required bool animations,
    RoleTypographyConfig? headingsTypography,
    RoleTypographyConfig? titlesTypography,
    RoleTypographyConfig? bodyTypography,
    RoleTypographyConfig? labelsTypography,
  }) {

    final effectiveColorScheme = highContrast
        ? colorScheme.copyWith(
            outline: colorScheme.onSurface,
            outlineVariant: colorScheme.onSurfaceVariant,
          )
        : colorScheme;

    final successColors = effectiveColorScheme.brightness == Brightness.light
        ? SuccessColors.light()
        : SuccessColors.dark();

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: effectiveColorScheme,
      brightness: effectiveColorScheme.brightness,
      extensions: [successColors],
      visualDensity: compactDensity
          ? VisualDensity.compact
          : VisualDensity.standard,
      pageTransitionsTheme: animations
          ? const PageTransitionsTheme()
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
              },
            ),
    );

    final headings = headingsTypography ?? RoleTypographyConfig.defaultHeadings;
    final titles = titlesTypography ?? RoleTypographyConfig.defaultTitles;
    final body = bodyTypography ?? RoleTypographyConfig.defaultBody;
    final labels = labelsTypography ?? RoleTypographyConfig.defaultLabels;

    final defaultText = baseTheme.textTheme;
    final effectiveTextTheme = defaultText.copyWith(
      // Headings & Display
      displayLarge: headings.toTextStyle(defaultText.displayLarge!),
      displayMedium: headings.toTextStyle(defaultText.displayMedium!),
      displaySmall: headings.toTextStyle(defaultText.displaySmall!),
      headlineLarge: headings.toTextStyle(defaultText.headlineLarge!),
      headlineMedium: headings.toTextStyle(defaultText.headlineMedium!),
      headlineSmall: headings.toTextStyle(defaultText.headlineSmall!),

      // Titles & Subheaders
      titleLarge: titles.toTextStyle(defaultText.titleLarge!),
      titleMedium: titles.toTextStyle(defaultText.titleMedium!),
      titleSmall: titles.toTextStyle(defaultText.titleSmall!),

      // Body & Content
      bodyLarge: body.toTextStyle(defaultText.bodyLarge!),
      bodyMedium: body.toTextStyle(defaultText.bodyMedium!),
      bodySmall: body.toTextStyle(defaultText.bodySmall!),

      // Labels & Controls
      labelLarge: labels.toTextStyle(
        defaultText.labelLarge!.copyWith(fontSize: 13.5, letterSpacing: 0),
      ),
      labelMedium: labels.toTextStyle(defaultText.labelMedium!),
      labelSmall: labels.toTextStyle(defaultText.labelSmall!),
    );

    return baseTheme.copyWith(
      textTheme: effectiveTextTheme,
      scaffoldBackgroundColor: effectiveColorScheme.surfaceContainerLow,
    );
  }
}
