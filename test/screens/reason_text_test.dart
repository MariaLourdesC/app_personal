import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/models/consequence_level.dart';
import 'package:app_personal/logic/priority/reason.dart';
import 'package:app_personal/screens/reason_text.dart';

void main() {
  test('CP-08: consecuencia declarada + deadline hoy + cabe en la ventana', () {
    final reason = Reason(
      consequenceLevel: ConsequenceLevel.alta,
      hasDeadline: true,
      deadline: DateTime.now(),
    );

    final lines = reasonText(reason, []);

    expect(lines, [
      'Consecuencia alta',
      'Vence hoy',
      'Cabe en tu ventana disponible',
    ]);
  });

  test('sin deadline: no aparece ninguna línea de deadline inventada', () {
    final reason = Reason(consequenceLevel: ConsequenceLevel.alta, hasDeadline: false);

    final lines = reasonText(reason, []);

    expect(lines, ['Consecuencia alta', 'Cabe en tu ventana disponible']);
  });

  test('CP-09: consecuencia asumida se marca explícitamente, no suena a dato real', () {
    final reason = Reason(consequenceLevel: ConsequenceLevel.media, hasDeadline: false);

    final lines = reasonText(reason, ['consequenceLevel']);

    expect(lines.first, 'Consecuencia asumida como media (no declarada)');
  });
}
