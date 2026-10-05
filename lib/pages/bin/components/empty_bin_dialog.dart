import 'package:material_ui/material_ui.dart';

import '../../../components/glass_alert_dialog.dart';

class EmptyBinDialog {
  static Future<bool?> show(BuildContext context, int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return showGlassDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
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
          GlassButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          GlassButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            isDestructive: true,
            child: const Text('Empty Bin'),
          ),
        ],
      ),
    );
  }
}
