import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';

QueryExecutor openPlatformConnection() {
  final isTest =
      WidgetsBinding.instance.runtimeType.toString().contains('Test');
  if (isTest) {
    return NativeDatabase.memory();
  }
  return driftDatabase(
    name: 'zeta_app_db',
  );
}
