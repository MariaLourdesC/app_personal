import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/fixed_event.dart';
import 'package:app_personal/models/user.dart';
import 'package:app_personal/logic/capacity/current_window.dart';

// Dormir 23:00, despertar 6:30, 45 min de tiempo personal protegido
// -> bloque personal 22:15-23:00.
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
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 15, 0),
      fixedEvents: [
        FixedEvent(
          id: 'e1',
          title: 'Recoger a Sami',
          start: DateTime(2026, 1, 1, 15, 40),
          end: DateTime(2026, 1, 1, 16, 0),
        ),
      ],
      user: _user(),
    );

    expect(result.block, CurrentBlock.disponible);
    expect(result.window!.duration, const Duration(minutes: 40));
  });

  test('sin eventos restantes: hasta el inicio del tiempo personal', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 20, 0),
      fixedEvents: [],
      user: _user(),
    );

    expect(result.block, CurrentBlock.disponible);
    expect(result.window!.end, DateTime(2026, 1, 1, 22, 15));
  });

  test('un evento después del bloque personal no extiende la ventana', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 20, 0),
      fixedEvents: [
        FixedEvent(
          id: 'e1',
          title: 'Algo tarde',
          start: DateTime(2026, 1, 1, 22, 45),
          end: DateTime(2026, 1, 1, 23, 0),
        ),
      ],
      user: _user(),
    );

    expect(result.window!.end, DateTime(2026, 1, 1, 22, 15));
  });

  test('CP-11: dentro del tiempo personal no hay ventana, y se sabe el motivo', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 22, 30),
      fixedEvents: [],
      user: _user(),
    );

    expect(result.block, CurrentBlock.tiempoPersonal);
    expect(result.window, isNull);
  });

  test('CP-11: después de la hora de dormir tampoco, con motivo de sueño', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 23, 30),
      fixedEvents: [],
      user: _user(),
    );

    expect(result.block, CurrentBlock.sueno);
    expect(result.window, isNull);
  });

  test('CP-11: de madrugada, antes de despertar, también es sueño', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 4, 0),
      fixedEvents: [],
      user: _user(),
    );

    expect(result.block, CurrentBlock.sueno);
  });

  test('ignora eventos que ya pasaron hoy', () {
    final result = currentWindow(
      now: DateTime(2026, 1, 1, 15, 0),
      fixedEvents: [
        FixedEvent(
          id: 'e0',
          title: 'Ya pasó',
          start: DateTime(2026, 1, 1, 10, 0),
          end: DateTime(2026, 1, 1, 10, 30),
        ),
        FixedEvent(
          id: 'e1',
          title: 'Próximo',
          start: DateTime(2026, 1, 1, 15, 40),
          end: DateTime(2026, 1, 1, 16, 0),
        ),
      ],
      user: _user(),
    );

    expect(result.window!.end, DateTime(2026, 1, 1, 15, 40));
  });
}
