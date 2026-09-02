import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/task_weight_calculator.dart';
import 'package:app_personal/logic/capacity/time_window.dart';
import 'package:app_personal/logic/capacity/fit_checker.dart';

void main() {
  group('taskFits - tabla completa CP-04 (ventana de 40 min)', () {
    final window = TimeWindow(
      start: DateTime(2026, 1, 1, 15, 0),
      end: DateTime(2026, 1, 1, 15, 40),
    );

    test('29 min -> peso 39 min -> cabe', () {
      final weight = calculateTaskWeight(const Duration(minutes: 29));
      expect(taskFits(taskWeight: weight, window: window), isTrue);
    });

    test('30 min -> peso 40 min -> cabe, exacto', () {
      final weight = calculateTaskWeight(const Duration(minutes: 30));
      expect(taskFits(taskWeight: weight, window: window), isTrue);
    });

    test('31 min -> peso 33 min -> cabe', () {
      final weight = calculateTaskWeight(const Duration(minutes: 31));
      expect(taskFits(taskWeight: weight, window: window), isTrue);
    });

    test('2 h 0 min -> peso 126 min -> no cabe', () {
      final weight = calculateTaskWeight(const Duration(hours: 2));
      expect(taskFits(taskWeight: weight, window: window), isFalse);
    });

    test('2 h 1 min -> peso 134 min -> no cabe', () {
      final weight = calculateTaskWeight(
        const Duration(hours: 2, minutes: 1),
      );
      expect(taskFits(taskWeight: weight, window: window), isFalse);
    });
  });
}
