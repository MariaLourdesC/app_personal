import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/consequence_level.dart';
import 'package:app_personal/models/task.dart';
import 'package:app_personal/models/task_source.dart';
import 'package:app_personal/models/task_status.dart';
import 'package:app_personal/logic/priority/task_adapter.dart';

Task _task({
  required String id,
  Duration? estimatedDuration,
  TaskStatus status = TaskStatus.porIniciar,
}) {
  return Task(
    id: id,
    title: 'tarea $id',
    estimatedDuration: estimatedDuration,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    source: TaskSource.capturaNl,
  );
}

void main() {
  test('tasksReadyForPriority descarta sin duración (caja rápida) y terminadas', () {
    final sinDuracion = _task(id: 'sin-duracion'); // ej. caja rápida
    final terminada = _task(
      id: 'terminada',
      estimatedDuration: const Duration(minutes: 20),
      status: TaskStatus.terminada,
    );
    final lista = _task(id: 'lista', estimatedDuration: const Duration(minutes: 20));

    final result = tasksReadyForPriority([sinDuracion, terminada, lista]);

    expect(result.map((t) => t.id), ['lista']);
  });

  test('priorityCandidateFromTask copia los campos relevantes', () {
    final task = Task(
      id: 't1',
      title: 'Enviar informe',
      consequenceLevel: ConsequenceLevel.alta,
      estimatedDuration: const Duration(minutes: 25),
      deadline: DateTime(2026, 1, 1, 18, 0),
      status: TaskStatus.porIniciar,
      createdAt: DateTime(2026, 1, 1),
      source: TaskSource.capturaNl,
    );

    final candidate = priorityCandidateFromTask(task);

    expect(candidate.id, 't1');
    expect(candidate.consequenceLevel, ConsequenceLevel.alta);
    expect(candidate.estimatedDuration, const Duration(minutes: 25));
    expect(candidate.deadline, DateTime(2026, 1, 1, 18, 0));
  });
}
