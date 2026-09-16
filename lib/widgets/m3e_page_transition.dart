import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/motion_tokens.dart';

/// Material 3 Expressive transition styles for page navigation.
enum M3EPageTransitionType {
  /// Lateral tab navigation (Home -> Tasks -> Revision -> Pomodoro -> Bin -> Settings).
  /// Slides horizontally based on index direction with subtle scale (0.96 -> 1.0) and fade.
  sharedAxisX,

  /// Vertical navigation.
  /// Slides vertically based on index direction with subtle scale (0.96 -> 1.0) and fade.
  sharedAxisY,

  /// Expressive Scale-Fade transition.
  /// Incoming page scales up from 0.92 to 1.0 with fade in.
  fadeThrough,
}

/// Material 3 Expressive Page Transition switcher widget.
/// Fulfills Material 3 Motion specifications for page transitions using
/// expressive curves ([M3MotionEasing.emphasized]), direction-aware horizontal
/// sliding, scale transitions, and automatic reduced-motion handling.
class M3EPageTransition extends StatelessWidget {
  /// The current active child page widget. Should have a distinct [Key] or [ValueKey].
  final Widget child;

  /// Current destination page index (e.g. 0 for Home, 1 for Tasks, etc.)
  final int currentIndex;

  /// Previous destination page index, used to calculate transition direction.
  final int previousIndex;

  /// Type of Material 3 transition to apply. Defaults to [M3EPageTransitionType.sharedAxisX].
  final M3EPageTransitionType transitionType;

  /// Duration of the transition animation. Defaults to 380ms per M3 Expressive motion guidelines.
  final Duration duration;

  const M3EPageTransition({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.previousIndex,
    this.transitionType = M3EPageTransitionType.sharedAxisX,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = context.select<ThemeProvider, bool>((p) => p.animations);

    final effectiveDuration = animationsEnabled ? duration : Duration.zero;
    final isForward = currentIndex >= previousIndex;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveDuration,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      layoutBuilder: (currentChild, previousChildren) {
        return ClipRect(
          child: Stack(
            alignment: Alignment.topCenter,
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
        );
      },
      transitionBuilder: (switcherChild, animation) {
        if (!animationsEnabled) return switcherChild;

        final isIncoming = switcherChild.key == child.key;
        final anim = isIncoming ? animation : ReverseAnimation(animation);

        switch (transitionType) {
          case M3EPageTransitionType.sharedAxisX:
            return _buildSharedAxisX(
              child: switcherChild,
              animation: anim,
              isIncoming: isIncoming,
              isForward: isForward,
            );
          case M3EPageTransitionType.sharedAxisY:
            return _buildSharedAxisY(
              child: switcherChild,
              animation: anim,
              isIncoming: isIncoming,
              isForward: isForward,
            );
          case M3EPageTransitionType.fadeThrough:
            return _buildFadeThrough(
              child: switcherChild,
              animation: anim,
              isIncoming: isIncoming,
            );
        }
      },
      child: child,
    );
  }

  Widget _buildSharedAxisX({
    required Widget child,
    required Animation<double> animation,
    required bool isIncoming,
    required bool isForward,
  }) {
    const double slideDistance = 0.08;
    final double incomingBegin = isForward ? slideDistance : -slideDistance;
    final double outgoingEnd = isForward ? -slideDistance : slideDistance;

    final slideAnimation = Tween<Offset>(
      begin: isIncoming ? Offset(incomingBegin, 0.0) : Offset.zero,
      end: isIncoming ? Offset.zero : Offset(outgoingEnd, 0.0),
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? M3MotionEasing.emphasizedDecelerate
          : M3MotionEasing.emphasizedAccelerate,
    ));

    final scaleAnimation = Tween<double>(
      begin: isIncoming ? 0.96 : 1.0,
      end: isIncoming ? 1.0 : 0.96,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? M3MotionEasing.emphasizedDecelerate
          : M3MotionEasing.emphasizedAccelerate,
    ));

    final fadeAnimation = Tween<double>(
      begin: isIncoming ? 0.0 : 1.0,
      end: isIncoming ? 1.0 : 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? const Interval(0.20, 1.0, curve: Curves.easeOutCubic)
          : const Interval(0.0, 0.35, curve: Curves.easeInCubic),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSharedAxisY({
    required Widget child,
    required Animation<double> animation,
    required bool isIncoming,
    required bool isForward,
  }) {
    const double slideDistance = 0.08;
    final double incomingBegin = isForward ? slideDistance : -slideDistance;
    final double outgoingEnd = isForward ? -slideDistance : slideDistance;

    final slideAnimation = Tween<Offset>(
      begin: isIncoming ? Offset(0.0, incomingBegin) : Offset.zero,
      end: isIncoming ? Offset.zero : Offset(0.0, outgoingEnd),
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? M3MotionEasing.emphasizedDecelerate
          : M3MotionEasing.emphasizedAccelerate,
    ));

    final scaleAnimation = Tween<double>(
      begin: isIncoming ? 0.96 : 1.0,
      end: isIncoming ? 1.0 : 0.96,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? M3MotionEasing.emphasizedDecelerate
          : M3MotionEasing.emphasizedAccelerate,
    ));

    final fadeAnimation = Tween<double>(
      begin: isIncoming ? 0.0 : 1.0,
      end: isIncoming ? 1.0 : 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? const Interval(0.20, 1.0, curve: Curves.easeOutCubic)
          : const Interval(0.0, 0.35, curve: Curves.easeInCubic),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  Widget _buildFadeThrough({
    required Widget child,
    required Animation<double> animation,
    required bool isIncoming,
  }) {
    final scaleAnimation = Tween<double>(
      begin: isIncoming ? 0.92 : 1.0,
      end: isIncoming ? 1.0 : 1.04,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? M3MotionEasing.emphasizedDecelerate
          : M3MotionEasing.emphasizedAccelerate,
    ));

    final fadeAnimation = Tween<double>(
      begin: isIncoming ? 0.0 : 1.0,
      end: isIncoming ? 1.0 : 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isIncoming
          ? const Interval(0.25, 1.0, curve: Curves.easeOut)
          : const Interval(0.0, 0.35, curve: Curves.easeIn),
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// Shows a dialog with Material 3 Expressive Container Transform motion.
/// The container smoothly scales in from 0.88 to 1.0 with an emphasized decelerate curve,
/// paired with an organic opacity ramp and reduced-motion fallback.
Future<T?> showM3EDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Duration duration = M3MotionDuration.medium4,
}) {
  final animationsEnabled = Provider.of<ThemeProvider>(context, listen: false).animations;
  final effectiveDuration = animationsEnabled ? duration : Duration.zero;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.modalBarrierDismissLabel ??
        'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: effectiveDuration,
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      if (!animationsEnabled) return child;

      final curvedAnim = CurvedAnimation(
        parent: animation,
        curve: M3MotionEasing.emphasizedDecelerate,
        reverseCurve: M3MotionEasing.emphasizedAccelerate,
      );

      final scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim);
      final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
        ),
      );

      return FadeTransition(
        opacity: fadeAnim,
        child: ScaleTransition(
          scale: scaleAnim,
          child: child,
        ),
      );
    },
  );
}
