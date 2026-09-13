import 'capture_parser.dart';
import 'capture_result.dart';

/// Implementación de C1 con reglas locales: gratis, sin conexión y
/// determinista. Extrae solo lo que §11 permite — acción, entidad, fecha
/// objetivo y deadline explícito — y deja en `null` todo lo que no puede
/// inferir, en vez de fabricarlo.
class RulesCaptureParser implements CaptureParser {
  @override
  Future<CaptureResult> parse(String text, {required DateTime now}) async {
    final raw = text.trim();
    final normalized = _normalize(raw);

    // Todos los tramos se llevan en coordenadas del texto **normalizado**,
    // que es sobre el que buscan las expresiones regulares. Recién al
    // final se traducen a coordenadas del original, para poder extraer los
    // pedazos conservando acentos y mayúsculas.
    final spansToRemove = <_Span>[];

    // "para + fecha" marca vencimiento (decisión de la usuaria). El otro
    // uso de "para" ("comida para los perros") no matchea porque lo que
    // sigue no es una expresión de fecha.
    DateTime? deadline;
    final deadlineMatch = _findDateAfterKeyword(normalized.text, 'para', now);
    if (deadlineMatch != null) {
      deadline = deadlineMatch.date;
      spansToRemove.add(deadlineMatch.span);
    }

    // La fecha objetivo es cualquier otra expresión de fecha del texto.
    DateTime? targetDate;
    final targetMatch = _findDate(normalized.text, now, skip: spansToRemove);
    if (targetMatch != null) {
      targetDate = targetMatch.date;
      spansToRemove.add(targetMatch.span);
    }

    final actionMatch = _findAction(normalized.text);
    if (actionMatch != null) spansToRemove.add(actionMatch.span);

    final originalSpans = spansToRemove
        .map(normalized.toOriginalSpan)
        .toList();
    final actionSpan = actionMatch == null
        ? null
        : normalized.toOriginalSpan(actionMatch.span);

    return CaptureResult(
      rawText: raw,
      action: actionSpan == null
          ? null
          : raw.substring(actionSpan.start, actionSpan.end),
      entity: _entityFrom(raw, originalSpans),
      targetDate: targetDate,
      deadline: deadline,
    );
  }
}

/// Un tramo del texto original que ya fue consumido por alguna regla.
class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;

  bool overlaps(int from, int to) => from < end && to > start;
}

class _DateMatch {
  const _DateMatch(this.date, this.span);
  final DateTime date;
  final _Span span;
}

class _ActionMatch {
  const _ActionMatch(this.span);
  final _Span span;
}

/// Texto en minúsculas y sin acentos, más el mapa que dice de qué posición
/// del texto original salió cada carácter del normalizado.
///
/// El mapa hace falta porque la normalización **puede acortar** el texto:
/// una "ñ" escrita como "n" + tilde combinable son dos caracteres que se
/// vuelven uno solo. Sin el mapa, los índices de una coincidencia sobre el
/// normalizado cortarían el original en el lugar equivocado.
class _Normalized {
  const _Normalized(this.text, this._original, this._rawCodeUnits);

  final String text;

  /// `_original[i]` = índice en el texto original del carácter `i` del
  /// normalizado.
  final List<int> _original;

  /// Los caracteres del original, para poder mirar qué hay justo después
  /// de un tramo. Campo de instancia, no estático: `parse` puede correr
  /// varias veces a la vez (la pantalla parsea en cada tecla).
  final List<int> _rawCodeUnits;

  _Span toOriginalSpan(_Span span) {
    if (_original.isEmpty) return span;

    final start = _original[span.start];
    var end = _original[span.end - 1] + 1;

    // Si justo después quedó una marca combinable (la tilde de una "ñ"
    // descompuesta, por ejemplo), se la lleva también: pertenece a la
    // letra que ya está incluida, no a lo que sigue.
    while (end < _rawCodeUnits.length && _isCombiningMark(_rawCodeUnits[end])) {
      end++;
    }

    return _Span(start, end);
  }
}

const _accents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ñ': 'n',
  'ü': 'u',
};

/// Marcas diacríticas combinables (U+0300–U+036F): la tilde, el acento y
/// la diéresis cuando vienen como carácter aparte en vez de fusionados.
bool _isCombiningMark(int codeUnit) => codeUnit >= 0x0300 && codeUnit <= 0x036F;

_Normalized _normalize(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  final original = <int>[];

  for (var i = 0; i < lower.length; i++) {
    final char = lower[i];
    if (_isCombiningMark(lower.codeUnitAt(i))) continue; // se descarta

    buffer.write(_accents[char] ?? char);
    original.add(i);
  }

  return _Normalized(buffer.toString(), original, lower.codeUnits);
}

const _weekdays = {
  'lunes': DateTime.monday,
  'martes': DateTime.tuesday,
  'miercoles': DateTime.wednesday,
  'jueves': DateTime.thursday,
  'viernes': DateTime.friday,
  'sabado': DateTime.saturday,
  'domingo': DateTime.sunday,
};

const _months = {
  'enero': 1,
  'febrero': 2,
  'marzo': 3,
  'abril': 4,
  'mayo': 5,
  'junio': 6,
  'julio': 7,
  'agosto': 8,
  'septiembre': 9,
  'setiembre': 9,
  'octubre': 10,
  'noviembre': 11,
  'diciembre': 12,
};

