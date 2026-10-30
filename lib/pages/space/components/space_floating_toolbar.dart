import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../providers/space_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../components/glass_surface.dart';
import 'create_mindmap_dialog.dart';
import '../../../utils/haptics.dart';

/// Refined top floating toolbar for the Space mindmap canvas.
class SpaceFloatingToolbar extends StatelessWidget {
  const SpaceFloatingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final activeMap = provider.activeMindMap;

    // React to global theme changes via ThemeProvider and ZetaContextX
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final isCompact = context.isCompact;

    final dropdownItems = provider.mindMaps.map((map) {
      return M3EDropdownItem<String>(
        label: map.title,
        value: map.id,
        selected: map.id == activeMap?.id,
      );
    }).toList();

    final isBalanced = activeMap?.layoutType == 'balanced';

    return GlassSurface(
      borderRadius: BorderRadius.circular(32),
      blurSigma: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.70)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mindmap Selector Dropdown via M3EDropdownMenu
            if (dropdownItems.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? 135 : 190,
                  minWidth: 100,
                ),
                child: M3EDropdownMenu<String>(
                  key: ValueKey('${activeMap?.id}_$isDark'),
                  items: dropdownItems,
                  singleSelect: true,
                  searchEnabled: false,
                  containerRadius: 16.0,
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      ZetaHaptics.selection();
                      provider.selectMindMap(selected.first.value);
                    }
                  },
                ),
              ),

            Container(
              width: 1,
              height: 22,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Layout Mode Toggle: Horizontal (LTR) vs Balanced Dual-Sided
            Tooltip(
              message: isBalanced
                  ? 'Layout: Dual-Sided (click for Horizontal)'
                  : 'Layout: Horizontal (click for Dual-Sided)',
              child: IconButton(
                icon: Icon(
                  isBalanced ? Symbols.schema_rounded : Symbols.account_tree_rounded,
                  size: 20,
                ),
                onPressed: () {
                  ZetaHaptics.selection();
                  provider.changeLayoutType(isBalanced ? 'horizontal' : 'balanced');
                },
              ),
            ),

            // Undo Button
            Tooltip(
              message: 'Undo (Ctrl+Z)',
              child: IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                onPressed: provider.canUndo
                    ? () {
                        ZetaHaptics.light();
                        provider.undo();
                      }
                    : null,
              ),
            ),

            // Redo Button
            Tooltip(
              message: 'Redo (Ctrl+Y)',
              child: IconButton(
                icon: const Icon(Icons.redo_rounded, size: 20),
                onPressed: provider.canRedo
                    ? () {
                        ZetaHaptics.light();
                        provider.redo();
                      }
                    : null,
              ),
            ),

            Container(
              width: 1,
              height: 22,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // More Options Menu (Rename / Delete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'Mindmap Options',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (action) async {
                ZetaHaptics.light();
                if (action == 'rename' && activeMap != null) {
                  final newTitle = await CreateMindMapDialog.show(
                    context,
                    initialTitle: activeMap.title,
                    isRename: true,
                  );
                  if (newTitle != null && context.mounted) {
                    await provider.renameActiveMindMap(newTitle);
                  }
                } else if (action == 'delete' && activeMap != null) {
                  if (provider.mindMaps.length > 1) {
                    await provider.deleteActiveMindMap();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot delete the only remaining mindmap.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Symbols.edit_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Rename Mindmap'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: provider.mindMaps.length > 1,
                  child: Row(
                    children: [
                      Icon(
                        Symbols.delete_rounded,
                        size: 18,
                        color: provider.mindMaps.length > 1
                            ? colorScheme.error
                            : colorScheme.outline,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Delete Mindmap',
                        style: TextStyle(
                          color: provider.mindMaps.length > 1
                              ? colorScheme.error
                              : colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
