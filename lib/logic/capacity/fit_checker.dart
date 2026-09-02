import 'time_window.dart';

/// ¿Cabe una tarea (ya con su peso calculado) en una ventana disponible?
/// No distingue "ventana posible" de "ventana segura" (§8 del PRD): el buffer
/// de D1 ya incluido en `taskWeight` es la respuesta de Fase 1 a esa distinción.
bool taskFits({required Duration taskWeight, required TimeWindow window}) {
  return taskWeight <= window.duration;
}
