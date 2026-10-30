import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/mindmap_edge.dart';

/// CustomPainter that renders procedurally calculated Cubic Bézier splines
/// with M3 Expressive tonal glow and ring-styled anchor joints.
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

      final strokeWidth =
          isHighlighted ? edge.strokeWidth + 1.4 : edge.strokeWidth;

      final start = edge.startPoint;
      final end = edge.endPoint;
      final dx = end.dx - start.dx;

      final cp1 = Offset(start.dx + dx * 0.5, start.dy);
      final cp2 = Offset(end.dx - dx * 0.5, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

      // 1. Subtle ambient under-glow for depth
      final glowPaint = Paint()
        ..color = edge.color.withValues(
          alpha: isHighlighted ? (isDark ? 0.45 : 0.30) : (isDark ? 0.18 : 0.10),
        )
        ..strokeWidth = strokeWidth + (isHighlighted ? 6.0 : 3.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawPath(path, glowPaint);

      // 2. Crisp core spline
      final corePaint = Paint()
        ..color = isHighlighted
            ? edge.color
            : edge.color.withValues(alpha: isDark ? 0.90 : 0.82)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawPath(path, corePaint);

      // 3. Expressive two-tone terminal joint
      final jointRadius = (strokeWidth * 1.15).clamp(3.0, 5.5);
      canvas.drawCircle(
        end,
        jointRadius,
        Paint()
          ..color = edge.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        end,
        jointRadius * 0.45,
        Paint()
          ..color = isDark ? const Color(0xFF1A1C1E) : Colors.white
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindMapEdgePainter oldDelegate) {
    return oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.isDark != isDark ||
        !listEquals(oldDelegate.edges, edges);
  }
}