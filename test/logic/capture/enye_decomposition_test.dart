import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capture/rules_capture_parser.dart';

final _viernes = DateTime(2026, 4, 3, 10, 0);

/// "mañana" con ñ precompuesta: un solo carácter, U+00F1.
const _precompuesta = 'mañana';

/// "mañana" con ñ descompuesta: "n" seguido de una tilde combinable
/// (U+0303). Se ve igual en pantalla, pero son dos caracteres.
const _descompuesta = 'mañana';

void main() {
  final parser = RulesCaptureParser();

  test('las dos formas se ven iguales pero no son el mismo texto', () {
    expect(_precompuesta.length, 6);
    expect(_descompuesta.length, 7);
    expect(_precompuesta == _descompuesta, isFalse);
  });

  test('ñ precompuesta: se detecta la fecha', () async {
    final result = await parser.parse('comprar pan $_precompuesta', now: _viernes);
    expect(result.targetDate, DateTime(2026, 4, 4));
  });

  test('ñ descompuesta: se detecta la fecha', () async {
    final result = await parser.parse('comprar pan $_descompuesta', now: _viernes);
    expect(result.targetDate, DateTime(2026, 4, 4));
  });

  // Lo que protege el mapa de índices: al normalizar, el texto se acorta
  // (dos caracteres pasan a ser uno), así que recortar la fecha usando los
  // índices del normalizado cortaría el original en el lugar equivocado.
  test('ñ descompuesta: la entidad queda limpia, sin restos de la fecha', () async {
    final result = await parser.parse(
      'comprar comida para los perros $_descompuesta',
      now: _viernes,
    );

    expect(result.action, 'comprar');
    expect(result.entity, 'comida para los perros');
  });

  test('una entidad con ñ descompuesta conserva sus caracteres', () async {
    final result = await parser.parse(
      'comprar pañales hoy',
      now: _viernes,
    );

    expect(result.targetDate, DateTime(2026, 4, 3));
    // El texto original se devuelve tal cual llegó, sin normalizar.
    expect(result.entity, 'pañales');
  });
}
