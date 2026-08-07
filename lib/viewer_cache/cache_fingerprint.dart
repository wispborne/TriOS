import 'dart:io';

import 'package:path/path.dart' as p;

/// One directory listing as a parse saw it: whether the listing was recursive,
/// and the sorted names of everything it returned.
///
/// The recursive flag is stored so the check can repeat the same kind of
/// listing. Comparing a flat listing's names against a recursive re-list (or
/// the other way around) would always mismatch.
class RecordedDirectory {
  final bool recursive;

  /// Entry names relative to the listed directory, forward slashes, sorted.
  /// For a recursive listing this holds everything the whole walk returned,
  /// nested paths included.
  final List<String> entryNames;

  const RecordedDirectory({required this.recursive, required this.entryNames});
}

/// What a parse read from one source folder: which directories it listed and
/// which files it read, with each file's last-modified time.
///
/// The next launch compares this against the disk. If every directory lists
/// the same names and every file has the same modified time, parsing again
/// would produce the same result, so the parse is skipped.
///
/// All paths are relative to the source folder with forward slashes, so a mod
/// folder that moves does not invalidate its own cache.
class CacheFingerprint {
  /// Directory path → what its listing returned.
  final Map<String, RecordedDirectory> directories;

  /// File path → last-modified time in milliseconds since epoch.
  final Map<String, int> files;

  const CacheFingerprint({required this.directories, required this.files});

  /// True when every recorded directory still lists the same entry names and
  /// every recorded file still exists with the same modified time. Any
  /// mismatch, missing file, or filesystem error returns false, meaning
  /// "changed — parse again".
  bool isUnchanged(Directory sourceFolder) {
    try {
      for (final entry in directories.entries) {
        final dir = Directory(p.join(sourceFolder.path, entry.key));
        final recorded = entry.value;
        final List<String> currentNames;
        if (!dir.existsSync()) {
          currentNames = const [];
        } else {
          currentNames =
              dir
                  .listSync(recursive: recorded.recursive)
                  .map(
                    (e) => p
                        .relative(e.path, from: dir.path)
                        .replaceAll('\\', '/'),
                  )
                  .toList()
                ..sort();
        }
        if (!_sameNames(currentNames, recorded.entryNames)) return false;
      }
      for (final entry in files.entries) {
        final file = File(p.join(sourceFolder.path, entry.key));
        if (file.lastModifiedSync().millisecondsSinceEpoch != entry.value) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _sameNames(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// A plain map for embedding in the cache envelope's msgpack.
  Map<String, dynamic> toEncodable() => <String, dynamic>{
    'dirs': <String, dynamic>{
      for (final e in directories.entries)
        e.key: <String, dynamic>{
          'recursive': e.value.recursive,
          'entries': e.value.entryNames,
        },
    },
    'files': files,
  };

  /// Returns null on anything malformed, matching how `CacheEnvelope.tryDecode`
  /// handles bad data. A malformed fingerprint must not take the payload down
  /// with it — the caller just parses fresh.
  static CacheFingerprint? tryDecode(dynamic raw) {
    try {
      if (raw is! Map) return null;
      final rawDirs = raw['dirs'];
      final rawFiles = raw['files'];
      if (rawDirs is! Map || rawFiles is! Map) return null;

      final directories = <String, RecordedDirectory>{};
      for (final e in rawDirs.entries) {
        final value = e.value;
        if (value is! Map) return null;
        final recursive = value['recursive'];
        final entries = value['entries'];
        if (recursive is! bool || entries is! List) return null;
        directories[e.key.toString()] = RecordedDirectory(
          recursive: recursive,
          entryNames: entries.map((name) => name.toString()).toList(),
        );
      }

      final files = <String, int>{};
      for (final e in rawFiles.entries) {
        final value = e.value;
        if (value is! int) return null;
        files[e.key.toString()] = value;
      }

      return CacheFingerprint(directories: directories, files: files);
    } catch (_) {
      return null;
    }
  }
}
