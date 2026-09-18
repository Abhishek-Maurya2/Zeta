import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/models/revision.dart';
import 'package:zeta/providers/revision_provider.dart';
import 'package:zeta/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Revision Model Tests', () {
    test('Subject serialization', () {
      final subject = Subject(
        id: 'sub-1',
        name: 'Physics',
        iconName: 'science_rounded',
        colorValue: 0xFF10B981,
      );

      final json = subject.toJson();
      final restored = Subject.fromJson(json);

      expect(restored.id, equals('sub-1'));
      expect(restored.name, equals('Physics'));
      expect(restored.iconName, equals('science_rounded'));
      expect(restored.colorValue, equals(0xFF10B981));
    });

    test('ChapterTopic spaced repetition status', () {
      final topicNotStarted = ChapterTopic(
        id: 'top-1',
        subjectId: 'sub-1',
        title: 'Quantum Mechanics',
        isCompleted: false,
        revisionStage: 0,
      );
      expect(topicNotStarted.status, equals(RevisionStatus.notStarted));

      final topicMastered = ChapterTopic(
        id: 'top-2',
        subjectId: 'sub-1',
        title: 'Newtonian Dynamics',
        isCompleted: true,
        revisionStage: 4,
      );
      expect(topicMastered.status, equals(RevisionStatus.mastered));
      expect(topicMastered.isMastered, isTrue);

      final topicOverdue = ChapterTopic(
        id: 'top-3',
        subjectId: 'sub-1',
        title: 'Thermodynamics',
        isCompleted: true,
        revisionStage: 1,
        nextRevisionDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(topicOverdue.status, equals(RevisionStatus.overdue));

      final topicScheduled = ChapterTopic(
        id: 'top-4',
        subjectId: 'sub-1',
        title: 'Electromagnetism',
        isCompleted: true,
        revisionStage: 1,
        nextRevisionDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(topicScheduled.status, equals(RevisionStatus.scheduled));
    });
  });

  group('RevisionProvider Integration Tests', () {
    test('completeTopic advances revision stage and creates Task', () async {
      final revProvider = RevisionProvider();
      final taskProvider = TaskProvider();

      // Wait for async load
      await Future.delayed(const Duration(milliseconds: 100));

      final subjectId = 'sub-test';
      await revProvider.addSubject('Test Subject');
      final createdSubId = revProvider.selectedSubjectId!;

      await revProvider.addTopic(createdSubId, 'Test Topic');
      final topic = revProvider.topicsForSelectedSubject.first;

      expect(topic.revisionStage, equals(0));
      expect(topic.isCompleted, isFalse);

      // Advance to Stage 1
      await revProvider.completeTopic(topic.id, taskProvider);
      final updatedTopic = revProvider.topicsForSelectedSubject.firstWhere((t) => t.id == topic.id);

      expect(updatedTopic.revisionStage, equals(1));
      expect(updatedTopic.isCompleted, isTrue);
      expect(updatedTopic.associatedTaskId, isNotNull);

      // Verify task was inserted into taskProvider
      final revisionTask = taskProvider.allTasks.firstWhere((t) => t.id == updatedTopic.associatedTaskId);
      expect(revisionTask.title, contains('Revise: Test Topic'));
      expect(TaskProvider.isRevisionTask(revisionTask), isTrue);
    });

    test('bi-directional sync from Task completion to RevisionProvider', () async {
      final revProvider = RevisionProvider();
      final taskProvider = TaskProvider();

      await Future.delayed(const Duration(milliseconds: 100));

      await revProvider.addSubject('Math');
      final subId = revProvider.selectedSubjectId!;
      await revProvider.addTopic(subId, 'Calculus');

      final topic = revProvider.topicsForSelectedSubject.first;

      // Complete topic -> creates Stage 1 revision task
      await revProvider.completeTopic(topic.id, taskProvider);
      final topicStage1 = revProvider.topicsForSelectedSubject.firstWhere((t) => t.id == topic.id);
      final taskId = topicStage1.associatedTaskId!;

      // Simulate checking off the revision task in TaskProvider
      await revProvider.syncFromTaskCompletion(taskId, taskProvider);

      final topicStage2 = revProvider.topicsForSelectedSubject.firstWhere((t) => t.id == topic.id);
      expect(topicStage2.revisionStage, equals(2));
    });
  });
}
