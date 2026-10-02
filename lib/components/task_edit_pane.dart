import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'segmented_column.dart';
import 'zeta_time_picker.dart';
import '../models/task.dart';
import '../models/attachment.dart';
import '../providers/task_provider.dart';
import '../services/cross_device_service.dart';
import '../utils/task_date_formatter.dart';
import '../utils/haptics.dart';
import '../theme/breakpoints.dart';
import '../theme/success_colors.dart';

/// Modal pane / dialog for creating or editing a task[cite: 1, 2].
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
    List<AttachmentItem>? initialAttachments,
  }) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    if (isCompact) {
      final taskProvider = context.read<TaskProvider>();
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
          final viewInsets = MediaQuery.of(ctx).viewInsets;
          final maxHeight = MediaQuery.of(ctx).size.height * 0.90;

          return ChangeNotifierProvider.value(
            value: taskProvider,
            child: AnimatedPadding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
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
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.40),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Flexible(
                              child: TaskEditFormContent(
                                task: task,
                                initialTitle: initialTitle,
                                initialDescription: initialDescription,
                                initialDueDate: initialDueDate,
                                initialDueTime: initialDueTime,
                                initialHasTime: initialHasTime,
                                initialSubtasks: initialSubtasks,
                                initialAttachments: initialAttachments,
                                onClose: () => Navigator.of(ctx).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
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
  final List<AttachmentItem>? initialAttachments;
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
    this.initialAttachments,
    this.onClose,
  });

  @override
  State<TaskEditFormContent> createState() => TaskEditFormContentState();
}

