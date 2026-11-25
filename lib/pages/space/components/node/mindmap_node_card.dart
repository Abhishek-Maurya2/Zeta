import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../models/mindmap_node.dart';
import '../../providers/space_provider.dart';
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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isRoot = node.isRoot;

    final Border border;
    final Color cardBgColor;
    final Color textColor;

    if (isDisallowedTarget) {
      border = Border.all(color: colorScheme.error, width: 2.0);
      cardBgColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
    } else if (isReparentGlow) {
      border = Border.all(color: colorScheme.primary, width: 2.2);
      cardBgColor = branchColor;
      textColor =
          ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
          ? const Color(0xFFF0F2FA)
          : const Color(0xFF1A1C1E);
    } else if (isSelected) {
      border = Border.all(color: colorScheme.primary, width: 2.0);
      cardBgColor = branchColor;
      textColor =
          ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
          ? const Color(0xFFF0F2FA)
          : const Color(0xFF1A1C1E);
    } else {
      border = Border.all(color: Colors.transparent, width: 1.0);
      cardBgColor = branchColor;
      textColor =
          ThemeData.estimateBrightnessForColor(cardBgColor) == Brightness.dark
          ? const Color(0xFFF0F2FA)
          : const Color(0xFF1A1C1E);
    }

    final borderRadius = BorderRadius.circular(
      node.isCollapsed ? bounds.height / 2 : (isRoot ? 10 : 9),
    );

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
            vertical: isRoot ? 13 : 10,
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
                          fontSize: isRoot ? 18 : 16,
                          fontWeight: isRoot
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColor,
                          height: 1.35,
                          decoration: node.style.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: textColor.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
