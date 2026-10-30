import 'package:flutter/gestures.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../models/mindmap_node.dart';
import '../providers/space_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart';

/// Interactive node tile inside the MindMap canvas.
class MindMapNodeWidget extends StatefulWidget {
  final MindMapNode node;
  final Rect bounds;
  final Color branchColor;
  final bool hasChildren;
  final int childCount;
  final bool isLeft;

  const MindMapNodeWidget({
    super.key,
    required this.node,
    required this.bounds,
    required this.branchColor,
    required this.hasChildren,
    required this.childCount,
    this.isLeft = false,
  });

  @override
  State<MindMapNodeWidget> createState() => _MindMapNodeWidgetState();
}

class _MindMapNodeWidgetState extends State<MindMapNodeWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.content);
    _focusNode = FocusNode();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _commitEdit() {
    final provider = context.read<SpaceProvider>();
    provider.updateNodeContent(widget.node.id, _textController.text.trim());
    _focusNode.unfocus();
  }

  /// Claims mouse wheel events over the card so InteractiveViewer never zooms,
  /// and scrolls the card's internal content instead.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, (
        PointerSignalEvent resolvedEvent,
      ) {
        final scrollEvent = resolvedEvent as PointerScrollEvent;
        if (_scrollController.hasClients &&
            _scrollController.position.maxScrollExtent > 0) {
          final targetOffset =
              (_scrollController.offset + scrollEvent.scrollDelta.dy).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              );
          _scrollController.jumpTo(targetOffset);
        }
      });
    }
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

    final cardBgColor = isRoot
        ? widget.branchColor.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isSelected
              ? (isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHigh)
              : (isDark
                    ? colorScheme.surfaceContainer
                    : colorScheme.surfaceContainerLow));

    const double hitMargin = 48.0;

    return AnimatedPositioned(
      duration: M3MotionDuration.medium3,
      curve: M3MotionEasing.emphasized,
      left: widget.bounds.left - hitMargin,
      top: widget.bounds.top - hitMargin,
      width: widget.bounds.width + (hitMargin * 2),
      height: widget.bounds.height + (hitMargin * 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: M3MotionDuration.medium2,
        curve: M3MotionEasing.emphasizedDecelerate,
        builder: (context, enterProgress, child) {
          return Opacity(
            opacity: enterProgress.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.86 + (0.14 * enterProgress),
              alignment: widget.isLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: child,
            ),
          );
        },
        child: Stack(
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

            // 2. Main Node Card
            Positioned(
              left: hitMargin,
              top: hitMargin,
              width: widget.bounds.width,
              height: widget.bounds.height,
              child: Listener(
                onPointerSignal: _handlePointerSignal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isEditing
                      ? null
                      : () {
                          ZetaHaptics.selection();
                          provider.selectNode(widget.node.id);
                        },
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
                        final cardY = (localPos.dy - hitMargin)
                            .clamp(0.0, widget.bounds.height);
                        final h = widget.bounds.height;
                        final isReparent = cardY >= h * 0.25 && cardY <= h * 0.75;
                        final isAbove = cardY < h * 0.5;
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
                      Widget nodeContent = Opacity(
                        opacity: isDraggingSelf ? 0.4 : 1.0,
                        child: AnimatedContainer(
                          duration: M3MotionDuration.short4,
                          curve: M3MotionEasing.standard,
                          width: widget.bounds.width,
                          height: widget.bounds.height,
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
                            children: [
                              if (widget.node.style.hasCheckbox) ...[
                                GestureDetector(
                                  onTap: () {
                                    ZetaHaptics.light();
                                    provider.toggleNodeChecked(widget.node.id);
                                  },
                                  child: AnimatedContainer(
                                    duration: M3MotionDuration.short4,
                                    curve: M3MotionEasing.emphasized,
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
                                          height: 1.35,
                                        ),
                                        cursorColor: colorScheme.primary,
                                        maxLines: null,
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onSubmitted: (_) => _commitEdit(),
                                      )
                                    : SingleChildScrollView(
                                        controller: _scrollController,
                                        physics: const ClampingScrollPhysics(),
                                        child: Text(
                                          widget.node.content.isEmpty
                                              ? (isRoot
                                                    ? 'Central Topic'
                                                    : 'Node')
                                              : widget.node.content,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontSize: isRoot ? 20 : 18,
                                            fontWeight: isRoot
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: colorScheme.onSurface,
                                            height: 1.35,
                                            decoration:
                                                widget.node.style.isChecked
                                                ? TextDecoration.lineThrough
                                                : null,
                                            decorationColor: colorScheme.outline,
                                          ),
                                        ),
                                      ),
                              ),

                              // Expressive Animated Collapse / Expand Toggle Badge
                              if (widget.hasChildren) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    ZetaHaptics.selection();
                                    provider.toggleNodeCollapsed(widget.node.id);
                                  },
                                  child: Tooltip(
                                    message: widget.node.isCollapsed
                                        ? 'Expand (${widget.childCount})'
                                        : 'Collapse branch',
                                    child: AnimatedContainer(
                                      duration: M3MotionDuration.short4,
                                      curve: M3MotionEasing.emphasized,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.node.isCollapsed
                                            ? widget.branchColor
                                            : widget.branchColor.withValues(
                                                alpha: isDark ? 0.25 : 0.16,
                                              ),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: M3MotionDuration.short4,
                                        switchInCurve:
                                            M3MotionEasing.emphasizedDecelerate,
                                        switchOutCurve:
                                            M3MotionEasing.emphasizedAccelerate,
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                              scale: anim,
                                              child: FadeTransition(
                                                opacity: anim,
                                                child: child,
                                              ),
                                            ),
                                        child: widget.node.isCollapsed
                                            ? Text(
                                                '${widget.childCount}',
                                                key: const ValueKey('collapsed'),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Icon(
                                                widget.isLeft
                                                    ? Icons.chevron_right_rounded
                                                    : Icons.chevron_left_rounded,
                                                key: const ValueKey('expanded'),
                                                size: 23,
                                                color: widget.branchColor,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );

                      if (!isRoot && !isEditing) {
                        nodeContent = Draggable<String>(
                          data: widget.node.id,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          onDragStarted: () {
                            ZetaHaptics.medium();
                            provider.startDragNode(widget.node.id);
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
                                    maxWidth:
                                        widget.bounds.width.clamp(120.0, 220.0),
                                    maxHeight: 42.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh
                                          .withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: widget.branchColor,
                                        width: 1.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.branchColor.withValues(
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
                                          color: widget.branchColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            widget.node.content.isEmpty
                                                ? 'Node'
                                                : widget.node.content,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (widget.hasChildren) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.branchColor
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '+${widget.childCount}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: widget.branchColor,
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
                            child: nodeContent,
                          ),
                          child: nodeContent,
                        );
                      }

                      return nodeContent;
                    },
                  ),
                ),
              ),
            ),

            // 3. Child (+) Affordance Button
            if (isSelected && !isEditing)
              Positioned(
                left: widget.isLeft ? 6 : null,
                right: widget.isLeft ? null : 6,
                top: hitMargin + (widget.bounds.height - 30) / 2,
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

            // 4. Sibling (+) Affordance Button
            if (isSelected && !isEditing && !isRoot)
              Positioned(
                bottom: 8,
                left: hitMargin + (widget.bounds.width - 36) / 2,
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
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}