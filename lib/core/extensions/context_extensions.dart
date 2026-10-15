import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/success_colors.dart';

/// Ergonomic BuildContext extensions for UI styling and responsive layouts.
/// Eliminates boilerplate definitions of colorScheme, textTheme, and isCompact.
extension ZetaContextX on BuildContext {
  /// Active ThemeData.
  ThemeData get theme => Theme.of(this);

  /// Active ColorScheme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Active TextTheme.
  TextTheme get textTheme => theme.textTheme;

  /// Active Success Colors semantic family.
  SuccessColors get successColors => theme.successColors;

  /// Logical screen size (uses MediaQuery.sizeOf for zero wasteful rebuilds).
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Logical screen width in dp.
  double get screenWidth => screenSize.width;

  /// Logical screen height in dp.
  double get screenHeight => screenSize.height;

  /// Window size class based on official Material 3 breakpoints.
  ZetaWindowSizeClass get windowSizeClass =>
      ZetaWindowSizeClass.fromWidth(screenWidth);

  /// Phone portrait / compact layout (< 600dp).
  bool get isCompact => screenWidth < ZetaBreakpoints.mediumMin;

  /// Tablet portrait / foldable medium layout (600dp - 839dp).
  bool get isMedium =>
      screenWidth >= ZetaBreakpoints.mediumMin &&
      screenWidth < ZetaBreakpoints.expandedMin;

  /// Desktop / expanded landscape layout (>= 840dp).
  bool get isExpanded => screenWidth >= ZetaBreakpoints.expandedMin;

  /// Whether the layout should render as a single pane (< 840dp).
  bool get isSinglePane => windowSizeClass.isSinglePane;

  /// Whether the layout supports concurrent multi-pane presentation (>= 840dp).
  bool get isMultiPane => windowSizeClass.isMultiPane;
}
