import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// CustomPainter that renders a viewport-culled dual-tier dot-matrix grid
/// synced with the canvas pan and zoom.
class DotMatrixPainter extends CustomPainter {
  final Color dotColor;
  final Color? majorDotColor;
  final double spacing;
  final double dotRadius;
  final TransformationController transformationController;

  static Float32List? _minorBuffer;
  static Float32List? _majorBuffer;

  DotMatrixPainter({
    required this.dotColor,
    this.majorDotColor,
    required this.transformationController,
    this.spacing = 24.0,
    this.dotRadius = 1.25,
  }) : super(repaint: transformationController);

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // Hide minor dots if zoomed out so far they would alias into solid noise
    final effectiveSpacing = spacing * scale;
    if (effectiveSpacing < 6.0) return;

    final translation = matrix.getTranslation();
    final offsetX = translation.x % effectiveSpacing;
    final offsetY = translation.y % effectiveSpacing;

    final startCol = -(translation.x / effectiveSpacing).floor();
    final startRow = -(translation.y / effectiveSpacing).floor();

    final cols = (size.width / effectiveSpacing).ceil() + 1;
    final rows = (size.height / effectiveSpacing).ceil() + 1;

    final maxPoints = cols * rows * 2;
    if (_minorBuffer == null || _minorBuffer!.length < maxPoints) {
      _minorBuffer = Float32List(maxPoints);
    }
    if (_majorBuffer == null || _majorBuffer!.length < maxPoints) {
      _majorBuffer = Float32List(maxPoints);
    }

    int minorIdx = 0;
    int majorIdx = 0;

    for (int i = 0; i < cols; i++) {
      final x = offsetX + i * effectiveSpacing;
      final isMajorCol = ((startCol + i) % 5) == 0;
      for (int j = 0; j < rows; j++) {
        final y = offsetY + j * effectiveSpacing;
        if (isMajorCol && ((startRow + j) % 5) == 0) {
          _majorBuffer![majorIdx++] = x;
          _majorBuffer![majorIdx++] = y;
        } else {
          _minorBuffer![minorIdx++] = x;
          _minorBuffer![minorIdx++] = y;
        }
      }
    }

    if (minorIdx > 0) {
      final minorPaint = Paint()
        ..color = dotColor
        ..strokeWidth = (dotRadius * 2 * scale).clamp(1.1, 3.6)
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(
        ui.PointMode.points,
        _minorBuffer!.buffer.asFloat32List(0, minorIdx),
        minorPaint,
      );
    }

    if (majorIdx > 0) {
      final majorPaint = Paint()
        ..color = majorDotColor ?? dotColor.withValues(alpha: 0.7)
        ..strokeWidth = (dotRadius * 3.1 * scale).clamp(2.0, 5.2)
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(
        ui.PointMode.points,
        _majorBuffer!.buffer.asFloat32List(0, majorIdx),
        majorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DotMatrixPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.majorDotColor != majorDotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.transformationController != transformationController;
  }
}