final _datePatterns = <RegExp>[
  RegExp(r'\bpasado manana\b'),
  RegExp(r'\bmanana\b'),
  RegExp(r'\bhoy\b'),
  RegExp('\\b(?:el\\s+)?(?:proximo\\s+)?(${_weekdays.keys.join('|')})\\b'),
  RegExp('\\b(?:el\\s+)?(\\d{1,2})\\s+de\\s+(${_months.keys.join('|')})\\b'),
];

/// Busca la primera expresión de fecha del texto, ignorando los tramos ya
/// consumidos por otra regla.
_DateMatch? _findDate(
  String normalized,
  DateTime now, {
  List<_Span> skip = const [],
  int from = 0,
}) {
  _DateMatch? earliest;

  for (final pattern in _datePatterns) {
    for (final match in pattern.allMatches(normalized, from)) {
      final overlapped = skip.any((s) => s.overlaps(match.start, match.end));
      if (overlapped) continue;

      final date = _resolve(match, now);
      if (date == null) continue;

      if (earliest == null || match.start < earliest.span.start) {
        earliest = _DateMatch(date, _Span(match.start, match.end));
      }
      break;
    }
  }

  return earliest;
}

/// Busca una fecha que venga inmediatamente después de una palabra clave
/// ("para el lunes"). El tramo devuelto incluye la palabra clave.
_DateMatch? _findDateAfterKeyword(
  String normalized,
  String keyword,
  DateTime now,
) {
  for (final match in RegExp('\\b$keyword\\b').allMatches(normalized)) {
    final after = _findDate(normalized, now, from: match.end);
    if (after == null) continue;

    // Solo cuenta si la fecha arranca justo después de la palabra clave
    // (separada apenas por espacios), no en cualquier parte posterior.
    final between = normalized.substring(match.end, after.span.start);
    if (between.trim().isNotEmpty) continue;

    return _DateMatch(after.date, _Span(match.start, after.span.end));
  }
  return null;
}

DateTime? _resolve(RegExpMatch match, DateTime now) {
  final text = match.group(0)!;
  final today = DateTime(now.year, now.month, now.day);

  if (text.contains('pasado manana')) {
    return today.add(const Duration(days: 2));
  }
  if (text.contains('manana')) return today.add(const Duration(days: 1));
  if (text.contains('hoy')) return today;

  final weekday = _weekdays[match.groupCount >= 1 ? match.group(1) : null];
  if (weekday != null) {
    // Siempre la próxima ocurrencia futura: si hoy es lunes, "el lunes"
    // se entiende como el lunes que viene, no hoy.
    var days = (weekday - today.weekday) % 7;
    if (days == 0) days = 7;
    return today.add(Duration(days: days));
  }

  if (match.groupCount >= 2) {
    final day = int.tryParse(match.group(1) ?? '');
    final month = _months[match.group(2)];
    if (day != null && month != null) {
      var date = DateTime(today.year, month, day);
      // Si esa fecha ya pasó este año, se entiende el año que viene.
      if (date.isBefore(today)) date = DateTime(today.year + 1, month, day);
      return date;
    }
  }

  return null;
}

/// Sustantivos comunes que terminan igual que un infinitivo. Sin esta
/// lista, "taller de Sami el lunes" daría "taller" como acción: un verbo
/// que nadie escribió, justo lo que §11 prohíbe. Es una lista a mano y
/// por lo tanto incompleta — ampliarla cuando aparezca un caso nuevo.
const _noVerbs = {'lugar', 'taller', 'mujer', 'hogar', 'bar', 'colegio'};

/// La acción es la **primera palabra** del texto, y solo si parece
/// infinitivo (`-ar`/`-er`/`-ir`) y no está en `_noVerbs`. Si no, `null`
/// — CP-01 contempla "texto sin verbo reconocible".
///
/// Se exige que sea la primera palabra, y no la primera coincidencia en
/// cualquier parte, para que un sustantivo de esos en medio de la frase
/// ("cita en el taller el lunes") no se tome como verbo. El costo es que
/// "el lunes llamar a la miss" no detecta el verbo — se completa a mano
/// en el Inbox.
_ActionMatch? _findAction(String normalized) {
  final match = RegExp(r'^[a-z]{4,}\b').firstMatch(normalized);
  if (match == null) return null;

  final word = match.group(0)!;
  if (_noVerbs.contains(word)) return null;
  if (word.endsWith('ar') || word.endsWith('er') || word.endsWith('ir')) {
    return _ActionMatch(_Span(match.start, match.end));
  }
  return null;
}

/// Lo que queda del texto después de sacar la acción y las fechas.
String? _entityFrom(String raw, List<_Span> consumed) {
  final sorted = [...consumed]..sort((a, b) => a.start.compareTo(b.start));
  final buffer = StringBuffer();
  var cursor = 0;

  for (final span in sorted) {
    if (span.start > cursor) buffer.write(raw.substring(cursor, span.start));
    cursor = span.end > cursor ? span.end : cursor;
  }
  if (cursor < raw.length) buffer.write(raw.substring(cursor));

  final cleaned = buffer
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return cleaned.isEmpty ? null : cleaned;
}
