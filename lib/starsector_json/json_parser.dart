import 'dart:typed_data';

import 'package:trios/starsector_json/hash_comments.dart';
import 'package:trios/starsector_json/java_values.dart';
import 'package:trios/starsector_json/json_exception.dart';

const int _tab = 0x09;
const int _lineFeed = 0x0A;
const int _formFeed = 0x0C;
const int _carriageReturn = 0x0D;
const int _space = 0x20;
const int _doubleQuote = 0x22;
const int _singleQuote = 0x27;
const int _openParen = 0x28;
const int _closeParen = 0x29;
const int _comma = 0x2C;
const int _colon = 0x3A;
const int _semicolon = 0x3B;
const int _equals = 0x3D;
const int _greaterThan = 0x3E;
const int _openBracket = 0x5B;
const int _backslash = 0x5C;
const int _closeBracket = 0x5D;
const int _openBrace = 0x7B;
const int _closeBrace = 0x7D;

/// Characters that end an unquoted token: any control character, or one of
/// `,` `:` `]` `}` `/` `\` `"` `[` `{` `;` `=` `#`. The enders are taken
/// straight from `JSONTokener.nextValue`; folding the control characters into
/// the same table makes the token scan a single lookup per character.
final Uint8List _tokenStops = _buildTokenStops();

Uint8List _buildTokenStops() {
  final table = Uint8List(128);
  for (var char = 0; char < _space; char++) {
    table[char] = 1;
  }
  for (final char in r',:]}/\"[{;=#'.codeUnits) {
    table[char] = 1;
  }
  return table;
}

/// Characters that end the fast scan through a quoted string: NUL, the line
/// breaks, the backslash, and both quote characters — all below 0x60. Which
/// quote actually closes the string is sorted out at the stop.
final Uint8List _stringStops = _buildStringStops();

Uint8List _buildStringStops() {
  final table = Uint8List(0x60);
  table[0] = 1;
  table[_lineFeed] = 1;
  table[_carriageReturn] = 1;
  table[_doubleQuote] = 1;
  table[_singleQuote] = 1;
  table[_backslash] = 1;
  return table;
}

/// Reads a Starsector JSON file exactly the way the game does.
///
/// Two steps, the same two `SettingsAPI.loadJSON` runs: strip `#` comments (see
/// [removeHashComments]), then parse the result with the org.json parser the
/// game ships. Throws [StarsectorJsonException] on anything the game would
/// reject.
Map<String, dynamic> parseStarsectorJson(String text) =>
    parseJsonObject(removeHashComments(text));

/// Parses text as a JSON object using only the org.json parser, with no comment
/// stripping first.
///
/// Use [parseStarsectorJson] to read a file the way the game does. This is the
/// second half on its own, for when the text is already clean.
Map<String, dynamic> parseJsonObject(String text) =>
    _Tokener(text).readObject();

/// A port of `org.json.JSONTokener` plus the parsing constructors of
/// `JSONObject` and `JSONArray`, from the 2010 json.org release that ships in
/// Starsector's `json.jar`.
///
/// The Java version reads through a `Reader` one character at a time and can
/// step back one character. This walks the string with an index instead, which
/// comes to the same thing: the next character [next] returns is always the one
/// at [_index], in both the normal and the stepped-back case.
///
/// [_line] and [_character] are only used to build error messages, and are kept
/// up to date the same odd way Java does it — [back] rolls back the character
/// but not the line.
class _Tokener {
  _Tokener(this._text);

  final String _text;
  int _index = 0;
  int _line = 1;
  int _character = 1;
  int _previous = 0;

  /// Next character, or 0 at the end of the text.
  int next() {
    final char = _index < _text.length ? _text.codeUnitAt(_index) : 0;
    _index++;
    if (_previous == _carriageReturn) {
      _line++;
      _character = char == _lineFeed ? 0 : 1;
    } else if (char == _lineFeed) {
      _line++;
      _character = 0;
    } else {
      _character++;
    }
    _previous = char;
    return char;
  }

  /// Steps back one character. Java refuses to do this twice in a row; every
  /// caller here only ever does it once, right after a [next].
  void back() {
    _index--;
    _character--;
  }

