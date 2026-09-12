import '../models/energy_required.dart';
import '../models/user.dart';

Map<String, Object?> userToMap(User user) {
  return {
    'id': user.id,
    'timezone': user.timezone,
    'sleep_target_minutes': user.sleepTarget.inMinutes,
    'wake_target_minutes': user.wakeTarget.inMinutes,
    'focus_block_minutes': user.focusBlockMinutes.inMinutes,
    'break_minutes': user.breakMinutes.inMinutes,
    'protected_personal_minutes': user.protectedPersonalMinutes.inMinutes,
    'default_buffer_minutes': user.defaultBufferMinutes.inMinutes,
    'current_energy_state': user.currentEnergyState?.name,
  };
}

User userFromMap(Map<String, Object?> map) {
  final energyStateName = map['current_energy_state'] as String?;
  return User(
    id: map['id'] as String,
    timezone: map['timezone'] as String,
    sleepTarget: Duration(minutes: map['sleep_target_minutes'] as int),
    wakeTarget: Duration(minutes: map['wake_target_minutes'] as int),
    focusBlockMinutes: Duration(minutes: map['focus_block_minutes'] as int),
    breakMinutes: Duration(minutes: map['break_minutes'] as int),
    protectedPersonalMinutes: Duration(
      minutes: map['protected_personal_minutes'] as int,
    ),
    defaultBufferMinutes: Duration(
      minutes: map['default_buffer_minutes'] as int,
    ),
    currentEnergyState: energyStateName == null
        ? null
        : EnergyIntensity.values.byName(energyStateName),
  );
}
