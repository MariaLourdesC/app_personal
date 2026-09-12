/// §64 del PRD: registro de cierre de una tarea. Productor silencioso —
/// nadie lo lee en Fase 1 (ver Arquitectura_Fase_1.md, CompletionRepository).
class TaskCompletion {
  TaskCompletion({
    required this.id,
    required this.taskId,
    required this.start,
    required this.end,
    required this.actualDuration,
    this.estimatedDuration,
    this.interruptions = 0,
    this.distractions = 0,
  });

  final String id;
  final String taskId;
  final DateTime start;
  final DateTime end;
  final Duration actualDuration;
  final Duration? estimatedDuration;

  /// Siempre 0 en Fase 1 — nada produce interrupciones/distracciones reales
  /// todavía (§25/26, §27-32 son de una fase posterior).
  final int interruptions;
  final int distractions;
}
