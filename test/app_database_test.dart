import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:zeta/database/app_database.dart';

void main() {
  test('AppDatabase opens and reopens with the current schema', () async {
    final tempDir = await Directory.systemTemp.createTemp('zeta_test_db');
    final dbFile = File('${tempDir.path}/test.db');

    final firstOpen = AppDatabase(NativeDatabase(dbFile));
    await firstOpen.customSelect('SELECT 1').get();
    await firstOpen.close();

    final reopenedDb = AppDatabase(NativeDatabase(dbFile));
    final sessions = await reopenedDb
        .customSelect('SELECT * FROM pomodoro_sessions')
        .get();
    expect(sessions, isNotNull);
    await reopenedDb.close();

    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });
}
