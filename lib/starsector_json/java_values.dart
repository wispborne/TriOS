import 'package:trios/starsector_json/json_exception.dart';

const int _plus = 0x2B;
const int _minus = 0x2D;
const int _dot = 0x2E;
const int _zero = 0x30;
const int _nine = 0x39;
const int _upperE = 0x45;
const int _lowerE = 0x65;

const int _javaIntMin = -2147483648;
const int _javaIntMax = 2147483647;

/// Turns a bare (unquoted) token into a value, matching
/// `org.json.JSONObject.stringToValue`.
///
/// Order of checks, same as the Java:
///   1. Empty string stays an empty string.
///   2. `true` / `false` / `null`, any capitalisation.
///   3. If the first character isn't a digit, `.`, `-` or `+`, it's a string.
///   4. `0x...` is tried as a 32-bit hex int.
///   5. No `.`, `e` or `E` anywhere means try a whole number.
///   6. Otherwise try a double.
///   7. Anything that fails to parse stays a string.
///
/// JSON `null` comes back as Dart `null`, standing in for Java's
/// `JSONObject.NULL`.
Object? stringToValue(String token) {
  if (token.isEmpty) return token;
  if (_equalsIgnoreCase(token, 'true')) return true;
  if (_equalsIgnoreCase(token, 'false')) return false;
  if (_equalsIgnoreCase(token, 'null')) return null;

  final first = token.codeUnitAt(0);
  final looksNumeric =
      (first >= _zero && first <= _nine) ||
      first == _dot ||
      first == _minus ||
      first == _plus;
  if (!looksNumeric) return token;

  // `0x` / `0X` prefix, but only when there's at least one character after it.
  if (first == _zero &&
      token.length > 2 &&
      (token.codeUnitAt(1) | 0x20) == 0x78) {
    final hex = parseJavaHexInt(token.substring(2));
    if (hex != null) return hex;
  }

  var hasDotOrExponent = false;
  for (var i = 0; i < token.length; i++) {
    final char = token.codeUnitAt(i);
    if (char == _dot || char == _lowerE || char == _upperE) {
      hasDotOrExponent = true;
      break;
    }
  }

  if (!hasDotOrExponent) return parseJavaLong(token) ?? token;
  return parseJavaDouble(token) ?? token;
}

/// `Long.parseLong` in base 10: an optional `+` or `-`, then digits only, and
/// the result has to fit in 64 bits. Returns null where Java would throw.
///
/// Dart's own `int.tryParse` is looser than this — it also accepts a `0x`
/// prefix — so the digits are checked by hand first.
int? parseJavaLong(String text) {
  if (text.isEmpty) return null;
  var start = 0;
  final first = text.codeUnitAt(0);
  if (first == _plus || first == _minus) {
    if (text.length == 1) return null;
    start = 1;
  }
  for (var i = start; i < text.length; i++) {
    final char = text.codeUnitAt(i);
    if (char < _zero || char > _nine) return null;
  }
  // Returns null when the value is too big for 64 bits, which is where Java
  // throws too.
  return int.tryParse(text);
}

/// `Integer.parseInt(text, 16)`: an optional sign, then hex digits only, and the
/// result has to fit in a signed 32-bit int. Returns null where Java would
/// throw.
int? parseJavaHexInt(String text) {
  if (text.isEmpty) return null;
  var start = 0;
  final first = text.codeUnitAt(0);
  if (first == _plus || first == _minus) {
    if (text.length == 1) return null;
    start = 1;
  }
  for (var i = start; i < text.length; i++) {
    if (_hexDigitValue(text.codeUnitAt(i)) < 0) return null;
  }
  final value = int.tryParse(text, radix: 16);
  if (value == null || value < _javaIntMin || value > _javaIntMax) return null;
  return value;
}

/// `Double.valueOf`. Returns null where Java would throw.
///
/// The one thing Java accepts that this doesn't is a hex floating-point literal
/// such as `0x1.8p1`. Nothing in the game's data files uses that form.
double? parseJavaDouble(String text) {
  // Java trims surrounding whitespace before parsing.
  var body = text.trim();
  if (body.isEmpty) return null;
  // Java allows one trailing type suffix: f, F, d or D.
  final last = body.codeUnitAt(body.length - 1) | 0x20;
  if (last == 0x66 || last == 0x64) {
    body = body.substring(0, body.length - 1);
    if (body.isEmpty) return null;
  }
  // `NaN` and `Infinity` can't reach here — stringToValue only calls this for
  // tokens containing `.`, `e` or `E` — so Dart and Java accept the same set
  // of decimal forms at this point.
  return double.tryParse(body);
}

/// Java's `Object.toString()`, for the values org.json can produce.
///
/// The object parser calls `nextValue().toString()` on every key, so an
/// unquoted key that happens to look like a number goes through Java's number
/// formatting on its way to becoming a string.
String javaToString(Object? value) {
  if (value is String) return value;
  if (value == null) return 'null'; // org.json's NULL.toString()
  if (value is bool) return value ? 'true' : 'false';
  if (value is int) return value.toString();
  if (value is double) return javaDoubleToString(value);
  if (value is Map<String, dynamic>) return _encodeMap(value);
  if (value is List) return _encodeList(value);
  throw StarsectorJsonException('Cannot use $value as a key');
}

