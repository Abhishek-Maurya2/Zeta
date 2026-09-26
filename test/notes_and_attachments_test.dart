import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/attachment.dart';
import 'package:zeta/models/note_item.dart';
import 'package:zeta/models/revision.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/services/attachment_parser_service.dart';

void main() {
  group('AttachmentParserService Tests', () {
    test('detectType identifies YouTube URLs correctly', () {
      expect(
        AttachmentParserService.detectType('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals(AttachmentType.youtube),
      );
      expect(
        AttachmentParserService.detectType('https://youtu.be/dQw4w9WgXcQ'),
        equals(AttachmentType.youtube),
      );
      expect(
        AttachmentParserService.detectType('https://m.youtube.com/shorts/dQw4w9WgXcQ'),
        equals(AttachmentType.youtube),
      );
    });

    test('detectType identifies Google Drive URLs correctly', () {
      expect(
        AttachmentParserService.detectType('https://drive.google.com/file/d/12345/view'),
        equals(AttachmentType.googleDrive),
      );
      expect(
        AttachmentParserService.detectType('https://docs.google.com/document/d/1abc/edit'),
        equals(AttachmentType.googleDrive),
      );
      expect(
        AttachmentParserService.detectType('https://docs.google.com/spreadsheets/d/1xyz/edit'),
        equals(AttachmentType.googleDrive),
      );
      expect(
        AttachmentParserService.detectType('https://docs.google.com/presentation/d/1ppt/edit'),
        equals(AttachmentType.googleDrive),
      );
    });

    test('detectGoogleDriveType distinguishes Docs, Sheets, Slides, and Folders', () {
      expect(
        AttachmentParserService.detectGoogleDriveType('https://docs.google.com/document/d/1abc'),
        equals(GoogleDriveType.document),
      );
      expect(
        AttachmentParserService.detectGoogleDriveType('https://docs.google.com/spreadsheets/d/1abc'),
        equals(GoogleDriveType.spreadsheets),
      );
      expect(
        AttachmentParserService.detectGoogleDriveType('https://docs.google.com/presentation/d/1abc'),
        equals(GoogleDriveType.presentation),
      );
      expect(
        AttachmentParserService.detectGoogleDriveType('https://drive.google.com/drive/folders/1abc'),
        equals(GoogleDriveType.folder),
      );
      expect(
        AttachmentParserService.detectGoogleDriveType('https://drive.google.com/file/d/1abc/view'),
        equals(GoogleDriveType.genericFile),
      );
    });

    test('detectType identifies generic Web Links', () {
      expect(
        AttachmentParserService.detectType('https://flutter.dev'),
        equals(AttachmentType.link),
      );
      expect(
        AttachmentParserService.detectType('https://github.com/flutter/flutter'),
        equals(AttachmentType.link),
      );
    });
  });

  group('AttachmentItem and NoteItem Serialization Tests', () {
    test('AttachmentItem serializes and deserializes cleanly', () {
      final attachment = AttachmentItem(
        id: 'att-1',
        url: 'https://youtu.be/dQw4w9WgXcQ',
        title: 'Rick Astley - Never Gonna Give You Up',
        type: AttachmentType.youtube,
        videoId: 'dQw4w9WgXcQ',
        createdAt: DateTime(2026, 9, 27, 12, 0, 0),
      );

      final json = attachment.toJson();
      final revived = AttachmentItem.fromJson(json);

      expect(revived.id, equals(attachment.id));
      expect(revived.url, equals(attachment.url));
      expect(revived.title, equals(attachment.title));
      expect(revived.type, equals(AttachmentType.youtube));
      expect(revived.videoId, equals('dQw4w9WgXcQ'));
    });

    test('NoteItem serializes and deserializes with nested attachments', () {
      final note = NoteItem(
        id: 'note-1',
        title: 'Chapter 1 Notes',
        content: '# Chapter 1 Notes\nKey points: Spaced repetition is effective.',
        createdAt: DateTime(2026, 9, 27, 10, 0, 0),
        updatedAt: DateTime(2026, 9, 27, 11, 0, 0),
        attachments: [
          AttachmentItem(
            id: 'att-sub-1',
            url: 'https://docs.google.com/document/d/xyz',
            title: 'Syllabus Summary Doc',
            type: AttachmentType.googleDrive,
            driveType: GoogleDriveType.document.toDbString(),
          ),
        ],
      );

      final json = note.toJson();
      final revived = NoteItem.fromJson(json);

      expect(revived.id, equals(note.id));
      expect(revived.title, equals(note.title));
      expect(revived.content, equals(note.content));
      expect(revived.attachments.length, equals(1));
      expect(revived.attachments.first.driveType, equals('document'));
    });
  });

  group('Model Attachments and Notes Integration', () {
    test('Task model retains attachments in copyWith and JSON roundtrip', () {
      final task = Task(
        id: 't-1',
        title: 'Study Fluid Mechanics',
        description: 'Review Bernoulli principle',
        attachments: [
          AttachmentItem(
            id: 'a-1',
            url: 'https://en.wikipedia.org/wiki/Bernoulli%27s_principle',
            title: "Bernoulli's principle - Wikipedia",
            type: AttachmentType.link,
          ),
        ],
      );

      expect(task.attachments.length, equals(1));
      expect(task.attachments.first.title, contains('Bernoulli'));

      final json = task.toJson();
      final revived = Task.fromJson(json);
      expect(revived.attachments.length, equals(1));
      expect(revived.attachments.first.url, equals('https://en.wikipedia.org/wiki/Bernoulli%27s_principle'));

      final copied = task.copyWith(
        attachments: [
          ...task.attachments,
          AttachmentItem(
            id: 'a-2',
            url: 'https://youtube.com/watch?v=123',
            title: 'Bernoulli Demonstration',
            type: AttachmentType.youtube,
          ),
        ],
      );
      expect(copied.attachments.length, equals(2));
    });

    test('Subject model serializes note and direct attachments', () {
      final subject = Subject(
        id: 's-1',
        name: 'Physics',
        note: NoteItem(
          id: 'n-sub',
          title: 'Physics Syllabus',
          content: 'Course syllabus and formulas',
        ),
        attachments: [
          AttachmentItem(
            id: 'att-sub',
            url: 'https://drive.google.com/drive/folders/folder123',
            title: 'Physics Drive Folder',
            type: AttachmentType.googleDrive,
            driveType: GoogleDriveType.folder.toDbString(),
          ),
        ],
      );

      final json = subject.toJson();
      final revived = Subject.fromJson(json);

      expect(revived.note?.content, equals('Course syllabus and formulas'));
      expect(revived.attachments.length, equals(1));
      expect(revived.attachments.first.driveType, equals('folder'));
    });

    test('ChapterTopic preserves backward compatibility with description/notes fallback', () {
      // Legacy JSON without note object or attachments
      final legacyJson = {
        'id': 'top-1',
        'subjectId': 's-1',
        'title': 'Kinematics',
        'description': 'Velocity and acceleration vectors',
        'notes': 'Legacy notes string',
      };

      final topic = ChapterTopic.fromJson(legacyJson);
      expect(topic.note, isNotNull);
      expect(topic.note!.content, equals('Velocity and acceleration vectors'));
      expect(topic.attachments, isEmpty);

      final updated = topic.copyWith(
        note: NoteItem(
          id: 'new-note',
          title: 'Kinematics Notes',
          content: 'Updated modern markdown notes',
          attachments: [
            AttachmentItem(
              id: 'att-t-1',
              url: 'https://flutter.dev',
              title: 'Flutter Website',
              type: AttachmentType.link,
            ),
          ],
        ),
      );

      expect(updated.note?.content, equals('Updated modern markdown notes'));
      expect(updated.note?.attachments.length, equals(1));
    });
  });
}
