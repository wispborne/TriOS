import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/utils/logging.dart';
import 'package:uuid/uuid.dart';

part 'shared_mod_list.mapper.dart';

/// A shared representation of a mod list that can be used for profiles, exports, or imports
@MappableClass()
class SharedModList with SharedModListMappable {
  const SharedModList({
    required this.id,
    required this.name,
    required this.description,
    required this.mods,
    required this.dateCreated,
    required this.dateModified,
  });

  final String id;
  final String name;
  final String description;
  final List<SharedModVariant> mods;
  final DateTime dateCreated;
  final DateTime dateModified;

  static SharedModList create({
    String? id,
    required String name,
    required List<SharedModVariant> mods,
    String description = '',
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    return SharedModList(
      id: id ?? const Uuid().v4(),
      name: name,
      description: description,
      mods: mods,
      dateCreated: dateCreated ?? DateTime.now(),
      dateModified: dateModified ?? DateTime.now(),
    );
  }
}

/// A lightweight representation of a mod variant for sharing
@MappableClass()
class SharedModVariant with SharedModVariantMappable {
  const SharedModVariant({
    required this.modId,
    this.modName,
    @MappableField(key: 'variantId') required this.smolVariantId,
    @MappableField(hook: VersionHook()) this.versionName,
  });

  SharedModVariant.create({
    required this.modId,
    this.modName,
    @MappableField(hook: VersionHook()) this.versionName,
  }) : smolVariantId = createSmolId(modId, versionName);

  final String modId;
  final String? modName;
  final String smolVariantId;
  final Version? versionName;
}

// Custom share format codec for SharedModList / SharedModVariant.
// Spec:
//   Header: "<name> (=<id>)"
//   Mods per line: "<name> - <version> (<modId>)" | "<name> (<modId>)" |
//                  "<modId> - <version>" | "<modId>"
// Escaping: "\(", "\)", "\\"
extension SharedModListCodec on SharedModList {
  String toShareString({bool includeSeparator = true}) {
    final buf = StringBuffer()..writeln('${_esc(name)} (=${_escHeaderId(id)})');
    if (includeSeparator) buf.writeln('===');

    for (final m in mods) {
      final hasName = (m.modName != null && m.modName!.isNotEmpty);
      final hasVer = (m.versionName != null);
      final line = StringBuffer();

      if (hasName) {
        line.write(_esc(m.modName!));
        if (hasVer) line.write(' - ${_esc(m.versionName!.toString())}');
        line.write(' (${_esc(m.modId)})');
      } else {
        // No name: either "id - version" or just "id"
        line.write(_esc(m.modId));
        if (hasVer) line.write(' - ${_esc(m.versionName!.toString())}');
      }
      buf.writeln(line.toString());
    }
    return buf.toString().trimRight();
  }

  static SharedModList fromShareString(
    String input, {
    required String fallbackId,
    required String fallbackName,
  }) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException('Empty share string');
    }

    // Header: "<name> (=<id>)"
    final headLine = lines.first;
    final headParens = _takeTrailingParens(headLine);
    String id = fallbackId;
    String name = fallbackName;

    if (headParens != null && headParens.content.startsWith('=')) {
      id = _unesc(headParens.content.substring(1));
      name = _unesc(headParens.left.trimRight());
    } else {
      // No valid header; fallbacks in use and treat all lines as mods.
      Fimber.w('Missing or malformed header; using fallbacks');
    }

    // Skip separator lines of '=' exactly, if present.
    var i = (id != fallbackId || name != fallbackName) ? 1 : 0;
    if (i < lines.length && RegExp(r'^=+$').hasMatch(lines[i])) i++;

