import '../models/consequence_level.dart';
import '../models/energy_required.dart';
import '../models/pillar.dart';
import '../models/strategic_value.dart';
import '../models/task.dart';
import '../models/task_source.dart';
import '../models/task_status.dart';

Map<String, Object?> taskToMap(Task task) {
  return {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'pillar_id': task.pillarId,
    'consequence_level': task.consequenceLevel?.name,
    'strategic_value': task.strategicValue?.name,
    'deadline': task.deadline?.millisecondsSinceEpoch,
    'desired_date': task.desiredDate?.millisecondsSinceEpoch,
    'estimated_duration_minutes': task.estimatedDuration?.inMinutes,
    'energy_intensity': task.energyRequired?.intensity.name,
    'energy_type': task.energyRequired?.type.name,
    'divisible': task.divisible == null ? null : (task.divisible! ? 1 : 0),
    'status': task.status.name,
    'created_at': task.createdAt.millisecondsSinceEpoch,
    'completed_at': task.completedAt?.millisecondsSinceEpoch,
    'source': task.source.name,
    'responsible_person': task.responsiblePerson,
  };
}

Task taskFromMap(Map<String, Object?> map) {
  final energyIntensityName = map['energy_intensity'] as String?;
  final energyTypeName = map['energy_type'] as String?;

  return Task(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    pillarId: map['pillar_id'] as String?,
    consequenceLevel: _enumOrNull(
      ConsequenceLevel.values,
      map['consequence_level'] as String?,
    ),
    strategicValue: _enumOrNull(
      StrategicValue.values,
      map['strategic_value'] as String?,
    ),
    deadline: _dateTimeOrNull(map['deadline'] as int?),
    desiredDate: _dateTimeOrNull(map['desired_date'] as int?),
    estimatedDuration: map['estimated_duration_minutes'] == null
        ? null
        : Duration(minutes: map['estimated_duration_minutes'] as int),
    energyRequired: energyIntensityName == null || energyTypeName == null
        ? null
        : EnergyRequired(
            intensity: _enumOrNull(
              EnergyIntensity.values,
              energyIntensityName,
            )!,
            type: _enumOrNull(EnergyType.values, energyTypeName)!,
          ),
    divisible: map['divisible'] == null ? null : map['divisible'] == 1,
    status: _enumOrNull(TaskStatus.values, map['status'] as String)!,
    createdAt: _dateTimeOrNull(map['created_at'] as int)!,
    completedAt: _dateTimeOrNull(map['completed_at'] as int?),
    source: _enumOrNull(TaskSource.values, map['source'] as String)!,
    responsiblePerson: map['responsible_person'] as String?,
  );
}

Map<String, Object?> pillarToMap(Pillar pillar) {
  return {'id': pillar.id, 'name': pillar.name, 'policy': pillar.policy};
}

Pillar pillarFromMap(Map<String, Object?> map) {
  return Pillar(
    id: map['id'] as String,
    name: map['name'] as String,
    policy: map['policy'] as String,
  );
}

T? _enumOrNull<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  return values.byName(name);
}

DateTime? _dateTimeOrNull(int? millis) {
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
