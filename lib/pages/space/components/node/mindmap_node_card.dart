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
    final shadows = <BoxShadow>[];

    if (isDisallowedTarget) {
      border = Border.all(color: colorScheme.error, width: 2.2);
      shadows.add(
        BoxShadow(
          color: colorScheme.error.withValues(alpha: isDark ? 0.45 : 0.35),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      );
    } else if (isReparentGlow) {
      border = Border.all(color: branchColor, width: 2.5);
      shadows.add(
        BoxShadow(
          color: branchColor.withValues(alpha: isDark ? 0.65 : 0.50),
          blurRadius: 14,
          spreadRadius: 3,
        ),
      );
    } else if (isSelected) {
      border = Border.all(color: branchColor, width: 2.0);
      shadows.add(
        BoxShadow(
          color: branchColor.withValues(alpha: isDark ? 0.45 : 0.30),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      );
    } else {
      border = Border.all(
        color: isRoot
            ? branchColor.withValues(alpha: isDark ? 0.80 : 0.60)
            : (isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45)),
        width: isRoot ? 1.8 : 1.0,
      );
    }

    final cardBgColor = branchColor.withValues(
      alpha: isSelected ? 0.5 : 0.3,
    );

    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: isDraggingSelf ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: M3MotionDuration.short4,
          curve: M3MotionEasing.standard,
          width: bounds.width,
          height: bounds.height,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(isRoot ? 8 : 15),
            border: border,
            boxShadow: shadows,
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
                        maxLines: null,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: isRoot ? 20 : 18,
                          fontWeight: isRoot
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: colorScheme.onSurface,
                          height: 1.35,
                          decoration: node.style.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colorScheme.outline,
                        ),
                      ),
              ),

              // 3. OG AnimatedSwitcher Collapse / Expand Toggle Badge
              if (hasChildren) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ZetaHaptics.selection();
                    provider.toggleNodeCollapsed(node.id);
                  },
                  child: Tooltip(
                    message: node.isCollapsed
                        ? 'Expand ($childCount)'
                        : 'Collapse branch',
                    child: AnimatedContainer(
                      duration: M3MotionDuration.short4,
                      curve: M3MotionEasing.emphasized,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: node.isCollapsed
                            ? branchColor
                            : branchColor.withValues(
                                alpha: isDark ? 0.25 : 0.16,
                              ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: AnimatedSwitcher(
                        duration: M3MotionDuration.short4,
                        switchInCurve: M3MotionEasing.emphasizedDecelerate,
                        switchOutCurve: M3MotionEasing.emphasizedAccelerate,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                        ),
                        child: node.isCollapsed
                            ? Text(
                                '$childCount',
                                key: const ValueKey('collapsed'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isLeft
                                    ? Icons.chevron_right_rounded
                                    : Icons.chevron_left_rounded,
                                key: const ValueKey('expanded'),
                                size: 23,
                                color: branchColor,
                              ),
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
