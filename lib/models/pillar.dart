/// §105 del PRD. Los cuatro pilares están precargados (§3), no se crean
/// desde la UI en Fase 1.
class Pillar {
  Pillar({required this.id, required this.name, required this.policy});

  final String id;
  final String name;
  final String policy;
}
