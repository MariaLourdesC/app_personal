import '../capacity/time_window.dart';
import 'decision_result.dart';
import 'last_window_protection.dart';
import 'priority_candidate.dart';
import 'priority_ranking.dart';
import 'reason.dart';
import 'window_filter.dart';

/// Punto de entrada público de C4: dadas las candidatas y la ventana
/// disponible, devuelve la decisión ya tomada.
///
/// `laterWindows` (las demás ventanas libres del día) habilita la regla de
/// §23: si la ganadora por ranking le quitaría a otra candidata su última
/// oportunidad antes de vencer, cede el lugar. Si no se pasan ventanas
/// posteriores, la protección simplemente no se activa.
///
/// Precondición: debe existir al menos una candidata que quepa en `window`.
/// Si el filtro deja la lista vacía, es el caso CP-07 ("no hay ninguna
/// ventana disponible"), que la pantalla resuelve mostrando el motivo y la
/// siguiente ventana con espacio.
DecisionResult decide(
  List<PriorityCandidate> candidates,
  TimeWindow window, {
  List<TimeWindow> laterWindows = const [],
}) {
  final fitting = candidatesThatFit(candidates, window);
  final winner = pickWinner(fitting);

  final protegida = candidateLosingItsLastWindow(
    winner: winner,
    fitting: fitting,
    window: window,
    laterWindows: laterWindows,
  );

  final chosen = protegida ?? winner;

  return DecisionResult(
    candidate: chosen,
    reason: reasonFor(chosen),
    assumed: assumedFields(chosen),
  );
}
