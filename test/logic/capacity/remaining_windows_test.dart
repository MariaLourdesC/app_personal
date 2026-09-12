import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/fixed_event.dart';
import 'package:app_personal/models/user.dart';
import 'package:app_personal/logic/capacity/current_window.dart';

// Dormir 23:00, 45 min personales -> el día "útil" termina 22:15.
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

FixedEvent _event(String id, int startHour, int startMin, int endHour, int endMin) {
  return FixedEvent(
    id: id,
    title: id,
    start: DateTime(2026, 1, 1, startHour, startMin),
    end: DateTime(2026, 1, 1, endHour, endMin),
  );
}

void main() {
  test('sin eventos: una sola ventana, hasta el tiempo personal', () {
    final windows = remainingWindows(
      now: DateTime(2026, 1, 1, 15, 0),
      fixedEvents: [],
      user: _user(),
    );

    expect(windows.length, 1);
    expect(windows.first.start, DateTime(2026, 1, 1, 15, 0));
    expect(windows.first.end, DateTime(2026, 1, 1, 22, 15));
  });

  test('con dos eventos: tres huecos, antes, entre y después', () {
    final windows = remainingWindows(
      now: DateTime(2026, 1, 1, 15, 0),
      fixedEvents: [
        _event('recoger a Sami', 15, 40, 16, 10),
        _event('reunión', 18, 0, 19, 0),
      ],
      user: _user(),
    );

    expect(windows.length, 3);
    expect(windows[0].end, DateTime(2026, 1, 1, 15, 40));
    expect(windows[1].start, DateTime(2026, 1, 1, 16, 10));
    expect(windows[1].end, DateTime(2026, 1, 1, 18, 0));
    expect(windows[2].start, DateTime(2026, 1, 1, 19, 0));
    expect(windows[2].end, DateTime(2026, 1, 1, 22, 15));
  });

  test('un evento pegado al momento actual no genera ventana vacía', () {
    final windows = remainingWindows(
      now: DateTime(2026, 1, 1, 15, 0),
      fixedEvents: [_event('inmediato', 15, 0, 16, 0)],
      user: _user(),
    );

    expect(windows.length, 1);
    expect(windows.first.start, DateTime(2026, 1, 1, 16, 0));
  });

  test('dentro del tiempo personal: no queda ninguna ventana', () {
    final windows = remainingWindows(
      now: DateTime(2026, 1, 1, 22, 30),
      fixedEvents: [],
      user: _user(),
    );

    expect(windows, isEmpty);
  });

  test('eventos que terminan después del corte no extienden el día', () {
    final windows = remainingWindows(
      now: DateTime(2026, 1, 1, 21, 0),
      fixedEvents: [_event('tarde', 21, 30, 23, 30)],
      user: _user(),
    );

    expect(windows.length, 1);
    expect(windows.first.end, DateTime(2026, 1, 1, 21, 30));
  });
}
