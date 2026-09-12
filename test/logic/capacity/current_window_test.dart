import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/fixed_event.dart';
import 'package:app_personal/models/user.dart';
import 'package:app_personal/logic/capacity/current_window.dart';

User _user() {
  return User(
    id: 'u1',
    timezone: 'America/Lima',
    sleepTarget: const Duration(hours: 23),
    wakeTarget: const Duration(hours: 6, minutes: 30),
    focusBlockMinutes: const Duration(minutes: 30),
    breakMinutes: const Duration(minutes: 5),
    protectedPersonalMinutes: const Duration(minutes: 45),
    defaultBufferMinutes: Duration.zero,
  );
}

void main() {
  test('CP-03: hasta el próximo evento fijo de hoy', () {
    final now = DateTime(2026, 1, 1, 15, 0);
    final recogerSami = FixedEvent(
      id: 'e1',
      title: 'Recoger a Sami',
      start: DateTime(2026, 1, 1, 15, 40),
      end: DateTime(2026, 1, 1, 16, 0),
    );

    final window = currentWindow(
      now: now,
      fixedEvents: [recogerSami],
      user: _user(),
    );

    expect(window.duration, const Duration(minutes: 40));
  });

  test('sin eventos restantes hoy: hasta la hora de dormir', () {
    final now = DateTime(2026, 1, 1, 20, 0);

    final window = currentWindow(now: now, fixedEvents: [], user: _user());

    expect(window.end, DateTime(2026, 1, 1, 23, 0));
  });

  test('ignora eventos que ya pasaron hoy', () {
    final now = DateTime(2026, 1, 1, 15, 0);
    final eventoPasado = FixedEvent(
      id: 'e0',
      title: 'Ya pasó',
      start: DateTime(2026, 1, 1, 10, 0),
      end: DateTime(2026, 1, 1, 10, 30),
    );
    final proximo = FixedEvent(
      id: 'e1',
      title: 'Próximo',
      start: DateTime(2026, 1, 1, 15, 40),
      end: DateTime(2026, 1, 1, 16, 0),
    );

    final window = currentWindow(
      now: now,
      fixedEvents: [eventoPasado, proximo],
      user: _user(),
    );

    expect(window.end, DateTime(2026, 1, 1, 15, 40));
  });
}
