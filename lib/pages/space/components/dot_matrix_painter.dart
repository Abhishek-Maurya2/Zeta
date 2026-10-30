import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// CustomPainter that renders a viewport-culled dot-matrix grid synced with the canvas pan/zoom.
class DotMatrixPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;
  final TransformationController transformationController;

  DotMatrixPainter({
    required this.dotColor,
    required this.transformationController,
    this.spacing = 24.0,
    this.dotRadius = 1.25,
  }) : super(repaint: transformationController);

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // Hide dots if zoomed out so far they would alias into solid noise
    final effectiveSpacing = spacing * scale;
    if (effectiveSpacing < 6.0) return;

    final translation = matrix.getTranslation();
    final offsetX = translation.x % effectiveSpacing;
    final offsetY = translation.y % effectiveSpacing;

    final cols = (size.width / effectiveSpacing).ceil() + 1;
    final rows = (size.height / effectiveSpacing).ceil() + 1;

    final coords = Float32List(cols * rows * 2);
    int idx = 0;

    for (int i = 0; i < cols; i++) {
      final x = offsetX + i * effectiveSpacing;
      for (int j = 0; j < rows; j++) {
        final y = offsetY + j * effectiveSpacing;
        coords[idx++] = x;
        coords[idx++] = y;
      }
    }

    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = (dotRadius * 2 * scale).clamp(1.2, 4.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawRawPoints(ui.PointMode.points, coords, paint);
  }

  @override
  bool shouldRepaint(covariant DotMatrixPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.transformationController != transformationController;
  }
}