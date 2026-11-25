import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../models/mindmap_node.dart';
import '../../providers/space_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../utils/haptics.dart';
import '../../../../theme/motion_tokens.dart';
import 'mindmap_node_metrics.dart';
import 'mindmap_node_editor.dart';

/// Visual card presentation for a MindMap node.
/// Restores the original M3E animated checkbox, unconstrained natural sizing,
/// and the OG AnimatedSwitcher collapse/expand badge with count pill & chevron.
class MindMapNodeCard extends StatelessWidget {
  final MindMapNode node;
  final Rect bounds;
  final Color branchColor;
  final bool hasChildren;
  final int childCount;
  final bool isLeft;
  final bool isSelected;
  final bool isEditing;
  final bool isDraggingSelf;
  final bool isDisallowedTarget;
  final bool isReparentGlow;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onCommitEdit;
  final VoidCallback onCancelEdit;

  const MindMapNodeCard({
    super.key,
    required this.node,
    required this.bounds,
    required this.branchColor,
    required this.hasChildren,
    required this.childCount,
    this.isLeft = false,
    required this.isSelected,
    required this.isEditing,
    required this.isDraggingSelf,
    required this.isDisallowedTarget,
    required this.isReparentGlow,
    required this.textController,
    required this.focusNode,
    required this.onCommitEdit,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isRoot = node.isRoot;

    final Border border;
    final Color cardBgColor;
    final Color? textColorOverride;

    if (isDisallowedTarget) {
      border = Border.all(color: colorScheme.error, width: 2.0);
      cardBgColor = colorScheme.errorContainer;
      textColorOverride = colorScheme.onErrorContainer;
    } else if (isReparentGlow) {
      border = Border.all(color: branchColor, width: 2.2);
      cardBgColor = Color.alphaBlend(
        branchColor.withValues(alpha: isDark ? 0.30 : 0.20),
        colorScheme.surfaceContainerHigh,
      );
      textColorOverride = null;
    } else if (isSelected) {
      border = Border.all(color: branchColor, width: 2.0);
      cardBgColor = Color.alphaBlend(
        branchColor.withValues(alpha: isDark ? 0.26 : 0.16),
        colorScheme.surfaceContainerHigh,
      );
      textColorOverride = null;
    } else {
      border = Border.all(
        color: isRoot
            ? branchColor.withValues(alpha: isDark ? 0.70 : 0.55)
            : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
        width: isRoot ? 1.6 : 1.0,
      );
      cardBgColor = Color.alphaBlend(
        branchColor.withValues(
          alpha: isRoot ? (isDark ? 0.24 : 0.16) : (isDark ? 0.15 : 0.10),
        ),
        isRoot
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
      );
      textColorOverride = null;
    }

    final borderRadius = BorderRadius.circular(
      isRoot ? (isSelected ? 18 : 28) : (isSelected ? 12 : 20),
    );
    final badgeFgColor =
        ThemeData.estimateBrightnessForColor(branchColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF141414);

    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: isDraggingSelf ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: M3MotionDuration.short4,
          curve: M3MotionEasing.emphasizedDecelerate,
          width: bounds.width,
          height: bounds.height,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: borderRadius,
            border: border,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isRoot ? 18 : 14,
            vertical: isRoot ? 14 : 11,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Genuine M3E Expressive Checkbox
              if (node.style.hasCheckbox) ...[
                M3ECheckbox(
                  value: node.style.isChecked,
                  focusable: false,
                  onChanged: (_) {
                    ZetaHaptics.light();
                    provider.toggleNodeChecked(node.id);
                  },
                ),
                const SizedBox(width: MindMapNodeMetrics.checkboxGap),
              ],

              // 2. Node Content: Inline Editor or Pure Expanding Text
              Expanded(
                child: isEditing
                    ? MindMapNodeEditor(
                        node: node,
                        controller: textController,
                        focusNode: focusNode,
                        onCommit: onCommitEdit,
                        onCancel: onCancelEdit,
                      )
                    : Text(
                        node.content.isEmpty
                            ? (isRoot ? 'Central Topic' : 'Node')
                            : node.content,
                        softWrap: true,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: isRoot ? 20 : 18,
                          fontWeight: isRoot
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColorOverride ?? colorScheme.onSurface,
                          height: 1.35,
                          decoration: node.style.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colorScheme.outline,
                        ),
                      ),
              ),

              // 3. Expressive Collapse / Expand Pill
              if (hasChildren && (node.isCollapsed || isSelected)) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ZetaHaptics.selection();
                    provider.toggleNodeCollapsed(node.id);
                  },
                  child: M3ETooltip(
                    message: node.isCollapsed
                        ? 'Expand ($childCount)'
                        : 'Collapse',
                    child: AnimatedContainer(
                      duration: M3MotionDuration.short4,
                      curve: M3MotionEasing.emphasizedDecelerate,
                      padding: EdgeInsets.symmetric(
                        horizontal: node.isCollapsed ? 8 : 5,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: node.isCollapsed
                            ? branchColor
                            : branchColor.withValues(
                                alpha: isDark ? 0.28 : 0.18,
                              ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: node.isCollapsed
                          ? Text(
                              '$childCount',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: badgeFgColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            )
                          : Icon(
                              Icons.unfold_less_rounded,
                              size: 16,
                              color: colorScheme.onSurface,
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
