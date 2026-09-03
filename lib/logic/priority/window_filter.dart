import '../capacity/fit_checker.dart';
import '../capacity/task_weight_calculator.dart';
import '../capacity/time_window.dart';
import 'priority_candidate.dart';

/// Filtro duro: de una lista de candidatas, cuáles caben en la ventana dada.
/// No decide cuál gana entre las que caben — eso es la pieza de ranking.
List<PriorityCandidate> candidatesThatFit(
  List<PriorityCandidate> candidates,
  TimeWindow window,
) {
  return candidates.where((candidate) {
    final weight = calculateTaskWeight(candidate.estimatedDuration);
    return taskFits(taskWeight: weight, window: window);
  }).toList();
}
