import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

/// Remembers the mod list from the last time TriOS read the mods folder, so the
/// next launch can show mods straight away instead of waiting for the folder
/// scan to finish.
///
/// This is only a head start. The scan still runs on every launch and its
/// result replaces whatever came out of here, so a stale file means showing the
/// wrong list for a second, not forever. Anything that doesn't read back
/// cleanly is deleted and ignored.
class ModListCache {
  static const fileName = 'trios_mod_list_cache.json';

  /// Where the list is saved, or null if there's nowhere to save it yet.
  ///
  /// The folder TriOS keeps its data in is found during startup. Anything
  /// running before that — or a test that never sets it — gets null here and
  /// skips the cache entirely rather than failing.
  File? get file {
    try {
      return File(p.join(Constants.cacheDirPath.path, fileName));
    } catch (_) {
      return null;
    }
  }

  /// Writes run one at a time. A full scan and a file-watcher reload can both
  /// finish close together, and two writes at once would interleave.
  Future<void> _writeChain = Future.value();

  /// Returns the mods found last launch, or null if there's nothing usable
  /// saved.
  ///
  /// [modsFolder] is the folder the mods would be scanned from now. A saved
  /// list from a different folder is thrown away — that's someone having
  /// pointed TriOS at another game install since last time.
  Future<List<ModVariant>?> read(Directory modsFolder) async {
    final cacheFile = file;
    if (cacheFile == null) return null;
    try {
      if (!await cacheFile.exists()) return null;

      final json =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;

      final savedModsFolder = json['modsFolder'] as String?;
      if (savedModsFolder == null ||
          p.canonicalize(savedModsFolder) !=
              p.canonicalize(modsFolder.absolute.path)) {
        Fimber.i(
          'Saved mod list is for a different mods folder, ignoring it.',
        );
        await delete();
        return null;
      }

      final variants = (json['variants'] as List)
          .map((it) => ModVariantMapper.fromMap(it as Map<String, dynamic>))
          .toList();

      Fimber.i(
        'Showing ${variants.length} mod(s) from the last launch while the '
        'mods folder is read.',
      );
      return variants;
    } catch (e, st) {
      Fimber.w(
        "Couldn't read the saved mod list, deleting it.",
        ex: e,
        stacktrace: st,
      );
      await delete();
      return null;
    }
  }

  /// Saves [variants] for the next launch. Failures are logged and dropped —
  /// not being able to save this only costs a slower next startup.
  Future<void> write(List<ModVariant> variants, Directory modsFolder) {
    final task = _writeChain.then((_) => _write(variants, modsFolder));
    // Keep one write failing from breaking every write after it.
    _writeChain = task.catchError((Object _) {});
    return task;
  }

  Future<void> _write(List<ModVariant> variants, Directory modsFolder) async {
    final cacheFile = file;
    if (cacheFile == null) return;
    try {
      final cacheDir = Constants.cacheDirPath;
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final json = jsonEncode({
        'modsFolder': modsFolder.absolute.path,
        'variants': variants.map((it) => it.toMap()).toList(),
      });

      // Write to a temp file and rename it into place, so quitting partway
      // through can't leave a half-written file to be read next launch.
      final tempFile = File('${cacheFile.path}.tmp');
      await tempFile.writeAsString(json, flush: true);
      await tempFile.rename(cacheFile.path);
    } catch (e, st) {
      Fimber.w("Couldn't save the mod list.", ex: e, stacktrace: st);
    }
  }

  Future<void> delete() async {
    final cacheFile = file;
    if (cacheFile == null) return;
    try {
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
    } catch (e) {
      Fimber.w("Couldn't delete the saved mod list: $e");
    }
  }
}