    // Mods
    final mods = <SharedModVariant>[];
    for (; i < lines.length; i++) {
      final raw = lines[i];
      if (RegExp(r'^=+$').hasMatch(raw)) continue; // stray separators

      final par = _takeTrailingParens(raw);
      final rightId = par?.content != null ? _unesc(par!.content) : null;
      final left = _trimRight(par?.left ?? raw);

      // Split by last " - " for version.
      String? versionStr;
      String leftNoVer = left;
      // Match last occurrence of <ws>-<ws>
      final reg = RegExp(r'\s-\s');
      Match? last;
      for (final m in reg.allMatches(left)) {
        last = m;
      }
      if (last != null) {
        versionStr = _unesc(left.substring(last.end).trim());
        leftNoVer = _trimRight(left.substring(0, last.start));
      }

      String modId;
      String? modName;

      if (rightId != null) {
        // Name is required when parens are present; id comes from parens.
        modId = rightId;
        final nm = _unesc(leftNoVer.trim());
        modName = nm.isNotEmpty ? nm : null;
      } else {
        // No parens: left token is the id, optional version to the right.
        modId = _unesc(leftNoVer.trim());
        modName = null;
      }

      final version = (versionStr != null && versionStr.isNotEmpty)
          ? Version.parse(versionStr)
          : null;

      if (modId.isEmpty) {
        Fimber.w('Skipping line ${i + 1}: empty mod id');
        continue;
      }

      mods.add(
        SharedModVariant(
          modId: modId,
          modName: modName,
          versionName: version,
          smolVariantId: createSmolId(modId, version),
        ),
      );
    }

    return SharedModList(
      id: id,
      name: name,
      mods: mods,
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
      description: '',
    );
  }
}

// ---------- helpers ----------

class _ParensTail {
  final String left;
  final String content;

  _ParensTail(this.left, this.content);
}

/// Returns trailing "(...)" pair if present at end of line, respecting escapes.
/// Example: "Alpha (com.id)" -> left="Alpha ", content="com.id"
_ParensTail? _takeTrailingParens(String s) {
  if (s.isEmpty || s.codeUnitAt(s.length - 1) != ')'.codeUnitAt(0)) return null;

  // Ensure closing ')' is not escaped.
  var i = s.length - 1;
  var backslashes = 0;
  for (var j = i - 1; j >= 0 && s[j] == r'\'; j--) backslashes++;
  if (backslashes.isOdd) return null;

  // Find matching unescaped '(' scanning backward.
  var depth = 0;
  for (var j = s.length - 1; j >= 0; j--) {
    final ch = s[j];
    final prevIsEscape = j > 0 && s[j - 1] == r'\';
    if (ch == ')' && !prevIsEscape) {
      depth++;
    } else if (ch == '(' && !prevIsEscape) {
      depth--;
      if (depth == 0) {
        final left = s.substring(0, j);
        final content = s.substring(j + 1, s.length - 1);
        return _ParensTail(left, content);
      }
    }
  }
  return null;
}

String _escHeaderId(String s) {
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    // If the original text already has a backslash before a paren,
    // keep that single backslash to serve as the escape.
    if (ch == r'\' &&
        i + 1 < s.length &&
        (s[i + 1] == '(' || s[i + 1] == ')')) {
      sb.write(r'\');
      sb.write(s[i + 1]);
      i++; // skip the paren we just wrote
      continue;
    }
    if (ch == r'\') {
      sb.write(r'\\'); // escape literal backslash
      continue;
    }
    if (ch == '(' || ch == ')') {
      sb.write(r'\');
      sb.write(ch); // escape parens that weren't already escaped
      continue;
    }
    sb.write(ch);
  }
  return sb.toString();
}

String _esc(String s) {
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    // Keep an existing escape for parentheses as-is: "\(" or "\)"
    if (ch == r'\' &&
        i + 1 < s.length &&
        (s[i + 1] == '(' || s[i + 1] == ')')) {
      sb.write(r'\');
      sb.write(s[i + 1]);
      i++; // consume the parenthesis too
      continue;
    }
    if (ch == '(' || ch == ')') {
      sb.write(r'\');
      sb.write(ch);
    } else if (ch == r'\') {
      sb.write(r'\\'); // escape a literal backslash
    } else {
      sb.write(ch);
    }
  }
  return sb.toString();
}

String _unesc(String s) {
  final sb = StringBuffer();
  var esc = false;
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (esc) {
      sb.write(ch);
      esc = false;
    } else if (ch == r'\') {
      esc = true;
    } else {
      sb.write(ch);
    }
  }
  if (esc) sb.write(r'\'); // lone trailing backslash kept literal
  return sb.toString();
}

String _trimRight(String s) {
  var end = s.length;
  while (end > 0 && s[end - 1].trim().isEmpty) end--;
  return s.substring(0, end);
}

extension _TakeIf on String {
  String? takeIf(bool Function(String) pred) => pred(this) ? this : null;
}
