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
    this.id,
    this.name,
    this.description,
    required this.mods,
    this.dateCreated,
    this.dateModified,
  });

  final String? id;
  final String? name;
  final String? description;
  final List<SharedModVariant> mods;
  final DateTime? dateCreated;
  final DateTime? dateModified;

  static SharedModList create({
    String? id,
    String? name,
    required List<SharedModVariant> mods,
    String description = '',
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    return SharedModList(
      id: id,
      name: name,
      description: description,
      mods: mods,
      dateCreated: dateCreated,
      dateModified: dateModified,
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
//   Header: "<name> (<id>)"
//   Separator: "---"
//   Mods per line: "<name> v<version> (<modId>)"
//                  If name is missing, we use "<modId> v<version> (<modId>)"
// Escaping: "\(", "\)", "\\", and "\ v" for literal " v" inside versions.
// Parsing notes:
//   - Work backwards: ID is the trailing "(...)".
//   - Version is detected by the last unescaped " v" before the ID.
//   - Everything to the left of that delimiter is the (optional) name.
extension SharedModListCodec on SharedModList {
  String toShareString() {
    final buf = StringBuffer();
    final hasNameOrId = name != null || id != null;

    if (hasNameOrId) {
      buf.writeln(
        '${_esc(name ?? '')} (${_escHeaderId(id ?? const Uuid().v4())})',
      );
      buf.writeln('---');
    }

    for (final m in mods) {
      final hasName = (m.modName != null && m.modName!.isNotEmpty);
      final hasVer = (m.versionName != null);
      final line = StringBuffer();

      // Always include something on the left for readability:
      // prefer name; fall back to modId if name is missing.
      line.write(_esc(hasName ? m.modName! : m.modId));

      if (hasVer) {
        // Version delimiter is " v" and we must escape any literal " v" in the version itself.
        line.write(' v${_escVersion(m.versionName!.toString())}');
      } else {
        // Version is required in this format to ensure unambiguous parsing.
        // If absent, emit a placeholder that will fail parsing back (consistent with parser expectations).
        line.write(' v'); // creates a guaranteed parse error if used
      }

      // ID is always at the end, in parenthesis.
      line.write(' (${_esc(m.modId)})');

      buf.writeln(line.toString());
    }
    return buf.toString().trimRight();
  }

  static SharedModList fromShareString(
    String input, {
    required String fallbackProfileId,
    required String fallbackProfileName,
  }) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException('Empty share string');
    }

    // Header: "<name> (<id>)" ONLY if followed by a hyphen separator line.
    final headLine = lines.first;
    final headParens = _takeTrailingParens(headLine);
    String id = fallbackProfileId;
    String name = fallbackProfileName;

    bool headerAccepted = false;
    if (headParens != null) {
      // Look ahead for a hyphen separator ('---', or any run of '-')
      final hasHyphenSeparator =
          lines.length > 1 && RegExp(r'^-+$').hasMatch(lines[1]);
      if (hasHyphenSeparator) {
        id = _unesc(headParens.content);
        name = _unesc(headParens.left.trimRight());
        headerAccepted = true;
      } else {
        // No separator after header-like line; treat entire input as mods.
        Fimber.w('Header-like first line without separator; treating as mods');
      }
    } else {
      // No valid header; fallbacks in use and treat all lines as mods.
      Fimber.w('Missing or malformed header; using fallbacks');
    }

    // Start index: skip header and the following hyphen separator if we accepted the header.
    var i = headerAccepted ? 2 : 0;

    // Mods
    final mods = <SharedModVariant>[];
    for (; i < lines.length; i++) {
      final raw = lines[i];
      if (RegExp(r'^-+$').hasMatch(raw)) continue; // stray separators

      // Extract trailing "(modId)"
      final par = _takeTrailingParens(raw);
      final rightId = par?.content != null ? _unesc(par!.content) : null;
      if (rightId == null || rightId.trim().isEmpty) {
        throw FormatException(
          'Line ${i + 1}: missing mod id in parentheses at end',
        );
      }

      final left = _trimRight(par!.left);

      // Find the last unescaped " v" delimiter (space followed by 'v').
      final delimIdx = _lastUnescapedVersionDelimiter(left);
      if (delimIdx == null) {
        throw FormatException(
          'Line ${i + 1}: missing version (expected " v<version>") for "$rightId"',
        );
      }

      final namePart = left.substring(
        0,
        delimIdx,
      ); // up to the space before 'v'
      final versionPart = left.substring(delimIdx + 1); // starts with 'v...'

      final versionStr = _unesc(versionPart.trim());
      if (versionStr.isEmpty || !versionStr.startsWith('v')) {
        throw FormatException(
          'Line ${i + 1}: invalid version "$versionStr" for "$rightId"',
        );
      }

      final version = Version.parse(versionStr.substring(1));

      final nm = _unesc(namePart.trimRight());
      final modName = nm.isNotEmpty ? nm : null;

      mods.add(
        SharedModVariant(
          modId: rightId,
          modName: modName,
          versionName: version,
          smolVariantId: createSmolId(rightId, version),
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

/// Escape for versions:
/// - First escape parens and backslashes (same as _esc)
/// - Then escape any literal " v" by turning it into "\ v"
String _escVersion(String s) {
  final base = _esc(s);
  // Escape the delimiter occurrence inside version text
  // We only target space followed by 'v'
  final sb = StringBuffer();
  for (var i = 0; i < base.length; i++) {
    final ch = base[i];
    if (ch == ' ' && i + 1 < base.length && base[i + 1] == 'v') {
      // ensure it's not already escaped with a backslash just before the space
      final prevIsEscape = i > 0 && base[i - 1] == r'\';
      if (!prevIsEscape) {
        sb.write(r'\'); // add escape before space
      }
      sb.write(' ');
      continue;
    }
    sb.write(ch);
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

/// Find the index of the space that begins the last unescaped " v" sequence.
/// Returns null if not found. The returned index is the position of the space.
/// Example: "Name v1.2" -> returns index of ' ' before 'v'
int? _lastUnescapedVersionDelimiter(String s) {
  for (var i = s.length - 2; i >= 0; i--) {
    // need at least " v"
    if (s[i] == ' ' && s[i + 1] == 'v') {
      // Check that this space wasn't escaped as "\ "
      final prevIsEscape = i > 0 && s[i - 1] == r'\';
      if (!prevIsEscape) return i;
    }
  }
  return null;
}

String _trimRight(String s) {
  var end = s.length;
  while (end > 0 && s[end - 1].trim().isEmpty) end--;
  return s.substring(0, end);
}

extension _TakeIf on String {
  String? takeIf(bool Function(String) pred) => pred(this) ? this : null;
}
