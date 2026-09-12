import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/consequence_level.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/priority/next_window_finder.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';

PriorityCandidate _candidate(String id, int minutes) {
  return PriorityCandidate(
    id: id,
    consequenceLevel: ConsequenceLevel.alta,
    estimatedDuration: Duration(minutes: minutes),
  );
}

void main() {
  test('CP-07: devuelve la primera ventana donde sí entra algo', () {
    // Peso de una tarea de 20 min = 30 min (tramo corto, +10 fijos).
    final candidates = [_candidate('t1', 20)];

    final ventanaChica = TimeWindow(
      start: DateTime(2026, 1, 1, 15, 38),
      end: DateTime(2026, 1, 1, 15, 40),
    );
    final ventanaGrande = TimeWindow(
      start: DateTime(2026, 1, 1, 16, 0),
      end: DateTime(2026, 1, 1, 18, 0),
    );

    final found = nextWindowWithSpace(
      candidates: candidates,
      windows: [ventanaChica, ventanaGrande],
    );

    expect(found, isNotNull);
    expect(found!.start, DateTime(2026, 1, 1, 16, 0));
  });

  test('si no entra en ninguna ventana restante, devuelve null', () {
    final candidates = [_candidate('larga', 180)];

    final found = nextWindowWithSpace(
      candidates: candidates,
      windows: [
        TimeWindow(
          start: DateTime(2026, 1, 1, 16, 0),
          end: DateTime(2026, 1, 1, 17, 0),
        ),
      ],
    );

    expect(found, isNull);
  });
}
