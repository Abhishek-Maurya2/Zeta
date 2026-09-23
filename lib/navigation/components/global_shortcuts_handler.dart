import 'package:flutter/material.dart';

/// Utility to evaluate and route global hardware keyboard shortcuts.
class GlobalShortcutsHandler {
  GlobalShortcutsHandler._();

  /// Checks whether focus is currently on an editable text input or form field.
  static bool isTyping() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;

    // 1. Direct label check (Flutter sets debugLabel: 'EditableText')
    final label = focus.debugLabel;
    if (label != null && label.contains('EditableText')) return true;

    // 2. Element tree traversal check
    final ctx = focus.context;
    if (ctx != null && ctx.mounted) {
      if (ctx.widget is EditableText) return true;
      if (ctx.findAncestorWidgetOfExactType<EditableText>() != null) {
        return true;
      }
      if (ctx.findAncestorStateOfType<EditableTextState>() != null) return true;
    }

    return false;
  }
}
