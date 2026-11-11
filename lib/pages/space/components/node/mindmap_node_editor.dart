import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../models/mindmap_node.dart';
import '../../providers/space_provider.dart';

/// Inline text editor widget for MindMap nodes.
/// Supports multi-line input, real-time dynamic re-measurement,
/// and keyboard navigation (Tab for child, Enter for sibling, Esc to cancel/delete).
class MindMapNodeEditor extends StatelessWidget {
  final MindMapNode node;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCommit;
  final VoidCallback onCancel;

  const MindMapNodeEditor({
    super.key,
    required this.node,
    required this.controller,
    required this.focusNode,
    required this.onCommit,
    required this.onCancel,
  });

  KeyEventResult _handleKeyEvent(BuildContext context, FocusNode fn, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      onCancel();
      return KeyEventResult.handled;
    }

    final provider = context.read<SpaceProvider>();
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      provider.updateNodeContent(node.id, controller.text.trim());
      provider.addChildNode(parentId: node.id);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored; // Allow newline on Shift+Enter
      }
      provider.updateNodeContent(node.id, controller.text.trim());
      provider.addSiblingNode(siblingOfId: node.id);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SpaceProvider>();
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isRoot = node.isRoot;

    return Focus(
      onKeyEvent: (fn, event) => _handleKeyEvent(context, fn, event),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        style: textTheme.bodyMedium?.copyWith(
          fontSize: isRoot ? 20 : 18,
          fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
          color: colorScheme.onSurface,
          height: 1.35,
        ),
        cursorColor: colorScheme.primary,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (newText) {
          provider.updateNodeContentRealtime(node.id, newText);
        },
        onSubmitted: (_) => onCommit(),
      ),
    );
  }
}
