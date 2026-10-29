import 'package:material_ui/material_ui.dart';
import 'package:zeta/core/core.dart';
import '../../../utils/haptics.dart';

/// Material 3 dialog for creating or renaming a mindmap.
class CreateMindMapDialog extends StatefulWidget {
  final String? initialTitle;
  final bool isRename;

  const CreateMindMapDialog({
    super.key,
    this.initialTitle,
    this.isRename = false,
  });

  static Future<String?> show(
    BuildContext context, {
    String? initialTitle,
    bool isRename = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => CreateMindMapDialog(
        initialTitle: initialTitle,
        isRename: isRename,
      ),
    );
  }

  @override
  State<CreateMindMapDialog> createState() => _CreateMindMapDialogState();
}

class _CreateMindMapDialogState extends State<CreateMindMapDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      ZetaHaptics.medium();
      Navigator.of(context).pop(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AlertDialog(
      title: Text(widget.isRename ? 'Rename Mindmap' : 'New Mindmap'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter mindmap title...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isRename ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
