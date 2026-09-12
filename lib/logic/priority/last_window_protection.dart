import '../capacity/fit_checker.dart';
import '../capacity/task_weight_calculator.dart';
import '../capacity/time_window.dart';
import 'priority_candidate.dart';
import 'priority_ranking.dart';

/// §23 / CP-06: la ganadora por ranking no debe ocupar la ventana actual
/// si eso destruye la **última** oportunidad de otra candidata que vence
/// pronto. Devuelve esa candidata a proteger, o `null` si no hay ninguna
/// en riesgo (el caso normal).
///
/// Alcance elegido por la usuaria: la protección solo aplica si la
/// candidata desplazada vence **hoy o mañana**. Si vence en dos semanas,
/// no cede — ya habrá otros días.
PriorityCandidate? candidateLosingItsLastWindow({
  required PriorityCandidate winner,
  required List<PriorityCandidate> fitting,
  required TimeWindow window,
  required List<TimeWindow> laterWindows,
}) {
  final winnerWeight = calculateTaskWeight(winner.estimatedDuration);

  final atRisk = fitting.where((candidate) {
    if (candidate.id == winner.id) return false;

    final deadline = candidate.deadline;
    if (deadline == null) return false;
    if (!_vencePronto(deadline, window.start)) return false;

    final weight = calculateTaskWeight(candidate.estimatedDuration);

    // Si las dos entran juntas en esta ventana, nadie destruye nada.
    if (winnerWeight + weight <= window.duration) return false;

    // ¿Le queda alguna ventana posterior donde todavía entre a tiempo?
    final tieneOtraChance = laterWindows.any(
      (later) => _entraAntesDelDeadline(weight, later, deadline),
    );
    return !tieneOtraChance;
  }).toList();

  if (atRisk.isEmpty) return null;
  return pickWinner(atRisk);
}

bool _vencePronto(DateTime deadline, DateTime now) {
  final manana = now.add(const Duration(days: 1));
  final finDeManana = DateTime(manana.year, manana.month, manana.day, 23, 59);
  return !deadline.isAfter(finDeManana);
}

bool _entraAntesDelDeadline(
  Duration weight,
  TimeWindow window,
  DateTime deadline,
) {
  // La parte usable de la ventana es hasta el deadline, no hasta su final.
  final usableEnd = window.end.isBefore(deadline) ? window.end : deadline;
  if (!usableEnd.isAfter(window.start)) return false;
  final usable = TimeWindow(start: window.start, end: usableEnd);
  return taskFits(taskWeight: weight, window: usable);
}
