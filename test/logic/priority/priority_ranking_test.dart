import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/priority_ranking.dart';

void main() {
  // Candidatas que ya caben en la ventana (T2 quedó afuera en el filtro previo).
  final t1 = PriorityCandidate(
    id: 'T1',
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: const Duration(minutes: 25),
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

  test('TB-01: T1 gana entre las que caben', () {
    final winner = pickWinner([t1, t3, t4, t5]);
    expect(winner.id, 'T1');
  });

  test('Alta sin deadline pierde contra Alta con deadline', () {
    final winner = pickWinner([t3, t1]);
    expect(winner.id, 'T1');
  });

  test('Baja con deadline no le gana a Alta sin deadline', () {
    final winner = pickWinner([t4, t3]);
    expect(winner.id, 'T3');
  });

  test('entre dos con deadline, gana la más próxima', () {
    final proxima = PriorityCandidate(
      id: 'proxima',
      consequenceLevel: ConsequenceLevel.alta,
      estimatedDuration: const Duration(minutes: 10),
      deadline: DateTime(2026, 1, 1, 16, 0),
    );
    final lejana = PriorityCandidate(
      id: 'lejana',
      consequenceLevel: ConsequenceLevel.alta,
      estimatedDuration: const Duration(minutes: 10),
      deadline: DateTime(2026, 1, 5),
    );
    final winner = pickWinner([lejana, proxima]);
    expect(winner.id, 'proxima');
  });

  test('empate total (mismo nivel, ninguna con deadline): gana la primera de la lista', () {
    final primera = PriorityCandidate(
      id: 'primera',
      consequenceLevel: ConsequenceLevel.media,
      estimatedDuration: const Duration(minutes: 10),
    );
    final segunda = PriorityCandidate(
      id: 'segunda',
      consequenceLevel: ConsequenceLevel.media,
      estimatedDuration: const Duration(minutes: 10),
    );

    expect(pickWinner([primera, segunda]).id, 'primera');
    expect(pickWinner([segunda, primera]).id, 'segunda');
  });
}
