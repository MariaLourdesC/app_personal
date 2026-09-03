import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_personal/models/task.dart';
import 'package:app_personal/models/task_source.dart';
import 'package:app_personal/models/task_status.dart';
import 'package:app_personal/repositories/database_schema.dart';
import 'package:app_personal/repositories/sqlite_task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('CP-01: guardar una tarea recién capturada y volver a leerla', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => createSchema(db),
      ),
    );
    final repository = SqliteTaskRepository(db);

    final task = Task(
      id: 't1',
      title: 'Comprar comida para los perros',
      desiredDate: DateTime(2026, 1, 2),
      status: TaskStatus.porIniciar,
      createdAt: DateTime(2026, 1, 1, 10, 0),
      source: TaskSource.capturaNl,
    );

    await repository.save(task);
    final loaded = await repository.getById('t1');

    expect(loaded, isNotNull);
    expect(loaded!.title, 'Comprar comida para los perros');
    expect(loaded.consequenceLevel, isNull);

    await db.close();
  });

  test('CP-02: actualizar campos de una tarea existente (upsert por id)', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => createSchema(db),
      ),
    );
    final repository = SqliteTaskRepository(db);

    final original = Task(
      id: 't1',
      title: 'Comprar comida para los perros',
      status: TaskStatus.porIniciar,
      createdAt: DateTime(2026, 1, 1, 10, 0),
      source: TaskSource.capturaNl,
    );
    await repository.save(original);

    final completado = Task(
      id: 't1',
      title: 'Comprar comida para los perros',
      status: TaskStatus.porIniciar,
      createdAt: DateTime(2026, 1, 1, 10, 0),
      source: TaskSource.capturaNl,
      estimatedDuration: const Duration(minutes: 20),
    );
    await repository.save(completado);

    final all = await repository.getAll();
    expect(all.length, 1); // no duplicó la fila
    expect(all.first.estimatedDuration, const Duration(minutes: 20));

    await db.close();
  });

  test('los 4 pilares quedan sembrados al crear el esquema', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => createSchema(db),
      ),
    );
    final repository = SqliteTaskRepository(db);

    final pillars = await repository.getPillars();

    expect(pillars.length, 4);

    await db.close();
  });
}
