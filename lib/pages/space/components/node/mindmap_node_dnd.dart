import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../models/mindmap_node.dart';
import '../../providers/space_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../utils/haptics.dart';
import 'mindmap_node_metrics.dart';

/// Handles drag-and-drop mechanics (Draggable & DragTarget) for a MindMap node.
/// Displays sibling insertion lines, drag feedback pill, and triggers reparenting.
class MindMapNodeDnd extends StatelessWidget {
  final MindMapNode node;
  final Rect bounds;
  final Color branchColor;
  final bool hasChildren;
  final int childCount;
  final bool isEditing;
  final Widget child;

  const MindMapNodeDnd({
    super.key,
    required this.node,
    required this.bounds,
    required this.branchColor,
    required this.hasChildren,
    required this.childCount,
    required this.isEditing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final isRoot = node.isRoot;
    final isHoverTarget = provider.hoverTargetId == node.id;
    final isSiblingIndicator =
        isHoverTarget && !provider.isHoverReparent && !provider.isInvalidDrop;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    const hitMargin = MindMapNodeMetrics.hitMargin;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Sibling insertion indicator line
        if (isSiblingIndicator)
          Positioned(
            left: hitMargin,
            right: hitMargin,
            top: provider.isHoverAbove ? hitMargin - 6 : null,
            bottom: provider.isHoverAbove ? null : hitMargin - 6,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: branchColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: branchColor.withValues(
                      alpha: isDark ? 0.8 : 0.6,
                    ),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),

        // 2. DragTarget & Draggable Slot
        Positioned(
          left: hitMargin,
          top: hitMargin,
          width: bounds.width,
          height: bounds.height,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) {
              return details.data != node.id;
            },
            onMove: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPos = renderBox.globalToLocal(details.offset);
                final cardY = (localPos.dy - hitMargin).clamp(0.0, bounds.height);
                final h = bounds.height;
                final isReparent = cardY >= h * 0.25 && cardY <= h * 0.75;
                final isAbove = cardY < h * 0.5;
                provider.updateDragHover(
                  targetId: node.id,
                  isReparent: isReparent,
                  isAbove: isAbove,
                );
              }
            },
            onLeave: (_) {
              if (provider.hoverTargetId == node.id) {
                provider.updateDragHover(
                  targetId: null,
                  isReparent: false,
                  isAbove: false,
                );
              }
            },
            onAcceptWithDetails: (_) {
              provider.endDragNode();
            },
            builder: (context, candidateData, rejectedData) {
              if (!isRoot && !isEditing) {
                return Draggable<String>(
                  data: node.id,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  onDragStarted: () {
                    ZetaHaptics.medium();
                    provider.startDragNode(node.id);
                  },
                  onDragEnd: (_) => provider.endDragNode(),
                  onDragCompleted: () => provider.endDragNode(),
                  onDraggableCanceled: (_, _) => provider.endDragNode(),
                  feedback: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: IgnorePointer(
                      child: Material(
                        color: Colors.transparent,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: bounds.width.clamp(120.0, 220.0),
                            maxHeight: 42.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh.withValues(
                                alpha: 0.82,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: branchColor,
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: branchColor.withValues(
                                    alpha: isDark ? 0.40 : 0.25,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Symbols.drag_indicator_rounded,
                                  size: 15,
                                  color: branchColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    node.content.isEmpty ? 'Node' : node.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (hasChildren) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: branchColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+$childCount',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: branchColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.25,
                    child: child,
                  ),
                  child: child,
                );
              }

              return child;
            },
          ),
        ),
      ],
    );
  }
}
