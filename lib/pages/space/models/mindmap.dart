import 'mindmap_node.dart';

/// Container for an entire mindmap hierarchy.
class MindMap {
  final String id;
  final String title;
  final int createdAtMs;
  final int updatedAtMs;
  final String layoutType; // 'horizontal' or 'balanced'
  final List<MindMapNode> nodes;

  const MindMap({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.layoutType = 'horizontal',
    required this.nodes,
  });

  MindMapNode? get rootNode {
    for (final node in nodes) {
      if (node.isRoot) return node;
    }
    return nodes.isNotEmpty ? nodes.first : null;
  }

  List<MindMapNode> childrenOf(String? parentId) {
    final children = nodes.where((n) => n.parentId == parentId).toList();
    children.sort((a, b) {
      final cmp = a.orderIndex.compareTo(b.orderIndex);
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });
    return children;
  }

  List<MindMapNode> descendantsOf(String parentId) {
    final result = <MindMapNode>[];
    final queue = <String>[parentId];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = nodes.where((n) => n.parentId == current);
      for (final child in children) {
        result.add(child);
        queue.add(child.id);
      }
    }
    return result;
  }

  bool isDescendant(String potentialDescendantId, String ancestorId) {
    if (potentialDescendantId == ancestorId) return true;
    final descendants = descendantsOf(ancestorId);
    return descendants.any((d) => d.id == potentialDescendantId);
  }

  MindMap copyWith({
    String? id,
    String? title,
    int? createdAtMs,
    int? updatedAtMs,
    String? layoutType,
    List<MindMapNode>? nodes,
  }) {
    return MindMap(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      layoutType: layoutType ?? this.layoutType,
      nodes: nodes ?? this.nodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'layoutType': layoutType,
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }

  factory MindMap.fromJson(Map<String, dynamic> json) {
    return MindMap(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Mindmap',
      createdAtMs:
          json['createdAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAtMs:
          json['updatedAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      layoutType: json['layoutType'] as String? ?? 'horizontal',
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}