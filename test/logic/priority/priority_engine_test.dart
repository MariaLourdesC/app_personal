import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/priority_engine.dart';

void main() {
  final window = TimeWindow(
    start: DateTime(2026, 1, 1, 15, 0),
    end: DateTime(2026, 1, 1, 15, 40),
  );

  test('CP-03/TB-01: decide() elige T1, con su motivo y sin campos asumidos', () {
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

    final result = decide([t1, t2, t3, t4, t5], window);

    expect(result.candidate.id, 'T1');
    expect(result.reason.consequenceLevel, ConsequenceLevel.alta);
    expect(result.reason.hasDeadline, isTrue);
    expect(result.reason.deadline, DateTime(2026, 1, 1, 18, 0));
    expect(result.assumed, isEmpty);
  });

  test('CP-09: decide() degrada con consequenceLevel null, y lo marca en assumed', () {
    final sinConsecuencia = PriorityCandidate(
      id: 'sin-consecuencia',
      consequenceLevel: null,
      estimatedDuration: const Duration(minutes: 20),
    );

    final result = decide([sinConsecuencia], window);

    expect(result.candidate.id, 'sin-consecuencia');
    expect(result.reason.consequenceLevel, ConsequenceLevel.media);
    expect(result.assumed, ['consequenceLevel']);
  });
}
