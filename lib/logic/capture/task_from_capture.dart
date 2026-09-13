import '../../models/task.dart';
import '../../models/task_source.dart';
import '../../models/task_status.dart';
import 'capture_result.dart';

/// Arma la `Task` que se va a persistir a partir de lo que C1 logró
/// extraer. Todo lo que el parser no pudo inferir (consecuencia, energía,
/// duración) queda en `null` a propósito: CP-01 exige que esos campos
/// queden vacíos, no rellenados con valores fabricados.
///
/// `id` y `now` se reciben de afuera para que la función sea determinista
/// y testeable, sin leer el reloj ni generar azar por dentro.
Task taskFromCapture(
  CaptureResult capture, {
  required String id,
  required DateTime now,
}) {
  return Task(
    id: id,
    title: _title(capture),
    desiredDate: capture.targetDate,
    deadline: capture.deadline,
    status: TaskStatus.porIniciar,
    createdAt: now,
    source: TaskSource.capturaNl,
  );
}

/// Acción + entidad recompuestas, sin la expresión de fecha (que ya quedó
/// guardada en su propio campo). Si el parser no separó nada, cae al
/// texto original completo: nunca se pierde lo que la usuaria escribió.
String _title(CaptureResult capture) {
  final parts = [
    capture.action,
    capture.entity,
  ].whereType<String>().where((part) => part.isNotEmpty);

  if (parts.isEmpty) return capture.rawText;
  return _capitalize(parts.join(' '));
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
