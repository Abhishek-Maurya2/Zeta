import 'package:material_ui/material_ui.dart';
import '../../../utils/haptics.dart';

/// Banner displayed when a search filter is active on the Tasks page.
class TasksSearchBanner extends StatelessWidget {
  final String query;
  final int foundCount;
  final VoidCallback onClear;

  const TasksSearchBanner({
    super.key,
    required this.query,
    required this.foundCount,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(
          alpha: 0.6,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Search results for ',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSecondaryContainer,
                ),
                children: [
                  TextSpan(
                    text: '"$query"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  •  $foundCount found',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
            ),
            onPressed: () {
              ZetaHaptics.light();
              onClear();
            },
          ),
        ],
      ),
    );
  }
}
