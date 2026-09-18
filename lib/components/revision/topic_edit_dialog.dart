import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../models/revision.dart';
import '../../providers/revision_provider.dart';

/// Confirmation dialog for deletions
Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title),
      content: Text(message),
      actions: [
        M3EButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: M3EButtonStyle.text,
          size: M3EButtonSize.sm,
          child: const Text('Cancel'),
        ),
        M3EButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// Dialog for adding or editing a Subject.
class SubjectEditDialog extends StatefulWidget {
  final Subject? subject;

  const SubjectEditDialog({super.key, this.subject});

  static Future<void> show(BuildContext context, {Subject? subject}) {
    return showDialog(
      context: context,
      builder: (context) => SubjectEditDialog(subject: subject),
    );
  }

  @override
  State<SubjectEditDialog> createState() => _SubjectEditDialogState();
}

class _SubjectEditDialogState extends State<SubjectEditDialog> {
  late final TextEditingController _controller;
  late String _selectedIcon;
  late int _selectedColor;

  bool get isEditing => widget.subject != null;

  static const _icons = [
    (name: 'menu_book_rounded', icon: Icons.menu_book_rounded),
    (name: 'account_balance_rounded', icon: Icons.account_balance_rounded),
    (name: 'history_edu_rounded', icon: Icons.history_edu_rounded),
    (name: 'trending_up_rounded', icon: Icons.trending_up_rounded),
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
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subject?.name ?? '');
    _selectedIcon = widget.subject?.iconName ?? 'menu_book_rounded';
    _selectedColor = widget.subject?.colorValue ?? 0xFF3B82F6;
  }

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
          Icon(
            isEditing ? Icons.edit_rounded : Icons.library_books_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Subject' : 'New Subject'),
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
                  hintText: 'e.g. Operating Systems, Indian Polity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                color: colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(c).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
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
                    onTap: () => setState(() => _selectedIcon = item.name),
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
                                color: colorScheme.primary,
                                width: 2,
                              )
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
              final revProvider = context.read<RevisionProvider>();
              if (isEditing) {
                await revProvider.updateSubject(
                  widget.subject!.copyWith(
                    name: name,
                    iconName: _selectedIcon,
                    colorValue: _selectedColor,
                  ),
                );
              } else {
                await revProvider.addSubject(
                  name,
                  iconName: _selectedIcon,
                  colorValue: _selectedColor,
                );
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: Text(isEditing ? 'Save Changes' : 'Create Subject'),
        ),
      ],
    );
  }
}

/// Backward compatibility wrapper for [SubjectEditDialog].
class AddSubjectDialog {
  static Future<void> show(BuildContext context) {
    return SubjectEditDialog.show(context);
  }
}

/// Dialog for adding or editing a Chapter / Topic.
class TopicEditDialog extends StatefulWidget {
  final String? subjectId;
  final ChapterTopic? topic;

  const TopicEditDialog({
    super.key,
    this.subjectId,
    this.topic,
  }) : assert(subjectId != null || topic != null, 'Either subjectId or topic must be provided');

  static Future<void> show(
    BuildContext context, {
    String? subjectId,
    ChapterTopic? topic,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TopicEditDialog(
        subjectId: subjectId ?? topic?.subjectId,
        topic: topic,
      ),
    );
  }

  @override
  State<TopicEditDialog> createState() => _TopicEditDialogState();
}

class _TopicEditDialogState extends State<TopicEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  bool get isEditing => widget.topic != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _descController = TextEditingController(text: widget.topic?.description ?? '');
  }

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
          Icon(
            isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Topic / Chapter' : 'Add Topic / Chapter'),
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
                hintText: 'e.g. Fundamental Rights, Preamble',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Key Concepts / Notes (Optional)',
                hintText: 'Short notes or core syllabus references',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
              maxLines: 3,
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
            final desc = _descController.text.trim();
            if (title.isNotEmpty) {
              final revProvider = context.read<RevisionProvider>();
              if (isEditing) {
                await revProvider.updateTopic(
                  widget.topic!.copyWith(
                    title: title,
                    description: desc.isNotEmpty ? desc : null,
                  ),
                );
              } else {
                await revProvider.addTopic(
                  widget.subjectId!,
                  title,
                  description: desc.isNotEmpty ? desc : null,
                );
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: Text(isEditing ? 'Save Changes' : 'Add Topic'),
        ),
      ],
    );
  }
}

/// Backward compatibility wrapper for [TopicEditDialog].
class AddTopicDialog {
  static Future<void> show(
    BuildContext context, {
    required String subjectId,
  }) {
    return TopicEditDialog.show(context, subjectId: subjectId);
  }
}
