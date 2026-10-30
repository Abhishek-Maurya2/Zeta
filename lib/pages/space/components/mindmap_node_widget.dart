import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../models/mindmap_node.dart';
import '../providers/space_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/haptics.dart';

/// Interactive node tile inside the MindMap canvas.
class MindMapNodeWidget extends StatefulWidget {
  final MindMapNode node;
  final Rect bounds;
  final Color branchColor;
  final bool hasChildren;
  final int childCount;

  const MindMapNodeWidget({
    super.key,
    required this.node,
    required this.bounds,
    required this.branchColor,
    required this.hasChildren,
    required this.childCount,
  });

  @override
  State<MindMapNodeWidget> createState() => _MindMapNodeWidgetState();
}

class _MindMapNodeWidgetState extends State<MindMapNodeWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.content);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant MindMapNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.content != widget.node.content && !_focusNode.hasFocus) {
      _textController.text = widget.node.content;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final provider = context.read<SpaceProvider>();
      if (provider.editingNodeId == widget.node.id) {
        provider.updateNodeContent(widget.node.id, _textController.text.trim());
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitEdit() {
    final provider = context.read<SpaceProvider>();
    provider.updateNodeContent(widget.node.id, _textController.text.trim());
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final isSelected = provider.selectedNodeId == widget.node.id;
    final isEditing = provider.editingNodeId == widget.node.id;
    final isDraggingSelf = provider.draggedNodeId == widget.node.id;

    // Drop targeting
    final isHoverTarget = provider.hoverTargetId == widget.node.id;
    final isReparentGlow =
        isHoverTarget && provider.isHoverReparent && !provider.isInvalidDrop;
    final isSiblingIndicator =
        isHoverTarget && !provider.isHoverReparent && !provider.isInvalidDrop;
    final isDisallowedTarget = isHoverTarget && provider.isInvalidDrop;

    // Theme hook reactivity via ThemeProvider and ZetaContextX
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isRoot = widget.node.isRoot;

    // Trigger focus if entering edit mode
    if (isEditing && !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _textController.text.length,
          );
        }
      });
    }

    // Border & Glow styling tailored for Dark & Light modes
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
      border = Border.all(color: widget.branchColor, width: 2.5);
      shadows.add(
        BoxShadow(
          color: widget.branchColor.withValues(alpha: isDark ? 0.65 : 0.50),
          blurRadius: 14,
          spreadRadius: 3,
        ),
      );
    } else if (isSelected) {
      border = Border.all(color: widget.branchColor, width: 2.0);
      shadows.add(
        BoxShadow(
          color: widget.branchColor.withValues(alpha: isDark ? 0.45 : 0.30),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      );
    } else {
      border = Border.all(
        color: isRoot
            ? widget.branchColor.withValues(alpha: isDark ? 0.80 : 0.60)
            : (isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45)),
        width: isRoot ? 1.8 : 1.0,
      );
    }

    // Dynamic container surface background colors
    final cardBgColor = isRoot
        ? widget.branchColor.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isSelected
              ? (isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh)
              : (isDark
                    ? colorScheme.surfaceContainer
                    : colorScheme.surfaceContainerLow));

    const double hitMargin = 20;

    return Positioned(
      left: widget.bounds.left - hitMargin,
      top: widget.bounds.top - hitMargin,
      width: widget.bounds.width + (hitMargin * 2),
      height: widget.bounds.height + (hitMargin * 2),
      child: Padding(
        padding: const EdgeInsets.all(hitMargin),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sibling insertion indicator line (top or bottom)
            if (isSiblingIndicator)
              Positioned(
                left: 0,
                right: 0,
                top: provider.isHoverAbove ? -4 : null,
                bottom: provider.isHoverAbove ? null : -4,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.branchColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.branchColor.withValues(
                          alpha: isDark ? 0.8 : 0.6,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

            // Main Node Card
            GestureDetector(
              // Single tap/click: expands/collapses the subtree & selects the node
              onTap: isEditing
                  ? null
                  : () {
                      ZetaHaptics.selection();
                      provider.selectNode(widget.node.id);
                      if (widget.hasChildren) {
                        provider.toggleNodeCollapsed(widget.node.id);
                      }
                    },
              // Double tap/click: opens inline text editor
              onDoubleTap: isEditing
                  ? null
                  : () {
                      ZetaHaptics.light();
                      provider.startEditingNode(widget.node.id);
                    },
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) {
                  return details.data != widget.node.id;
                },
                onMove: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.offset);
                    final h = renderBox.size.height;
                    // Center 60% is reparent, top 20% is above sibling, bottom 20% is below sibling
                    final isReparent =
                        localPos.dy >= h * 0.2 && localPos.dy <= h * 0.8;
                    final isAbove = localPos.dy < h * 0.5;
                    provider.updateDragHover(
                      targetId: widget.node.id,
                      isReparent: isReparent,
                      isAbove: isAbove,
                    );
                  }
                },
                onLeave: (_) {
                  if (provider.hoverTargetId == widget.node.id) {
                    provider.updateDragHover(
                      targetId: '',
                      isReparent: false,
                      isAbove: false,
                    );
                  }
                },
                onAcceptWithDetails: (_) {
                  provider.endDragNode();
                },
                builder: (context, candidateData, rejectedData) {
                  Widget nodeContent = Opacity(
                    opacity: isDraggingSelf ? 0.4 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(isRoot ? 8 : 15),
                        border: border,
                        boxShadow: shadows,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Optional Task Checkbox
                          if (widget.node.style.hasCheckbox) ...[
                            GestureDetector(
                              onTap: () {
                                ZetaHaptics.light();
                                provider.toggleNodeChecked(widget.node.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: widget.node.style.isChecked
                                      ? widget.branchColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.node.style.isChecked
                                        ? widget.branchColor
                                        : (isDark
                                              ? colorScheme.outlineVariant
                                                    .withValues(alpha: 0.7)
                                              : colorScheme.outlineVariant),
                                    width: 1.5,
                                  ),
                                ),
                                child: widget.node.style.isChecked
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Node Content / Inline Text Editor
                          Expanded(
                            child: isEditing
                                ? TextField(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: isRoot ? 20 : 18,
                                      fontWeight: isRoot
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                    cursorColor: colorScheme.primary,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _commitEdit(),
                                  )
                                : Text(
                                    widget.node.content.isEmpty
                                        ? (isRoot ? 'Central Topic' : 'Node')
                                        : widget.node.content,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: isRoot ? 20 : 18,
                                      fontWeight: isRoot
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                      decoration: widget.node.style.isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: colorScheme.outline,
                                    ),
                                    maxLines: 8,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),

                          // Trailing Subtree Collapse / Expand Indicator
                          if (widget.hasChildren &&
                              widget.node.isCollapsed) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.branchColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${widget.childCount}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  // Wrap with Draggable for subtree dragging if not root
                  if (!isRoot) {
                    nodeContent = Draggable<String>(
                      data: widget.node.id,
                      onDragStarted: () {
                        ZetaHaptics.medium();
                        provider.startDragNode(widget.node.id);
                      },
                      onDragEnd: (_) {
                        provider.endDragNode();
                      },
                      onDragCompleted: () {
                        provider.endDragNode();
                      },
                      onDraggableCanceled: (_, __) {
                        provider.endDragNode();
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: widget.bounds.width,
                          height: widget.bounds.height,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.90,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.branchColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.branchColor.withValues(
                                  alpha: isDark ? 0.55 : 0.4,
                                ),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Symbols.drag_indicator_rounded,
                                size: 16,
                                color: widget.branchColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.node.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.hasChildren)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.branchColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${widget.childCount}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: widget.branchColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: nodeContent,
                      ),
                      child: nodeContent,
                    );
                  }

                  return nodeContent;
                },
              ),
            ),

            // Right '+' affordance: Add Child Node (Tab) - visible when node is active/pressed
            if (isSelected && !isEditing)
              Positioned(
                right: -35,
                top: (widget.bounds.height - 35) / 2,
                child: _AffordanceButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add Child (Tab)',
                  color: widget.branchColor,
                  onTap: () {
                    ZetaHaptics.light();
                    provider.addChildNode(parentId: widget.node.id);
                  },
                ),
              ),

            // Bottom '+' affordance: Add Sibling Node (Enter) - visible when node is active/pressed
            if (isSelected && !isEditing && !isRoot)
              Positioned(
                bottom: -25,
                left: (widget.bounds.width - 30) / 2,
                child: _AffordanceButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add Sibling (Enter)',
                  color: widget.branchColor,
                  onTap: () {
                    ZetaHaptics.light();
                    provider.addSiblingNode(siblingOfId: widget.node.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AffordanceButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _AffordanceButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 45,
          height: 35,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 25, color: Colors.white),
        ),
      ),
    );
  }
}
