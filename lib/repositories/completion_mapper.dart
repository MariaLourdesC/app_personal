import '../models/task_completion.dart';

Map<String, Object?> completionToMap(TaskCompletion completion) {
  return {
    'id': completion.id,
    'task_id': completion.taskId,
    'start_time': completion.start.millisecondsSinceEpoch,
    'end_time': completion.end.millisecondsSinceEpoch,
    'actual_duration_minutes': completion.actualDuration.inMinutes,
    'estimated_duration_minutes': completion.estimatedDuration?.inMinutes,
    'interruptions': completion.interruptions,
    'distractions': completion.distractions,
  };
}
