import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/debouncer.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../utils/logging.dart';
import 'app_state.dart';

/// Master list of all mod variants found in the mods folder.
class ModVariantsNotifier extends AsyncNotifier<List<ModVariant>> {
  final _lock = Mutex();
  bool _initializedFileWatcher = false;
  final Debouncer _fileWatcherReloadDebouncer = Debouncer(
    duration: Duration(milliseconds: 250),
  );
  bool shouldAutomaticallyReloadOnFilesChanged = true;
  bool _isReloadingInternal = false;

  @override
  Future<List<ModVariant>> build() async {
    // if (state.value == null && !state.hasError) {
    try {
      await reloadModVariants();
    } catch (e, stacktrace) {
      state = AsyncValue.error(e, stacktrace);
      Fimber.e("Failed to reload mod variants", ex: e, stacktrace: stacktrace);
    }
    // }

    ref.listen(AppState.modsFolder, (previous, next) {
      if (previous != next) {
        Fimber.i("Mods directory changed, resetting file watcher.");
        _initializedFileWatcher = false;
      }
    });

    if (!_initializedFileWatcher) {
      _initializedFileWatcher = true;
      final modsPath = ref.watch(AppState.modsFolder).value;

      if (modsPath != null && modsPath.existsSync()) {
        addModsFolderFileWatcher(modsPath, (List<File> files) {
          _fileWatcherReloadDebouncer.debounce(() {
            onModsFolderChanged(files);
            return null;
          });
        });
      }
    }
    return state.value ?? [];
  }

  Future onModsFolderChanged(List<File> files) async {
    if (!shouldAutomaticallyReloadOnFilesChanged && !_isReloadingInternal) {
      Fimber.i(
        "Mods folder changed, reloading mods for files: ${files.joinToString(transform: (it) => it.path)}",
      );
      // Fimber.i("Mods folder changed, invalidating mod variants.");
      // ref.invalidateSelf();
      // return;
    } else if (!shouldAutomaticallyReloadOnFilesChanged) {
      Fimber.i(
        "Mods folder changed, but not reloading mod variants because shouldAutomaticallyReloadOnFilesChanged is false.",
      );
      return;
    } else if (_isReloadingInternal) {
      Fimber.i(
        "Mods folder changed, but not reloading mod variants because _isReloadingInternal is true.",
      );
      return;
    }

    final modsDir = ref.read(AppState.modsFolder).value;
    if (modsDir == null) return;

    final touchedTopLevelNames = files
        .map((f) {
          final rel = p.relative(f.path, from: modsDir.path);
          if (rel.isEmpty || rel == ".") return null;
          final parts = p.split(rel);
          if (parts.isEmpty) return null;
          final first = parts.first;
          if (first == "." || first == "..") return null;
          return first;
        })
        .whereType<String>()
        .toSet();

    if (touchedTopLevelNames.isEmpty) {
      // Couldn't determine; safest fallback.
      ref.invalidateSelf();
      return;
    }

    final touchedFolders = touchedTopLevelNames
        .map((name) => modsDir.resolve(name).toDirectory())
        .toList();

    await reloadModVariantsFromFolders(onlyFolders: touchedFolders);
  }

  Future<void> setModVariants(List<ModVariant> newVariants) async {
    await _lock.protect(() async {
      state = AsyncValue.data(newVariants);
    });
  }

  Future<void> reloadModVariants({List<ModVariant>? onlyVariants}) async {
    // Delegate to folder-based method (variants -> folders)
    await reloadModVariantsFromFolders(
      onlyFolders: onlyVariants?.map((v) => v.modFolder).toList(),
    );
  }

  /// Folder-based reload entrypoint (useful for file watchers).
  Future<void> reloadModVariantsFromFolders({
    List<Directory>? onlyFolders,
  }) async {
    _isReloadingInternal = true;
    try {
      Fimber.i(
        "Loading mod variant data from disk (reading mod_info.json files)."
        "${(onlyFolders == null) ? "" : " Only reloading ${onlyFolders.map((d) => d.name).join(", ")}"}",
      );

      final gamePath = ref.watch(AppState.gameFolder).value;
      final modsPath = ref.watch(AppState.modsFolder).value;
      if (gamePath == null || modsPath == null) {
        return;
      }

      final folders = onlyFolders
          ?.where((d) => d.existsSync())
          .toList(growable: false);

      final variants = folders == null
          ? await getModsVariantsInFolder(
              modsPath.toDirectory(),
              searchRootFolder: false,
            )
          : (await Future.wait(
              folders.map((folder) async {
                try {
                  return getModsVariantsInFolder(
                    folder,
                    searchRootFolder: true,
                  );
                } catch (e, st) {
                  Fimber.w(
                    "Error getting mod variants for folder ${folder.path}",
                    ex: e,
                    stacktrace: st,
                  );
                  return Future<List<ModVariant>?>.value(null);
                }
              }),
            )).nonNulls.flattened.toList();

      if (folders == null) {
        state = AsyncValue.data(variants);
        ModVariant.iconCache.clear();
      } else {
        // Remove any variants whose modFolder was reloaded, then add updated ones.
        final newVariants = state.value?.toList() ?? [];
        final folderPaths = folders.map((d) => d.path).toSet();

        newVariants.removeWhere(
          (it) => folderPaths.contains(it.modFolder.path),
        );
        newVariants.addAll(variants);

        state = AsyncValue.data(newVariants);
        // Remove icons of mods/variants that changed.
        ModVariant.iconCache.removeWhere(
          (key, value) => variants.any((variant) => variant.modInfo.id == key),
        );
      }
    } finally {
      _isReloadingInternal = false;
    }
  }

  Future<List<ModVariant>> getModsVariantsInFolder(
    Directory modsFolder, {
    required bool searchRootFolder,
  }) async {
    final mods = <ModVariant?>[];
    if (!modsFolder.existsSync()) return [];
    final gameCoreFolder = ref.watch(AppState.gameCoreFolder).value;
    if (gameCoreFolder == null) return [];

    final folders = modsFolder.listSync().whereType<Directory>().toList();

    // If we're searching the game's mods folder, we don't want to include `mods/mod_info.json` (invalid mod, and dangerous because its parent folder is `mods`).
    // But if we're searching just one mod's folder, then yeah we do expect there to be a mod_info.json` file at the root.
    if (searchRootFolder) {
      folders.add(modsFolder);
    }

    for (final modFolder in folders) {
      try {
        var progressText = StringBuffer();
        var modInfo = await getModInfo(modFolder, progressText);
        if (modInfo == null) {
          continue;
        }

        final modVariant = ModVariant(
          modInfo: modInfo,
          modFolder: modFolder,
          versionCheckerInfo: getVersionFile(
            modFolder,
          )?.let((it) => getVersionCheckerInfo(it)),
          hasNonBrickedModInfo: await modFolder
              .resolve(Constants.unbrickedModInfoFileName)
              .exists(),
          gameCoreFolder: gameCoreFolder,
        );

        Fimber.d("Found mod ${modVariant.smolId} in folder ${modFolder.name}");

        // Screenshot mode
        // if (modVariant.modInfo.isCompatibleWithGame("0.97a-RC10") == GameCompatibility.compatible || (Random().nextBool() && Random().nextBool())) {
        mods.add(modVariant);
        // }
      } catch (e, st) {
        Fimber.w("Unable to read mod in ${modFolder.absolute}. ($e)\n$st");
      }
    }

    return mods.whereType<ModVariant>().toList();
  }
}
