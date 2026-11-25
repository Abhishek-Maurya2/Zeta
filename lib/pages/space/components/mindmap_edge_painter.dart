import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../models/mindmap_edge.dart';

/// CustomPainter that renders clean Cubic Bézier S-curve branches
/// with depth-based tonal colors and subtle focus emphasis.
class MindMapEdgePainter extends CustomPainter {
  final List<MindMapEdge> edges;
  final String? hoveredNodeId;
  final bool isDark;
  final Rect? visibleRect;

  static final Paint _highlightHaloPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  const MindMapEdgePainter({
    required this.edges,
    this.hoveredNodeId,
    this.isDark = false,
    this.visibleRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    final hasFocus = hoveredNodeId != null;

    for (final edge in edges) {
      if (visibleRect != null) {
        final edgeBounds =
            Rect.fromPoints(edge.startPoint, edge.endPoint).inflate(28.0);
        if (!edgeBounds.overlaps(visibleRect!)) {
          continue;
        }
      }

      final isHighlighted =
          hasFocus &&
          (edge.sourceId == hoveredNodeId || edge.targetId == hoveredNodeId);

      final strokeWidth =
          isHighlighted ? edge.strokeWidth + 0.8 : edge.strokeWidth;

      final start = edge.startPoint;
      final end = edge.endPoint;

      final Path path;
      if (edge.isVertical) {
        final dy = end.dy - start.dy;
        final cp1 = Offset(start.dx, start.dy + dy * 0.55);
        final cp2 = Offset(end.dx, end.dy - dy * 0.55);
        path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      } else {
        final dx = end.dx - start.dx;
        final cp1 = Offset(start.dx + dx * 0.55, start.dy);
        final cp2 = Offset(end.dx - dx * 0.55, end.dy);
        path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      }

      if (isHighlighted) {
        _highlightHaloPaint
          ..color = edge.color.withValues(alpha: isDark ? 0.22 : 0.14)
          ..strokeWidth = strokeWidth + 4.0;
        canvas.drawPath(path, _highlightHaloPaint);
      }

      final double lineAlpha;
      if (isHighlighted) {
        lineAlpha = 1.0;
      } else if (hasFocus) {
        lineAlpha = isDark ? 0.45 : 0.40;
      } else {
        lineAlpha = isDark ? 0.88 : 0.82;
      }

      _corePaint
        ..color = edge.color.withValues(alpha: lineAlpha)
        ..strokeWidth = strokeWidth;
      canvas.drawPath(path, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MindMapEdgePainter oldDelegate) {
    return oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.isDark != isDark ||
        oldDelegate.visibleRect != visibleRect ||
        !listEquals(oldDelegate.edges, edges);
  }
}
