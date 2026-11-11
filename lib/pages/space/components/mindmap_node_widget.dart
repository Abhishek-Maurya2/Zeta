import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/mindmap_node.dart';
import '../providers/space_provider.dart';
import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart';
import 'node/node.dart';

export 'node/mindmap_node_metrics.dart';

/// Top-level coordinator widget for an interactive node in the MindMap canvas.
/// Delegates rendering and interactions cleanly to modular subcomponents in `node/`.
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

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final provider = context.read<SpaceProvider>();
      if (provider.editingNodeId == widget.node.id) {
        final trimmed = _textController.text.trim();
        if (!widget.node.isRoot &&
            (widget.node.id == provider.pendingNewNodeId ||
             trimmed == 'New Topic' ||
             trimmed == 'New Node' ||
             trimmed.isEmpty)) {
          if (trimmed == 'New Topic' || trimmed == 'New Node' || trimmed.isEmpty) {
            provider.deleteNode(widget.node.id);
            return;
          }
        }
        provider.updateNodeContent(widget.node.id, trimmed);
      }
    }
  }

  void _commitEdit() {
    final provider = context.read<SpaceProvider>();
    provider.updateNodeContent(widget.node.id, _textController.text.trim());
    _focusNode.unfocus();
  }

  void _cancelEdit() {
    final provider = context.read<SpaceProvider>();
    final trimmed = _textController.text.trim();
    if (!widget.node.isRoot &&
        (widget.node.id == provider.pendingNewNodeId ||
         trimmed == 'New Topic' ||
         trimmed == 'New Node' ||
         trimmed.isEmpty)) {
      provider.deleteNode(widget.node.id);
    } else {
      provider.stopEditingNode();
    }
    _focusNode.unfocus();
  }

  /// Claims mouse wheel events over the card so InteractiveViewer never zooms,
  /// and scrolls internal multi-line content instead.
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

    // Drop targeting states
    final isHoverTarget = provider.hoverTargetId == widget.node.id;
    final isReparentGlow =
        isHoverTarget && provider.isHoverReparent && !provider.isInvalidDrop;
    final isDisallowedTarget = isHoverTarget && provider.isInvalidDrop;

    // Trigger focus and select all text if entering edit mode
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

    const hitMargin = MindMapNodeMetrics.hitMargin;

    final cardWidget = Listener(
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
            MindMapNodeMenu.showContextMenu(
              context: context,
              globalPosition: details.globalPosition,
              node: widget.node,
              hasChildren: widget.hasChildren,
              childCount: widget.childCount,
              provider: provider,
            );
          }
        },
        onLongPressStart: (details) {
          if (!isEditing) {
            MindMapNodeMenu.showContextMenu(
              context: context,
              globalPosition: details.globalPosition,
              node: widget.node,
              hasChildren: widget.hasChildren,
              childCount: widget.childCount,
              provider: provider,
            );
          }
        },
        child: MindMapNodeCard(
          node: widget.node,
          bounds: widget.bounds,
          branchColor: widget.branchColor,
          hasChildren: widget.hasChildren,
          childCount: widget.childCount,
          isLeft: widget.isLeft,
          isSelected: isSelected,
          isEditing: isEditing,
          isDraggingSelf: isDraggingSelf,
          isDisallowedTarget: isDisallowedTarget,
          isReparentGlow: isReparentGlow,
          textController: _textController,
          focusNode: _focusNode,
          onCommitEdit: _commitEdit,
          onCancelEdit: _cancelEdit,
        ),
      ),
    );

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
        child: MindMapNodeDnd(
          node: widget.node,
          bounds: widget.bounds,
          branchColor: widget.branchColor,
          hasChildren: widget.hasChildren,
          childCount: widget.childCount,
          isEditing: isEditing,
          child: cardWidget,
        ),
      ),
    );
  }
}
