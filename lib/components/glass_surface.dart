import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared blurred surface foundation for glass buttons, dialogs, and sheets.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final double blurSigma;
  final Color? color;
  final Border? border;
  final bool material;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blurSigma = 6,
    this.color,
    this.border,
    this.material = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color;
    final content = material
        ? Material(color: Colors.transparent, child: child)
        : child;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: resolvedColor,
            borderRadius: borderRadius,
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}
