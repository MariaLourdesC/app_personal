import '../models/fixed_event.dart';

abstract class FixedEventRepository {
  Future<void> save(FixedEvent event);
  Future<List<FixedEvent>> getAll();
}
