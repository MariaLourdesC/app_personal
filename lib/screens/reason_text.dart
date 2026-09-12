import '../models/consequence_level.dart';
import '../logic/priority/reason.dart';

/// Arma las frases de "¿Por qué ahora?" (§40, CP-08) a partir de los datos
/// estructurados de `Reason` — aquí vive la redacción en español, no en C4
/// ("la pantalla no decide, solo muestra", pero mostrar sí implica redactar).
///
/// Si `consequenceLevel` fue asumida (D2, CP-09), lo marca explícitamente
/// en vez de sonar tan segura como con un dato real.
List<String> reasonText(Reason reason, List<String> assumed) {
  final consequenceWasAssumed = assumed.contains('consequenceLevel');
  final lines = <String>[
    consequenceWasAssumed
        ? 'Consecuencia asumida como ${_consequenceLabel(reason.consequenceLevel)} (no declarada)'
        : 'Consecuencia ${_consequenceLabel(reason.consequenceLevel)}',
  ];

  if (reason.hasDeadline) {
    lines.add(_deadlineLabel(reason.deadline!));
  }

  lines.add('Cabe en tu ventana disponible');
  return lines;
}

String _consequenceLabel(ConsequenceLevel level) {
  switch (level) {
    case ConsequenceLevel.alta:
      return 'alta';
    case ConsequenceLevel.media:
      return 'media';
    case ConsequenceLevel.baja:
      return 'baja';
  }
}

String _deadlineLabel(DateTime deadline) {
  final now = DateTime.now();
  final isToday =
      deadline.year == now.year &&
      deadline.month == now.month &&
      deadline.day == now.day;
  return isToday ? 'Vence hoy' : 'Vence el ${deadline.day}/${deadline.month}';
}
