import '../capacity/time_window.dart';
import 'priority_candidate.dart';
import 'window_filter.dart';

/// CP-07: cuando no hay ninguna tarea que quepa ahora, la pantalla debe
/// mostrar "la siguiente ventana en la que sí habrá espacio". Devuelve la
/// primera ventana de `windows` donde entra al menos una candidata, o
/// `null` si en ninguna entra nada en lo que queda del día.
TimeWindow? nextWindowWithSpace({
  required List<PriorityCandidate> candidates,
  required List<TimeWindow> windows,
}) {
  for (final window in windows) {
    if (candidatesThatFit(candidates, window).isNotEmpty) return window;
  }
  return null;
}
