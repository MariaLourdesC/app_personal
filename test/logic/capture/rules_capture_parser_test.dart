import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capture/rules_capture_parser.dart';

// Viernes 3 de abril de 2026.
final _viernes = DateTime(2026, 4, 3, 10, 0);

void main() {
  final parser = RulesCaptureParser();

  test('CP-01: "comprar comida para los perros mañana"', () async {
    final result = await parser.parse(
      'comprar comida para los perros mañana',
      now: _viernes,
    );

    expect(result.action, 'comprar');
    expect(result.entity, 'comida para los perros');
    expect(result.targetDate, DateTime(2026, 4, 4));
    // "mañana" es cuándo quiere hacerlo, no un vencimiento declarado.
    expect(result.deadline, isNull);
  });

  test('variante: texto sin fecha', () async {
    final result = await parser.parse('revisar arquitectura', now: _viernes);

    expect(result.action, 'revisar');
    expect(result.entity, 'arquitectura');
    expect(result.targetDate, isNull);
    expect(result.deadline, isNull);
  });

  test('variante: fecha relativa por día de la semana', () async {
    final result = await parser.parse('llamar a la miss el lunes', now: _viernes);

    expect(result.action, 'llamar');
    expect(result.targetDate, DateTime(2026, 4, 6));
  });

  test('variante: fecha explícita', () async {
    final result = await parser.parse(
      'pagar el colegio el 3 de septiembre',
      now: _viernes,
    );

    expect(result.action, 'pagar');
    expect(result.targetDate, DateTime(2026, 9, 3));
  });

  test('variante: texto sin verbo reconocible', () async {
    final result = await parser.parse('cita con el dentista', now: _viernes);

    expect(result.action, isNull);
    expect(result.rawText, 'cita con el dentista');
  });

  test('"para + fecha" es deadline, no fecha objetivo', () async {
    final result = await parser.parse(
      'revisar postulación para el lunes',
      now: _viernes,
    );

    expect(result.deadline, DateTime(2026, 4, 6));
    expect(result.targetDate, isNull);
  });

  test('los dos a la vez: "mañana para el lunes"', () async {
    final result = await parser.parse(
      'revisar postulación mañana para el lunes',
      now: _viernes,
    );

    expect(result.targetDate, DateTime(2026, 4, 4));
    expect(result.deadline, DateTime(2026, 4, 6));
  });

  test('"para" seguido de algo que no es fecha no marca deadline', () async {
    final result = await parser.parse(
      'comprar comida para los perros',
      now: _viernes,
    );

    expect(result.deadline, isNull);
    expect(result.entity, 'comida para los perros');
  });

  test('"el lunes" escrito un lunes significa el lunes siguiente', () async {
    final lunes = DateTime(2026, 4, 6, 10, 0);
    final result = await parser.parse('llamar el lunes', now: lunes);

    expect(result.targetDate, DateTime(2026, 4, 13));
  });

  test('fecha explícita ya pasada se entiende como el año que viene', () async {
    final result = await parser.parse('pagar el 3 de enero', now: _viernes);

    expect(result.targetDate, DateTime(2027, 1, 3));
  });

  test('un sustantivo de la lista de excepciones no se toma como verbo', () async {
    final result = await parser.parse('taller de Sami el lunes', now: _viernes);

    expect(result.action, isNull);
    expect(result.targetDate, DateTime(2026, 4, 6));
  });

  test('un sustantivo así en medio de la frase tampoco se toma como verbo', () async {
    final result = await parser.parse('cita en el taller el lunes', now: _viernes);

    expect(result.action, isNull);
  });

  test('limitación conocida: si el verbo no va primero, no se detecta', () async {
    final result = await parser.parse('el lunes llamar a la miss', now: _viernes);

    expect(result.action, isNull);
    expect(result.targetDate, DateTime(2026, 4, 6));
  });

  test('"pasado mañana" no se confunde con "mañana"', () async {
    final result = await parser.parse('comprar pan pasado mañana', now: _viernes);

    expect(result.targetDate, DateTime(2026, 4, 5));
  });
}
