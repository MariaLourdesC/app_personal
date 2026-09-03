import 'priority_candidate.dart';
import 'reason.dart';

/// Contrato de C4 (ver Arquitectura_Fase_1.md): la decisión ya tomada, no
/// una lista para que la pantalla ordene. Usa `PriorityCandidate` en vez de
/// `Task` (§106) porque esa entidad todavía no existe como tal (C2 no está
/// construido).
class DecisionResult {
  DecisionResult({
    required this.candidate,
    required this.reason,
    required this.assumed,
  });

  final PriorityCandidate candidate;
  final Reason reason;
  final List<String> assumed;
}
