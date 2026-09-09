import 'package:material_ui/material_ui.dart';

class BinPage extends StatelessWidget {
  const BinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bin',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recycle bin, archived tasks, and restore options',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
