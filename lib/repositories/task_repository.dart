import '../models/pillar.dart';
import '../models/task.dart';

/// Contrato de persistencia de Task (§106) y Pillar (§105) — ver
/// Arquitectura_Fase_1.md. La implementación concreta (SQLite) vive aparte.
abstract class TaskRepository {
  Future<void> save(Task task);
  Future<List<Task>> getAll();
  Future<Task?> getById(String id);
  Future<List<Pillar>> getPillars();
}
