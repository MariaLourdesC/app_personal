import '../capacity/time_window.dart';
import 'decision_result.dart';
import 'priority_candidate.dart';
import 'priority_ranking.dart';
import 'reason.dart';
import 'window_filter.dart';

/// Punto de entrada público de C4: dadas las candidatas y la ventana
/// disponible, devuelve la decisión ya tomada.
///
/// Precondición: debe existir al menos una candidata que quepa en `window`.
/// Si el filtro deja la lista vacía, es el caso CP-07 ("no hay ninguna
/// ventana disponible"), que todavía no está resuelto (ver CLAUDE.md).
DecisionResult decide(List<PriorityCandidate> candidates, TimeWindow window) {
  final fitting = candidatesThatFit(candidates, window);
  final winner = pickWinner(fitting);
  return DecisionResult(
    candidate: winner,
    reason: reasonFor(winner),
    assumed: assumedFields(winner),
  );
}
