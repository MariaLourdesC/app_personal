import 'package:sqflite/sqflite.dart';

import '../models/default_pillars.dart';
import 'task_mapper.dart';

/// Crea las tablas de Fase 1 y siembra los 4 pilares precargados (§3).
/// Se corre una sola vez, en el `onCreate` de `openDatabase`.
Future<void> createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE pillars (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      policy TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      pillar_id TEXT,
      consequence_level TEXT,
      strategic_value TEXT,
      deadline INTEGER,
      desired_date INTEGER,
      estimated_duration_minutes INTEGER,
      energy_intensity TEXT,
      energy_type TEXT,
      divisible INTEGER,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      completed_at INTEGER,
      source TEXT NOT NULL,
      responsible_person TEXT
    )
  ''');
  for (final pillar in defaultPillars) {
    await db.insert('pillars', pillarToMap(pillar));
  }

  await db.execute('''
    CREATE TABLE task_completions (
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      start_time INTEGER NOT NULL,
      end_time INTEGER NOT NULL,
      actual_duration_minutes INTEGER NOT NULL,
      estimated_duration_minutes INTEGER,
      interruptions INTEGER NOT NULL,
      distractions INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE fixed_events (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      start_time INTEGER NOT NULL,
      end_time INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE app_user (
      id TEXT PRIMARY KEY,
      timezone TEXT NOT NULL,
      sleep_target_minutes INTEGER NOT NULL,
      wake_target_minutes INTEGER NOT NULL,
      focus_block_minutes INTEGER NOT NULL,
      break_minutes INTEGER NOT NULL,
      protected_personal_minutes INTEGER NOT NULL,
      default_buffer_minutes INTEGER NOT NULL,
      current_energy_state TEXT
    )
  ''');
}
