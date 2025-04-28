import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/audit_log.dart';
import '../mod_manager/mod_manager_logic.dart';
import '../models/mod.dart';
import '../utils/logging.dart';
import 'app_state.dart';
import 'constants.dart';

class ModVariantsNotifier extends AsyncNotifier<List<ModVariant>> {
  /// Master list of all mod variants found in the mods folder.
  static var _cancelController = StreamController<void>();
  final lock = Mutex();
  bool _initializedFileWatcher = false;
  bool shouldAutomaticallyReloadOnFilesChanged = true;

  @override
  Future<List<ModVariant>> build() async {
    await reloadModVariants();
    if (!_initializedFileWatcher) {
      _initializedFileWatcher = true;
      final modsPath = ref.watch(appSettings.select((value) => value.modsDir));
      if (modsPath != null && modsPath.existsSync()) {
        addModsFolderFileWatcher(modsPath, (List<File> files) {
          if (shouldAutomaticallyReloadOnFilesChanged) {
            Fimber.i("Mods folder changed, invalidating mod variants.");
            ref.invalidateSelf();
          } else {
            Fimber.i(
              "Mods folder changed, but not reloading mod variants because shouldAutomaticallyReloadOnFilesChanged is false.",
            );
          }
        });
      }
    }
    return state.valueOrNull ?? [];
  }

  Future<void> setModVariants(List<ModVariant> newVariants) async {
    await lock.protect(() async {
      state = AsyncValue.data(newVariants);
    });
  }

  Future<void> reloadModVariants({List<ModVariant>? onlyVariants}) async {
    Fimber.i(
      "Loading mod variant data from disk (reading mod_info.json files).",
    );
    final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
    final modsPath = ref.watch(appSettings.select((value) => value.modsDir));
    if (gamePath == null || modsPath == null) {
      return;
    }

    final variants =
        onlyVariants == null
            ? await getModsVariantsInFolder(modsPath.toDirectory())
            : (await Future.wait(
              onlyVariants.map((variant) {
                try {
                  return getModsVariantsInFolder(variant.modFolder);
                } catch (e, st) {
                  Fimber.w(
                    "Error getting mod variants for ${variant.smolId}",
                    ex: e,
                    stacktrace: st,
                  );
                  return Future.value(null);
                }
              }),
            )).nonNulls.flattened.toList();
    // for (var variant in variants) {
    //   watchSingleModFolder(
    //       variant,
    //       (ModVariant variant, File? modInfoFile) =>
    //           Fimber.i("${variant.smolId} mod_info.json file changed: $modInfoFile"));
    // }
    _cancelController.close();
    _cancelController = StreamController<void>();
    // watchModsFolder(
    //   modsPath,
    //   ref,
    //   (event) {
    //     Fimber.i("Mods folder changed, invalidating mod variants.");
    //     ref.invalidateSelf();
    //   },
    //   _cancelController,
    // );

    if (onlyVariants == null) {
      // Replace the entire state with the new data.
      state = AsyncValue.data(variants);
    } else {
      // Update only the variants that were changed, keep the rest of the state.
      final newVariants = state.valueOrNull ?? [];
      for (var variant in onlyVariants) {
        newVariants.removeWhere((it) => it.smolId == variant.smolId);
      }
      newVariants.addAll(variants);
      state = AsyncValue.data(newVariants);
    }

    ModVariant.iconCache.clear();
  }
}
