import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_alert_dialog.dart';
import '../../../models/revision.dart';
import '../../../providers/revision_provider.dart';

/// Confirmation dialog for deletions
Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) {
  return showGlassDialog<bool>(
    context: context,
    builder: (ctx) => GlassAlertDialog(
      maxWidth: 400.0,
      title: Text(title),
      content: Text(message),
      actions: [
        GlassButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        GlassButton(
          isDestructive: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
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
    return showGlassDialog(
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

  static const _icons = [
    'account_balance_rounded',
    'history_edu_rounded',
    'trending_up_rounded',
    'terminal_rounded',
    'calculate_rounded',
    'biotech_rounded',
    'science_rounded',
    'palette_rounded',
    'language_rounded',
    'psychology_rounded',
    'menu_book_rounded',
  ];

  static const _colors = [
    0xFF1B6EF3, // Blue
    0xFF00A86B, // Emerald
    0xFFE65100, // Orange
    0xFF8E24AA, // Purple
    0xFFD81B60, // Pink
    0xFF00897B, // Teal
    0xFFFDD835, // Amber
    0xFF5C6BC0, // Indigo
    0xFFE53935, // Red
    0xFF43A047, // Green
  ];

  IconData _resolveIcon(String name) {
    return switch (name) {
      'account_balance_rounded' => Icons.account_balance_rounded,
      'history_edu_rounded' => Icons.history_edu_rounded,
      'trending_up_rounded' => Icons.trending_up_rounded,
      'terminal_rounded' => Icons.terminal_rounded,
      'calculate_rounded' => Icons.calculate_rounded,
      'biotech_rounded' => Icons.biotech_rounded,
      'science_rounded' => Icons.science_rounded,
      'palette_rounded' => Icons.palette_rounded,
      'language_rounded' => Icons.language_rounded,
      'psychology_rounded' => Icons.psychology_rounded,
      _ => Icons.menu_book_rounded,
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subject?.name ?? '');
    _selectedIcon = widget.subject?.iconName ?? _icons.first;
    _selectedColor = widget.subject?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassAlertDialog(
      title: Text(isEditing ? 'Edit Subject' : 'New Subject'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g. Modern World History',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Select Icon',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.35,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                        ),
                        child: Icon(
                          _resolveIcon(iconName),
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Text(
              'Accent Color',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((cVal) {
                final isSelected = _selectedColor == cVal;
                final color = Color(cVal);
                return InkWell(
                  onTap: () => setState(() => _selectedColor = cVal),
                  borderRadius: BorderRadius.circular(50),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        GlassButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GlassButton(
          isPrimary: true,
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
          child: Text(isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}

/// Dialog for adding or editing a Chapter Topic.
class TopicEditDialog extends StatefulWidget {
  final ChapterTopic? topic;
  final String? subjectId;

  const TopicEditDialog({super.key, this.topic, this.subjectId})
      : assert(topic != null || subjectId != null,
            'Must provide either a topic to edit or a subjectId to add to.');

  static Future<void> show(
    BuildContext context, {
    ChapterTopic? topic,
    String? subjectId,
  }) {
    return showGlassDialog(
      context: context,
      builder: (context) => TopicEditDialog(topic: topic, subjectId: subjectId),
    );
  }

  @override
  State<TopicEditDialog> createState() => _TopicEditDialogState();
}

class _TopicEditDialogState extends State<TopicEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _descController =
        TextEditingController(text: widget.topic?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.topic != null;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassAlertDialog(
      title: Text(isEditing ? 'Edit Topic' : 'Add Topic'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Topic Title',
                hintText: 'e.g. Causes of World War I',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Key Concepts / Notes (Optional)',
                hintText: 'Short notes or core syllabus references',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.45),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        GlassButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GlassButton(
          isPrimary: true,
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

/// Backward compatibility wrapper for [SubjectEditDialog].
class AddSubjectDialog {
  static Future<void> show(BuildContext context) {
    return SubjectEditDialog.show(context);
  }
}

