import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_variant.dart';

export 'color_variant.dart';

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
    String fontChoice = 'google-sans',
    bool highContrast = false,
    String fontScale = 'standard',
    bool compactDensity = false,
    bool animations = true,
    double fontWeight = 400,
  ]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    return _buildTheme(
      colorScheme,
      cornerStyle: cornerStyle,
      fontChoice: fontChoice,
      highContrast: highContrast,
      fontScale: fontScale,
      compactDensity: compactDensity,
      animations: animations,
      fontWeight: fontWeight,
    );
  }

  static ThemeData dark(
    Color seedColor, [
    M3EColorVariant variant = M3EColorVariant.expressive,
    String cornerStyle = 'expressive',
    String fontChoice = 'google-sans',
    bool highContrast = false,
    String fontScale = 'standard',
    bool compactDensity = false,
    bool animations = true,
    double fontWeight = 400,
  ]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: variant.toDynamicSchemeVariant(),
    );
    return _buildTheme(
      colorScheme,
      cornerStyle: cornerStyle,
      fontChoice: fontChoice,
      highContrast: highContrast,
      fontScale: fontScale,
      compactDensity: compactDensity,
      animations: animations,
      fontWeight: fontWeight,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required String cornerStyle,
    required String fontChoice,
    required bool highContrast,
    required String fontScale,
    required bool compactDensity,
    required bool animations,
    required double fontWeight,
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

    // Apply font choice to emphasized text theme
    final String? fontFamily;
    switch (fontChoice) {
      case 'roboto':
        fontFamily = GoogleFonts.roboto().fontFamily;
        break;
      case 'system':
        fontFamily = null;
        break;
      case 'google-sans':
      default:
        fontFamily = GoogleFonts.inter().fontFamily;
        break;
    }

    final baseTextTheme = fontFamily != null
        ? baseTheme.textTheme.apply(fontFamily: fontFamily)
        : baseTheme.textTheme;

    final effectiveFontWeight = FontWeight.values[
        (fontWeight / 100).round().clamp(1, 9) - 1];

    final effectiveTextTheme = baseTextTheme.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: effectiveFontWeight),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: effectiveFontWeight),
      labelLarge: const TextStyle(fontSize: 13.5, letterSpacing: 0),
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
