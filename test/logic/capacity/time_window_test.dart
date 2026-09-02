import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capacity/time_window.dart';

void main() {
  group('TimeWindow', () {
    test('duration calcula la diferencia entre start y end', () {
      final window = TimeWindow(
        start: DateTime(2026, 8, 25, 15, 0),
        end: DateTime(2026, 8, 25, 15, 40),
      );
      expect(window.duration, const Duration(minutes: 40));
    });

    test('end igual a start lanza ArgumentError', () {
      final sameTime = DateTime(2026, 8, 25, 15, 0);
      expect(
        () => TimeWindow(start: sameTime, end: sameTime),
        throwsArgumentError,
      );
    });

    test('end antes que start lanza ArgumentError', () {
      expect(
        () => TimeWindow(
          start: DateTime(2026, 8, 25, 15, 40),
          end: DateTime(2026, 8, 25, 15, 0),
        ),
        throwsArgumentError,
      );
    });
  });
}
