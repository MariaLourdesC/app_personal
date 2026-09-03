import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/default_pillars.dart';

void main() {
  test('§3: existen exactamente los 4 pilares esperados', () {
    final names = defaultPillars.map((p) => p.name).toList();
    expect(names, [
      'Familia y cuidados',
      'Ingresos protegidos y creciendo',
      'Hogar funcional',
      'Valor estratégico',
    ]);
  });

  test('cada pilar tiene un id único', () {
    final ids = defaultPillars.map((p) => p.id).toSet();
    expect(ids.length, defaultPillars.length);
  });
}
