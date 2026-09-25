import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'segmented_column.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/cross_device_service.dart';
import '../utils/task_date_formatter.dart';
import '../utils/haptics.dart';
import '../theme/breakpoints.dart';
import '../theme/success_colors.dart';

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
  static Future<void> show(
    BuildContext context, {
    Task? task,
    String? initialTitle,
    String? initialDescription,
    String? initialDueDate,
    String? initialDueTime,
    bool? initialHasTime,
    List<Subtask>? initialSubtasks,
  }) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    if (isCompact) {
      final taskProvider = context.read<TaskProvider>();
      // Docked Bottom Sheet on Compact (< 600dp)
      return showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.05),
        builder: (ctx) {
          final colorScheme = Theme.of(ctx).colorScheme;

          return ChangeNotifierProvider.value(
            value: taskProvider,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.40,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(ctx).viewInsets.bottom,
                          ),
                          child: TaskEditFormContent(
                            task: task,
                            initialTitle: initialTitle,
                            initialDescription: initialDescription,
                            initialDueDate: initialDueDate,
                            initialDueTime: initialDueTime,
                            initialHasTime: initialHasTime,
                            initialSubtasks: initialSubtasks,
                            onClose: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Co-planar 2-pane split mode on Medium & Expanded+ (>= 600dp):
      // Opens temporary resizable split side pane in TaskProvider
      context.read<TaskProvider>().openEditPane(
        task: task,
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        initialDueDate: initialDueDate,
        initialDueTime: initialDueTime,
        initialHasTime: initialHasTime,
        initialSubtasks: initialSubtasks,
      );
      return Future.value();
    }
  }
}

class TaskEditFormContent extends StatefulWidget {
  final Task? task;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialDueDate;
  final String? initialDueTime;
  final bool? initialHasTime;
  final List<Subtask>? initialSubtasks;
  final VoidCallback? onClose;
  const TaskEditFormContent({
    super.key,
    this.task,
    this.initialTitle,
    this.initialDescription,
    this.initialDueDate,
    this.initialDueTime,
    this.initialHasTime,
    this.initialSubtasks,
    this.onClose,
  });

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
    _titleController = TextEditingController(
      text: widget.task?.title ?? widget.initialTitle ?? '',
    );
    _descController = TextEditingController(
      text: widget.task?.description ?? widget.initialDescription ?? '',
    );
    _dueDate = widget.task?.dueDate != null
        ? TaskDateFormatter.formatString(widget.task!.dueDate!)
        : widget.initialDueDate;
    _hasTime = widget.initialHasTime ??
        ((widget.task?.hasTime ?? false) ||
        (widget.task?.dueTime != null &&
            widget.task!.dueTime!.trim().isNotEmpty));
    _dueTime = widget.initialDueTime ?? widget.task?.dueTime;
    if (_hasTime && (_dueTime == null || _dueTime!.isEmpty)) {
      _dueTime = '09:00 AM';
    }
    _subtasks = widget.initialSubtasks != null
        ? widget.initialSubtasks!.map((s) => s.copyWith()).toList()
        : widget.task?.subtasks.map((s) => s.copyWith()).toList() ?? [];

