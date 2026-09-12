import 'energy_required.dart';

/// §104 del PRD. Un solo registro (ver Arquitectura_Fase_1.md,
/// ConfigRepository) — no hay múltiples usuarios en Fase 1.
///
/// `sleepTarget`/`wakeTarget`/`focusBlockMinutes`/`breakMinutes`/
/// `protectedPersonalMinutes`/`defaultBufferMinutes` son horas del día u
/// horarios expresados como `Duration` desde medianoche (ej. 23:00 ->
/// `Duration(hours: 23)`), no intervalos de tiempo — es una reutilización
/// deliberada de `Duration` para evitar una dependencia de UI (`TimeOfDay`
/// es de `package:flutter`, y este modelo no puede importar eso).
class User {
  User({
    required this.id,
    required this.timezone,
    required this.sleepTarget,
    required this.wakeTarget,
    required this.focusBlockMinutes,
    required this.breakMinutes,
    required this.protectedPersonalMinutes,
    required this.defaultBufferMinutes,
    this.currentEnergyState,
  });

  final String id;
  final String timezone;
  final Duration sleepTarget;
  final Duration wakeTarget;
  final Duration focusBlockMinutes;
  final Duration breakMinutes;
  final Duration protectedPersonalMinutes;

  /// No usado en Fase 1 — ver CLAUDE.md ("Decisiones... D1 buffer").
  final Duration defaultBufferMinutes;

  /// Nada lo lee todavía en Fase 1.
  final EnergyIntensity? currentEnergyState;
}
