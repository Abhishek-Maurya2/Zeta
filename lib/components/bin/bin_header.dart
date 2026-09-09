import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';

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
          crossAxisAlignment:
              isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // Title + Count Badge
            Row(
              children: [
                Text(
                  'Bin',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (totalCount > 0 && !isCompact)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3EButton.icon(
                    onPressed: onRestoreAll,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore All'),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                  ),
                  const SizedBox(width: 8),
                  M3EButton.icon(
                    onPressed: onRequestEmptyBin,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Empty Bin'),
                    style: M3EButtonStyle.filled,
                    size: M3EButtonSize.sm,
                    decoration: M3EButtonDecoration.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Items in the bin can be restored or permanently removed. Right-click any item for options.',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // Compact mobile buttons row
        if (totalCount > 0 && isCompact) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: M3EButton.icon(
                  onPressed: onRestoreAll,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Restore All'),
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3EButton.icon(
                  onPressed: onRequestEmptyBin,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Empty Bin'),
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.sm,
                  decoration: M3EButtonDecoration.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
