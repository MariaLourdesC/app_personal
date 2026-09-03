import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/consequence_level.dart';
import 'package:app_personal/models/energy_required.dart';
import 'package:app_personal/models/strategic_value.dart';
import 'package:app_personal/models/task.dart';
import 'package:app_personal/models/task_source.dart';
import 'package:app_personal/models/task_status.dart';
import 'package:app_personal/repositories/task_mapper.dart';

void main() {
  test('Task completa: ida y vuelta preserva todos los campos', () {
    final original = Task(
      id: 't1',
      title: 'Enviar informe al cliente',
      description: 'Incluye el resumen ejecutivo',
      pillarId: 'ingresos',
      consequenceLevel: ConsequenceLevel.alta,
      strategicValue: StrategicValue.media,
      deadline: DateTime(2026, 1, 1, 18, 0),
      desiredDate: DateTime(2026, 1, 1),
      estimatedDuration: const Duration(minutes: 25),
      energyRequired: EnergyRequired(
        intensity: EnergyIntensity.alta,
        type: EnergyType.administrativa,
      ),
      divisible: false,
      status: TaskStatus.enProgreso,
      createdAt: DateTime(2025, 12, 30, 9, 0),
      completedAt: null,
      source: TaskSource.capturaNl,
      responsiblePerson: 'yo',
    );

    final restored = taskFromMap(taskToMap(original));

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.description, original.description);
    expect(restored.pillarId, original.pillarId);
    expect(restored.consequenceLevel, original.consequenceLevel);
    expect(restored.strategicValue, original.strategicValue);
    expect(restored.deadline, original.deadline);
    expect(restored.desiredDate, original.desiredDate);
    expect(restored.estimatedDuration, original.estimatedDuration);
    expect(restored.energyRequired?.intensity, original.energyRequired?.intensity);
    expect(restored.energyRequired?.type, original.energyRequired?.type);
    expect(restored.divisible, original.divisible);
    expect(restored.status, original.status);
    expect(restored.createdAt, original.createdAt);
    expect(restored.completedAt, original.completedAt);
    expect(restored.source, original.source);
    expect(restored.responsiblePerson, original.responsiblePerson);
  });

  test('Task recién capturada (CP-01): campos no inferibles quedan null tras el viaje', () {
    final original = Task(
      id: 't2',
      title: 'Comprar comida para los perros',
      desiredDate: DateTime(2026, 1, 2),
      status: TaskStatus.porIniciar,
      createdAt: DateTime(2026, 1, 1, 10, 0),
      source: TaskSource.capturaNl,
    );

    final restored = taskFromMap(taskToMap(original));

    expect(restored.consequenceLevel, isNull);
    expect(restored.energyRequired, isNull);
    expect(restored.estimatedDuration, isNull);
    expect(restored.deadline, isNull);
    expect(restored.desiredDate, original.desiredDate);
  });
}
