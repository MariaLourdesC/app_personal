/// Niveles de consecuencia de no hacer una tarea (§5 del PRD).
enum ConsequenceLevel { alta, media, baja }

/// Entrada de C4: los campos de una tarea que el motor de prioridad
/// realmente necesita para decidir. No es el `Task` completo de §106
/// (todavía no existe como entidad persistida, C2 no está construido).
class PriorityCandidate {
  PriorityCandidate({
    required this.id,
    required this.consequenceLevel,
    required this.estimatedDuration,
    this.deadline,
  });

  final String id;

  /// `null` significa "todavía no declarada" (D2) — no es lo mismo que un
  /// valor real. Quien necesite un valor para decidir debe aplicar el
  /// default de D2 explícitamente, nunca asumir uno en silencio.
  final ConsequenceLevel? consequenceLevel;
  final Duration estimatedDuration;
  final DateTime? deadline;
}
