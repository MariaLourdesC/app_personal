import '../models/fixed_event.dart';

Map<String, Object?> fixedEventToMap(FixedEvent event) {
  return {
    'id': event.id,
    'title': event.title,
    'start_time': event.start.millisecondsSinceEpoch,
    'end_time': event.end.millisecondsSinceEpoch,
  };
}

FixedEvent fixedEventFromMap(Map<String, Object?> map) {
  return FixedEvent(
    id: map['id'] as String,
    title: map['title'] as String,
    start: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
    end: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
  );
}
