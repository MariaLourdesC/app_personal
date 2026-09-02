/// Representa un hueco de tiempo libre (inicio/fin).
class TimeWindow {
  TimeWindow({required this.start, required this.end}) {
    if (!end.isAfter(start)) {
      throw ArgumentError('end debe ser posterior a start');
    }
  }

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}