class TaskEditFormContentState extends State<TaskEditFormContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final TextEditingController _newSubtaskController = TextEditingController();
  final TextEditingController _editSubtaskController = TextEditingController();
  final TextEditingController _attachmentInputController =
      TextEditingController();

  final FocusNode _descFocusNode = FocusNode();
  final FocusNode _editSubtaskFocusNode = FocusNode();
  final FocusNode _newSubtaskFocusNode = FocusNode();
  final FocusNode _attachmentFocusNode = FocusNode();

  String? _editingSubtaskId;
  String? _dueDate;
  bool _hasTime = false;
  String? _dueTime;
  late List<Subtask> _subtasks;
  late List<AttachmentItem> _attachments;
  String? _errorMessage;

  bool _showDescriptionSection = false;
  bool _showSubtaskSection = false;
  bool _showAttachmentInput = false;
  bool _isFetchingAttachmentTitle = false;

  bool get isEditing => widget.task != null;
  bool get _hasDueDateOrTime => _dueDate != null || _hasTime;
  bool get _showDescription =>
      _showDescriptionSection || _descController.text.trim().isNotEmpty;
  bool get _showSubtasks => _showSubtaskSection || _subtasks.isNotEmpty;
  bool get _showAttachments => _showAttachmentInput || _attachments.isNotEmpty;

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
    _hasTime =
        widget.initialHasTime ??
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
    _attachments = widget.initialAttachments != null
        ? widget.initialAttachments!.map((a) => a.copyWith()).toList()
        : widget.task?.attachments.map((a) => a.copyWith()).toList() ?? [];

    if (_descController.text.trim().isNotEmpty) {
      _showDescriptionSection = true;
    }
    if (_subtasks.isNotEmpty) {
      _showSubtaskSection = true;
    }

    _titleController.addListener(_syncDraft);
    _descController.addListener(() {
      setState(() {});
      _syncDraft();
    });
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
    _titleController.dispose();
    _descController.dispose();
    _descFocusNode.dispose();
    _newSubtaskController.dispose();
    _editSubtaskController.dispose();
    _editSubtaskFocusNode.dispose();
    _newSubtaskFocusNode.dispose();
    _attachmentInputController.dispose();
    _attachmentFocusNode.dispose();
    super.dispose();
  }

  void _handleDescriptionAction() {
    ZetaHaptics.light();
    setState(() {
      _showDescriptionSection = true;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _descFocusNode.requestFocus();
    });
  }

  void _handleAttachmentAction() {
    ZetaHaptics.light();
    setState(() {
      _showAttachmentInput = !_showAttachmentInput;
    });
    if (_showAttachmentInput) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _attachmentFocusNode.requestFocus();
      });
    }
  }

  Future<String?> _fetchPageTitle(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final match = RegExp(
          r'<title[^>]*>(.*?)</title>',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(response.body);

        if (match != null) {
          final raw = match.group(1) ?? '';
          final cleaned = raw
              .replaceAll(RegExp(r'\s+'), ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .trim();
          if (cleaned.isNotEmpty) return cleaned;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _addAttachmentInline() async {
    final text = _attachmentInputController.text.trim();
    if (text.isEmpty) return;

    final isUrl = RegExp(
      r'^(https?:\/\/)?([\w\-]+(\.[\w\-]+)+.*)$',
      caseSensitive: false,
    ).hasMatch(text);

    final formattedUrl =
        isUrl && !text.startsWith('http://') && !text.startsWith('https://')
        ? 'https://$text'
        : text;

    final placeholderDomain = isUrl
        ? Uri.tryParse(formattedUrl)?.host ?? text
        : text;
    final attachmentId = 'att-${DateTime.now().millisecondsSinceEpoch}';

    final tempItem = AttachmentItem(
      id: attachmentId,
      title: placeholderDomain,
      url: formattedUrl,
      type: AttachmentType.link,
    );

    setState(() {
      _attachments.add(tempItem);
      _attachmentInputController.clear();
      _showAttachmentInput = false;
      if (isUrl) _isFetchingAttachmentTitle = true;
    });
    ZetaHaptics.light();
    _syncDraft();

    if (isUrl) {
      final fetchedTitle = await _fetchPageTitle(formattedUrl);
      if (mounted && fetchedTitle != null && fetchedTitle.isNotEmpty) {
        setState(() {
          final idx = _attachments.indexWhere((a) => a.id == attachmentId);
          if (idx != -1) {
            _attachments[idx] = _attachments[idx].copyWith(title: fetchedTitle);
          }
          _isFetchingAttachmentTitle = false;
        });
        _syncDraft();
      } else if (mounted) {
        setState(() => _isFetchingAttachmentTitle = false);
      }
    }
  }

  void _handleSubtaskAction() {
    ZetaHaptics.light();
    setState(() {
      _showSubtaskSection = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _newSubtaskFocusNode.requestFocus();
      }
    });
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    if (_editingSubtaskId != null) {
      _saveEditedSubtask(_editingSubtaskId!);
    }
    setState(() {
      _subtasks.add(
        Subtask(
          id: 'st-${DateTime.now().millisecondsSinceEpoch}',
          title: text,
          completed: false,
        ),
      );
      _newSubtaskController.clear();
      _showSubtaskSection = true;
    });
    _syncDraft();
  }

  void _startEditingSubtask(Subtask st) {
    if (_editingSubtaskId == st.id) return;
    if (_editingSubtaskId != null) {
      _saveEditedSubtask(_editingSubtaskId!);
    }
    setState(() {
      _editingSubtaskId = st.id;
      _editSubtaskController.text = st.title;
      _editSubtaskController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: st.title.length,
      );
    });
    _editSubtaskFocusNode.requestFocus();
  }

  void _saveEditedSubtask(String id) {
    final newTitle = _editSubtaskController.text.trim();
    if (newTitle.isNotEmpty) {
      setState(() {
        final index = _subtasks.indexWhere((s) => s.id == id);
        if (index != -1) {
          _subtasks[index].title = newTitle;
        }
        _editingSubtaskId = null;
      });
      ZetaHaptics.light();
      _syncDraft();
    } else {
      _cancelEditingSubtask();
    }
  }

  void _cancelEditingSubtask() {
    setState(() {
      _editingSubtaskId = null;
      _editSubtaskController.clear();
    });
  }

  void _reorderSubtask(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 ||
        oldIndex >= _subtasks.length ||
        newIndex < 0 ||
        newIndex >= _subtasks.length) {
      return;
    }
    setState(() {
      final moved = _subtasks.removeAt(oldIndex);
      _subtasks.insert(newIndex, moved);
    });
    ZetaHaptics.medium();
    _syncDraft();
  }

  @visibleForTesting
  void reorderSubtaskForTesting(int oldIndex, int newIndex) =>
      _reorderSubtask(oldIndex, newIndex);

  void _removeSubtask(String id) {
    setState(() {
      if (_editingSubtaskId == id) {
        _editingSubtaskId = null;
        _editSubtaskController.clear();
      }
      _subtasks.removeWhere((s) => s.id == id);
      if (_subtasks.isEmpty) {
        _showSubtaskSection = false;
      }
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
    final picked = await ZetaTimePicker.show(
      context,
      initialTime: M3ETime(hour: initial.hour, minute: initial.minute),
      // orientation: Orientation.landscape,
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
    if (_editingSubtaskId != null) {
      final newTitle = _editSubtaskController.text.trim();
      if (newTitle.isNotEmpty) {
        final index = _subtasks.indexWhere((s) => s.id == _editingSubtaskId);
        if (index != -1) {
          _subtasks[index].title = newTitle;
        }
      }
      _editingSubtaskId = null;
    }
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
        attachments: _attachments,
      );
    } else {
      provider.addTask(
        title: title,
        description: desc.isNotEmpty ? desc : null,
        dueDate: _dueDate,
        hasTime: _hasTime,
        dueTime: _hasTime ? _dueTime : null,
        subtasks: _subtasks,
        attachments: _attachments,
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
              focusNode: _newSubtaskFocusNode,
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

  BorderRadius _getSubtaskBorderRadius(int index, int total) {
    const outer = Radius.circular(20.0);
    const inner = Radius.circular(4.0);
    if (total <= 1) return const BorderRadius.all(outer);
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: outer,
        topRight: outer,
        bottomLeft: inner,
        bottomRight: inner,
      );
    }
    if (index == total - 1) {
      return const BorderRadius.only(
        topLeft: inner,
        topRight: inner,
        bottomLeft: outer,
        bottomRight: outer,
      );
    }
    return const BorderRadius.all(inner);
  }

  Widget _buildSubtaskTile({
    required BuildContext context,
    required Subtask st,
    required int index,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    final isEditingThis = _editingSubtaskId == st.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_subtasks.length > 1 && !isEditingThis)
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 2),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            )
          else
            const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ZetaHaptics.selection();
              _toggleSubtask(st.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  st.completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(st.completed),
                  size: 20,
                  color: st.completed
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: isEditingThis
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: _editSubtaskController,
                      focusNode: _editSubtaskFocusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        hintText: 'Subtask title...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _saveEditedSubtask(st.id),
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ZetaHaptics.light();
                      _startEditingSubtask(st);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Text(
                        st.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: st.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: st.completed
                              ? colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                )
                              : colorScheme.onSurface,
                          fontWeight: st.completed
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          if (isEditingThis)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3EIconButton(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.tonal,
                    tooltip: 'Save',
                    onPressed: () => _saveEditedSubtask(st.id),
                  ),
                  const SizedBox(width: 4),
                  M3EIconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    tooltip: 'Cancel',
                    onPressed: _cancelEditingSubtask,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: M3EIconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                size: M3EIconButtonSize.xs,
                variant: M3EIconButtonVariant.standard,
                tooltip: 'Delete subtask',
                onPressed: () {
                  ZetaHaptics.light();
                  _removeSubtask(st.id);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtasksList({
    required BuildContext context,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    if (_subtasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        padding: EdgeInsets.zero,
        itemCount: _subtasks.length,
        onReorderItem: _reorderSubtask,
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? animChild) {
              final animValue = Curves.easeInOut.transform(animation.value);
              final elevation = 4.0 * animValue;
              return Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(14),
                shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
                color: isCompact
                    ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.95)
                    : colorScheme.surfaceContainerLowest,
                child: animChild,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final st = _subtasks[index];
          final borderRadius = _getSubtaskBorderRadius(index, _subtasks.length);

          return Padding(
            key: ValueKey(st.id),
            padding: EdgeInsets.only(
              bottom: index == _subtasks.length - 1 ? 0 : 2.5,
            ),
            child: Dismissible(
              key: ValueKey('dismiss-${st.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                ZetaHaptics.medium();
                _removeSubtask(st.id);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: colorScheme.errorContainer.withValues(alpha: 0.7),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Material(
                  color: isCompact
                      ? colorScheme.surfaceContainerLowest.withValues(
                          alpha: 0.4,
                        )
                      : colorScheme.surfaceContainerLowest,
                  child: SubtaskReorderListener(
                    index: index,
                    enabled: _subtasks.length > 1 && _editingSubtaskId != st.id,
                    child: _buildSubtaskTile(
                      context: context,
                      st: st,
                      index: index,
                      isCompact: isCompact,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
          // ─── Scrollable Fields (Scrollbar Hidden) ───
          Flexible(
            fit: isCompact ? FlexFit.loose : FlexFit.tight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            autofocus: true,
                            maxLines: 4,
                            minLines: 1,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  fontSize: 26,
                                  height: 1.25,
                                ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Task Title',
                              hintStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.only(top: 4),
                              errorText: _errorMessage,
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                            onSubmitted: (_) => _handleSave(),
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(width: 12),
                          M3EIconButton(
                            icon: const Icon(Icons.close_rounded),
                            size: M3EIconButtonSize.sm,
                            width: M3EIconButtonWidth.wide,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStateProperty.all(
                                colorScheme.surfaceContainerLowest.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            onPressed: () {
                              ZetaHaptics.light();
                              _closePane();
                            },
                          ),
                        ],
                      ],
                    ),

                    // ─── 2. Notes / Description Section (Below Title) ───
                    if (_showDescription) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.notes_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _descController,
                              focusNode: _descFocusNode,
                              maxLines: 4,
                              minLines: 1,
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Add details or notes...',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: colorScheme.onSurfaceVariant
                                          .withAlpha(150),
                                    ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_descController.text.trim().isEmpty)
                            M3EIconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              size: M3EIconButtonSize.xs,
                              variant: M3EIconButtonVariant.standard,
                              tooltip: 'Hide notes',
                              onPressed: () {
                                setState(() {
                                  _showDescriptionSection = false;
                                });
                              },
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),

                    // ─── 3. Actions Button Group (Below Description) ───
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 48,
                        child: M3EButtonGroup(
                          type: M3EButtonGroupType.standard,
                          style: M3EButtonStyle.tonal,
                          size: M3EButtonSize.sm,
                          shape: M3EButtonShape.round,
                          neighborSquish: true,
                          selectedIndex: null,
                          onSelectedIndexChanged: (int? index) {
                            if (index == null) return;
                            ZetaHaptics.medium();
                            switch (index) {
                              case 0:
                                _handleDescriptionAction();
                              case 1:
                                _handleSubtaskAction();
                              case 2:
                                _pickDate();
                              case 3:
                                _pickTime();
                              case 4:
                                _handleAttachmentAction();
                            }
                          },
                          actions: [
                            M3EButtonGroupAction(
                              width: 60,
                              icon: const Icon(Icons.notes_rounded, size: 20),
                              tooltip: 'Add notes',
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: _showDescription
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                foregroundColor: _showDescription
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            M3EButtonGroupAction(
                              width: 60,
                              icon: const Icon(
                                Icons.checklist_rounded,
                                size: 20,
                              ),
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: _showSubtasks
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                foregroundColor: _showSubtasks
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            M3EButtonGroupAction(
                              width: 60,
                              icon: const Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                              ),
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: _dueDate != null
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                foregroundColor: _dueDate != null
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            M3EButtonGroupAction(
                              width: 60,
                              icon: const Icon(
                                Icons.schedule_rounded,
                                size: 20,
                              ),
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: _hasTime
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                foregroundColor: _hasTime
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            M3EButtonGroupAction(
                              width: 60,
                              icon: const Icon(
                                Icons.attach_file_rounded,
                                size: 20,
                              ),
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: _showAttachments
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                foregroundColor: _showAttachments
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── 4. Attachments Section (Inline - Full Width) ───
                    if (_showAttachments) ...[
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Attachments',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: colorScheme.primary,
                                    ),
                              ),
                              if (_isFetchingAttachmentTitle) ...[
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (!_showAttachmentInput)
                                M3EIconButton(
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  size: M3EIconButtonSize.xs,
                                  variant: M3EIconButtonVariant.standard,
                                  tooltip: 'Add link',
                                  onPressed: () {
                                    setState(() => _showAttachmentInput = true);
                                    Future.delayed(
                                      const Duration(milliseconds: 80),
                                      () {
                                        if (mounted) {
                                          _attachmentFocusNode.requestFocus();
                                        }
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                          if (_showAttachmentInput) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _attachmentInputController,
                                      focusNode: _attachmentFocusNode,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: 'Paste link or note...',
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                      ),
                                      onSubmitted: (_) =>
                                          _addAttachmentInline(),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  M3EIconButton(
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                    size: M3EIconButtonSize.xs,
                                    variant: M3EIconButtonVariant.tonal,
                                    tooltip: 'Attach',
                                    onPressed: _addAttachmentInline,
                                  ),
                                  const SizedBox(width: 4),
                                  M3EIconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    size: M3EIconButtonSize.xs,
                                    variant: M3EIconButtonVariant.standard,
                                    tooltip: 'Cancel',
                                    onPressed: () {
                                      setState(() {
                                        _attachmentInputController.clear();
                                        _showAttachmentInput = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_attachments.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _attachments.map((att) {
                                return AttachmentChip(
                                  attachment: att,
                                  maxTitleLength: 18,
                                  onDelete: () {
                                    setState(() {
                                      _attachments.removeWhere(
                                        (a) => a.id == att.id,
                                      );
                                    });
                                    _syncDraft();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // ─── 5. Due Date & Time Section (Visible if set) ───
                    if (_hasDueDateOrTime) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Due Date & Time',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                  _syncDraft();
                                }),
                              ),
                            ),
                          if (_hasTime)
                            _buildGlassChip(
                              isCompact: isCompact,
                              colorScheme: colorScheme,
                              selected: true,
                              child: M3EChip(
                                type: M3EChipType.filter,
                                label: _dueTime ?? 'Time',
                                leading: Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                selected: true,
                                onPressed: _pickTime,
                                onDeleted: () => setState(() {
                                  _hasTime = false;
                                  _dueTime = null;
                                  _syncDraft();
                                }),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // ─── 6. Subtasks Section (Visible when requested or not empty) ───
                    if (_showSubtasks) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtasks',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colorScheme.primary,
                                ),
                          ),
                          if (_subtasks.isEmpty)
                            M3EIconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              size: M3EIconButtonSize.xs,
                              variant: M3EIconButtonVariant.standard,
                              tooltip: 'Hide subtasks',
                              onPressed: () {
                                setState(() {
                                  _showSubtaskSection = false;
                                });
                              },
                            ),
                        ],
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
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
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
                  borderRadius: isCompact ? 16.0 : 24.0,
                  child: isCompact
                      ? M3EIconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 25,
                            color: colorScheme.error,
                          ),
                          size: M3EIconButtonSize.md,
                          width: M3EIconButtonWidth.wide,
                          variant: M3EIconButtonVariant.tonal,
                          decoration: M3EIconButtonDecoration(
                            backgroundColor: WidgetStatePropertyAll(
                              colorScheme.errorContainer.withValues(alpha: 0.6),
                            ),
                          ),
                          onPressed: _handleDelete,
                        )
                      : M3EButton.icon(
                          onPressed: _handleDelete,
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
                            size: 25,
                            color: colorScheme.error,
                          ),
                          label: const Text('Delete'),
                        ),
                )
              else
                _buildGlassButton(
                  isCompact: isCompact,
                  borderColor: colorScheme.error.withValues(alpha: 0.35),
                  borderRadius: isCompact ? 16.0 : 24.0,
                  child: isCompact
                      ? M3EIconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 25,
                            color: colorScheme.onErrorContainer,
                          ),
                          size: M3EIconButtonSize.md,
                          width: M3EIconButtonWidth.wide,
                          variant: M3EIconButtonVariant.tonal,
                          decoration: M3EIconButtonDecoration(
                            backgroundColor: WidgetStatePropertyAll(
                              colorScheme.errorContainer.withValues(alpha: 0.6),
                            ),
                          ),
                          onPressed: () {
                            ZetaHaptics.light();
                            _closePane();
                          },
                        )
                      : M3EButton(
                          onPressed: () {
                            ZetaHaptics.light();
                            _closePane();
                          },
                          size: M3EButtonSize.md,
                          decoration: M3EButtonDecoration(
                            backgroundColor: WidgetStatePropertyAll(
                              colorScheme.errorContainer,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              colorScheme.onErrorContainer,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
              _buildGlassButton(
                isCompact: isCompact,
                borderColor: colorScheme.success.withValues(alpha: 0.35),
                borderRadius: isCompact ? 16.0 : 24.0,
                child: isCompact
                    ? M3EIconButton(
                        icon: Icon(
                          isEditing ? Icons.check_rounded : Icons.add_rounded,
                          size: 25,
                          color: colorScheme.onSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                        size: M3EIconButtonSize.md,
                        width: M3EIconButtonWidth.wide,
                        variant: M3EIconButtonVariant.tonal,
                        decoration: M3EIconButtonDecoration(
                          backgroundColor: WidgetStatePropertyAll(
                            colorScheme.success.withValues(alpha: 0.80),
                          ),
                        ),
                        onPressed: _handleSave,
                      )
                    : M3EButton.icon(
                        onPressed: _handleSave,
                        decoration: M3EButtonDecoration(
                          backgroundColor: WidgetStatePropertyAll(
                            colorScheme.success,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            colorScheme.onSuccess,
                          ),
                        ),
                        size: M3EButtonSize.md,
                        icon: Icon(
                          isEditing ? Icons.check_rounded : Icons.add_rounded,
                          size: 25,
                          color: colorScheme.onSuccess,
                        ),
                        label: Text(
                          isEditing ? 'Save' : 'Create',
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

/// Adaptive reorder listener that supports drag-and-drop operations[cite: 2].
class SubtaskReorderListener extends StatelessWidget {
  final int index;
  final bool enabled;
  final Widget child;

  const SubtaskReorderListener({
    super.key,
    required this.index,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled
          ? (PointerDownEvent event) {
              if (event.buttons != 0 &&
                  event.buttons != kPrimaryMouseButton &&
                  event.buttons != kPrimaryButton) {
                return;
              }
              final DeviceGestureSettings? gestureSettings =
                  MediaQuery.maybeGestureSettingsOf(context);
              final SliverReorderableListState? list =
                  SliverReorderableList.maybeOf(context);
              if (list == null) return;

              final MultiDragGestureRecognizer recognizer =
                  event.kind == PointerDeviceKind.mouse
                  ? ImmediateMultiDragGestureRecognizer(debugOwner: this)
                  : DelayedMultiDragGestureRecognizer(
                      delay: const Duration(milliseconds: 250),
                      debugOwner: this,
                    );

              recognizer.gestureSettings = gestureSettings;
              list.startItemDragReorder(
                index: index,
                event: event,
                recognizer: recognizer,
              );
            }
          : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.grab : MouseCursor.defer,
        child: child,
      ),
    );
  }
}

/// Attachment Chip styled consistently with M3E date/time filter chips,
/// displaying the page's favicon and truncated title to prevent RenderFlex overflow.
class AttachmentChip extends StatelessWidget {
  final AttachmentItem attachment;
  final VoidCallback onDelete;
  final int maxTitleLength;

  const AttachmentChip({
    super.key,
    required this.attachment,
    required this.onDelete,
    this.maxTitleLength = 18,
  });

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(
        url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url',
      );
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return '';
    }
  }

  String _getDisplayTitle() {
    String rawTitle = '';
    if (attachment.title.isNotEmpty && attachment.title != attachment.url) {
      rawTitle = attachment.title;
    } else {
      final domain = _getDomain(attachment.url);
      rawTitle = domain.isNotEmpty ? domain : attachment.url;
    }

    if (rawTitle.length > maxTitleLength) {
      return '${rawTitle.substring(0, maxTitleLength)}…';
    }
    return rawTitle;
  }

  Widget _buildFavicon(String domain, ColorScheme colorScheme) {
    if (domain.isEmpty) {
      return Icon(
        Icons.link_rounded,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      );
    }

    final faviconUrl =
        'https://www.google.com/s2/favicons?sz=32&domain_url=$domain';

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        faviconUrl,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.public_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;
    final domain = _getDomain(attachment.url);
    final displayTitle = _getDisplayTitle();

    final chipWidget = M3EChip(
      type: M3EChipType.filter,
      selected: true,
      label: displayTitle,
      leading: _buildFavicon(domain, colorScheme),
      onDeleted: onDelete,
      onPressed: () {},
    );

    if (!isCompact) return chipWidget;

    final radius = BorderRadius.circular(8.0);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: chipWidget,
        ),
      ),
    );
  }
}
