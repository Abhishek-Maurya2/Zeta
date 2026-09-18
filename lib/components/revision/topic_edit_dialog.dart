import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../providers/revision_provider.dart';

class AddSubjectDialog extends StatefulWidget {
  const AddSubjectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AddSubjectDialog(),
    );
  }

  @override
  State<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _controller = TextEditingController();
  String _selectedIcon = 'menu_book_rounded';
  int _selectedColor = 0xFF3B82F6;

  static const _icons = [
    (name: 'menu_book_rounded', icon: Icons.menu_book_rounded),
    (name: 'terminal_rounded', icon: Icons.terminal_rounded),
    (name: 'calculate_rounded', icon: Icons.calculate_rounded),
    (name: 'biotech_rounded', icon: Icons.biotech_rounded),
    (name: 'science_rounded', icon: Icons.science_rounded),
    (name: 'palette_rounded', icon: Icons.palette_rounded),
    (name: 'language_rounded', icon: Icons.language_rounded),
  ];

  static const _colors = [
    0xFF3B82F6,
    0xFF10B981,
    0xFF8B5CF6,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFEC4899,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.library_books_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('New Subject'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Operating Systems, Calculus',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Color Picker ─────────────────────────────────────────────
              Text('Color', style: textTheme.labelLarge),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 42 : 36,
                      height: isSelected ? 42 : 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: colorScheme.onSurface, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: Color(c).withValues(alpha: 0.5),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ─── Icon Picker ──────────────────────────────────────────────
              Text('Icon', style: textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((item) {
                  final isSelected = _selectedIcon == item.name;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIcon = item.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(
                                color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.pop(context),
          style: M3EButtonStyle.text,
          size: M3EButtonSize.sm,
          child: const Text('Cancel'),
        ),
        M3EButton(
          onPressed: () async {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              await context.read<RevisionProvider>().addSubject(
                    name,
                    iconName: _selectedIcon,
                    colorValue: _selectedColor,
                  );
              if (context.mounted) Navigator.pop(context);
            }
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: const Text('Create Subject'),
        ),
      ],
    );
  }
}

class AddTopicDialog extends StatefulWidget {
  final String subjectId;

  const AddTopicDialog({super.key, required this.subjectId});

  static Future<void> show(BuildContext context,
      {required String subjectId}) {
    return showDialog(
      context: context,
      builder: (context) => AddTopicDialog(subjectId: subjectId),
    );
  }

  @override
  State<AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<AddTopicDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          Icon(Icons.post_add_rounded,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Add Topic / Chapter'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Topic Title',
                hintText: 'e.g. Hash Tables, Matrix Multiplication',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Key Concepts / Notes (Optional)',
                hintText: 'Short notes or formula references',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.pop(context),
          style: M3EButtonStyle.text,
          size: M3EButtonSize.sm,
          child: const Text('Cancel'),
        ),
        M3EButton(
          onPressed: () async {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              await context.read<RevisionProvider>().addTopic(
                    widget.subjectId,
                    title,
                    description: _descController.text.trim().isNotEmpty
                        ? _descController.text.trim()
                        : null,
                  );
              if (context.mounted) Navigator.pop(context);
            }
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: const Text('Add Topic'),
        ),
      ],
    );
  }
}
