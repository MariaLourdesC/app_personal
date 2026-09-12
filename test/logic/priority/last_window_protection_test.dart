import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/consequence_level.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/priority_engine.dart';

// Ventana de ahora: 16:00-18:00 (120 min).
final _ahora = TimeWindow(
  start: DateTime(2026, 1, 1, 16, 0),
  end: DateTime(2026, 1, 1, 18, 0),
);

void main() {
  group('§23 / CP-06: no destruir la última ventana segura de una superior', () {
    // TY gana por ranking (alta > media) y ocuparía toda la ventana.
    final ty = PriorityCandidate(
      id: 'TY',
      consequenceLevel: ConsequenceLevel.alta,
      estimatedDuration: const Duration(minutes: 100),
    );
    // TX vence mañana y necesita 90 min: esta es su única chance.
    final tx = PriorityCandidate(
      id: 'TX',
      consequenceLevel: ConsequenceLevel.media,
      estimatedDuration: const Duration(minutes: 90),
      deadline: DateTime(2026, 1, 2, 9, 0),
    );

    test('sin ventanas posteriores: TX se protege y gana pese a rankear más bajo', () {
      final result = decide([ty, tx], _ahora, laterWindows: const []);
      expect(result.candidate.id, 'TX');
    });

    test('si TX tiene otra ventana antes de su deadline, no se protege: gana TY', () {
      final maniana = TimeWindow(
        start: DateTime(2026, 1, 2, 6, 30),
        end: DateTime(2026, 1, 2, 8, 40),
      );

      final result = decide([ty, tx], _ahora, laterWindows: [maniana]);
      expect(result.candidate.id, 'TY');
    });

    test('una ventana posterior que termina después del deadline no cuenta', () {
      // Empieza 8:00 y el deadline es 9:00: solo 60 min usables, no entran 90+.
      final tarde = TimeWindow(
        start: DateTime(2026, 1, 2, 8, 0),
        end: DateTime(2026, 1, 2, 12, 0),
      );

      final result = decide([ty, tx], _ahora, laterWindows: [tarde]);
      expect(result.candidate.id, 'TX');
    });

    test('deadline lejano (dos semanas): no se protege, gana el ranking', () {
      final txLejano = PriorityCandidate(
        id: 'TX-lejano',
        consequenceLevel: ConsequenceLevel.media,
        estimatedDuration: const Duration(minutes: 90),
        deadline: DateTime(2026, 1, 15),
      );

      final result = decide([ty, txLejano], _ahora, laterWindows: const []);
      expect(result.candidate.id, 'TY');
    });

    test('si las dos entran juntas en la ventana, nadie destruye nada', () {
      final corta = PriorityCandidate(
        id: 'corta',
        consequenceLevel: ConsequenceLevel.media,
        estimatedDuration: const Duration(minutes: 20),
        deadline: DateTime(2026, 1, 2, 9, 0),
      );
      final tambienCorta = PriorityCandidate(
        id: 'tambien-corta',
        consequenceLevel: ConsequenceLevel.alta,
        estimatedDuration: const Duration(minutes: 25),
      );

      // 30 + 35 = 65 min, entran de sobra en 120.
      final result = decide([tambienCorta, corta], _ahora, laterWindows: const []);
      expect(result.candidate.id, 'tambien-corta');
    });
  });
}
