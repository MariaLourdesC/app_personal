import '../../models/fixed_event.dart';
import '../../models/user.dart';
import 'time_window.dart';

/// La ventana disponible ahora mismo: desde `now` hasta el próximo evento
/// fijo de hoy, o hasta la hora de dormir (`User.sleepTarget`) si no queda
/// ninguno. No resuelve CP-06/CP-07 (necesitaría conocer huecos más allá
/// de la ventana actual) — solo responde "¿cuánto dura el hueco de ahora?".
TimeWindow currentWindow({
  required DateTime now,
  required List<FixedEvent> fixedEvents,
  required User user,
}) {
  final upcomingToday = fixedEvents
      .where((event) => event.start.isAfter(now))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  if (upcomingToday.isNotEmpty) {
    return TimeWindow(start: now, end: upcomingToday.first.start);
  }

  final sleepTime = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(user.sleepTarget);

  return TimeWindow(start: now, end: sleepTime);
}