/// `Double.toString`.
///
/// Dart and Java pick the same digits — both print the shortest decimal that
/// reads back as the same double — but they lay them out differently, so the
/// digits are taken from Dart and re-formatted using Java's rules:
///
/// - Between 1e-3 (inclusive) and 1e7 (exclusive), plain decimal with at least
///   one digit after the point.
/// - Anything else, `d.dddEnn` with exactly one digit before the point.
String javaDoubleToString(double value) {
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
  final negative = value.isNegative; // true for -0.0 as well
  final sign = negative ? '-' : '';
  final magnitude = negative ? -value : value;
  if (magnitude == 0.0) return '${sign}0.0';

  final (digits, pointAt) = _shortestDigits(magnitude);

  // pointAt is where the decimal point sits relative to the digits, so the
  // value is in [10^(pointAt-1), 10^pointAt).
  if (pointAt >= -2 && pointAt <= 7) {
    if (pointAt <= 0) {
      return '${sign}0.${'0' * -pointAt}$digits';
    }
    if (pointAt >= digits.length) {
      return '$sign$digits${'0' * (pointAt - digits.length)}.0';
    }
    return '$sign${digits.substring(0, pointAt)}.${digits.substring(pointAt)}';
  }

  final fraction = digits.length > 1 ? digits.substring(1) : '0';
  return '$sign${digits[0]}.${fraction}E${pointAt - 1}';
}

/// Splits a positive finite double into its shortest round-trip digits and the
/// position of the decimal point within them. `123.45` gives `('12345', 3)`;
/// `0.001` gives `('1', -2)`.
(String, int) _shortestDigits(double magnitude) {
  final printed = magnitude.toString();
  var mantissa = printed;
  var exponent = 0;
  final e = printed.indexOf('e');
  if (e >= 0) {
    mantissa = printed.substring(0, e);
    exponent = int.parse(printed.substring(e + 1));
  }

  String digits;
  int pointAt;
  final dot = mantissa.indexOf('.');
  if (dot >= 0) {
    digits = mantissa.substring(0, dot) + mantissa.substring(dot + 1);
    pointAt = dot;
  } else {
    digits = mantissa;
    pointAt = mantissa.length;
  }
  pointAt += exponent;

  var from = 0;
  while (from < digits.length - 1 && digits.codeUnitAt(from) == _zero) {
    from++;
    pointAt--;
  }
  var to = digits.length;
  while (to > from + 1 && digits.codeUnitAt(to - 1) == _zero) {
    to--;
  }
  return (digits.substring(from, to), pointAt);
}

/// `JSONObject.toString()`. Only reachable when a whole object is used as a key,
/// which no real game file does.
///
/// Java iterates a `HashMap` here, so its key order is neither insertion order
/// nor sorted. This uses insertion order.
String _encodeMap(Map<String, dynamic> map) {
  final out = StringBuffer('{');
  var first = true;
  for (final entry in map.entries) {
    if (!first) out.write(',');
    first = false;
    out
      ..write(javaJsonQuote(entry.key))
      ..write(':')
      ..write(_valueToString(entry.value));
  }
  return (out..write('}')).toString();
}

/// `JSONArray.toString()`. Same story as [_encodeMap].
String _encodeList(List<dynamic> list) {
  final out = StringBuffer('[');
  for (var i = 0; i < list.length; i++) {
    if (i > 0) out.write(',');
    out.write(_valueToString(list[i]));
  }
  return (out..write(']')).toString();
}

/// `JSONObject.valueToString`.
String _valueToString(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is int) return value.toString();
  if (value is double) return javaNumberToString(value);
  if (value is Map<String, dynamic>) return _encodeMap(value);
  if (value is List) return _encodeList(value);
  return javaJsonQuote(value.toString());
}

/// `JSONObject.numberToString`: `Double.toString`, then trailing zeros trimmed
/// off the fraction when there's no exponent.
String javaNumberToString(double value) {
  var text = javaDoubleToString(value);
  if (text.indexOf('.') > 0 && !text.contains('E') && !text.contains('e')) {
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  return text;
}

/// `JSONObject.quote`.
String javaJsonQuote(String text) {
  if (text.isEmpty) return '""';
  final out = StringBuffer('"');
  var previous = 0;
  for (var i = 0; i < text.length; i++) {
    final char = text.codeUnitAt(i);
    switch (char) {
      case 0x08:
        out.write(r'\b');
      case 0x09:
        out.write(r'\t');
      case 0x0A:
        out.write(r'\n');
      case 0x0C:
        out.write(r'\f');
      case 0x0D:
        out.write(r'\r');
      case 0x22:
      case 0x5C:
        out
          ..write(r'\')
          ..writeCharCode(char);
      case 0x2F:
        // Java escapes a slash only when it follows a `<`, so `</` in a string
        // can't close an HTML tag.
        if (previous == 0x3C) out.write(r'\');
        out.writeCharCode(char);
      default:
        final printable =
            char >= 0x20 &&
            (char < 128 || char >= 160) &&
            (char < 8192 || char >= 8448);
        if (printable) {
          out.writeCharCode(char);
        } else {
          out.write('\\u${char.toRadixString(16).padLeft(4, '0')}');
        }
    }
    previous = char;
  }
  return (out..write('"')).toString();
}

/// Value of a hex digit, or -1 if the character isn't one.
int _hexDigitValue(int char) {
  if (char >= _zero && char <= _nine) return char - _zero;
  if (char >= 0x41 && char <= 0x46) return char - 0x37; // A-F
  if (char >= 0x61 && char <= 0x66) return char - 0x57; // a-f
  return -1;
}

/// `String.equalsIgnoreCase` against an all-lowercase ASCII word.
bool _equalsIgnoreCase(String text, String lowercaseWord) {
  if (text.length != lowercaseWord.length) return false;
  for (var i = 0; i < text.length; i++) {
    if ((text.codeUnitAt(i) | 0x20) != lowercaseWord.codeUnitAt(i)) return false;
  }
  return true;
}
