import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/debouncer.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../utils/logging.dart';

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
    try {
      await reloadModVariants();
    } catch (e, stacktrace) {
      state = AsyncValue.error(e, stacktrace);
      Fimber.e("Failed to reload mod variants", ex: e, stacktrace: stacktrace);
    }

    ref.listen(appSettings.select((value) => value.modsDir), (previous, next) {
      if (previous != next) {
        Fimber.i("Mods directory changed, resetting file watcher.");
        _initializedFileWatcher = false;
      }
    });

    if (!_initializedFileWatcher) {
      _initializedFileWatcher = true;
      final modsPath = ref.watch(appSettings.select((value) => value.modsDir));

      if (modsPath != null && modsPath.existsSync()) {
        addModsFolderFileWatcher(modsPath, (List<File> files) {
          _fileWatcherReloadDebouncer.debounce(onModsFolderChanged);
        });
      }
    }
    return state.valueOrNull ?? [];
  }

  Future onModsFolderChanged() async {
    if (shouldAutomaticallyReloadOnFilesChanged && !_isReloadingInternal) {
      Fimber.i("Mods folder changed, invalidating mod variants.");
      ref.invalidateSelf();
    } else if (!shouldAutomaticallyReloadOnFilesChanged) {
      Fimber.i(
        "Mods folder changed, but not reloading mod variants because shouldAutomaticallyReloadOnFilesChanged is false.",
      );
    } else if (_isReloadingInternal) {
      Fimber.i(
        "Mods folder changed, but not reloading mod variants because _isReloadingInternal is true.",
      );
    }
  }

  Future<void> setModVariants(List<ModVariant> newVariants) async {
    await _lock.protect(() async {
      state = AsyncValue.data(newVariants);
    });
  }

  Future<void> reloadModVariants({List<ModVariant>? onlyVariants}) async {
    _isReloadingInternal = true;
    try {
      Fimber.i(
        "Loading mod variant data from disk (reading mod_info.json files).${(onlyVariants == null) ? "" : " Only reloading ${onlyVariants.joinToString(transform: (it) => it.smolId)}"}",
      );
      final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
      final modsPath = ref.watch(appSettings.select((value) => value.modsDir));
      if (gamePath == null || modsPath == null) {
        return;
      }

      final variants = onlyVariants == null
          ? await getModsVariantsInFolder(
              modsPath.toDirectory(),
              searchRootFolder: false,
            )
          : (await Future.wait(
              onlyVariants.map((variant) {
                try {
                  return getModsVariantsInFolder(
                    variant.modFolder,
                    searchRootFolder: true,
                  );
                } catch (e, st) {
                  Fimber.w(
                    "Error getting mod variants for ${variant.smolId}",
                    ex: e,
                    stacktrace: st,
                  );
                  return Future<List<ModVariant>?>.value(null);
                }
              }),
            )).nonNulls.flattened.toList();

      if (onlyVariants == null) {
        // Replace the entire state with the new data.
        state = AsyncValue.data(variants);
      } else {
        // Update only the variants that were changed, keep the rest of the state.
        final newVariants = state.valueOrNull?.toList() ?? [];
        for (var variant in onlyVariants) {
          newVariants.removeWhere((it) => it.smolId == variant.smolId);
        }
        newVariants.addAll(variants);
        state = AsyncValue.data(newVariants);
      }

      ModVariant.iconCache.clear();
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
