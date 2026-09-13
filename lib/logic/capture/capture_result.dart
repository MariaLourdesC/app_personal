/// Lo que C1 logra extraer de un texto libre (§11): únicamente acción,
/// entidad, fecha objetivo y deadline explícito. Todo lo demás
/// (consecuencia, energía, duración, pilar) queda fuera a propósito y se
/// completa a mano en el Inbox.
///
/// Los cuatro campos son nullable porque §11 es explícito: "inferir
/// únicamente lo que el texto permite inferir, no inventar razones".
/// CP-01 incluye la variante "texto sin verbo reconocible" — ahí `action`
/// queda en `null`, no se fabrica un verbo.
class CaptureResult {
  CaptureResult({
    required this.rawText,
    this.action,
    this.entity,
    this.targetDate,
    this.deadline,
  });

  /// Lo que la usuaria escribió, tal cual. Siempre presente: sirve de
  /// título aunque el parser no logre separar nada.
  final String rawText;

  final String? action;
  final String? entity;

  /// La "fecha objetivo" de §10, ya resuelta a una fecha real — CP-01 pide
  /// explícitamente que no quede el literal "mañana".
  final DateTime? targetDate;

  /// Solo si el texto declara un vencimiento explícito.
  final DateTime? deadline;
}
