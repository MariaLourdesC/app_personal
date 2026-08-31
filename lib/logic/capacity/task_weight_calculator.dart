import 'buffer_calculator.dart';

/// Calcula el peso total de una tarea: duración + preparación + traslado + buffer.
/// (Fase_1_Nucleo_de_decision.md, C3 / §7 del PRD)
///
/// `prepTime` y `travelTime` no tienen campos equivalentes en `Task` (§106)
/// en Fase 1: siempre llegan en Duration.zero. Se dejan como parámetros para
/// no requerir un cambio de firma si algún día existieran.
Duration calculateTaskWeight(
  Duration estimatedDuration, {
  Duration prepTime = Duration.zero,
  Duration travelTime = Duration.zero,
}) {
  final buffer = calculateBuffer(estimatedDuration);
  return estimatedDuration + prepTime + travelTime + buffer;
}
