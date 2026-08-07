import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/viewer_cache/cache_fingerprint.dart';

/// Collects what a parse touched, so the next launch can tell whether parsing
/// again would find anything new.
///
/// The base class hands one of these to `parseVanilla` and `parseVariant`.
/// The parse calls [directory] after each folder listing and [file] after each
/// file read.
///
/// This records what the parse read *this* time. If a domain's parse changes
/// to read files it did not read before, fingerprints stored by the old code
/// no longer describe it, and an unchanged mod could be skipped when it should
/// be re-read. So a change to which files a parse reads must bump that
/// domain's `schemaVersion` in the same change — that discards the stale
/// fingerprints along with the payloads.
class ParseRecorder {
  ParseRecorder(this.sourceFolder);

  /// The mod folder (or game core folder) this parse is reading from. Recorded
  /// paths are stored relative to it.
  final Directory sourceFolder;

  final Map<String, RecordedDirectory> _directories = {};
  final Map<String, int> _files = {};

  /// Call right after listing [dir]. Pass the entries the listing returned,
  /// before any filtering. For a recursive listing, pass everything the whole
  /// walk returned and set [recursive] — the names are stored under [dir], so
  /// a file added in a nested subfolder still changes the fingerprint. A
  /// folder that does not exist is recorded with an empty entry list, so
  /// creating it later counts as a change.
  ///
  /// A parse can list the same folder twice, once flat and once recursively
  /// (weapons does, for `.wpn` and `.proj` files). The recursive record is
  /// kept, because it sees everything the flat listing sees and more.
  void directory(
    Directory dir,
    Iterable<FileSystemEntity> entries, {
    bool recursive = false,
  }) {
    final key = _relativeToSource(dir.path);
    final existing = _directories[key];
    if (existing != null && existing.recursive && !recursive) return;
    final names =
        entries
            .map((e) => p.relative(e.path, from: dir.path).replaceAll('\\', '/'))
            .toList()
          ..sort();
    _directories[key] = RecordedDirectory(
      recursive: recursive,
      entryNames: names,
    );
  }

  /// Call when a file is read. Reads its last-modified time. A file that has
  /// vanished between read and record is skipped rather than throwing.
  void file(File file) {
    try {
      _files[_relativeToSource(file.path)] = file
          .lastModifiedSync()
          .millisecondsSinceEpoch;
    } on FileSystemException {
      // The file was deleted while the parse was running. Leaving it out means
      // the fingerprint check next launch sees a changed directory listing (or
      // never knows about the file), and either way parses fresh.
    }
  }

  /// The fingerprint to store with the cache write. Null when the parse
  /// recorded nothing — a parse that doesn't call the recorder must not get a
  /// fingerprint, because an empty fingerprint would match every launch and
  /// the domain would never re-parse.
  CacheFingerprint? build() {
    if (_directories.isEmpty && _files.isEmpty) return null;
    return CacheFingerprint(
      directories: Map.of(_directories),
      files: Map.of(_files),
    );
  }

  String _relativeToSource(String path) =>
      p.relative(path, from: sourceFolder.path).replaceAll('\\', '/');
}
