import 'package:sqflite/sqflite.dart';

import '../models/fixed_event.dart';
import 'fixed_event_mapper.dart';
import 'fixed_event_repository.dart';

class SqliteFixedEventRepository implements FixedEventRepository {
  SqliteFixedEventRepository(this._db);

  final Database _db;

  @override
  Future<void> save(FixedEvent event) async {
    await _db.insert(
      'fixed_events',
      fixedEventToMap(event),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<FixedEvent>> getAll() async {
    final rows = await _db.query('fixed_events');
    return rows.map(fixedEventFromMap).toList();
  }
}
