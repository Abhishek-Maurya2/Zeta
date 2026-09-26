enum AttachmentType {
  youtube,
  googleDrive,
  link;

  static AttachmentType fromString(String? val) {
    if (val == null) return AttachmentType.link;
    return switch (val.toLowerCase()) {
      'youtube' => AttachmentType.youtube,
      'google_drive' || 'googledrive' => AttachmentType.googleDrive,
      _ => AttachmentType.link,
    };
  }

  String toDbString() => switch (this) {
    AttachmentType.youtube => 'youtube',
    AttachmentType.googleDrive => 'google_drive',
    AttachmentType.link => 'link',
  };
}

enum GoogleDriveType {
  document,
  spreadsheets,
  presentation,
  folder,
  genericFile;

  static GoogleDriveType fromString(String? val) {
    if (val == null) return GoogleDriveType.genericFile;
    return switch (val.toLowerCase()) {
      'document' || 'doc' || 'docs' => GoogleDriveType.document,
      'spreadsheets' || 'sheet' || 'sheets' => GoogleDriveType.spreadsheets,
      'presentation' || 'slide' || 'slides' => GoogleDriveType.presentation,
      'folder' || 'folders' => GoogleDriveType.folder,
      _ => GoogleDriveType.genericFile,
    };
  }

  String toDbString() => switch (this) {
    GoogleDriveType.document => 'document',
    GoogleDriveType.spreadsheets => 'spreadsheets',
    GoogleDriveType.presentation => 'presentation',
    GoogleDriveType.folder => 'folder',
    GoogleDriveType.genericFile => 'file',
  };
}

class AttachmentItem {
  final String id;
  final String url;
  final String title;
  final AttachmentType type;
  final String? driveType;
  final String? videoId;
  final String? faviconUrl;
  final DateTime createdAt;

  AttachmentItem({
    required this.id,
    required this.url,
    required this.title,
    required this.type,
    this.driveType,
    this.videoId,
    this.faviconUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'title': title,
    'type': type.toDbString(),
    'driveType': driveType,
    'videoId': videoId,
    'faviconUrl': faviconUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AttachmentItem.fromJson(Map<String, dynamic> json) => AttachmentItem(
    id: json['id'] as String? ?? '',
    url: json['url'] as String? ?? '',
    title: json['title'] as String? ?? '',
    type: AttachmentType.fromString(json['type'] as String?),
    driveType: json['driveType'] as String?,
    videoId: json['videoId'] as String?,
    faviconUrl: json['faviconUrl'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  AttachmentItem copyWith({
    String? id,
    String? url,
    String? title,
    AttachmentType? type,
    String? driveType,
    String? videoId,
    String? faviconUrl,
    DateTime? createdAt,
  }) => AttachmentItem(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    type: type ?? this.type,
    driveType: driveType ?? this.driveType,
    videoId: videoId ?? this.videoId,
    faviconUrl: faviconUrl ?? this.faviconUrl,
    createdAt: createdAt ?? this.createdAt,
  );
}
