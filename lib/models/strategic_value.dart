/// §6 y §3.4 del PRD: cuánto construye futuro una tarea, independiente de
/// su consecuencia inmediata. Un enum propio, separado de `ConsequenceLevel`
/// aunque comparta estructura — son ejes distintos (§6: "son variables
/// diferentes").
enum StrategicValue { alta, media, baja }
