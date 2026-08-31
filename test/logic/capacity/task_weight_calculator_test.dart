import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/task_weight_calculator.dart';

void main() {
  group('calculateTaskWeight - juego TB-01', () {
    test('T1: 25 min -> peso 35 min (corta, +10 fijos)', () {
      final result = calculateTaskWeight(const Duration(minutes: 25));
      expect(result, const Duration(minutes: 35));
    });

    test('T2: 60 min -> peso 63 min (media, +5%)', () {
      final result = calculateTaskWeight(const Duration(minutes: 60));
      expect(result, const Duration(minutes: 63));
    });
  });

  group('calculateTaskWeight - prepTime y travelTime', () {
    test('sin prepTime ni travelTime, se comportan como cero', () {
      final result = calculateTaskWeight(const Duration(minutes: 25));
      expect(result, const Duration(minutes: 35));
    });

    test('con prepTime y travelTime, se suman al peso', () {
      final result = calculateTaskWeight(
        const Duration(minutes: 25),
        prepTime: const Duration(minutes: 5),
        travelTime: const Duration(minutes: 10),
      );
      // 25 (duracion) + 5 (prep) + 10 (traslado) + 10 (buffer corta) = 50
      expect(result, const Duration(minutes: 50));
    });
  });
}
