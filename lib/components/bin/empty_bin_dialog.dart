import 'package:material_ui/material_ui.dart';

class EmptyBinDialog {
  static Future<bool?> show(BuildContext context, int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Icon(
          Icons.delete_forever_rounded,
          color: colorScheme.error,
          size: 32,
        ),
        title: const Text(
          'Empty Bin Permanently?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete all $totalCount ${totalCount == 1 ? 'task' : 'tasks'} in the bin. This action cannot be undone.',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Empty Bin'),
          ),
        ],
      ),
    );
  }
}
