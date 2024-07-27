import 'dart:async';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/mod_manager_logic.dart';
import '../models/mod.dart';
import '../utils/logging.dart';
import 'app_state.dart';
import 'constants.dart';

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
  // TODO should move all this into modManager at some point.

  Future<void> changeActiveModVariant(Mod mod, ModVariant? modVariant,
      {bool validateDependencies = true}) async {
    Fimber.i(
        "Changing active variant of ${mod.id} to ${modVariant?.smolId}. (current: ${mod.findFirstEnabled?.smolId}).");

    final modVariantParentModId = modVariant?.modInfo;
    if (modVariantParentModId != null && mod.id != modVariantParentModId.id) {
      final errMsg =
          "Mod variant ${modVariant?.smolId} does not belong to mod ${mod.id}.";
      Fimber.e(errMsg);
      throw Exception(errMsg);
    }

    // Optimization: If the mod variant is already enabled, don't do anything.
    if (modVariant != null && mod.isEnabled(modVariant)) {
      // Ensure that this is the only active variant.
      // If there are somehow more than one active variant for the mod, don't return here,
      // run the rest of the method to clean that up.
      if (mod.modVariants.countWhere((it) => mod.isEnabled(it)) <= 1) {
        Fimber.i("Variant ${modVariant.smolId} is already enabled.");
        return;
      }
    }

    final activeVariants =
        mod.modVariants.where((it) => mod.isEnabled(it)).toList();
    if (modVariant == null && activeVariants.isEmpty) {
      Fimber.i(
          "Went to disable the mod but no variants were active, nothing to do! $mod");
      return;
    }

    // Disable all active mod variants
    // or variants in the mod folder while the mod itself is disabled
    // (except for the variant we want to actually enable, if that's already active).
    // There should only ever be one active but might as well be careful.
    for (var variant in activeVariants) {
      if (variant != modVariant) {
        try {
          await _disableModVariant(
            variant,
            // If disabling mod, disable in vanilla launcher.
            disableModInVanillaLauncher: modVariant == null,
            // If there's just one variant, disable via enabled_mods.json only, don't rename mod_info.json.
            changeFileExtension: mod.modVariants.length > 1,
          );
        } catch (e, st) {
          Fimber.e("Error disabling mod variant: $e", ex: e, stacktrace: st);
        }
      }
    }

    if (modVariant != null) {
      await _enableModVariant(modVariant, mod, enableInVanillaLauncher: true);
    }

    // TODO update ONLY the mod that changed and any dependents/dependencies.
    await reloadModVariants();

    if (validateDependencies) {
      validateModDependencies(modsToFreeze: [mod.id]);
    }
  }

  /// Check for multiple enabled variants for the same mod.
  /// If an enabled mod has a disabled dependency, enable the dependency.
  /// If an enabled mod's dependencies are not met, disable the mod.
  /// `modsToFreeze` is a list of mod ids that are being modified already and things should change around them.
  Future<void> validateModDependencies({
    List<String>? modsToFreeze,
  }) async {
    final modifiedModIds = modsToFreeze.toSet();
    var numModsChangedLastLoop = 0;
    final gameVersion = ref.read(AppState.starsectorVersion).valueOrNull;

    do {
      numModsChangedLastLoop = 0;
      final enabledMods = ref.read(AppState.enabledModsFile).valueOrNull;
      if (enabledMods == null) return;

      final allMods = AppState.getModsFromVariants(
              state.valueOrNull ?? [], enabledMods.enabledMods.toList())
          .toList();
      final allVariants = state.valueOrNull ?? [];
      // final dependencyCheck = ref.read(AppState.modCompatibility);
      for (final mod in allMods) {
        if (!mod.isEnabledInGameSync(enabledMods)) continue;

        // Check for multiple enabled variants for the same mod.
        if (mod.enabledVariants.length > 1) {
          for (var value in mod.enabledVariants.where((variant) =>
              variant.smolId != mod.findHighestEnabledVersion?.smolId)) {
            Fimber.i(
                "Found multiple enabled versions for mod ${mod.id}. Disabling ${value.smolId}");
            try {
              _disableModVariant(value,
                  changeFileExtension: true,
                  disableModInVanillaLauncher: false);
            } catch (e, st) {
              Fimber.e("Error disabling mod variant: $e",
                  ex: e, stacktrace: st);
            }
          }
        }

        final enabledVariant = mod.findFirstEnabled;
        if (enabledVariant == null) continue;

        final dependenciesFound = enabledVariant.checkDependencies(
            allVariants, enabledMods, gameVersion);
        Fimber.d(
            "Dependencies found for ${enabledVariant.smolId}: $dependenciesFound.");

        for (final dependencyCheck in dependenciesFound) {
          final wasAlreadyModified =
              modifiedModIds.contains(dependencyCheck.dependency.id) == true;
          Fimber.d(
              "Dependency ${dependencyCheck.dependency.id} check for ${enabledVariant.smolId}: frozen? $wasAlreadyModified, ${dependencyCheck.satisfiedAmount}.");

          // If an enabled mod has a disabled dependency, enable the dependency.
          if (dependencyCheck.dependency.id == null) continue;

          if (!modifiedModIds.contains(dependencyCheck.dependency.id) &&
              dependencyCheck.satisfiedAmount is Disabled) {
            final dependency = dependencyCheck.satisfiedAmount.modVariant!;
            Fimber.i(
                "Enabling dependency ${dependency.smolId} for ${enabledVariant.smolId}.");
            modifiedModIds.add(mod.id);
            await changeActiveModVariant(dependency.mod(allMods)!, dependency,
                validateDependencies: false);
            numModsChangedLastLoop++;
          } else if (!modifiedModIds.contains(mod.id) &&
                  dependencyCheck.satisfiedAmount is VersionInvalid ||
              dependencyCheck.satisfiedAmount is Missing ||
              dependencyCheck.satisfiedAmount is Disabled) {
            // If an enabled mod's dependencies are not met, disable the mod.
            Fimber.i(
                "Disabling ${mod.id} because ${dependencyCheck.dependency.formattedNameVersionId} was ${dependencyCheck.satisfiedAmount}.");
            modifiedModIds.add(mod.id);
            await changeActiveModVariant(mod, null,
                validateDependencies: false);
            numModsChangedLastLoop++;
          }
        }
      }

      if (numModsChangedLastLoop > 0) {
        Fimber.i(
            "Doing another validation pass. Modified so far: ${modifiedModIds.join(", ")}.");
      }
    } while (numModsChangedLastLoop > 0);
  }

  Future<void> _enableModVariant(
    ModVariant modVariant,
    Mod mod, {
    bool enableInVanillaLauncher = true,
  }) async {
    // final mods = ref.read(AppState.mods);
    // final mod = mods.firstWhereOrNull((mod) => mod.id == modVariant.modInfo.id);
    final enabledMods = ref.read(AppState.enabledModsFile).valueOrNull;
    Fimber.i("Enabling variant ${modVariant.smolId}");
    final modsFolderPath = ref.read(appSettings).modsDir;

    if (modsFolderPath == null || !modsFolderPath.existsSync()) {
      throw Exception("Mods folder does not exist: $modsFolderPath");
    }

    if (enabledMods == null) {
      throw Exception(
          "Enabled mods is null, can't enable mod ${modVariant.smolId}.");
    }

    if (mod == null) {
      throw Exception("Mod ${modVariant.modInfo.id} not found in mods.");
    }

    if (mod.isEnabled(modVariant)) {
      Fimber.i("Variant ${modVariant.smolId} is already enabled.");
      return;
    }

    // Look for any disabled mod_info files in the folder.
    final disabledModInfoFiles = (await Constants.modInfoFileDisabledNames
            .map((it) => modVariant.modsFolder.resolve(it).toFile())
            .whereAsync((it) async => await it.isWritable()))
        .toList();

    // And re-enable one.
    if (!modVariant.isModInfoEnabled) {
      disabledModInfoFiles.firstOrNull?.let((disabledModInfoFile) async {
        disabledModInfoFile.renameSync(
            modVariant.modsFolder.resolve(Constants.modInfoFileName).path);
        Fimber.i(
            "Re-enabled ${modVariant.smolId}: renamed ${disabledModInfoFile.nameWithExtension} to ${Constants.modInfoFileName}.");
      });
    }

    if (enableInVanillaLauncher && !mod.isEnabledInGame) {
      await _enableModInEnabledMods(modVariant.modInfo.id);
    }
  }

  Future<void> _disableModVariant(
    ModVariant modVariant, {
    bool changeFileExtension = false,
    bool disableModInVanillaLauncher = true,
  }) async {
    final enabledMods = ref.read(AppState.enabledModIds).valueOrNull;
    final mods = AppState.getModsFromVariants(
        state.valueOrNull ?? [], enabledMods.orEmpty().toList());
    Fimber.i("Disabling variant ${modVariant.smolId}");
    final modInfoFile =
        modVariant.modsFolder.resolve(Constants.unbrickedModInfoFileName);

    if (!modInfoFile.existsSync()) {
      throw Exception(
          "mod_info.json not found in ${modVariant.modsFolder.absolute}");
    }

    if (changeFileExtension) {
      modInfoFile.renameSync(modInfoFile.parent
          .resolve(Constants.modInfoFileDisabledNames.first)
          .path);
      Fimber.i(
          "Disabled ${modVariant.smolId}: renamed to ${Constants.modInfoFileDisabledNames.first}.");
    }

    if (disableModInVanillaLauncher) {
      final mod = modVariant.mod(mods)!;
      if (mod.isEnabledInGame) {
        Fimber.i(
            "Disabling mod ${modVariant.modInfo.id} as part of disabling variant ${modVariant.smolId}.");
        _disableModInEnabledMods(modVariant.modInfo.id);
      } else {
        Fimber.i(
            "Mod ${modVariant.modInfo.id} was already disabled in enabled_mods.json and won't be disabled as part of disabling variant ${modVariant.smolId}.");
      }
    }

    // if (disableInVanillaLauncher) {
    //   val mod = modVariant.mod(modsCache) ?: return Result.failure(NullPointerException())
    //   if (mod.isEnabledInGame) {
    //     Timber.i { "Disabling mod ${modVariant.modInfo.id} as part of disabling variant ${modVariant.smolId}." }
    //     gameEnabledMods.disable(modVariant.modInfo.id)
    //   } else {
    //     Timber.i { "Mod ${modVariant.modInfo.id} was already disabled in enabled_mods.json and won't be disabled as part of disabling variant ${modVariant.smolId}." }
    //   }
    // }

    Fimber.i("Disabling ${modVariant.smolId}: success.");
  }

  Future<void> _disableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).disableMod(modId);
  }

  Future<void> _enableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).enableMod(modId);
  }
}
