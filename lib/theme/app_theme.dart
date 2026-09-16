import 'package:material_ui/material_ui.dart';

import 'color_variant.dart';
import 'typography_config.dart';

export 'breakpoints.dart';
export 'color_variant.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    return _buildTheme(
      colorScheme,
      cornerStyle: cornerStyle,
      highContrast: highContrast,
      compactDensity: compactDensity,
      animations: animations,
      headingsTypography: headingsTypography,
      titlesTypography: titlesTypography,
      bodyTypography: bodyTypography,
      labelsTypography: labelsTypography,
    );
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    return _buildTheme(
      colorScheme,
      cornerStyle: cornerStyle,
      highContrast: highContrast,
      compactDensity: compactDensity,
      animations: animations,
      headingsTypography: headingsTypography,
      titlesTypography: titlesTypography,
      bodyTypography: bodyTypography,
      labelsTypography: labelsTypography,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required String cornerStyle,
    required bool highContrast,
    required bool compactDensity,
    required bool animations,
    RoleTypographyConfig? headingsTypography,
    RoleTypographyConfig? titlesTypography,
    RoleTypographyConfig? bodyTypography,
    RoleTypographyConfig? labelsTypography,
  }) {
    final radius = getCornerRadius(cornerStyle);

    final effectiveColorScheme = highContrast
        ? colorScheme.copyWith(
            outline: colorScheme.onSurface,
            outlineVariant: colorScheme.onSurfaceVariant,
          )
        : colorScheme;

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: effectiveColorScheme,
      brightness: effectiveColorScheme.brightness,
      visualDensity: compactDensity ? VisualDensity.compact : VisualDensity.standard,
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

    final buttonRadius = (radius * 0.6).clamp(6.0, 20.0);

    return baseTheme.copyWith(
      textTheme: effectiveTextTheme,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: effectiveColorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: effectiveColorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: effectiveColorScheme.onSurfaceVariant,
        ),
        indicatorColor: effectiveColorScheme.secondaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: effectiveColorScheme.surfaceContainerHigh,
        indicatorColor: effectiveColorScheme.secondaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: effectiveColorScheme.brightness == Brightness.dark
            ? effectiveColorScheme.surfaceContainer
            : effectiveColorScheme.surface,
        foregroundColor: effectiveColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      scaffoldBackgroundColor:
          effectiveColorScheme.brightness == Brightness.dark
              ? effectiveColorScheme.surfaceContainer
              : effectiveColorScheme.surface,
      cardTheme: CardThemeData(
        color: effectiveColorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
