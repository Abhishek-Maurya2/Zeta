import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
