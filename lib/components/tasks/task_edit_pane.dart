import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskEditPane {
  static Future<void> show(BuildContext context, {Task? task}) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    if (isCompact) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => M3EBottomSheet(
          showDragHandle: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: TaskEditFormContent(task: task),
          ),
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHigh,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
            child: TaskEditFormContent(task: task),
          ),
        ),
      );
    }
  }
}

class TaskEditFormContent extends StatefulWidget {
  final Task? task;
  const TaskEditFormContent({super.key, this.task});

  @override
  State<TaskEditFormContent> createState() => _TaskEditFormContentState();
}

class _TaskEditFormContentState extends State<TaskEditFormContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final TextEditingController _newSubtaskController = TextEditingController();

  String? _dueDate;
  bool _hasTime = false;
  String? _dueTime;
  late List<Subtask> _subtasks;
  String? _errorMessage;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _dueDate = widget.task?.dueDate;
    _hasTime = widget.task?.hasTime ?? false;
    _dueTime = widget.task?.dueTime;
    if (_hasTime && _dueTime == null) {
      _dueTime = '09:00 AM';
    }
    _subtasks = widget.task?.subtasks.map((s) => s.copyWith()).toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        Subtask(
          id: 'st-${DateTime.now().millisecondsSinceEpoch}',
          title: text,
          completed: false,
        ),
      );
      _newSubtaskController.clear();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  void _toggleSubtask(String id) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == id);
      if (index != -1) {
        _subtasks[index].completed = !_subtasks[index].completed;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      setState(() {
        _dueDate = '${picked.day}, ${months[picked.month - 1]}';
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final initial = _dueTime != null ? _parseTimeOfDay(_dueTime!) ?? now : now;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _hasTime = true;
        _dueTime = '$hour:$minute $period';
        _dueDate ??= 'Today';
      });
    }
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final parts = str.trim().split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Task title cannot be empty.');
      return;
    }

    final desc = _descController.text.trim();
    final provider = context.read<TaskProvider>();

    if (isEditing) {
      provider.updateTask(
        widget.task!.id,
        title: title,
        description: desc.isNotEmpty ? desc : null,
        dueDate: _dueDate,
        hasTime: _hasTime,
        dueTime: _hasTime ? _dueTime : null,
        subtasks: _subtasks,
      );
    } else {
      provider.addTask(
        title: title,
        description: desc.isNotEmpty ? desc : null,
        dueDate: _dueDate,
        hasTime: _hasTime,
        dueTime: _hasTime ? _dueTime : null,
        subtasks: _subtasks,
      );
    }

    Navigator.of(context).pop();
  }

  void _handleDelete() {
    if (widget.task != null) {
      context.read<TaskProvider>().deleteTask(widget.task!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Drag indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'New Task',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scrollable fields
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Task Title
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task Title',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      border: InputBorder.none,
                      errorText: _errorMessage,
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                    onSubmitted: (_) => _handleSave(),
                  ),

                  const SizedBox(height: 8),

                  // 2. Description
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.menu_rounded, size: 20),
                      hintText: 'Add details / notes...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Due Date & Time Section
                  Text(
                    'DUE DATE & TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InputChip(
                        avatar: Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: _dueDate != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        label: Text(_dueDate ?? 'Pick Date'),
                        selected: _dueDate != null,
                        showCheckmark: false,
                        onPressed: _pickDate,
                        onDeleted: _dueDate != null
                            ? () => setState(() {
                                  _dueDate = null;
                                  _hasTime = false;
                                  _dueTime = null;
                                })
                            : null,
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        deleteButtonTooltipMessage: 'Clear date',
                      ),
                      InputChip(
                        avatar: Icon(
                          _hasTime
                              ? Icons.schedule_rounded
                              : Icons.alarm_add_rounded,
                          size: 16,
                          color: _hasTime
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        label: Text(
                          _hasTime && _dueTime != null
                              ? _dueTime!
                              : 'Add Time',
                        ),
                        selected: _hasTime,
                        showCheckmark: false,
                        onPressed: _pickTime,
                        onDeleted: _hasTime
                            ? () => setState(() {
                                  _hasTime = false;
                                  _dueTime = null;
                                })
                            : null,
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        deleteButtonTooltipMessage: 'Clear time',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Subtasks Section
                  Text(
                    'SUBTASKS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newSubtaskController,
                          decoration: const InputDecoration(
                            hintText: 'Add a subtask...',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _addSubtask,
                      ),
                    ],
                  ),

                  if (_subtasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _subtasks.map((st) {
                          return ListTile(
                            dense: true,
                            leading: InkWell(
                              onTap: () => _toggleSubtask(st.id),
                              child: Icon(
                                st.completed
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: st.completed
                                    ? const Color(0xFF10B981)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              st.title,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: st.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: st.completed
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () => _removeSubtask(st.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Footer buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditing)
                OutlinedButton.icon(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Move to Bin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              FilledButton.icon(
                onPressed: _handleSave,
                icon: Icon(
                  isEditing ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(isEditing ? 'Save Changes' : 'Create Task'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006A60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
