import 'capture_result.dart';

/// Contrato de C1. Hoy lo implementa un parser de reglas locales
/// (gratis, sin conexión, determinista); mañana puede implementarlo uno
/// que llame a un modelo, sin que las pantallas ni el resto de la lógica
/// se enteren — el principio del documento de Arquitectura: "las
/// interfaces se definen como si hablaran con un servidor".
///
/// Devuelve `Future` aunque las reglas locales respondan al instante:
/// una llamada a un modelo sería asíncrona, y la firma tiene que servir
/// para las dos implementaciones sin cambiar a quien la usa.
///
/// `now` se pasa como parámetro en vez de leer el reloj adentro para que
/// resolver "mañana" sea determinista y testeable.
abstract class CaptureParser {
  Future<CaptureResult> parse(String text, {required DateTime now});
}
