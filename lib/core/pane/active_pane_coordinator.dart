import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an active supporting pane in the Material 3 Expressive layout.
@immutable
class ActivePaneConfig {
  final Widget child;
  final String title;
  final String paneId;
  final double width;

  const ActivePaneConfig({
    required this.child,
    required this.title,
    required this.paneId,
    this.width = 400.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivePaneConfig &&
          runtimeType == other.runtimeType &&
          paneId == other.paneId;

  @override
  int get hashCode => paneId.hashCode;
}

/// Global coordinator for the active supporting pane in the Material 3 Expressive layout.
/// Pages publish their contextual side pane (e.g., Task Edit, Pomodoro Analysis, Revision Notes)
/// to this coordinator. The unified shell renders it as a docked side pane on desktop
/// or as an expressive modal sheet on compact viewports.
class ActivePaneCoordinator extends StateNotifier<ActivePaneConfig?> {
  ActivePaneCoordinator() : super(null);

  bool get isOpen => state != null;

  void openPane(ActivePaneConfig config) {
    state = config;
  }

  void closePane([String? expectedPaneId]) {
    if (expectedPaneId == null || state?.paneId == expectedPaneId) {
      state = null;
    }
  }

  void togglePane(ActivePaneConfig config) {
    if (state?.paneId == config.paneId) {
      state = null;
    } else {
      state = config;
    }
  }
}

final activePaneProvider =
    StateNotifierProvider<ActivePaneCoordinator, ActivePaneConfig?>((ref) {
  return ActivePaneCoordinator();
});
