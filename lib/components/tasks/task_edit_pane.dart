import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/task_date_formatter.dart';
import '../../utils/haptics.dart';

/// Modal pane / dialog for creating or editing a task.
///
/// Features Material 3 Expressive (M3E) design primitives:
/// - [M3EBottomSheet] on compact viewports (< 600px)
/// - Expressive rounded dialog on expanded viewports (≥ 600px)
/// - [M3EButton] for primary (Save/Create), secondary (Cancel), and destructive (Move to Bin) actions
/// - [M3EChip] for preset date selection (Today, Tomorrow, Next week) and custom date/time filters
/// - [M3EIconButton] for close, add-subtask, and remove-subtask interactions
/// - [M3EDatePicker] and [M3ETimePicker] for expressive scheduling dialogs
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
          elevation: 6,
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
    _dueDate = widget.task?.dueDate != null
        ? TaskDateFormatter.formatString(widget.task!.dueDate!)
        : null;
    _hasTime = (widget.task?.hasTime ?? false) ||
        (widget.task?.dueTime != null && widget.task!.dueTime!.trim().isNotEmpty);
    _dueTime = widget.task?.dueTime;
    if (_hasTime && (_dueTime == null || _dueTime!.isEmpty)) {
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
    ZetaHaptics.selection();
    final now = DateTime.now();
    final initial = _dueDate != null
        ? TaskDateFormatter.parse(_dueDate!) ?? now
        : now;
    final picked = await M3EDatePicker.show(
      context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = TaskDateFormatter.format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    ZetaHaptics.selection();
    final now = TimeOfDay.now();
    final initial = _dueTime != null ? _parseTimeOfDay(_dueTime!) ?? now : now;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: initial.hour, minute: initial.minute),
    );
    if (picked != null && mounted) {
      final hour = picked.hourOf12 == 0 ? 12 : picked.hourOf12;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.isPm ? 'PM' : 'AM';
      setState(() {
        _hasTime = true;
        _dueTime = '$hour:$minute $period';
        _dueDate ??= 'Today';
      });
    }
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
        caseSensitive: false,
      ).firstMatch(str.trim());
      if (match != null) {
        var hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _handleSave() {
    ZetaHaptics.medium();
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
    ZetaHaptics.medium();
    if (widget.task != null) {
      context.read<TaskProvider>().deleteTask(widget.task!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              M3EIconButton(
                icon: const Icon(Icons.close_rounded),
                size: M3EIconButtonSize.sm,
                width: M3EIconButtonWidth.wide,
                variant: M3EIconButtonVariant.standard,
                tooltip: 'Close',
                onPressed: () {
                  ZetaHaptics.light();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Scrollable Fields ───
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Task Title
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Task Title',
                      hintStyle: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      errorText: _errorMessage,
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                    onSubmitted: (_) => _handleSave(),
                  ),

                  const SizedBox(height: 18),

                  // 2. Description (max 3 lines)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.notes_rounded,
                          size: 20,
                          // color: colorScheme.onSurfaceVariant.withValues(
                          //   alpha: 0.8,
                          // ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _descController,
                          maxLines: 3,
                          minLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Add details',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 3. Due Date & Time Section
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DUE DATE & TIME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const Spacer(),
                        Text(
                          _dueDate! +
                              (_hasTime && _dueTime != null
                                  ? ' at $_dueTime'
                                  : ''),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 15),

                  // M3E Chips for Due Date Presets + Time
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_dueDate != null)
                        M3EChip(
                          type: M3EChipType.filter,
                          label: _dueDate!,
                          leading: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 16,
                          ),
                          selected: true,
                          onPressed: _pickDate,
                          onDeleted: () => setState(() {
                            _dueDate = null;
                            _hasTime = false;
                            _dueTime = null;
                          }),
                        )
                      else
                        M3EChip(
                          type: M3EChipType.assist,
                          label: 'Pick date',
                          leading: const Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                          ),
                          onPressed: _pickDate,
                        ),
                      M3EChip(
                        type: _hasTime
                            ? M3EChipType.filter
                            : M3EChipType.assist,
                        label: _hasTime && _dueTime != null
                            ? _dueTime!
                            : 'Add Time',
                        leading: Icon(
                          _hasTime
                              ? Icons.schedule_rounded
                              : Icons.alarm_add_rounded,
                          size: 16,
                          color: _hasTime
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        selected: _hasTime,
                        onPressed: _pickTime,
                        onDeleted: _hasTime
                            ? () => setState(() {
                                _hasTime = false;
                                _dueTime = null;
                              })
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Subtasks Section
                  Text(
                    'SUBTASKS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Add a subtask...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        M3EIconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          size: M3EIconButtonSize.xs,
                          width: M3EIconButtonWidth.narrow,
                          variant: M3EIconButtonVariant.tonal,
                          tooltip: 'Add subtask',
                          onPressed: _addSubtask,
                        ),
                      ],
                    ),
                  ),

                  if (_subtasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    M3ESegmentedColumn(
                      decoration: const M3ESegmentedListDecoration(
                        padding: EdgeInsets.all(0),
                      ),
                      color: colorScheme.surfaceContainerLowest,
                      children: _subtasks.map((st) {
                        return ListTile(
                          dense: true,
                          leading: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              ZetaHaptics.selection();
                              _toggleSubtask(st.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Icon(
                                st.completed
                                    ? Icons.check_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 22,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          title: Text(
                            st.title,
                            style: TextStyle(
                              fontSize: 15,
                              decoration: st.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: st.completed
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                          trailing: M3EIconButton(
                            icon: const Icon(Icons.close_rounded, size: 21),
                            size: M3EIconButtonSize.xs,
                            variant: M3EIconButtonVariant.standard,
                            tooltip: 'Remove subtask',
                            onPressed: () {
                              ZetaHaptics.light();
                              _removeSubtask(st.id);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ─── Footer Buttons ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditing)
                M3EButton.icon(
                  onPressed: _handleDelete,
                  // style: M3EButtonStyle.outlined,
                  size: M3EButtonSize.md,
                  decoration: M3EButtonDecoration(
                    backgroundColor: WidgetStatePropertyAll(
                      colorScheme.errorContainer,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      colorScheme.onErrorContainer,
                    ),
                  ),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  label: Text('Move to Bin'),
                )
              else
                M3EButton(
                  onPressed: () {
                    ZetaHaptics.light();
                    Navigator.of(context).pop();
                  },
                  style: M3EButtonStyle.text,
                  size: M3EButtonSize.sm,
                  child: const Text('Cancel'),
                ),
              M3EButton.icon(
                onPressed: _handleSave,
                style: M3EButtonStyle.filled,
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onPrimary,
                  ),
                ),
                size: M3EButtonSize.md,
                icon: Icon(
                  isEditing ? Icons.check_rounded : Icons.add_rounded,
                  size: 20,
                ),
                label: Text(
                  isEditing ? 'Save Changes' : 'Create Task',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
