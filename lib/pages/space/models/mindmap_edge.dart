import 'package:flutter/material.dart';

/// Representation of a procedurally routed edge connecting a parent node to a child node.
class MindMapEdge {
  final String sourceId;
  final String targetId;
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double strokeWidth;
  final bool isLeft;

  const MindMapEdge({
    required this.sourceId,
    required this.targetId,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
    this.isLeft = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MindMapEdge &&
        other.sourceId == sourceId &&
        other.targetId == targetId &&
        other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.isLeft == isLeft;
  }

  @override
  int get hashCode => Object.hash(
        sourceId,
        targetId,
        startPoint,
        endPoint,
        color,
        strokeWidth,
        isLeft,
      );
}