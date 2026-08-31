import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/buffer_calculator.dart';

void main() {
  group('calculateBuffer - bordes de tramos (CP-04)', () {
    test('29 min (corta) -> buffer de 10 min', () {
      final result = calculateBuffer(const Duration(minutes: 29));
      expect(result, const Duration(minutes: 10));
    });

    test('30 min exactos (corta, borde superior) -> buffer de 10 min', () {
      final result = calculateBuffer(const Duration(minutes: 30));
      expect(result, const Duration(minutes: 10));
    });

    test('31 min (media, borde inferior) -> buffer de 5%', () {
      final result = calculateBuffer(const Duration(minutes: 31));
      // 31 * 0.05 = 1.55 -> ceil -> 2
      expect(result, const Duration(minutes: 2));
    });

    test('2 h 0 min exactas (media, borde superior) -> buffer de 5%', () {
      final result = calculateBuffer(const Duration(hours: 2));
      // 120 * 0.05 = 6.0 -> ceil -> 6
      expect(result, const Duration(minutes: 6));
    });

    test('2 h 1 min (larga, borde inferior) -> buffer de 10%', () {
      final result = calculateBuffer(const Duration(hours: 2, minutes: 1));
      // 121 * 0.10 = 12.1 -> ceil -> 13
      expect(result, const Duration(minutes: 13));
    });
  });
}
