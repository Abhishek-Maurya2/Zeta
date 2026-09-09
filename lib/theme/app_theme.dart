import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';

/// Material 3 Expressive theme configuration for Zeta.
/// Uses m3e_core's M3EColorScheme and M3ETypography.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color seedColor, [M3EColorVariant variant = M3EColorVariant.expressive]) {
    final colorScheme = M3EColorScheme.light(
      seedColor: seedColor,
      variant: variant,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark(Color seedColor, [M3EColorVariant variant = M3EColorVariant.expressive]) {
    final colorScheme = M3EColorScheme.dark(
      seedColor: seedColor,
      variant: variant,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
    );

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.emphasized,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        indicatorColor: colorScheme.secondaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
