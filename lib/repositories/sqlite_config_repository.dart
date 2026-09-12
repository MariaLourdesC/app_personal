import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import 'config_repository.dart';
import 'user_mapper.dart';

class SqliteConfigRepository implements ConfigRepository {
  SqliteConfigRepository(this._db);

  final Database _db;

  @override
  Future<User?> getUser() async {
    final rows = await _db.query('app_user', limit: 1);
    if (rows.isEmpty) return null;
    return userFromMap(rows.first);
  }

  @override
  Future<void> saveUser(User user) async {
    await _db.insert(
      'app_user',
      userToMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
