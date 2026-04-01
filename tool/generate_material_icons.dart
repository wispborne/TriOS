/// Parses Flutter SDK's icons.dart and generates a const map of all base
/// Material icon names to their codePoints.
///
/// Usage: dart run tool/generate_material_icons.dart
///
/// Requires the FLUTTER_ROOT environment variable or auto-detects via `flutter`.
library;

import 'dart:io';

void main() async {
  // Find Flutter SDK icons.dart
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      await _findFlutterRoot();

  if (flutterRoot == null) {
    stderr.writeln('Could not find Flutter SDK. Set FLUTTER_ROOT.');
    exit(1);
  }

  final iconsFile = File(
    '$flutterRoot/packages/flutter/lib/src/material/icons.dart',
  );

  if (!iconsFile.existsSync()) {
    stderr.writeln('icons.dart not found at: ${iconsFile.path}');
    exit(1);
  }

  final lines = iconsFile.readAsLinesSync();
  final pattern = RegExp(
    r"static const IconData (\w+) = IconData\((0x[0-9a-fA-F]+)",
  );

  final entries = <String, String>{};

  for (final line in lines) {
    final match = pattern.firstMatch(line);
    if (match == null) continue;

    final name = match.group(1)!;

    // Skip variant suffixes — keep only base icons.
    if (name.endsWith('_sharp') ||
        name.endsWith('_rounded') ||
        name.endsWith('_outlined')) {
      continue;
    }

    final codePoint = match.group(2)!;
    entries[name] = codePoint;
  }

  // Generate output
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Re-generate: dart run tool/generate_material_icons.dart')
    ..writeln('//')
    ..writeln('// Source: Flutter ${await _flutterVersion()} icons.dart')
    ..writeln('// Total base icons: ${entries.length}')
    ..writeln()
    ..writeln()
    ..writeln('/// Every base Material icon (no _sharp/_rounded/_outlined variants).')
    ..writeln('const List<({String name, int codePoint})> allMaterialIcons = [');

  for (final entry in entries.entries) {
    buffer.writeln("  (name: '${entry.key}', codePoint: ${entry.value}),");
  }

  buffer.writeln('];');

  final outFile = File('lib/mod_tag_manager/material_icons_all.dart');
  outFile.writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote ${entries.length} icons to ${outFile.path}');
}

Future<String?> _findFlutterRoot() async {
  try {
    // Flutter SDK is at the parent of bin/flutter
    final which = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      ['flutter'],
      runInShell: true,
    );
    final path = (which.stdout as String).trim().split('\n').first.trim();
    // path is like .../flutter/bin/flutter — go up two levels
    return File(path).parent.parent.path;
  } catch (_) {
    return null;
  }
}

Future<String> _flutterVersion() async {
  try {
    final result = await Process.run('flutter', ['--version'],
        runInShell: true);
    final first = (result.stdout as String).split('\n').first;
    return first.contains('Flutter') ? first.trim() : 'unknown';
  } catch (_) {
    return 'unknown';
  }
}
