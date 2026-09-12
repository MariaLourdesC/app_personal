import 'package:sqflite/sqflite.dart';

import '../models/task_completion.dart';
import 'completion_mapper.dart';
import 'completion_repository.dart';

class SqliteCompletionRepository implements CompletionRepository {
  SqliteCompletionRepository(this._db);

  final Database _db;

  @override
  Future<void> save(TaskCompletion completion) async {
    await _db.insert('task_completions', completionToMap(completion));
  }
}
