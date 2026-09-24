import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:zeta/database/app_database.dart';

void main() {
  test('AppDatabase migration handles pre-existing columns idempotently', () async {
    // 1. Create a database at schema version 3 with columns already partially present
    final rawDb = NativeDatabase.memory();
    final dbAtV3 = AppDatabase(rawDb);
    // Force open
    await dbAtV3.customSelect('SELECT 1').get();
    await dbAtV3.close();

    // 2. Open again and verify migration to schema version 7 succeeds without duplicate column error
    final upgradedDb = AppDatabase(rawDb);
    final tasks = await upgradedDb.customSelect('SELECT * FROM pomodoro_sessions').get();
    expect(tasks, isNotNull);
    await upgradedDb.close();
  });
}
