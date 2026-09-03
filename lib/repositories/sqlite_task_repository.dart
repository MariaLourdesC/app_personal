import 'package:sqflite/sqflite.dart';

import '../models/pillar.dart';
import '../models/task.dart';
import 'task_mapper.dart';
import 'task_repository.dart';

/// Implementación de `TaskRepository` sobre SQLite. Recibe el `Database`
/// ya abierto por quien la construye — no sabe (ni le importa) si es la
/// base real del dispositivo o una de prueba.
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(this._db);

  final Database _db;

  @override
  Future<void> save(Task task) async {
    await _db.insert(
      'tasks',
      taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Task>> getAll() async {
    final rows = await _db.query('tasks');
    return rows.map(taskFromMap).toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final rows = await _db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return taskFromMap(rows.first);
  }

  @override
  Future<List<Pillar>> getPillars() async {
    final rows = await _db.query('pillars');
    return rows.map(pillarFromMap).toList();
  }
}
