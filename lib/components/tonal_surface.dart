import 'package:flutter/material.dart';

/// Elevation levels mapped to Material 3 surfaceContainer tokens.
enum TonalElevation {
  level0, // surface
  level1, // surfaceContainerLow
  level2, // surfaceContainer
  level3, // surfaceContainerHigh
  level4, // surfaceContainerHighest
}

/// Clean Material 3 Tonal Surface utilizing `surfaceContainer` tokens
/// with ZERO `BackdropFilter` or `saveLayer` GPU overhead.
class TonalSurface extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final Border? border;
  final TonalElevation elevation;
  final bool material;
  final Clip clipBehavior;
  final double? blurSigma; // Accepted for backward compatibility; zero GPU blur applied.

  const TonalSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.color,
    this.border,
    this.elevation = TonalElevation.level2,
    this.material = false,
    this.clipBehavior = Clip.antiAlias,
    this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? switch (elevation) {
      TonalElevation.level0 => colorScheme.surface,
      TonalElevation.level1 => colorScheme.surfaceContainerLow,
      TonalElevation.level2 => colorScheme.surfaceContainer,
      TonalElevation.level3 => colorScheme.surfaceContainerHigh,
      TonalElevation.level4 => colorScheme.surfaceContainerHighest,
    };

    if (material) {
      return Material(
        color: resolvedColor,
        borderRadius: borderRadius is BorderRadius ? borderRadius : null,
        shape: border != null && borderRadius is BorderRadius
            ? RoundedRectangleBorder(
                borderRadius: borderRadius as BorderRadius,
                side: border!.top,
              )
            : null,
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    Widget content = Container(
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: child,
    );

    if (clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    return content;
  }
}
