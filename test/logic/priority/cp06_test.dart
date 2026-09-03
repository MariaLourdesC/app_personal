import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/priority_ranking.dart';
import 'package:app_personal/logic/priority/window_filter.dart';

void main() {
  // CP-06: hora 15:55, ventana libre 16:00-18:00.
  final window = TimeWindow(
    start: DateTime(2026, 1, 1, 16, 0),
    end: DateTime(2026, 1, 1, 18, 0),
  );

  final tx = PriorityCandidate(
    id: 'TX',
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: const Duration(minutes: 90),
    deadline: DateTime(2026, 1, 2, 9, 0),
  );
  final ty = PriorityCandidate(
    id: 'TY',
    consequenceLevel: ConsequenceLevel.media,
    estimatedDuration: const Duration(minutes: 100),
  );

  test('CP-06: TX gana con el ranking que ya tenemos (sin lógica nueva)', () {
    final fit = candidatesThatFit([tx, ty], window);
    final winner = pickWinner(fit);
    expect(winner.id, 'TX');
  });
}
