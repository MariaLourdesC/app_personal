/// Calcula el buffer de seguridad de una tarea según su duración estimada,
/// aplicando la tabla de tramos de D1 (Fase_1_Nucleo_de_decision.md):
/// corta <= 30 min -> +10 min fijos
/// media 30 min - 2 h -> +5%
/// larga > 2 h -> +10%
Duration calculateBuffer(Duration estimatedDuration) {
  if (estimatedDuration <= const Duration(minutes: 30)) {
    return const Duration(minutes: 10);
  }
  if (estimatedDuration <= const Duration(hours: 2)) {
    return _percentageBuffer(estimatedDuration, 0.05);
  }
  return _percentageBuffer(estimatedDuration, 0.10);
}

Duration _percentageBuffer(Duration duration, double percentage) {
  final bufferMinutes = (duration.inMinutes * percentage).ceil();
  return Duration(minutes: bufferMinutes);
}
