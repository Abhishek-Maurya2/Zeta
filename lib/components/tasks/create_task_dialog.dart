import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/task_date_formatter.dart';

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _dueDate = 'Today';
  bool _hasTime = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final desc = _descController.text.trim();
    context.read<TaskProvider>().addTask(
          title: title,
          description: desc.isNotEmpty ? desc : null,
          dueDate: _dueDate,
          hasTime: _hasTime,
          dueTime: _hasTime ? '09:00 AM' : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
                hintText: 'e.g. Finish chemistry assignment',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Due Date',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _dueDate == 'Today',
                  onSelected: (val) {
                    setState(() => _dueDate = val ? 'Today' : null);
                  },
                ),
                ChoiceChip(
                  label: const Text('Tomorrow'),
                  selected: _dueDate == 'Tomorrow',
                  onSelected: (val) {
                    setState(() => _dueDate = val ? 'Tomorrow' : null);
                  },
                ),
                Builder(
                  builder: (context) {
                    final nextWeekDate = TaskDateFormatter.format(
                      DateTime.now().add(const Duration(days: 7)),
                    );
                    return ChoiceChip(
                      label: Text('Next week ($nextWeekDate)'),
                      selected: _dueDate == nextWeekDate,
                      onSelected: (val) {
                        setState(() => _dueDate = val ? nextWeekDate : null);
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Specific time (Clock)'),
              value: _hasTime,
              onChanged: (val) => setState(() => _hasTime = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006A60),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
