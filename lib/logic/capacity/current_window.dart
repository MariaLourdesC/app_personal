import '../../models/fixed_event.dart';
import '../../models/user.dart';
import 'time_window.dart';

/// En qué bloque del día cae el momento actual.
enum CurrentBlock {
  /// Hay ventana disponible para proponer tareas.
  disponible,

  /// Tiempo personal protegido (§34) — restricción dura, no se propone nada.
  tiempoPersonal,

  /// Bloque de sueño (§35) — restricción dura, no se propone nada.
  sueno,

  /// En medio de un compromiso fijo (ej. "recoger a Sami"): tampoco hay
  /// ventana, pero por un motivo distinto a los bloques protegidos.
  eventoFijo,
}

/// O hay una ventana disponible, o hay un motivo concreto por el que no.
/// CP-11 exige que los bloques duros expliquen el motivo, no que aparezca
/// una pantalla vacía.
class CurrentWindowResult {
  CurrentWindowResult.available(TimeWindow this.window)
    : block = CurrentBlock.disponible;

  CurrentWindowResult.blocked(this.block) : window = null;

  final TimeWindow? window;
  final CurrentBlock block;
}

/// La ventana disponible ahora mismo: desde `now` hasta lo que llegue
/// primero — el próximo evento fijo de hoy, o el inicio del bloque de
/// tiempo personal protegido.
///
/// Ubicación del tiempo personal: los últimos `protectedPersonalMinutes`
/// antes de `sleepTarget`. Decisión de la usuaria (no está en ningún
/// documento): "la mayoría de los días es al final, no todos". La
/// ubicación dinámica (fin de semana, según prioridades cumplidas) queda
/// para el planificador diario, §16-19, Fase 2.
CurrentWindowResult currentWindow({
  required DateTime now,
  required List<FixedEvent> fixedEvents,
  required User user,
}) {
  final midnight = DateTime(now.year, now.month, now.day);
  final sleepTime = midnight.add(user.sleepTarget);
  final wakeTime = midnight.add(user.wakeTarget);
  final personalTimeStart = sleepTime.subtract(user.protectedPersonalMinutes);

  // Bloque de sueño: desde la hora de dormir, o antes de la de despertar.
  if (!now.isBefore(sleepTime) || now.isBefore(wakeTime)) {
    return CurrentWindowResult.blocked(CurrentBlock.sueno);
  }

  if (!now.isBefore(personalTimeStart)) {
    return CurrentWindowResult.blocked(CurrentBlock.tiempoPersonal);
  }

  // Un evento que ya empezó y todavía no termina ocupa el momento actual:
  // no hay ventana, aunque no sea un bloque protegido.
  final enCurso = fixedEvents.any(
    (event) => !event.start.isAfter(now) && event.end.isAfter(now),
  );
  if (enCurso) return CurrentWindowResult.blocked(CurrentBlock.eventoFijo);

  var end = personalTimeStart;

  final upcoming =
      fixedEvents.where((event) => event.start.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  if (upcoming.isNotEmpty && upcoming.first.start.isBefore(end)) {
    end = upcoming.first.start;
  }

  return CurrentWindowResult.available(TimeWindow(start: now, end: end));
}

/// Todas las ventanas libres que quedan del día, en orden: desde `now`
/// hasta el primer evento, entre evento y evento, y del último evento
/// hasta el inicio del tiempo personal protegido. Vacía si el momento
/// actual ya cae en un bloque duro (tiempo personal o sueño).
///
/// La primera de la lista es la misma ventana que devuelve `currentWindow`.
List<TimeWindow> remainingWindows({
  required DateTime now,
  required List<FixedEvent> fixedEvents,
  required User user,
}) {
  final midnight = DateTime(now.year, now.month, now.day);
  final sleepTime = midnight.add(user.sleepTarget);
  final wakeTime = midnight.add(user.wakeTarget);
  final dayEnd = sleepTime.subtract(user.protectedPersonalMinutes);

  // Solo los bloques duros vacían el día. Estar dentro de un evento fijo
  // no: los huecos posteriores siguen existiendo, y son justamente lo que
  // CP-07 necesita mostrar.
  if (!now.isBefore(sleepTime) || now.isBefore(wakeTime)) return [];
  if (!now.isBefore(dayEnd)) return [];

  // Los que todavía no terminaron — no los que todavía no empezaron: un
  // evento en curso también ocupa tiempo del día.
  final upcoming =
      fixedEvents
          .where(
            (event) => event.end.isAfter(now) && event.start.isBefore(dayEnd),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  final windows = <TimeWindow>[];
  var cursor = now;

  for (final event in upcoming) {
    if (event.start.isAfter(cursor)) {
      windows.add(TimeWindow(start: cursor, end: event.start));
    }
    if (event.end.isAfter(cursor)) cursor = event.end;
  }

  if (dayEnd.isAfter(cursor)) {
    windows.add(TimeWindow(start: cursor, end: dayEnd));
  }

  return windows;
}
