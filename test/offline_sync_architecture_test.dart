import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:zeta/database/app_database.dart';
import 'package:zeta/database/daos/revision_dao.dart';
import 'package:zeta/database/daos/session_dao.dart';
import 'package:zeta/models/revision.dart';
import 'package:zeta/models/pomodoro.dart';
import 'package:zeta/services/network_service.dart';
import 'package:zeta/services/pomodoro_sync_service.dart';
import 'package:zeta/services/supabase_sync_service.dart';
import 'package:zeta/services/revision_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkService Connectivity Tests', () {
    test('Default status is online and transitions fire stream events', () async {
      final network = NetworkService();
      expect(network.isOnline, isTrue);

      final transitions = <bool>[];
      final subscription = network.onConnectivityChanged.listen(transitions.add);

      network.markOffline();
      expect(network.isOnline, isFalse);

      network.markOnline();
      expect(network.isOnline, isTrue);

      // Re-marking online with same value should not emit duplicate event
      network.markOnline();

      await Future.delayed(const Duration(milliseconds: 50));
      expect(transitions, equals([false, true]));

      await subscription.cancel();
    });
  });

  group('Drift SQLite RevisionDao Tests', () {
    late AppDatabase db;
    late RevisionDao revisionDao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      revisionDao = RevisionDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Subject CRUD in SQLite', () async {
      final subject = Subject(
        id: 'sub-test-1',
        name: 'Mathematics',
        iconName: 'functions_rounded',
        colorValue: 0xFF2563EB,
      );

      // Insert
      await revisionDao.upsertSubject(subject);
      var allSubjects = await revisionDao.getAllSubjects();
      expect(allSubjects.length, equals(1));
      expect(allSubjects.first.name, equals('Mathematics'));
      expect(allSubjects.first.colorValue, equals(0xFF2563EB));

      // Update
      final updated = subject.copyWith(name: 'Advanced Calculus');
      await revisionDao.upsertSubject(updated);
      allSubjects = await revisionDao.getAllSubjects();
      expect(allSubjects.length, equals(1));
      expect(allSubjects.first.name, equals('Advanced Calculus'));

      // Delete
      await revisionDao.deleteSubject(subject.id);
      allSubjects = await revisionDao.getAllSubjects();
      expect(allSubjects, isEmpty);
    });

    test('Topic CRUD and Subject Cascading in SQLite', () async {
      final topic1 = ChapterTopic(
        id: 'top-1',
        subjectId: 'sub-1',
        title: 'Linear Algebra',
        sortOrder: 0,
        revisionStage: 1,
      );
      final topic2 = ChapterTopic(
        id: 'top-2',
        subjectId: 'sub-1',
        title: 'Vector Spaces',
        sortOrder: 1,
        revisionStage: 2,
      );

      await revisionDao.upsertAllTopics([topic1, topic2]);
      var topics = await revisionDao.getTopicsForSubject('sub-1');
      expect(topics.length, equals(2));
      expect(topics.first.title, equals('Linear Algebra'));
      expect(topics.last.title, equals('Vector Spaces'));

      // Update topic
      final modifiedTopic = topic1.copyWith(isCompleted: true, revisionStage: 3);
      await revisionDao.upsertTopic(modifiedTopic);
      final singleTopic = await revisionDao.getTopic('top-1');
      expect(singleTopic?.isCompleted, isTrue);
      expect(singleTopic?.revisionStage, equals(3));

      // Delete topic
      await revisionDao.deleteTopic('top-1');
      topics = await revisionDao.getTopicsForSubject('sub-1');
      expect(topics.length, equals(1));
      expect(topics.first.id, equals('top-2'));
    });
  });

  group('Drift SQLite SessionDao Offline Durability Tests', () {
    late AppDatabase db;
    late SessionDao sessionDao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sessionDao = SessionDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Sessions created offline have null lastSyncedAt and appear in unsynced list', () async {
      const session1 = PomodoroSessionLog(
        id: 'sess-1',
        mode: PomodoroMode.focus,
        minutes: 25,
        completedAt: 1700000000000,
      );
      const session2 = PomodoroSessionLog(
        id: 'sess-2',
        mode: PomodoroMode.shortBreak,
        minutes: 5,
        completedAt: 1700001000000,
      );

      await sessionDao.upsertSession(session1);
      await sessionDao.upsertSession(session2);

      // Both should be unsynced initially
      var unsynced = await sessionDao.getUnsyncedSessions();
      expect(unsynced.length, equals(2));

      // Mark session1 as synced
      final syncTime = DateTime.now();
      await sessionDao.markSessionSynced('sess-1', syncTime);

      unsynced = await sessionDao.getUnsyncedSessions();
      expect(unsynced.length, equals(1));
      expect(unsynced.first.id, equals('sess-2'));

      // Mark batch synced
      await sessionDao.markSessionsSynced(['sess-2'], syncTime);
      unsynced = await sessionDao.getUnsyncedSessions();
      expect(unsynced, isEmpty);
    });
  });

  group('Fast-Fail Sync Service Tests', () {
    setUp(() {
      NetworkService().markOffline();
    });

    tearDown(() {
      NetworkService().markOnline();
    });

    test('SupabaseSyncService fast-fails immediately when offline', () async {
      final syncService = SupabaseSyncService();
      final pulled = await syncService.pullTasks();
      expect(pulled, isEmpty);
      expect(syncService.isSyncing, isFalse);
    });

    test('PomodoroSyncService fast-fails immediately when offline', () async {
      final pomodoroSync = PomodoroSyncService();
      final pulled = await pomodoroSync.pullSessions();
      expect(pulled, isEmpty);
      expect(pomodoroSync.isSyncing, isFalse);

      const session = PomodoroSessionLog(
        id: 'fast-fail-test',
        mode: PomodoroMode.focus,
        minutes: 25,
        completedAt: 1700000000000,
      );
      final pushSuccess = await pomodoroSync.pushSession(session);
      expect(pushSuccess, isFalse);
    });

    test('RevisionSyncService fast-fails immediately when offline', () async {
      final revisionSync = RevisionSyncService();
      final subjects = await revisionSync.pullSubjects();
      expect(subjects, isEmpty);
      expect(revisionSync.isSyncing, isFalse);

      final topics = await revisionSync.pullTopics();
      expect(topics, isEmpty);
      expect(revisionSync.isSyncing, isFalse);
    });
  });
}