  /// Next character that isn't whitespace, or 0 at the end of the text.
  ///
  /// Does what calling [next] in a loop would, but works in local variables
  /// and writes the fields back once at the end. This is the hottest loop in
  /// the parser — it runs between every two tokens — and indentation makes up
  /// a good share of a file's bytes.
  int nextClean() {
    final text = _text;
    final length = text.length;
    var index = _index;
    var line = _line;
    var character = _character;
    var previous = _previous;
    while (true) {
      final char = index < length ? text.codeUnitAt(index) : 0;
      index++;
      if (previous == _carriageReturn) {
        line++;
        character = char == _lineFeed ? 0 : 1;
      } else if (char == _lineFeed) {
        line++;
        character = 0;
      } else {
        character++;
      }
      previous = char;
      if (char == 0 || char > _space) {
        _index = index;
        _line = line;
        _character = character;
        _previous = previous;
        return char;
      }
    }
  }

  StarsectorJsonException syntaxError(String message) =>
      StarsectorJsonException(
        '$message at $_index [character $_character line $_line]',
      );

  /// Body of a quoted string, having already read the opening quote.
  ///
  /// Java builds this up character by character. Here the common case — no
  /// backslash anywhere — is one substring instead.
  ///
  /// The scan itself skips [next]'s bookkeeping: none of the characters it
  /// passes over can be a line break (one would end the scan), so reading them
  /// only moves [_character] along. The position fields end up exactly where a
  /// [next]-per-character loop would leave them, in every case — that matters
  /// because error messages carry the position.
  String readString(int quote) {
    final text = _text;
    final length = text.length;
    final start = _index;
    var i = start;
    while (i < length) {
      final char = text.codeUnitAt(i);
      if (char < 0x60 && _stringStops[char] != 0) {
        if (char == quote) {
          _character += i + 1 - start;
          _index = i + 1;
          _previous = quote;
          return text.substring(start, i);
        }
        if (char == _doubleQuote || char == _singleQuote) {
          // The other kind of quote, which is an ordinary character here.
          i++;
          continue;
        }
        break;
      }
      i++;
    }

    // A backslash, a line break, an embedded NUL, or the end of the text.
    // Settle up for the characters scanned so far, then take the last step
    // through [next] so the bookkeeping for it stays in one place.
    _character += i - start;
    _index = i;
    if (i > start) _previous = text.codeUnitAt(i - 1);
    final char = next();
    if (char != _backslash) {
      throw syntaxError('Unterminated string');
    }
    return _readStringWithEscapes(text.substring(start, i), quote);
  }

  /// Finishes a string that turned out to contain a backslash. [head] is
  /// everything before it, and the backslash itself has already been read.
  String _readStringWithEscapes(String head, int quote) {
    final out = StringBuffer(head);
    while (true) {
      _writeEscape(out);
      while (true) {
        final char = next();
        if (char == quote) return out.toString();
        if (char == 0 || char == _lineFeed || char == _carriageReturn) {
          throw syntaxError('Unterminated string');
        }
        if (char == _backslash) break;
        out.writeCharCode(char);
      }
    }
  }

  /// Writes what a backslash escape stands for. The backslash is already read.
  void _writeEscape(StringBuffer out) {
    final char = next();
    switch (char) {
      case _doubleQuote:
      case _singleQuote:
      case 0x2F: // forward slash
      case _backslash:
        out.writeCharCode(char);
      case 0x62: // b
        out.writeCharCode(0x08);
      case 0x66: // f
        out.writeCharCode(_formFeed);
      case 0x6E: // n
        out.writeCharCode(_lineFeed);
      case 0x72: // r
        out.writeCharCode(_carriageReturn);
      case 0x74: // t
        out.writeCharCode(_tab);
      case 0x75: // u
        out.writeCharCode(_readUnicodeEscape());
      default:
        throw syntaxError('Illegal escape.');
    }
  }

  /// The four digits of a `\u` escape.
  ///
  /// Java runs these through `Integer.parseInt(s, 16)` and casts to a char, so
  /// it keeps the low 16 bits. Java throws a `NumberFormatException` rather than
  /// a `JSONException` when the digits are bad; this throws
  /// [StarsectorJsonException] like everything else does.
  int _readUnicodeEscape() {
    final start = _index;
    for (var i = 0; i < 4; i++) {
      next();
      if (_index > _text.length) throw syntaxError('Substring bounds error');
    }
    final digits = _text.substring(start, start + 4);
    final value = parseJavaHexInt(digits);
    if (value == null) throw syntaxError('Illegal escape "\\u$digits"');
    return value & 0xFFFF;
  }

