import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class BinHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onRestoreAll;
  final VoidCallback onRequestEmptyBin;

  const BinHeader({
    super.key,
    required this.totalCount,
    required this.onRestoreAll,
    required this.onRequestEmptyBin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: isCompact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            // Title + Count Badge
            Row(
              children: [
                Text(
                  'Bin',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount ${totalCount == 1 ? 'Item' : 'Items'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Actions: Restore All and Empty Bin
            if (totalCount > 0 && !isCompact) _buildButtonGroup(context),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Items in the bin can be restored or permanently removed.',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),

        // Compact mobile buttons row
        if (totalCount > 0 && isCompact) ...[
          const SizedBox(height: 12),
          Center(child: _buildButtonGroup(context)),
        ],
      ],
    );
  }

  Widget _buildButtonGroup(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3EButtonGroup(
      type: M3EButtonGroupType.standard,
      size: M3EButtonSize.md,
      selectedIndex: null,
      onSelectedIndexChanged: (int? index) {
        if (index == 0) {
          onRestoreAll();
        } else if (index == 1) {
          onRequestEmptyBin();
        }
      },
      actions: [
        M3EButtonGroupAction(
          icon: const Icon(Icons.restore_rounded, size: 18),
          label: const Text('Restore All'),
          decoration: M3EToggleButtonDecoration.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
        ),
        M3EButtonGroupAction(
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: const Text('Empty Bin'),
          decoration: M3EToggleButtonDecoration.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
        ),
      ],
    );
  }
}
