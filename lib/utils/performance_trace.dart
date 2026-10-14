import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Adds async timeline spans in debug/profile builds without release overhead.
Future<T> traceAsync<T>(String name, Future<T> Function() operation) async {
  if (!kDebugMode && !kProfileMode) return operation();

  final task = developer.TimelineTask()..start(name);
  try {
    return await operation();
  } finally {
    task.finish();
  }
}
