import 'priority_candidate.dart';

/// Los factores que ganaron, como datos — no como texto. Armar la frase en
/// español (CP-08, "¿Por qué ahora?") es trabajo de la pantalla (C5), no de
/// C4: la lógica dice qué factores ganaron, la UI decide cómo redactarlo.
class Reason {
  Reason({
    required this.consequenceLevel,
    required this.hasDeadline,
    this.deadline,
  });

  /// Consecuencia ya resuelta (con el default de D2 aplicado si hacía falta).
  final ConsequenceLevel consequenceLevel;
  final bool hasDeadline;
  final DateTime? deadline;
}

Reason reasonFor(PriorityCandidate candidate) {
  return Reason(
    consequenceLevel: candidate.consequenceLevel ?? ConsequenceLevel.media,
    hasDeadline: candidate.deadline != null,
    deadline: candidate.deadline,
  );
}
