/// Finds a file the way the game does: a path written in a data file is a
/// request, not a location. Every enabled mod is asked in load order, then the
/// game core, and the first source that actually has the file wins.
///
/// Checked against decompiled Starsector 0.98a-RC8: `com.fs.util.C`,
/// `StarfarerLauncher`.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/utils/extensions.dart';

/// One place a file can come from: a mod folder, or the game core folder.
class GameFileSource {
  /// Absolute path to the mod folder (or the game core folder).
  final String folderPath;

  /// The image files this source ships under `graphics/`: lowercased relative
  /// path → the path as it is written on disk.
  ///
  /// Lookups ignore case, but the value keeps the real spelling so the built
  /// path still works on case-sensitive file systems.
  final Map<String, String> imageFiles;

  const GameFileSource({required this.folderPath, required this.imageFiles});
}

/// Turns a path out of a data file into a lookup key: forward slashes,
/// lowercase, no leading `./` or `/`. Returns null for a blank path.
String? normalizeGamePath(String? rawPath) {
  if (rawPath == null) return null;
  var path = rawPath.trim().replaceAll('\\', '/').toLowerCase();
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  return path.isEmpty ? null : path;
}

/// Resolves game-relative paths to real files across the whole source stack.
///
/// Build one per merge pass and reuse it: answers are remembered, and the only
/// disk reads are the fallback probes for paths outside `graphics/`.
class GameFileResolver {
  /// Sources in load order: mods first (alphabetically first mod asked first),
  /// the game core last.
  final List<GameFileSource> sources;

  final Map<String, String?> _answers = {};

  GameFileResolver(this.sources);

  /// A resolver with nothing in it. Everything resolves to null.
  static GameFileResolver get empty => GameFileResolver(const []);

  /// The absolute path of the first source that has [relativePath], or null
  /// when no source has it (every viewer treats null as "no image").
  String? resolve(String? relativePath) {
    final key = normalizeGamePath(relativePath);
    if (key == null) return null;
    if (_answers.containsKey(key)) return _answers[key];
    final answer = _find(key);
    _answers[key] = answer;
    return answer;
  }

  String? _find(String key) {
    if (key.startsWith('graphics/')) {
      for (final source in sources) {
        final onDiskPath = source.imageFiles[key];
        if (onDiskPath != null) return _join(source.folderPath, onDiskPath);
      }
      return null;
    }

    // Outside `graphics/` is rare but legal, and not indexed, so ask the disk.
    for (final source in sources) {
      final candidate = _join(source.folderPath, key);
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  String _join(String folderPath, String relativePath) =>
      p.join(folderPath, relativePath).toFile().normalize.path;
}
