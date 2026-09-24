import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../components/task_edit_pane.dart';
import '../models/task.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../utils/task_date_formatter.dart';

/// Keeps Android's native home-screen widget in sync with Flutter task data.
class AndroidTasksWidgetService with WidgetsBindingObserver {
  AndroidTasksWidgetService._();

  static final AndroidTasksWidgetService instance =
      AndroidTasksWidgetService._();
  static const MethodChannel _channel = MethodChannel('zeta/tasks_widget');

  BuildContext? _context;
  TaskProvider? _taskProvider;
  bool _initialized = false;
  bool _publishing = false;
  bool _publishAgain = false;

  Future<void> initialize(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _context = context;
    _taskProvider = context.read<TaskProvider>();
    if (!_initialized) {
      _initialized = true;
      _taskProvider!.addListener(_onProviderChanged);
      _channel.setMethodCallHandler(_handleNativeCall);
      WidgetsBinding.instance.addObserver(this);
    }

    unawaited(_publishWidgetState());
    try {
      final action = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialWidgetAction',
      );
      if (action != null) await _handleWidgetAction(action);
    } on MissingPluginException {
      // The bridge only exists in the Android app build.
    } on PlatformException {
      // Keep the app usable if an older installed build lacks the bridge.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWidgetAction' && call.arguments is Map) {
      await _handleWidgetAction(
        Map<String, dynamic>.from(call.arguments as Map),
      );
    }
  }

  void _onProviderChanged() {
    unawaited(_publishWidgetState());
  }

  @override
  void didChangePlatformBrightness() {
    unawaited(_publishWidgetState());
  }

  Future<void> _handleWidgetAction(Map<String, dynamic> action) async {
    final context = _context;
    final taskProvider = _taskProvider;
    if (context == null || !context.mounted || taskProvider == null) return;

    await taskProvider.loadFuture;
    if (!context.mounted) return;

    final actionName = action['action']?.toString();
    final taskId = action['taskId']?.toString();
    if (actionName == 'toggle' && taskId != null && taskId.isNotEmpty) {
      taskProvider.toggleTask(taskId);
      return;
    }

    Task? task;
    if (actionName == 'edit' && taskId != null && taskId.isNotEmpty) {
      for (final candidate in taskProvider.allTasks) {
        if (candidate.id == taskId) {
          task = candidate;
          break;
        }
      }
      if (task == null) return;
    } else if (actionName != 'create') {
      return;
    }

    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    await TaskEditPane.show(context, task: task);
  }

  /// Public method to force an immediate widget update (e.g. when theme changes).
  Future<void> refresh() => _publishWidgetState();

  Future<void> _publishWidgetState() async {
    if (!_initialized) return;
    if (_publishing) {
      _publishAgain = true;
      return;
    }

    _publishing = true;
    try {
      final context = _context;
      final taskProvider = _taskProvider;
      if (context == null || !context.mounted || taskProvider == null) return;
      await taskProvider.loadFuture;
      if (!context.mounted) return;

      final tasks = taskProvider.allTasks.where((task) => !task.completed).toList()
        ..sort(_compareTasksForWidget);
      final taskRows = tasks.map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'due': _formatDue(task),
          'completed': task.completed,
        };
      }).toList();

      final systemAccentValue = await _readDeviceAccentColor();
      if (!context.mounted) return;

      // Always follow the system seed / accent colour (fallback to primary seed if device has none).
      final seedColor = systemAccentValue != null
          ? Color(systemAccentValue)
          : const Color(0xFF6750A4);

      // Follow the system platform brightness (system dark / light mode).
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;

      final scheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: systemBrightness,
        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      );

      final payload = <String, Object>{
        'tasks': jsonEncode(taskRows),
        'secondaryContainer': scheme.secondaryContainer.toARGB32(),
        'onSecondaryContainer': scheme.onSecondaryContainer.toARGB32(),
        'primary': scheme.primary.toARGB32(),
        'onPrimary': scheme.onPrimary.toARGB32(),
        'onSurface': scheme.onSurface.toARGB32(),
      };
      await _channel.invokeMethod<void>('updateWidget', payload);
    } on MissingPluginException {
      // The bridge only exists in the Android app build.
    } on PlatformException {
      // A widget update failure should not interrupt the app.
    } finally {
      _publishing = false;
      if (_publishAgain) {
        _publishAgain = false;
        unawaited(_publishWidgetState());
      }
    }
  }

  Future<int?> _readDeviceAccentColor() async {
    try {
      return await _channel.invokeMethod<int>('getDeviceAccentColor');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _formatDue(Task task) {
    final hasDueDate = task.dueDate?.trim().isNotEmpty == true;
    final dueTime = task.dueTime?.trim();
    final hasDueTime = dueTime?.isNotEmpty == true;
    if (!hasDueDate) {
      // No date — show time alone if present.
      return hasDueTime ? dueTime! : '';
    }
    final isDueToday = TaskDateFormatter.isToday(task.dueDate);
    if (isDueToday) {
      // Due today: show time if present, else 'Today'.
      return hasDueTime ? dueTime! : 'Today';
    }
    // Not today: show date label (Yesterday / Tomorrow / 13, Sep).
    return TaskDateFormatter.formatString(task.dueDate!);
  }

  int _compareTasksForWidget(Task a, Task b) {
    final aDue = a.dueDate == null ? null : TaskDateFormatter.parse(a.dueDate!);
    final bDue = b.dueDate == null ? null : TaskDateFormatter.parse(b.dueDate!);
    if (aDue != null && bDue != null) {
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) return byDue;
    } else if (aDue != null) {
      return -1;
    } else if (bDue != null) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  void dispose() {
    if (_initialized) {
      _taskProvider?.removeListener(_onProviderChanged);
      WidgetsBinding.instance.removeObserver(this);
      _channel.setMethodCallHandler(null);
    }
    _initialized = false;
    _context = null;
    _taskProvider = null;
  }
}
