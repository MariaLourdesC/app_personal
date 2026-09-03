import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/window_filter.dart';

void main() {
  // Contexto fijo TB-01: martes 15:00, ventana de 40 min (evento a las 15:40).
  final window = TimeWindow(
    start: DateTime(2026, 1, 1, 15, 0),
    end: DateTime(2026, 1, 1, 15, 40),
  );

  final t1 = PriorityCandidate(
    id: 'T1',
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: const Duration(minutes: 25),
    deadline: DateTime(2026, 1, 1, 18, 0),
  );
  final t2 = PriorityCandidate(
    id: 'T2',
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: const Duration(minutes: 60),
    deadline: DateTime(2026, 1, 1, 18, 0),
  );
  final t3 = PriorityCandidate(
    id: 'T3',
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: const Duration(minutes: 20),
  );
  final t4 = PriorityCandidate(
    id: 'T4',
    consequenceLevel: ConsequenceLevel.baja,
    estimatedDuration: const Duration(minutes: 15),
    deadline: DateTime(2026, 1, 15),
  );
  final t5 = PriorityCandidate(
    id: 'T5',
    consequenceLevel: ConsequenceLevel.baja,
    estimatedDuration: const Duration(minutes: 5),
  );

  test('TB-01: T2 queda afuera, las otras cuatro caben', () {
    final result = candidatesThatFit([t1, t2, t3, t4, t5], window);
    final ids = result.map((c) => c.id).toList();

    expect(ids, containsAll(['T1', 'T3', 'T4', 'T5']));
    expect(ids, isNot(contains('T2')));
  });
}
