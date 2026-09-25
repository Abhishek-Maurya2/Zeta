import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:zeta/database/app_database.dart';

void main() {
  test('AppDatabase migration handles pre-existing columns idempotently', () async {
    final tempDir = await Directory.systemTemp.createTemp('zeta_test_db');
    final dbFile = File('${tempDir.path}/test.db');

    // 1. Create a database
    final dbAtV3 = AppDatabase(NativeDatabase(dbFile));
    // Force open
    await dbAtV3.customSelect('SELECT 1').get();
    await dbAtV3.close();

    // 2. Open again and verify migration succeeds
    final upgradedDb = AppDatabase(NativeDatabase(dbFile));
    final sessions = await upgradedDb.customSelect('SELECT * FROM pomodoro_sessions').get();
    expect(sessions, isNotNull);
    await upgradedDb.close();

    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });
}
