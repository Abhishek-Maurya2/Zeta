import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../models/mindmap_edge.dart';

/// CustomPainter that renders Material 3 Expressive Cubic Bézier splines
/// with tonal branch emphasis, dimmed inactive branches on focus, and crisp anchor joints.
class MindMapEdgePainter extends CustomPainter {
  final List<MindMapEdge> edges;
  final String? hoveredNodeId;
  final bool isDark;
  final Rect? visibleRect;

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
    final jointCenterColor =
        isDark ? const Color(0xFF141518) : const Color(0xFFFAF9FD);

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
          isHighlighted ? edge.strokeWidth + 1.4 : edge.strokeWidth;

      final start = edge.startPoint;
      final end = edge.endPoint;

      final Path path;
      if (edge.isVertical) {
        final dy = end.dy - start.dy;
        final cp1 = Offset(start.dx, start.dy + dy * 0.52);
        final cp2 = Offset(end.dx, end.dy - dy * 0.52);
        path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      } else {
        final dx = end.dx - start.dx;
        final cp1 = Offset(start.dx + dx * 0.52, start.dy);
        final cp2 = Offset(end.dx - dx * 0.52, end.dy);
        path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      }

      // 1. Subtle tonal halo ONLY on highlighted branch
      if (isHighlighted) {
        final highlightHaloPaint = Paint()
          ..color = edge.color.withValues(alpha: isDark ? 0.24 : 0.16)
          ..strokeWidth = strokeWidth + 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;
        canvas.drawPath(path, highlightHaloPaint);
      }

      // 2. Crisp core spline (dimmed slightly when another branch is focused)
      final double lineAlpha;
      if (isHighlighted) {
        lineAlpha = 1.0;
      } else if (hasFocus) {
        lineAlpha = isDark ? 0.42 : 0.36;
      } else {
        lineAlpha = isDark ? 0.80 : 0.70;
      }

      final corePaint = Paint()
        ..color = edge.color.withValues(alpha: lineAlpha)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(path, corePaint);

      // 3. Origin anchor dot & expressive two-tone terminal ring joint
      final jointRadius =
          (strokeWidth * (isHighlighted ? 1.25 : 1.05)).clamp(3.0, 5.5);

      canvas.drawCircle(
        start,
        jointRadius * 0.55,
        Paint()
          ..color = edge.color.withValues(alpha: lineAlpha)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      canvas.drawCircle(
        end,
        jointRadius,
        Paint()
          ..color = edge.color.withValues(alpha: lineAlpha)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        end,
        jointRadius * 0.45,
        Paint()
          ..color = jointCenterColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
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
