import '../models/task_completion.dart';

/// Solo escribe (ver Arquitectura_Fase_1.md) — nadie lee esto en Fase 1.
abstract class CompletionRepository {
  Future<void> save(TaskCompletion completion);
}
