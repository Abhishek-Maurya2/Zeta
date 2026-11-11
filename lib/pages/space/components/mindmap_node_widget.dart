import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../models/mindmap_node.dart';
import '../providers/space_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart';
import '../../../components/glass_alert_dialog.dart';
import '../../../components/glass_m3e_menu.dart';

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

  KeyEventResult _handleEditorKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final provider = context.read<SpaceProvider>();
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      provider.updateNodeContent(widget.node.id, _textController.text.trim());
      provider.addChildNode(parentId: widget.node.id);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      provider.updateNodeContent(widget.node.id, _textController.text.trim());
      provider.addSiblingNode(siblingOfId: widget.node.id);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _isOnSelectedPath(SpaceProvider provider) {
    final selectedId = provider.selectedNodeId;
    final nodes = provider.activeMindMap?.nodes;
    if (selectedId == null || nodes == null) return false;

    String? currentId = selectedId;
    while (currentId != null) {
      if (currentId == widget.node.id) return true;

      MindMapNode? currentNode;
      for (final node in nodes) {
        if (node.id == currentId) {
          currentNode = node;
          break;
        }
      }
      currentId = currentNode?.parentId;
    }

    return false;
  }

  Future<void> _handleDelete(SpaceProvider provider) async {
    if (widget.node.isRoot) return;

    if (widget.hasChildren) {
      final shouldDelete = await showGlassDialog<bool>(
        context: context,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Delete Node & Subtopics?'),
          content: Text(
            'Deleting "${widget.node.content.isEmpty ? 'this topic' : widget.node.content}" will also delete all of its ${widget.childCount} subtopic(s). This can be undone with Ctrl+Z.',
          ),
          actions: [
            GlassButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            GlassButton(
              isDestructive: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete != true || !mounted) return;
    }

    ZetaHaptics.medium();
    provider.deleteNode(widget.node.id);
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    final provider = context.read<SpaceProvider>();
    provider.selectNode(widget.node.id);
    final isRoot = widget.node.isRoot;
    final isCollapsed = widget.node.isCollapsed;
    final hasCheckbox = widget.node.style.hasCheckbox;
    showGlassM3EMenu<String>(
      context: context,
      anchor: Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      position: M3EMenuAnchorPosition.bottomStart,
      colorStyle: M3EMenuColorStyle.vibrant,
      preferredWidth: 220,
      children: [
        M3EMenuWidget(
          semanticLabel: 'Quick node actions',
          child: Row(
            children: [
              Expanded(
                child: _quickMenuAction(
                  context,
                  icon: Icons.add_rounded,
                  label: 'Child',
                  onTap: () => provider.addChildNode(parentId: widget.node.id),
                ),
              ),
              Expanded(
                child: _quickMenuAction(
                  context,
                  icon: Icons.playlist_add_rounded,
                  label: 'Sibling',
                  enabled: !isRoot,
                  onTap: () =>
                      provider.addSiblingNode(siblingOfId: widget.node.id),
                ),
              ),
              Expanded(
                child: _quickMenuAction(
                  context,
                  icon: hasCheckbox
                      ? Icons.check_box_outline_blank_rounded
                      : Icons.check_box_rounded,
                  label: 'Checkbox',
                  onTap: () => provider.toggleNodeCheckbox(widget.node.id),
                ),
              ),
            ],
          ),
        ),
        const M3EMenuEntry(
          value: 'edit',
          label: 'Edit (F2)',
          leading: Icon(Symbols.edit_rounded, size: 20),
        ),
        M3EMenuEntry(
          value: 'toggle_collapse',
          label: isCollapsed ? 'Expand Branch' : 'Collapse Branch',
          leading: Icon(
            isCollapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
            size: 20,
          ),
          enabled: widget.hasChildren,
        ),
        M3EMenuEntry(
          value: 'toggle_checkbox',
          label: hasCheckbox ? 'Remove Checkbox' : 'Add Checkbox',
          leading: Icon(
            hasCheckbox
                ? Icons.check_box_outline_blank_rounded
                : Icons.check_box_rounded,
            size: 20,
          ),
        ),
        if (!isRoot) ...[
          const M3EMenuDivider(),
          const M3EMenuEntry(
            value: 'delete',
            label: 'Delete (Del)',
            leading: Icon(Symbols.delete_rounded, size: 20),
            isDestructive: true,
          ),
        ],
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      if (value == 'edit') {
        provider.startEditingNode(widget.node.id);
      } else if (value == 'toggle_collapse') {
        provider.toggleNodeCollapsed(widget.node.id);
      } else if (value == 'delete') {
        _handleDelete(provider);
      }
    });
  }

  Widget _quickMenuAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colorScheme = context.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled
          ? () {
              ZetaHaptics.light();
              Navigator.of(context).pop();
              onTap();
            }
          : null,
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? colorScheme.onSurface : colorScheme.outline,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? colorScheme.onSurface : colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
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
    final isOnSelectedPath = _isOnSelectedPath(provider);

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

    final cardBgColor = widget.branchColor.withValues(
      alpha: isOnSelectedPath ? 0.5 : 0.3,
    );

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
                          if (widget.hasChildren) {
                            provider.toggleNodeCollapsed(widget.node.id);
                          }
                        },
                  onDoubleTap: isEditing
                      ? null
                      : () {
                          ZetaHaptics.light();
                          provider.startEditingNode(widget.node.id);
                        },
                  onSecondaryTapUp: (details) {
                    if (!isEditing) {
                      _showContextMenu(context, details.globalPosition);
                    }
                  },
                  onLongPressStart: (details) {
                    if (!isEditing) {
                      _showContextMenu(context, details.globalPosition);
                    }
                  },
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) {
                      return details.data != widget.node.id;
                    },
                    onMove: (details) {
                      final renderBox =
                          context.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final localPos = renderBox.globalToLocal(
                          details.offset,
                        );
                        final cardY = (localPos.dy - hitMargin).clamp(
                          0.0,
                          widget.bounds.height,
                        );
                        final h = widget.bounds.height;
                        final isReparent =
                            cardY >= h * 0.25 && cardY <= h * 0.75;
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
                      Widget nodeContent = Material(
                        type: MaterialType.transparency,
                        child: Opacity(
                          opacity: isDraggingSelf ? 0.4 : 1.0,
                          child: AnimatedContainer(
                          duration: M3MotionDuration.short4,
                          curve: M3MotionEasing.standard,
                          width: widget.bounds.width,
                          height: widget.bounds.height,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(
                              isRoot ? 8 : 15,
                            ),
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
                                M3ECheckbox(
                                  value: widget.node.style.isChecked,
                                  focusable: false,
                                  checkedChild: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: widget.branchColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    ZetaHaptics.light();
                                    provider.toggleNodeChecked(widget.node.id);
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Node Content / Inline Text Editor
                              Expanded(
                                child: isEditing
                                    ? Focus(
                                        onKeyEvent: _handleEditorKeyEvent,
                                        child: TextField(
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
                                          maxLines: 10,
                                          minLines: 1,
                                          textInputAction: TextInputAction.done,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onSubmitted: (_) => _commitEdit(),
                                        ),
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
                                          maxLines: 10,
                                          overflow: TextOverflow.ellipsis,
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
                                            decorationColor:
                                                colorScheme.outline,
                                          ),
                                        ),
                                      ),
                              ),

                              // Expressive Animated Collapse / Expand Toggle Badge
                              if (widget.hasChildren &&
                                  widget.node.isCollapsed) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    ZetaHaptics.selection();
                                    provider.toggleNodeCollapsed(
                                      widget.node.id,
                                    );
                                  },
                                  child: Tooltip(
                                    message: 'Expand (${widget.childCount})',
                                    child: AnimatedContainer(
                                      duration: M3MotionDuration.short4,
                                      curve: M3MotionEasing.emphasized,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.branchColor,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        '${widget.childCount}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                                    maxWidth: widget.bounds.width.clamp(
                                      120.0,
                                      220.0,
                                    ),
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

            if (isSelected && !isEditing)
              Positioned(
                right: hitMargin - 6,
                bottom: hitMargin - 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => provider.beginNodeResize(),
                  onPanUpdate: (details) {
                    provider.updateNodeWidth(
                      widget.node.id,
                      widget.bounds.width + details.delta.dx,
                    );
                  },
                  child: Tooltip(
                    message: 'Drag to resize node',
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: widget.branchColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.branchColor.withValues(alpha: 0.4),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
