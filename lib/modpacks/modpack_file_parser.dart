import 'dart:convert';

/// The readable transport accepts JSON and Hjson. Keep this separate from the
/// game's JSON parser: Hjson permits newline separators and multiline strings.
/// Syntax: https://hjson.github.io/syntax.html
Object? parseModpackFileText(String text) => _ModpackFileParser(text).parse();

class _ModpackFileParser {
  /// Compiled once: the parser reaches these per key and per value, and the
  /// accepted input runs to megabytes.
  static final RegExp _invalidKey = RegExp(r'[\s{}\[\],]');
  static final RegExp _number = RegExp(
    r'^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$',
  );

  final String text;
  int offset = 0;
  _ModpackFileParser(this.text);
  String get current => offset < text.length ? text[offset] : '';
  bool starts(String value) => text.startsWith(value, offset);
  Never fail(String message) => throw FormatException(message, text, offset);

  Object? parse() {
    space();
    // A file may omit the outermost braces.
    final result = object(0, root: current != '{');
    space();
    if (offset != text.length) fail('Unexpected text after the modpack.');
    return result;
  }

  bool space() {
    var newline = false;
    while (offset < text.length) {
      if (' \t\r\n'.contains(current)) {
        newline |= current == '\n' || current == '\r';
        offset++;
      } else if (starts('#') || starts('//')) {
        while (offset < text.length && current != '\n' && current != '\r') {
          offset++;
        }
      } else if (starts('/*')) {
        final end = text.indexOf('*/', offset + 2);
        if (end < 0) fail('Unclosed comment.');
        newline |= text.substring(offset, end).contains('\n');
        offset = end + 2;
      } else {
        break;
      }
    }
    return newline;
  }

  Map<String, Object?> object(int depth, {bool root = false}) {
    if (depth > 32) fail('The modpack is nested too deeply.');
    if (!root) offset++;
    final result = <String, Object?>{};
    space();
    while (offset < text.length && (root || current != '}')) {
      final String key;
      if (current == '"' || current == "'") {
        key = quoted();
      } else {
        final start = offset;
        while (offset < text.length && current != ':') {
          offset++;
        }
        key = text.substring(start, offset).trim();
        if (key.isEmpty || _invalidKey.hasMatch(key)) {
          fail('Invalid field name.');
        }
      }
      space();
      if (current != ':') fail('Expected a colon after the field name.');
      offset++;
      if (result.containsKey(key)) fail('Duplicate field: $key.');
      result[key] = value(depth + 1);
      final newline = space();
      if (current == ',') {
        offset++;
        space();
      } else if ((!root && current == '}') || (root && current.isEmpty)) {
        break;
      } else if (!newline) {
        fail('Separate fields with a comma or newline.');
      }
    }
    if (!root) {
      if (current != '}') fail('Unclosed object.');
      offset++;
    }
    return result;
  }

  Object? value(int depth) {
    if (depth > 32) fail('The modpack is nested too deeply.');
    space();
    if (current == '{') return object(depth);
    if (current == '[') {
      offset++;
      space();
      final result = <Object?>[];
      while (current != ']') {
        if (current.isEmpty) fail('Unclosed array.');
        result.add(value(depth + 1));
        final newline = space();
        if (current == ',') {
          offset++;
          space();
        } else if (current != ']' && !newline) {
          fail('Separate values with a comma or newline.');
        }
      }
      offset++;
      return result;
    }
    if (starts("'''")) return multiline();
    if (current == '"' || current == "'") return quoted();
    if (current.isEmpty || '{}[],:'.contains(current)) {
      fail('Expected a value.');
    }
    final start = offset;
    while (offset < text.length && current != '\n' && current != '\r') {
      // A primitive ends before a delimiter/comment; otherwise an unquoted
      // string extends to the end of its line, including commas and hashes.
      if (',}]'.contains(current) ||
          starts('#') ||
          starts('//') ||
          starts('/*')) {
        final candidate = text.substring(start, offset).trim();
        if (isPrimitive(candidate)) return jsonDecode(candidate);
      }
      offset++;
    }
    final candidate = text.substring(start, offset).trim();
    return isPrimitive(candidate) ? jsonDecode(candidate) : candidate;
  }

  bool isPrimitive(String text) =>
      const {'true', 'false', 'null'}.contains(text) ||
      _number.hasMatch(text);

  String quoted() {
    final quote = current;
    offset++;
    final result = StringBuffer();
    while (offset < text.length) {
      final char = current;
      offset++;
      if (char == quote) return result.toString();
      if (char.codeUnitAt(0) < 32) {
        fail('Control character in a quoted string.');
      }
      if (char != '\\') {
        result.write(char);
        continue;
      }
      if (current == "'") {
        result.write("'");
        offset++;
        continue;
      }
      final start = offset - 1;
      final end = offset + (current == 'u' ? 5 : 1);
      if (end > text.length) fail('Incomplete string escape.');
      result.write(jsonDecode('"${text.substring(start, end)}"'));
      offset = end;
    }
    fail('Unclosed string.');
  }

  String multiline() {
    final indentation = offset - text.lastIndexOf('\n', offset) - 1;
    offset += 3;
    final end = text.indexOf("'''", offset);
    if (end < 0) fail('Unclosed multiline string.');
    final lines = text
        .substring(offset, end)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    offset = end + 3;
    if (lines.length == 1) return lines.single;
    for (var i = 1; i < lines.length; i++) {
      var trim = 0;
      while (trim < indentation &&
          trim < lines[i].length &&
          ' \t'.contains(lines[i][trim])) {
        trim++;
      }
      lines[i] = lines[i].substring(trim);
    }
    if (lines.first.trim().isEmpty) lines.removeAt(0);
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    return lines.join('\n');
  }
}
