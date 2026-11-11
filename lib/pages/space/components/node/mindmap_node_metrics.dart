import 'dart:math' as math;

/// Single source of truth for MindMap node layout, spacing, and overhead constants.
class MindMapNodeMetrics {
  MindMapNodeMetrics._();

  // OG Horizontal and vertical card paddings (horizontal: 18/14, vertical: 14/11)
  static const double paddingHRoot = 36.0; // 18.0 * 2
  static const double paddingHNonRoot = 28.0; // 14.0 * 2
  static const double paddingVRoot = 28.0; // 14.0 * 2
  static const double paddingVNonRoot = 22.0; // 11.0 * 2

  // M3E Checkbox overhead
  static const double checkboxSlot = 48.0;
  static const double checkboxGap = 8.0;
  static const double checkboxOverhead = 58.0; // 48 slot + 8 gap + 2 cushion

  // Global hit margin & safety margins
  static const double hitMargin = 48.0;
  static const double safetyBuffer = 14.0;

  // Maximum node width constraint
  static const double maxNodeWidth = 250.0;

  // Minimum node dimensions
  static const double minNodeWidthRoot = 60.0;
  static const double minNodeWidthNonRoot = 44.0;
  static const double minNodeHeightRoot = 38.0;
  static const double minNodeHeightNonRoot = 32.0;

  /// Calculates the horizontal badge overhead in pixels.
  /// When expanded, reserves space for the chevron toggle icon (23px + padding + gap).
  /// When collapsed, reserves space for the child count pill.
  static double calculateBadgeOverhead({
    required bool hasChildren,
    required bool isCollapsed,
    required int childCount,
  }) {
    if (!hasChildren) return 0.0;
    if (isCollapsed) {
      final digits = childCount > 0 ? childCount.toString().length : 1;
      final pillContentWidth = math.max(16.0, digits * 10.0);
      return 6.0 + 12.0 + pillContentWidth + 6.0;
    } else {
      // Expanded: 6 gap + 12 padding + 23 icon size + 6 buffer = 47px
      return 6.0 + 12.0 + 23.0 + 6.0;
    }
  }
}
