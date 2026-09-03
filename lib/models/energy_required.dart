/// §22 del PRD: la energía que pide una tarea tiene dos dimensiones
/// independientes — intensidad y tipo. Ir al gimnasio (física, alta) y
/// resolver un ticket complejo (administrativa, alta) cansan distinto
/// aunque compartan intensidad.
enum EnergyIntensity { alta, media, baja }

/// Extensible a propósito: hoy solo física/administrativa (lo único que
/// menciona el documento), pero se espera sumar más tipos más adelante
/// (por ejemplo, energía social).
enum EnergyType { fisica, administrativa }

class EnergyRequired {
  EnergyRequired({required this.intensity, required this.type});

  final EnergyIntensity intensity;
  final EnergyType type;
}