    _titleController.addListener(_syncDraft);
    _descController.addListener(_syncDraft);
  }

  void _syncDraft() {
    if (!mounted) return;
    try {
      final tp = context.read<TaskProvider>();
      tp.updateTaskDraft(
        title: _titleController.text,
        description: _descController.text,
        dueDate: _dueDate,
        dueTime: _dueTime,
        hasTime: _hasTime,
        subtasks: _subtasks.map((s) => s.title).toList(),
        editingTaskId: widget.task?.id,
        isCreating: widget.task == null,
      );
      CrossDeviceService.instance.notifyDraftActivity();
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.removeListener(_syncDraft);
    _descController.removeListener(_syncDraft);
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
    _syncDraft();
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
    _syncDraft();
  }

  void _toggleSubtask(String id) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == id);
      if (index != -1) {
        _subtasks[index].completed = !_subtasks[index].completed;
      }
    });
    _syncDraft();
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
      _syncDraft();
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
      _syncDraft();
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

  void _closePane() {
    try {
      context.read<TaskProvider>().clearTaskDraft();
    } catch (_) {}
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      context.read<TaskProvider>().closeEditPane();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
    provider.clearTaskDraft();

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

    _closePane();
  }

  void _handleDelete() {
    ZetaHaptics.medium();
    if (widget.task != null) {
      context.read<TaskProvider>().deleteTask(widget.task!.id);
      _closePane();
    }
  }

  Widget _buildGlassButton({
    required Widget child,
    required bool isCompact,
    required Color borderColor,
    double borderRadius = 24.0,
  }) {
    if (!isCompact) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassChip({
    required Widget child,
    required bool isCompact,
    required ColorScheme colorScheme,
    bool selected = false,
    double borderRadius = 8.0,
  }) {
    if (!isCompact) return child;
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.20,
                      ),
              ),
              child: child,
            ),
            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(borderRadius: radius),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskInput({
    required BuildContext context,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    final inputWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isCompact
          ? const BoxDecoration(
              // color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.35),
              // borderRadius: BorderRadius.circular(16),
              // border: Border.all(
              //   color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              //   width: 1.0,
              // ),
            )
          : null,
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
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
    );

    if (!isCompact) return inputWidget;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: inputWidget,
      ),
    );
  }

  Widget _buildSubtasksList({
    required BuildContext context,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    if (_subtasks.isEmpty) return const SizedBox.shrink();

    final segmentedCol = M3ESegmentedColumn(
      decoration: const M3ESegmentedListDecoration(padding: EdgeInsets.all(0)),
      color: isCompact
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.35)
          : colorScheme.surfaceContainerLowest,
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
              decoration: st.completed ? TextDecoration.lineThrough : null,
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
    );

    if (!isCompact) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: segmentedCol,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // border: Border.all(
              //   color: colorScheme.outlineVariant.withValues(alpha: 0.30),
              //   width: 1.0,
              // ),
            ),
            child: segmentedCol,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ───
          if (!isCompact)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 5),
                M3EIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: M3EIconButtonSize.sm,
                  width: M3EIconButtonWidth.wide,
                  decoration: M3EIconButtonDecoration(
                    backgroundColor: WidgetStateProperty.all(
                      colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
                    ),
                  ),
                  tooltip: 'Close',
                  onPressed: () {
                    ZetaHaptics.light();
                    _closePane();
                  },
                ),
              ],
            ),

          // ─── Scrollable Fields ───
          Flexible(
            fit: isCompact ? FlexFit.loose : FlexFit.tight,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Task Title
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: 28,
                    ),

                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Task Title',
                      hintStyle: TextStyle(
                        fontSize: 25,
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

                  const SizedBox(height: 22),

                  // 2. Description (max 3 lines)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.notes_rounded, size: 20),
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

                            hintStyle: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: colorScheme.onSurfaceVariant.withAlpha(
                                    150,
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
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Due Date & Time',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorScheme.primary,
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
                        _buildGlassChip(
                          isCompact: isCompact,
                          colorScheme: colorScheme,
                          selected: true,
                          child: M3EChip(
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
                          ),
                        )
                      else
                        _buildGlassChip(
                          isCompact: isCompact,
                          colorScheme: colorScheme,
                          selected: false,
                          child: M3EChip(
                            type: M3EChipType.assist,
                            label: 'Pick date',
                            leading: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                            ),
                            onPressed: _pickDate,
                          ),
                        ),
                      _buildGlassChip(
                        isCompact: isCompact,
                        colorScheme: colorScheme,
                        selected: _hasTime,
                        child: M3EChip(
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
                            color: colorScheme.onSurfaceVariant,
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Subtasks Section
                  Text(
                    'Subtasks',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildSubtaskInput(
                    context: context,
                    isCompact: isCompact,
                    colorScheme: colorScheme,
                  ),

                  _buildSubtasksList(
                    context: context,
                    isCompact: isCompact,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Footer Buttons ───
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isEditing)
                _buildGlassButton(
                  isCompact: isCompact,
                  borderColor: colorScheme.error.withValues(alpha: 0.35),
                  child: M3EButton.icon(
                    onPressed: _handleDelete,
                    size: M3EButtonSize.md,
                    decoration: M3EButtonDecoration(
                      backgroundColor: WidgetStatePropertyAll(
                        isCompact
                            ? colorScheme.errorContainer.withValues(alpha: 0.6)
                            : colorScheme.errorContainer,
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
                    label: const Text('Delete'),
                  ),
                )
              else
                _buildGlassButton(
                  isCompact: isCompact,
                  borderColor: colorScheme.error.withValues(alpha: 0.35),
                  child: M3EButton(
                    onPressed: () {
                      ZetaHaptics.light();
                      _closePane();
                    },
                    size: M3EButtonSize.md,
                    decoration: M3EButtonDecoration(
                      backgroundColor: WidgetStatePropertyAll(
                        isCompact
                            ? colorScheme.errorContainer.withValues(alpha: 0.9)
                            : colorScheme.errorContainer,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        colorScheme.onErrorContainer,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
              _buildGlassButton(
                isCompact: isCompact,
                borderColor: colorScheme.success.withValues(alpha: 0.35),
                child: M3EButton.icon(
                  onPressed: _handleSave,
                  decoration: M3EButtonDecoration(
                    backgroundColor: WidgetStatePropertyAll(
                      isCompact
                          ? colorScheme.success.withValues(alpha: 0.80)
                          : colorScheme.success,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      colorScheme.onSuccess,
                    ),
                  ),
                  size: M3EButtonSize.md,
                  icon: Icon(
                    isEditing ? Icons.check_rounded : Icons.add_rounded,
                    size: 20,
                    color: colorScheme.onSuccess,
                  ),
                  label: Text(
                    isEditing ? 'Save Task' : 'Create Task',
                    style: const TextStyle(fontSize: 16),
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
