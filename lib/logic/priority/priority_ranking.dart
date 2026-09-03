import 'priority_candidate.dart';

/// Elige la candidata ganadora entre las que ya caben en la ventana (§4 del PRD):
/// 1. Consecuencia (Alta > Media > Baja)
/// 2. Deadline (tiene deadline > no tiene; entre dos con deadline, la más próxima gana)
///
/// Empate total (mismo nivel de consecuencia, ninguna con deadline): gana la
/// que aparece primero en `candidates`. Es una regla explícita, no un efecto
/// secundario del orden del código — ver `priority_ranking_test.dart`.
///
/// Si `consequenceLevel` es `null` (D2: no declarada todavía), se rankea
/// como si fuera `media` — el default explícito del documento D2. Quien
/// necesite saber si se usó un default debe llamar a `assumedFields`.
///
/// Un valor **asumido** nunca le gana a un valor **real** más bajo: si a
/// una candidata se le asume "media" y compite contra otra con "baja"
/// declarada de verdad, gana la de "baja" — un default no vale más que un
/// dato confirmado, aunque el número lo sugiera. Ver `_compareConsequence`.
///
/// Precondición: `candidates` no puede estar vacía — si el filtro de ventana
/// dejó la lista vacía, eso es el caso CP-07 ("no hay ninguna ventana
/// disponible"), que todavía no está resuelto (ver CLAUDE.md).
PriorityCandidate pickWinner(List<PriorityCandidate> candidates) {
  return candidates.reduce((best, candidate) {
    return _isHigherPriority(candidate, best) ? candidate : best;
  });
}

bool _isHigherPriority(PriorityCandidate a, PriorityCandidate b) {
  final consequenceComparison = _compareConsequence(a, b);
  if (consequenceComparison != 0) return consequenceComparison < 0;

  final aDeadline = a.deadline;
  final bDeadline = b.deadline;
  // Si ninguna tiene deadline, esto también cubre el empate total: a no
  // reemplaza a b, así que gana la primera encontrada en la lista original.
  if (aDeadline == null) return false;
  if (bDeadline == null) return true; // a tiene deadline, b no: a gana

  return aDeadline.isBefore(bDeadline); // ambas con deadline: la más próxima gana
}

/// Compara consecuencia como `_consequenceRank`, pero con una excepción: un
/// valor asumido (`null`) no puede ganarle a un valor real más bajo, aunque
/// su default numérico sea mejor. Fuera de ese caso puntual, es la misma
/// comparación numérica de siempre.
int _compareConsequence(PriorityCandidate a, PriorityCandidate b) {
  final aAssumed = a.consequenceLevel == null;
  final bAssumed = b.consequenceLevel == null;
  final aRank = _consequenceRank(a.consequenceLevel);
  final bRank = _consequenceRank(b.consequenceLevel);

  if (aAssumed && !bAssumed && aRank < bRank) {
    return 1; // a "ganaría" por default, pero b es real: no se permite.
  }
  if (bAssumed && !aAssumed && bRank < aRank) {
    return -1; // mismo caso, al revés.
  }
  return aRank.compareTo(bRank);
}

int _consequenceRank(ConsequenceLevel? level) {
  switch (level ?? ConsequenceLevel.media) {
    case ConsequenceLevel.alta:
      return 0;
    case ConsequenceLevel.media:
      return 1;
    case ConsequenceLevel.baja:
      return 2;
  }
}

/// D2: nombres de los campos que el motor tuvo que asumir con un default
/// para poder decidir sobre esta candidata. Vacía si todo estaba declarado.
List<String> assumedFields(PriorityCandidate candidate) {
  if (candidate.consequenceLevel == null) return ['consequenceLevel'];
  return [];
}
