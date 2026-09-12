import '../../models/task.dart';
import '../../models/task_status.dart';
import 'priority_candidate.dart';

/// Tareas que el motor de prioridad puede considerar: con duración estimada
/// (sin eso no se puede calcular peso ni ajuste) y no terminadas todavía.
/// Las que vienen de la caja rápida (solo título, sin duración) quedan
/// afuera hasta que alguien les complete ese campo en el Inbox.
List<Task> tasksReadyForPriority(List<Task> tasks) {
  return tasks
      .where(
        (task) =>
            task.estimatedDuration != null &&
            task.status != TaskStatus.terminada,
      )
      .toList();
}

/// Precondición: `task.estimatedDuration` no puede ser `null` — filtrar
/// primero con `tasksReadyForPriority`.
PriorityCandidate priorityCandidateFromTask(Task task) {
  return PriorityCandidate(
    id: task.id,
    consequenceLevel: task.consequenceLevel,
    estimatedDuration: task.estimatedDuration!,
    deadline: task.deadline,
  );
}