  /// One value: a string, an array, an object, or a bare token.
  Object? readValue() {
    final char = nextClean();
    switch (char) {
      case _doubleQuote:
      case _singleQuote:
        return readString(char);
      case _openParen:
      case _openBracket:
        back();
        return readArray();
      case _openBrace:
        back();
        return readObject();
    }

    // A bare token runs until a control character or one of the enders. Spaces
    // are not enders, so `two words` is a single token — it just gets trimmed.
    //
    // The scan reads ahead directly instead of going through [next]: a token
    // character is never a line break, so passing one only moves [_character]
    // along. What Java does at the end — read the stopping character, then
    // step back over it — is replayed onto the position fields by hand, so
    // they land exactly where [next]-then-[back] would put them. That includes
    // the odd cases: reading a `\n` and stepping back leaves [_character] at
    // -1 with the line already counted, and stopping at the end of the text
    // counts the end-marker read the same way [next] does.
    final start = _index - 1;
    final text = _text;
    final length = text.length;
    var stop = start;
    while (stop < length) {
      final c = text.codeUnitAt(stop);
      if (c < 128 && _tokenStops[c] != 0) break;
      stop++;
    }
    if (stop == start) {
      // The character we were handed is itself a stopper; no reads happened,
      // so this is just the step back over it.
      back();
    } else {
      _character += stop - start - 1;
      if (stop == length) {
        _character++;
        _previous = 0;
      } else {
        final c = text.codeUnitAt(stop);
        if (c == _lineFeed) {
          _line++;
          _character = 0;
        } else {
          _character++;
        }
        _previous = c;
      }
      _index = stop;
      _character--;
    }
    final token = text.substring(start, stop).trim();
    if (token.isEmpty) throw syntaxError('Missing value');
    return stringToValue(token);
  }

  /// `JSONObject(JSONTokener)`.
  Map<String, dynamic> readObject() {
    if (nextClean() != _openBrace) {
      throw syntaxError("A JSONObject text must begin with '{'");
    }

    final map = <String, dynamic>{};
    while (true) {
      var char = nextClean();
      if (char == 0) {
        throw syntaxError("A JSONObject text must end with '}'");
      }
      if (char == _closeBrace) return map;

      // Keys go through the same value reader as everything else, so an
      // unquoted key is fine and a key that looks like a number is turned into
      // one and then back into a string.
      back();
      final key = javaToString(readValue());

      char = nextClean();
      if (char == _equals) {
        // `=` works as well as `:`, and `=>` too.
        if (next() != _greaterThan) back();
      } else if (char != _colon) {
        throw syntaxError("Expected a ':' after a key");
      }

      final value = readValue();
      // Store first and see whether the map grew, so each pair costs one map
      // lookup instead of a containsKey plus a store. When a throw follows,
      // the half-updated map goes down with it, so no caller can tell.
      final sizeBefore = map.length;
      map[key] = value;
      if (map.length == sizeBefore) {
        throw StarsectorJsonException('Duplicate key "$key"');
      }
      if (value is double && !value.isFinite) {
        throw const StarsectorJsonException(
          'JSON does not allow non-finite numbers.',
        );
      }

      char = nextClean();
      if (char == _comma || char == _semicolon) {
        // A trailing comma before `}` is allowed.
        if (nextClean() == _closeBrace) return map;
        back();
      } else if (char == _closeBrace) {
        return map;
      } else {
        throw syntaxError("Expected a ',' or '}'");
      }
    }
  }

  /// `JSONArray(JSONTokener)`.
  ///
  /// Two quirks worth knowing: a missing element, as in `[1,,2]`, becomes null;
  /// and unlike objects, arrays don't reject infinity or NaN.
  List<dynamic> readArray() {
    final opener = nextClean();
    final int closer;
    if (opener == _openBracket) {
      closer = _closeBracket;
    } else if (opener == _openParen) {
      closer = _closeParen;
    } else {
      throw syntaxError("A JSONArray text must start with '['");
    }

    final list = <dynamic>[];
    // Java looks for `]` here whichever bracket opened the array.
    if (nextClean() == _closeBracket) return list;
    back();

    while (true) {
      if (nextClean() == _comma) {
        back();
        list.add(null);
      } else {
        back();
        list.add(readValue());
      }

      final char = nextClean();
      if (char == _closeParen || char == _closeBracket) {
        if (closer != char) {
          throw syntaxError("Expected a '${String.fromCharCode(closer)}'");
        }
        return list;
      } else if (char == _comma || char == _semicolon) {
        // A trailing comma before `]` is allowed.
        if (nextClean() == _closeBracket) return list;
        back();
      } else {
        throw syntaxError("Expected a ',' or ']'");
      }
    }
  }
}
