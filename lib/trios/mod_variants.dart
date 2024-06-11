import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../utils/logging.dart';

class ModVariantsNotifier extends AsyncNotifier<List<ModVariant>> {
  /// Master list of all mod variants found in the mods folder.
  static var _cancelController = StreamController<void>();
  final lock = Mutex();

  @override
  Future<List<ModVariant>> build() async {
    await reloadModVariants();
    return state.valueOrNull ?? [];
  }

  Future<void> setModVariants(List<ModVariant> newVariants) async {
    await lock.protect(() async {
      state = AsyncValue.data(newVariants);
    });
  }

  Future<void> reloadModVariants() async {
    Fimber.i(
        "Loading mod variant data from disk (reading mod_info.json files).");
    final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
    final modsPath = ref.watch(appSettings.select((value) => value.modsDir));
    if (gamePath == null || modsPath == null) {
      return;
    }

    final variants = await getModsVariantsInFolder(modsPath.toDirectory());
    // for (var variant in variants) {
    //   watchSingleModFolder(
    //       variant,
    //       (ModVariant variant, File? modInfoFile) =>
    //           Fimber.i("${variant.smolId} mod_info.json file changed: $modInfoFile"));
    // }
    _cancelController.close();
    _cancelController = StreamController<void>();
    watchModsFolder(
      modsPath,
      ref,
      (event) {
        Fimber.i("Mods folder changed, invalidating mod variants.");
        ref.invalidateSelf();
      },
      _cancelController,
    );

    state = AsyncValue.data(variants);
  }
}
