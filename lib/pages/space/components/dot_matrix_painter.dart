import 'package:flutter/material.dart';

/// CustomPainter that renders a clean, subtle dot-matrix grid across the canvas.
class DotMatrixPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  const DotMatrixPainter({
    required this.dotColor,
    this.spacing = 24.0,
    this.dotRadius = 1.25,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double width = size.width;
    final double height = size.height;

    final int cols = (width / spacing).ceil();
    final int rows = (height / spacing).ceil();

    for (int i = 0; i <= cols; i++) {
      final double x = i * spacing;
      for (int j = 0; j <= rows; j++) {
        final double y = j * spacing;
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotMatrixPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius;
  }
}
