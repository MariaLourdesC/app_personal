import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_personal/models/task_completion.dart';
import 'package:app_personal/repositories/database_schema.dart';
import 'package:app_personal/repositories/sqlite_completion_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('CP-10: queda un registro con los seis campos, verificable directo en la base', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => createSchema(db),
      ),
    );
    final repository = SqliteCompletionRepository(db);

    final start = DateTime(2026, 1, 1, 15, 0);
    final end = DateTime(2026, 1, 1, 15, 28);
    await repository.save(
      TaskCompletion(
        id: 'c1',
        taskId: 't1',
        start: start,
        end: end,
        actualDuration: const Duration(minutes: 28),
        estimatedDuration: const Duration(minutes: 25),
      ),
    );

    // Verificación directa, sin pasar por el repositorio (que no lee).
    final rows = await db.query('task_completions', where: 'id = ?', whereArgs: ['c1']);

    expect(rows.length, 1);
    final row = rows.first;
    expect(row['task_id'], 't1');
    expect(row['start_time'], start.millisecondsSinceEpoch);
    expect(row['end_time'], end.millisecondsSinceEpoch);
    expect(row['actual_duration_minutes'], 28);
    expect(row['estimated_duration_minutes'], 25);
    expect(row['interruptions'], 0);
    expect(row['distractions'], 0);

    await db.close();
  });
}
