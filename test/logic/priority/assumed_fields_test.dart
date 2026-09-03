import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/priority/priority_candidate.dart';
import 'package:app_personal/logic/priority/priority_ranking.dart';

void main() {
  group('assumedFields (D2 / CP-09)', () {
    test('consequenceLevel declarada: no hay campos asumidos', () {
      final candidate = PriorityCandidate(
        id: 'con-consecuencia',
        consequenceLevel: ConsequenceLevel.alta,
        estimatedDuration: const Duration(minutes: 20),
      );
      expect(assumedFields(candidate), isEmpty);
    });

    test('consequenceLevel null: se marca como asumido', () {
      final candidate = PriorityCandidate(
        id: 'sin-consecuencia',
        consequenceLevel: null,
        estimatedDuration: const Duration(minutes: 20),
      );
      expect(assumedFields(candidate), ['consequenceLevel']);
    });
  });

  group('un valor asumido no le gana a un valor real más bajo', () {
    final sinConsecuencia = PriorityCandidate(
      id: 'sin-consecuencia',
      consequenceLevel: null,
      estimatedDuration: const Duration(minutes: 20),
    );
    final baja = PriorityCandidate(
      id: 'baja',
      consequenceLevel: ConsequenceLevel.baja,
      estimatedDuration: const Duration(minutes: 20),
    );
    final media = PriorityCandidate(
      id: 'media',
      consequenceLevel: ConsequenceLevel.media,
      estimatedDuration: const Duration(minutes: 20),
    );

    test('sin-consecuencia (asumida "media") pierde contra "baja" real', () {
      expect(pickWinner([baja, sinConsecuencia]).id, 'baja');
      expect(pickWinner([sinConsecuencia, baja]).id, 'baja');
    });

    test('sin-consecuencia vs. "media" real: mismo rango, sigue a desempate por deadline', () {
      // Ninguna con deadline -> empate total -> gana la primera de la lista,
      // no la regla de "asumido vs. real": acá los rangos son iguales, no
      // es el caso de "ganarle a un valor más bajo".
      expect(pickWinner([sinConsecuencia, media]).id, 'sin-consecuencia');
      expect(pickWinner([media, sinConsecuencia]).id, 'media');
    });
  });
}
