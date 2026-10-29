import 'package:flutter/material.dart';
import '../models/mindmap_edge.dart';

/// CustomPainter that renders procedurally calculated Cubic Bézier splines
/// connecting parent nodes to child nodes with tapering strokes and branch colors.
class MindMapEdgePainter extends CustomPainter {
  final List<MindMapEdge> edges;
  final String? hoveredNodeId;
  final bool isDark;

  const MindMapEdgePainter({
    required this.edges,
    this.hoveredNodeId,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    for (final edge in edges) {
      final isHighlighted = hoveredNodeId != null &&
          (edge.sourceId == hoveredNodeId || edge.targetId == hoveredNodeId);

      final strokeWidth = isHighlighted ? edge.strokeWidth + 1.2 : edge.strokeWidth;
      final edgeColor = isHighlighted
          ? edge.color.withValues(alpha: 0.98)
          : edge.color.withValues(alpha: isDark ? 0.85 : 0.70);

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final start = edge.startPoint;
      final end = edge.endPoint;
      final dx = end.dx - start.dx;

      // Cubic Bézier control points
      final cp1 = Offset(start.dx + dx * 0.5, start.dy);
      final cp2 = Offset(end.dx - dx * 0.5, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

      canvas.drawPath(path, paint);

      // Draw subtle circular connector joints at endpoints
      final jointPaint = Paint()
        ..color = edge.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawCircle(end, strokeWidth * 0.9, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MindMapEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.isDark != isDark;
  }
}
