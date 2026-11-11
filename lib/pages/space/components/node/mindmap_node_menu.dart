import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/mindmap_node.dart';
import '../../providers/space_provider.dart';
import '../../../../utils/haptics.dart';
import '../../../../components/glass_alert_dialog.dart';
import '../../../../components/glass_m3e_menu.dart';

/// Context menu and modal confirmation dialogs for MindMap nodes.
class MindMapNodeMenu {
  MindMapNodeMenu._();

  static Future<void> showContextMenu({
    required BuildContext context,
    required Offset globalPosition,
    required MindMapNode node,
    required bool hasChildren,
    required int childCount,
    required SpaceProvider provider,
  }) async {
    provider.selectNode(node.id);
    final isRoot = node.isRoot;
    final isCollapsed = node.isCollapsed;
    final hasCheckbox = node.style.hasCheckbox;

    final value = await showGlassM3EMenu<String>(
      context: context,
      anchor: Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      position: M3EMenuAnchorPosition.bottomStart,
      colorStyle: M3EMenuColorStyle.vibrant,
      preferredWidth: 220,
      blurSigma: 8.0,
      themeOverride: const M3EMenuTheme(elevation: 0),
      children: [
        GlassMenuActionRow(
          actions: [
            GlassMenuActionItem(
              iconData: Symbols.add_rounded,
              label: 'Child',
              tooltip: 'Add Subtopic (Tab)',
              onTap: () => provider.addChildNode(parentId: node.id),
            ),
            GlassMenuActionItem(
              iconData: Symbols.playlist_add_rounded,
              label: 'Sibling',
              tooltip: 'Add Sibling (Enter)',
              enabled: !isRoot,
              onTap: () => provider.addSiblingNode(siblingOfId: node.id),
            ),
            GlassMenuActionItem(
              iconData: hasCheckbox
                  ? Symbols.check_box_outline_blank_rounded
                  : Symbols.check_box_rounded,
              label: 'Checkbox',
              tooltip: hasCheckbox ? 'Remove Checkbox' : 'Add Checkbox',
              selected: hasCheckbox,
              onTap: () => provider.toggleNodeCheckbox(node.id),
            ),
          ],
        ),
        const M3EMenuDivider(),
        const M3EMenuEntry(
          value: 'edit',
          label: 'Edit',
          trailingText: 'F2',
          leading: Icon(Symbols.edit_rounded, size: 20, fill: 1.0),
        ),
        M3EMenuEntry(
          value: 'toggle_collapse',
          label: isCollapsed ? 'Expand Branch' : 'Collapse Branch',
          leading: Icon(
            isCollapsed ? Symbols.unfold_more_rounded : Symbols.unfold_less_rounded,
            size: 20,
            fill: 1.0,
          ),
          enabled: hasChildren,
        ),
        M3EMenuEntry(
          value: 'toggle_checkbox',
          label: hasCheckbox ? 'Remove Checkbox' : 'Add Checkbox',
          leading: Icon(
            hasCheckbox
                ? Symbols.check_box_outline_blank_rounded
                : Symbols.check_box_rounded,
            size: 20,
            fill: 1.0,
          ),
        ),
        if (!isRoot) ...[
          const M3EMenuDivider(),
          const M3EMenuEntry(
            value: 'delete',
            label: 'Delete',
            trailingText: 'Del',
            leading: Icon(Symbols.delete_rounded, size: 20, fill: 1.0),
            isDestructive: true,
          ),
        ],
      ],
    );

    if (value == null || !context.mounted) return;

    if (value == 'edit') {
      provider.startEditingNode(node.id);
    } else if (value == 'toggle_collapse') {
      provider.toggleNodeCollapsed(node.id);
    } else if (value == 'delete') {
      await handleDeleteNode(
        context: context,
        node: node,
        hasChildren: hasChildren,
        childCount: childCount,
        provider: provider,
      );
    }
  }

  static Future<void> handleDeleteNode({
    required BuildContext context,
    required MindMapNode node,
    required bool hasChildren,
    required int childCount,
    required SpaceProvider provider,
  }) async {
    if (node.isRoot) return;

    if (hasChildren) {
      final shouldDelete = await showGlassDialog<bool>(
        context: context,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Delete Node & Subtopics?'),
          content: Text(
            'Deleting "${node.content.isEmpty ? 'this topic' : node.content}" will also delete all of its $childCount subtopic(s). This can be undone with Ctrl+Z.',
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

      if (shouldDelete != true || !context.mounted) return;
    }

    ZetaHaptics.medium();
    provider.deleteNode(node.id);
  }
}
