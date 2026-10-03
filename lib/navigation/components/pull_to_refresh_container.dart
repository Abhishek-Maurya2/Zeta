import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../theme/motion_tokens.dart';

/// Animated stretchable refresh indicator container displayed below the top app bar.
class PullToRefreshContainer extends StatelessWidget {
  final double refreshHeight;
  final double targetHeight;
  final bool isRefreshing;

  const PullToRefreshContainer({
    super.key,
    required this.refreshHeight,
    required this.targetHeight,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    if (refreshHeight <= 0.001) {
      return const SizedBox.shrink();
    }

    final pullRatio = (refreshHeight / targetHeight).clamp(0.0, 1.0);
    final expressiveRatio = M3MotionEasing.emphasized.transform(pullRatio);

    return ClipRect(
      child: SizedBox(
        height: refreshHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0 * (1.0 - expressiveRatio * 0.35),
            vertical: 4.0,
          ),
          child: AnimatedContainer(
            duration: M3MotionDuration.short3,
            curve: M3MotionEasing.emphasized,
            width: double.infinity,
            alignment: Alignment.center,
            child: Opacity(
              opacity: pullRatio,
              child: Transform.rotate(
                angle: isRefreshing ? 0.0 : (pullRatio * 1.5 * math.pi),
                child: Transform.scale(
                  scale: (0.55 + 0.45 * expressiveRatio).clamp(0.55, 1.1),
                  child: const M3ELoadingIndicator(
                    variant: M3ELoadingIndicatorVariant.contained,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
