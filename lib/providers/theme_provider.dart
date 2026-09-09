import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';

/// Mirrors Sharva's useThemeStore — manages theme mode, seed color, and scheme variant.
class ThemeProvider extends ChangeNotifier {
  // Theme Mode (light / dark / system)
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Seed Color (default: Iris Violet #6750A4)
  Color _seedColor = const Color(0xFF6750A4);
  Color get seedColor => _seedColor;

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  // M3E Scheme variant (expressive, tonalSpot, vibrant, etc.)
  M3EColorVariant _variant = M3EColorVariant.expressive;
  M3EColorVariant get variant => _variant;

  void setVariant(M3EColorVariant variant) {
    _variant = variant;
    notifyListeners();
  }
}
