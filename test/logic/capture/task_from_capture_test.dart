import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capture/rules_capture_parser.dart';
import 'package:app_personal/logic/capture/task_from_capture.dart';
import 'package:app_personal/models/task_source.dart';
import 'package:app_personal/models/task_status.dart';

final _viernes = DateTime(2026, 4, 3, 10, 0);

void main() {
  final parser = RulesCaptureParser();

  test('CP-01 completo: de texto libre a Task persistible', () async {
    final capture = await parser.parse(
      'comprar comida para los perros mañana',
      now: _viernes,
    );
    final task = taskFromCapture(capture, id: 't1', now: _viernes);

    expect(task.title, 'Comprar comida para los perros');
    expect(task.desiredDate, DateTime(2026, 4, 4));
    expect(task.status, TaskStatus.porIniciar);
    expect(task.source, TaskSource.capturaNl);

    // Los no inferibles quedan vacíos, no fabricados.
    expect(task.consequenceLevel, isNull);
    expect(task.energyRequired, isNull);
    expect(task.estimatedDuration, isNull);
    expect(task.deadline, isNull);
  });

  test('sin verbo reconocible: el título conserva lo escrito', () async {
    final capture = await parser.parse('cita con el dentista', now: _viernes);
    final task = taskFromCapture(capture, id: 't2', now: _viernes);

    expect(task.title, 'Cita con el dentista');
  });

  test('"para el lunes" queda como deadline en la Task', () async {
    final capture = await parser.parse(
      'revisar postulación para el lunes',
      now: _viernes,
    );
    final task = taskFromCapture(capture, id: 't3', now: _viernes);

    expect(task.title, 'Revisar postulación');
    expect(task.deadline, DateTime(2026, 4, 6));
    expect(task.desiredDate, isNull);
  });
}
