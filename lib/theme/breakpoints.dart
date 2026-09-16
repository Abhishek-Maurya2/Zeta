import 'package:flutter/widgets.dart';

/// Material Design 3 Window Size Classes.
///
/// Categorizes available display width into standardized window size classes:
/// - [compact]: < 600dp (Phone portrait, small foldables)
/// - [medium]: 600dp – 839dp (Tablet portrait, large foldables unfolded)
/// - [expanded]: 840dp – 1199dp (Tablet landscape, small laptops)
/// - [large]: 1200dp – 1599dp (Desktop monitors, laptops)
/// - [extraLarge]: 1600dp+ (Large monitors, ultra-wide screens)
enum ZetaWindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  /// Whether the current screen is in compact (mobile portrait) mode (< 600dp).
  bool get isCompact => this == ZetaWindowSizeClass.compact;

  /// Whether the current screen is in medium mode (600dp – 839dp).
  bool get isMedium => this == ZetaWindowSizeClass.medium;

  /// Whether the current screen is in expanded mode (840dp – 1199dp).
  bool get isExpanded => this == ZetaWindowSizeClass.expanded;

  /// Whether the current screen is in large desktop mode (1200dp – 1599dp).
  bool get isLarge => this == ZetaWindowSizeClass.large;

  /// Whether the current screen is in extra-large desktop mode (1600dp+).
  bool get isExtraLarge => this == ZetaWindowSizeClass.extraLarge;

  /// Whether the layout prefers a single-pane presentation (< 840dp).
  bool get isSinglePane => this == ZetaWindowSizeClass.compact || this == ZetaWindowSizeClass.medium;

  /// Whether the layout supports concurrent multi-pane presentation (>= 840dp).
  bool get isMultiPane => !isSinglePane;

  /// Resolves the [ZetaWindowSizeClass] based on the current [BuildContext].
  static ZetaWindowSizeClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Resolves the [ZetaWindowSizeClass] based on logical width in dp.
  static ZetaWindowSizeClass fromWidth(double width) {
    if (width < ZetaBreakpoints.mediumMin) {
      return ZetaWindowSizeClass.compact;
    } else if (width < ZetaBreakpoints.expandedMin) {
      return ZetaWindowSizeClass.medium;
    } else if (width < ZetaBreakpoints.largeMin) {
      return ZetaWindowSizeClass.expanded;
    } else if (width < ZetaBreakpoints.extraLargeMin) {
      return ZetaWindowSizeClass.large;
    } else {
      return ZetaWindowSizeClass.extraLarge;
    }
  }
}

/// Centralized Material Design 3 Breakpoint and Dimension Tokens for Zeta.
abstract final class ZetaBreakpoints {
  // ─── Breakpoint Threshold Constants (in dp) ──────────────────────────────
  static const double compactMax = 599.0;
  static const double mediumMin = 600.0;
  static const double mediumMax = 839.0;
  static const double expandedMin = 840.0;
  static const double expandedMax = 1199.0;
  static const double largeMin = 1200.0;
  static const double largeMax = 1599.0;
  static const double extraLargeMin = 1600.0;

  // ─── Outer Page Margin Tokens ─────────────────────────────────────────────
  /// 16dp outer margin for compact screens (< 600dp).
  static const double marginCompact = 16.0;

  /// 24dp outer margin for medium, expanded, large, and extra-large screens (>= 600dp).
  static const double marginExpanded = 24.0;

  /// Standard 24dp interior gutter between major panes / columns.
  static const double gutterPane = 24.0;

  // ─── Pane Dimension Tokens (M3 Canonical) ─────────────────────────────────
  /// Default fixed pane width on Expanded viewports (840dp – 1199dp).
  static const double paneFixedExpanded = 360.0;

  /// Scaled-up fixed pane width on Large & Extra-Large viewports (>= 1200dp).
  static const double paneFixedLarge = 412.0;

  /// Minimum usable width for supporting pane.
  static const double paneMinSupporting = 300.0;

  /// Minimum usable width for list pane.
  static const double paneMinList = 240.0;

  /// Minimum usable width for primary content / focus canvas.
  static const double paneMinContent = 360.0;

  /// Maximum recommended width for contextual side sheet.
  static const double paneMaxSideSheet = 400.0;

  /// Returns the recommended outer margin based on screen width.
  static double marginFor(double width) {
    return width < mediumMin ? marginCompact : marginExpanded;
  }

  /// Returns the recommended fixed pane default width based on total available width.
  static double fixedPaneWidthFor(double width) {
    return width >= largeMin ? paneFixedLarge : paneFixedExpanded;
  }
}
