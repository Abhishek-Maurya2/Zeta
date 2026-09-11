import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class BinEmptyState extends StatelessWidget {
  final VoidCallback onNavigateToTasks;

  const BinEmptyState({super.key, required this.onNavigateToTasks});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 36,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bin is Empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'No deleted tasks. Items deleted from your task list will appear here and can be restored at any time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            M3EButton.icon(
              onPressed: onNavigateToTasks,
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Go to Tasks'),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}
