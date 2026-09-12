/// No existe en el modelo de datos del PRD (§104-124), pero los propios
/// casos de prueba de Fase 1 (CP-03, CP-04, CP-06, CP-07) ya asumen que
/// hay eventos fijos ("recoger a Sami a las 15:40"). Entidad mínima:
/// el hecho de que a cierta hora hay un compromiso inamovible. No es el
/// planificador diario (§16-19, diferido) — no arma horarios ni recalcula.
class FixedEvent {
  FixedEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
}
