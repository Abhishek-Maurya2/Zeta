import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/components/add_attachment_dialog.dart';
import 'package:zeta/models/attachment.dart';
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

  group('AttachmentItem Serialization Tests', () {
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

  });

  group('AddAttachmentDialog Widget Layout Test', () {
    testWidgets('renders AddAttachmentDialog with no layout overflows', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AddAttachmentDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Attachment'), findsOneWidget);
      expect(find.text('URL (YouTube, Drive, or Web)'), findsOneWidget);
      expect(find.text('Title (Optional)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Attach'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
