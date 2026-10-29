/// Styling attributes for a mindmap node.
class MindMapNodeStyle {
  final int? colorIndex;
  final String shape;
  final bool hasCheckbox;
  final bool isChecked;
  final List<String> tags;

  const MindMapNodeStyle({
    this.colorIndex,
    this.shape = 'rounded',
    this.hasCheckbox = true,
    this.isChecked = false,
    this.tags = const [],
  });

  MindMapNodeStyle copyWith({
    int? colorIndex,
    String? shape,
    bool? hasCheckbox,
    bool? isChecked,
    List<String>? tags,
  }) {
    return MindMapNodeStyle(
      colorIndex: colorIndex ?? this.colorIndex,
      shape: shape ?? this.shape,
      hasCheckbox: hasCheckbox ?? this.hasCheckbox,
      isChecked: isChecked ?? this.isChecked,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorIndex': colorIndex,
      'shape': shape,
      'hasCheckbox': hasCheckbox,
      'isChecked': isChecked,
      'tags': tags,
    };
  }

  factory MindMapNodeStyle.fromJson(Map<String, dynamic> json) {
    return MindMapNodeStyle(
      colorIndex: json['colorIndex'] as int?,
      shape: json['shape'] as String? ?? 'rounded',
      hasCheckbox: json['hasCheckbox'] as bool? ?? true,
      isChecked: json['isChecked'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// A node within the N-ary mindmap tree.
class MindMapNode {
  final String id;
  final String? parentId;
  final double orderIndex;
  final String content;
  final bool isCollapsed;
  final MindMapNodeStyle style;

  const MindMapNode({
    required this.id,
    this.parentId,
    required this.orderIndex,
    required this.content,
    this.isCollapsed = false,
    this.style = const MindMapNodeStyle(),
  });

  bool get isRoot => parentId == null;

  MindMapNode copyWith({
    String? id,
    String? parentId,
    bool clearParent = false,
    double? orderIndex,
    String? content,
    bool? isCollapsed,
    MindMapNodeStyle? style,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      orderIndex: orderIndex ?? this.orderIndex,
      content: content ?? this.content,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'orderIndex': orderIndex,
      'content': content,
      'isCollapsed': isCollapsed,
      'style': style.toJson(),
    };
  }

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toDouble() ?? 0.0,
      content: json['content'] as String? ?? '',
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      style: json['style'] != null
          ? MindMapNodeStyle.fromJson(json['style'] as Map<String, dynamic>)
          : const MindMapNodeStyle(),
    );
  }
}
