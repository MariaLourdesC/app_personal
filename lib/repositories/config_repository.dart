import '../models/user.dart';

/// Un solo registro de `User` — se lee en cada cálculo, se escribe casi
/// nunca (ver Arquitectura_Fase_1.md).
abstract class ConfigRepository {
  Future<User?> getUser();
  Future<void> saveUser(User user);
}
