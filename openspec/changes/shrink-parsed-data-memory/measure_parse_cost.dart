// Throwaway measurement: how much memory the retained raw mod data actually
// costs, and how much cheaper layouts would save.
//
//   dart measure_parse_cost.dart <mode>
// modes: baseline | current | intern | rowlist | internrowlist
//
// "current" mirrors TriOS today: every CSV row and every .ship/.wpn/.proj/
// .skin file becomes a Map<String, dynamic>, and all of it is held at once.
//
// Self-contained on purpose — importing package:trios drags in its FFI
// bindings, which plain `dart` cannot compile.

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

const gameFolder = r'C:\Program Files (x86)\Fractal Softworks\Starsector';

final _pool = <String, String>{};
String _intern(String s) => s.length > 64 ? s : (_pool[s] ??= s);

bool internOn = false;
bool rowListOn = false;
bool dropNullsOn = false;

/// A CSV row as a plain values list over a header index shared by every row in
/// the file, instead of one Map per row.
class RowList {
  final Map<String, int> columns;
  final List<Object?> values;
  RowList(this.columns, this.values);
}

int rssMb() => (ProcessInfo.currentRss / 1048576).round();

final held = <Object>[];
int csvRows = 0;
int jsonOk = 0;
int jsonFailed = 0;

String readText(File f) {
  try {
    return f.readAsStringSync();
  } catch (_) {
    try {
      return latin1.decode(f.readAsBytesSync());
    } catch (_) {
      return '';
    }
  }
}

Iterable<Directory> sourceRoots() {
  final roots = <Directory>[Directory('$gameFolder\\starsector-core')];
  final mods = Directory('$gameFolder\\mods');
  if (mods.existsSync()) {
    for (final m in mods.listSync()) {
      if (m is Directory) roots.add(m);
    }
  }
  return roots;
}

// ── CSV ──────────────────────────────────────────────────────────────────────

Object? typedValue(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString();
  if (s.trim().isEmpty) return null;
  final upper = s.toUpperCase();
  if (upper == 'TRUE') return true;
  if (upper == 'FALSE') return false;
  final n = num.tryParse(s);
  if (n != null) return n;
  return internOn ? _intern(s) : s;
}

/// Drop `#` comments that fall outside quoted fields.
String stripCsvComments(String content) {
  final out = StringBuffer();
  var inQuotes = false;
  var inComment = false;
  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (c == '\n') {
      if (!inQuotes) {
        inComment = false;
        out.write('\n');
      } else {
        out.write('\n');
      }
      continue;
    }
    if (inComment) continue;
    if (c == '"') inQuotes = !inQuotes;
    if (c == '#' && !inQuotes) {
      inComment = true;
      continue;
    }
    out.write(c);
  }
  return out.toString();
}

void parseCsvFiles(String subPath, String fileName) {
  for (final root in sourceRoots()) {
    final f = File('${root.path}\\$subPath\\$fileName');
    if (!f.existsSync()) continue;
    final text = readText(f);
    if (text.isEmpty) continue;
    List<List<dynamic>> raw;
    try {
      raw = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(stripCsvComments(text));
    } catch (_) {
      continue;
    }
    if (raw.isEmpty) continue;
    final headers = [
      for (final h in raw.first)
        internOn
            ? _intern(h.toString().toLowerCase().trim())
            : h.toString().toLowerCase().trim(),
    ];
    final columnIndex = <String, int>{
      for (var i = 0; i < headers.length; i++) headers[i]: i,
    };
    for (var r = 1; r < raw.length; r++) {
      final row = raw[r];
      if (row.isEmpty) continue;
      csvRows++;
      if (rowListOn) {
        held.add(
          RowList(columnIndex, [
            for (var i = 0; i < headers.length; i++)
              typedValue(i < row.length ? row[i] : null),
          ]),
        );
      } else {
        final map = <String, dynamic>{};
        for (var i = 0; i < headers.length; i++) {
          final v = typedValue(i < row.length ? row[i] : null);
          if (dropNullsOn && v == null) continue;
          map[headers[i]] = v;
        }
        held.add(map);
      }
    }
  }
}

// ── JSON-ish .ship / .skin / .wpn / .proj ────────────────────────────────────

final _trailingComma = RegExp(r',(\s*[}\]])');
final _unquotedKey = RegExp(r'([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*:)');
final _bareWord = RegExp(r'([\[,:]\s*)([A-Za-z_][A-Za-z0-9_.]*)(\s*[,\]}])');
final _controlChars = RegExp('[\u0000-\u0008\u000b\u000c\u000e-\u001f]');
const _jsonKeywords = {'true', 'false', 'null'};

Map<String, dynamic>? parseStarsectorish(String raw) {
  var text = LineSplitter.split(raw).map((l) => l.split('#').first).join('\n');
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {}
  text = text.replaceAll(_controlChars, '');
  text = text.replaceAllMapped(_unquotedKey, (m) => '${m[1]}"${m[2]}"${m[3]}');
  for (var i = 0; i < 3; i++) {
    text = text.replaceAllMapped(_bareWord, (m) {
      final word = m[2]!;
      if (_jsonKeywords.contains(word.toLowerCase())) return m[0]!;
      return '${m[1]}"$word"${m[3]}';
    });
  }
  for (var i = 0; i < 3; i++) {
    text = text.replaceAllMapped(_trailingComma, (m) => m[1]!);
  }
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Object? internTree(Object? node) {
  if (node is Map) {
    final out = <String, dynamic>{};
    node.forEach((k, v) => out[_intern(k as String)] = internTree(v));
    return out;
  }
  if (node is List) return [for (final v in node) internTree(v)];
  if (node is String) return _intern(node);
  return node;
}

void parseJsonFiles(String subPath, String extension) {
  for (final root in sourceRoots()) {
    final dir = Directory('${root.path}\\$subPath');
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync()) {
      if (e is! File || !e.path.toLowerCase().endsWith(extension)) continue;
      final text = readText(e);
      if (text.isEmpty) continue;
      final map = parseStarsectorish(text);
      if (map == null) {
        jsonFailed++;
        continue;
      }
      jsonOk++;
      held.add(internOn ? internTree(map) as Object : map);
    }
  }
}

void main(List<String> args) {
  final mode = args.isEmpty ? 'current' : args.first;
  internOn = mode.startsWith('intern');
  rowListOn = mode.endsWith('rowlist');
  dropNullsOn = mode.contains('dropnull');

  final startRss = rssMb();
  final sw = Stopwatch()..start();

  if (mode != 'baseline') {
    parseCsvFiles('data\\hulls', 'ship_data.csv');
    parseCsvFiles('data\\weapons', 'weapon_data.csv');
    parseCsvFiles('data\\hullmods', 'hull_mods.csv');
    parseCsvFiles('data\\strings', 'descriptions.csv');
    parseCsvFiles('data\\hulls', 'wing_data.csv');
    parseCsvFiles('data\\shipsystems', 'ship_systems.csv');

    parseJsonFiles('data\\hulls', '.ship');
    parseJsonFiles('data\\hulls\\skins', '.skin');
    parseJsonFiles('data\\weapons', '.wpn');
    parseJsonFiles('data\\weapons\\proj', '.proj');
  }

  sw.stop();
  final anchor = held.length;
  stdout.writeln(
    'mode=${mode.padRight(14)} rss=${rssMb().toString().padLeft(4)}MB  '
    '(start ${startRss}MB)  csvRows=$csvRows  jsonOk=$jsonOk  '
    'jsonFailed=$jsonFailed  held=$anchor  pool=${_pool.length}  '
    'parse=${sw.elapsedMilliseconds}ms',
  );
}
