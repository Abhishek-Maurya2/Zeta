import 'package:flutter/material.dart';
import '../theme/breakpoints.dart';
import '../utils/haptics.dart';
import 'm3e_pane_divider.dart';

/// A Material 3 Expressive Supporting Pane Layout component.
///
/// Implements the M3 Canonical Supporting Pane pattern:
/// - **Compact / Medium (< 840dp)**: Displays the [mainPane] as a focused single pane.
/// - **Expanded / Large / Extra-Large (>= 840dp)**: Displays the [mainPane] alongside
///   the [supportingPane], separated by a draggable [M3EPaneDivider].
/// - Dynamic fixed-width scaling ($360\text{dp}$ on Expanded $\rightarrow$ $412\text{dp}$ on Large/XL).
/// - Graceful collapse/expand transitions with a trailing affordance button.
class M3ESupportingPaneScaffold extends StatelessWidget {
  /// The primary focus pane (e.g. Pomodoro timer, document editor).
  final Widget mainPane;

  /// The contextual supporting pane (e.g. analysis telemetry, properties inspector).
  final Widget supportingPane;

  /// Whether the supporting pane is currently collapsed in multi-pane mode.
  final bool isCollapsed;

  /// Callback when the collapse/expand affordance is triggered.
  final VoidCallback? onToggleCollapse;

  /// User-customized supporting pane width (if any).
  final double? customWidth;

  /// Callback when the supporting pane width is resized by dragging.
  final ValueChanged<double>? onWidthChanged;

  /// Callback when dragging starts.
  final VoidCallback? onDragStart;

  /// Callback when dragging ends.
  final VoidCallback? onDragEnd;

  /// Callback to reset to canonical width.
  final VoidCallback? onResetWidth;

  /// Minimum usable width for the primary main pane (default 360dp).
  final double minMainPaneWidth;

  /// Minimum usable width for the supporting pane (default 300dp).
  final double minSupportingPaneWidth;

  /// Tooltip for the collapsed expand affordance button.
  final String expandTooltip;

  const M3ESupportingPaneScaffold({
    super.key,
    required this.mainPane,
    required this.supportingPane,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.customWidth,
    this.onWidthChanged,
    this.onDragStart,
    this.onDragEnd,
    this.onResetWidth,
    this.minMainPaneWidth = ZetaBreakpoints.paneMinContent,
    this.minSupportingPaneWidth = ZetaBreakpoints.paneMinSupporting,
    this.expandTooltip = 'Expand supporting panel',
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = ZetaWindowSizeClass.of(context);

    // Single-pane mode on Compact & Medium (< 840dp)
    if (sizeClass.isSinglePane) {
      return mainPane;
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Multi-pane mode on Expanded & Large (>= 840dp)
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // When supporting pane is collapsed by the user
        if (isCollapsed) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mainPane),
              _buildCollapsedAffordance(context, colorScheme),
            ],
          );
        }

        final canonicalDefault = ZetaBreakpoints.fixedPaneWidthFor(totalWidth);
        final maxAllowed = (totalWidth - minMainPaneWidth - 24.0)
            .clamp(minSupportingPaneWidth, totalWidth * 0.75);
        final currentWidth = customWidth ?? canonicalDefault;
        final effectiveWidth = currentWidth.clamp(minSupportingPaneWidth, maxAllowed);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Flexible Main Focus Pane
            Expanded(child: mainPane),

            // Center: M3E Draggable Pane Divider
            M3EPaneDivider(
              onDragStart: onDragStart,
              onDragUpdate: (delta) {
                // Dragging right increases left pane, decreases right pane (-delta)
                final newWidth = effectiveWidth - delta;
                onWidthChanged?.call(newWidth);
              },
              onDragEnd: onDragEnd,
              onDoubleTap: onResetWidth,
              tooltip: 'Drag to resize · Double-tap to reset (${canonicalDefault.toInt()}dp)',
            ),

            // Right: Supporting Pane
            SizedBox(
              width: effectiveWidth,
              child: supportingPane,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedAffordance(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: 28,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ZetaHaptics.light();
            onToggleCollapse?.call();
          },
          child: Tooltip(
            message: expandTooltip,
            child: Center(
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
