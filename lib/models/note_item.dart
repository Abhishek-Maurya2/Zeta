import 'attachment.dart';

class NoteItem {
  final String id;
  String title;
  String content;
  List<AttachmentItem> attachments;
  DateTime createdAt;
  DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    this.content = '',
    List<AttachmentItem>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty && attachments.isEmpty;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    attachments: (json['attachments'] as List<dynamic>?)
        ?.map((a) => AttachmentItem.fromJson(a as Map<String, dynamic>))
        .toList() ??
        [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    List<AttachmentItem>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteItem(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    attachments: attachments ?? this.attachments.map((a) => a.copyWith()).toList(),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
