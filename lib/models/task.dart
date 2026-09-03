import 'consequence_level.dart';
import 'energy_required.dart';
import 'strategic_value.dart';
import 'task_source.dart';
import 'task_status.dart';

/// §106 del PRD. En Fase 1 excluye `actual_duration` (lo escribe C6) y
/// `alternative_responsible` (fuera de alcance) — ver Fase_1_Nucleo_de_decision.md.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.source,
    this.description,
    this.pillarId,
    this.consequenceLevel,
    this.strategicValue,
    this.deadline,
    this.desiredDate,
    this.estimatedDuration,
    this.energyRequired,
    this.divisible,
    this.completedAt,
    this.responsiblePerson,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final TaskStatus status;
  final TaskSource source;

  final String? description;
  final String? pillarId;

  /// D2: `null` = todavía no declarada, no un valor real.
  final ConsequenceLevel? consequenceLevel;
  final StrategicValue? strategicValue;
  final DateTime? deadline;
  final DateTime? desiredDate;
  final Duration? estimatedDuration;
  final EnergyRequired? energyRequired;
  final bool? divisible;
  final DateTime? completedAt;
  final String? responsiblePerson;
}
