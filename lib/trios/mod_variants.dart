import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../mod_manager/audit_page.dart';
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
      if (modsPath != null) {
        addModsFolderFileWatcher(modsPath, (List<File> files) {
          if (shouldAutomaticallyReloadOnFilesChanged) {
            Fimber.i("Mods folder changed, invalidating mod variants.");
            ref.invalidateSelf();
          } else {
            Fimber.i(
                "Mods folder changed, but not reloading mod variants because shouldAutomaticallyReloadOnFilesChanged is false.");
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
        "Loading mod variant data from disk (reading mod_info.json files).");
    final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
    final modsPath = ref.watch(appSettings.select((value) => value.modsDir));
    if (gamePath == null || modsPath == null) {
      return;
    }

    final variants = onlyVariants == null
        ? await getModsVariantsInFolder(modsPath.toDirectory())
        : (await Future.wait(onlyVariants.map((variant) {
            try {
              return getModsVariantsInFolder(variant.modFolder);
            } catch (e, st) {
              Fimber.w("Error getting mod variants for ${variant.smolId}",
                  ex: e, stacktrace: st);
              return Future.value(null);
            }
          })))
            .whereNotNull()
            .flattened
            .toList();
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

  // TODO should move all this into modManager at some point.

  Future<void> changeActiveModVariant(Mod mod, ModVariant? modVariant,
      {bool validateDependencies = true}) async {
    final isDisablingMod = modVariant == null;
    Fimber.i(isDisablingMod
        ? "Disabling ${mod.id}."
        : "Changing active variant of ${mod.id} to ${modVariant.smolId}. (current: ${mod.findFirstEnabled?.smolId}).");

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

    final enabledVariants =
        mod.modVariants.where((it) => it.isModInfoEnabled).toList();
    if (modVariant == null && enabledVariants.isEmpty) {
      Fimber.i(
          "Went to disable the mod but no variants were active, nothing to do! $mod");
      return;
    }

    // If enabling a variant, disable all other non-bricked mod variants
    // (except for the variant we want to actually enable, if that's already active).
    for (var variant in enabledVariants) {
      if (variant.smolId != modVariant?.smolId) {
        try {
          await _disableModVariant(
            variant,
            // If disabling mod, disable in vanilla launcher.
            disableModInVanillaLauncher: isDisablingMod,
            // Only need to brick `mod_info.json` files if enabling one variant among many.
            // If disabling the mod, all `mod_info.json` files should be unbricked (happens later in this method).
            // If there's only one variant, it's fine to leave the `mod_info.json` file unbricked.
            brickModInfo: !isDisablingMod && mod.modVariants.length > 1,
            reason: isDisablingMod
                ? "Disabled ${mod.id}."
                : "Changed ${mod.id} to ${modVariant.modInfo.version}, so ${variant.bestVersion} has to be disabled.",
          );
        } catch (e, st) {
          Fimber.e("Error disabling mod variant: $e", ex: e, stacktrace: st);
        }
      }
    }

    if (!isDisablingMod) {
      await _enableModVariant(modVariant, mod,
          enableInVanillaLauncher: true,
          reason:
              "Changed ${mod.id} to version ${modVariant.bestVersion} from ${mod.findFirstEnabled == null ? "disabled" : mod.findFirstEnabled?.bestVersion}.");
    } else {
      // If mod is disabled in `enabled_mods.json`, set all the `mod_info.json` files to non-bricked.
      // That makes things easier on the user & MOSS by mimicking vanilla behavior whenever possible.
      final disabledModVariants =
          mod.modVariants.where((v) => !v.isModInfoEnabled).toList();
      for (final disabledVariant in disabledModVariants) {
        try {
          await _enableModInfoFile(disabledVariant);
        } catch (e, st) {
          Fimber.e("Error enabling mod_info.json file: $e",
              ex: e, stacktrace: st);
        }
      }
    }

    // TODO update ONLY the mod that changed and any dependents/dependencies.
    await reloadModVariants(
        onlyVariants: [...enabledVariants, modVariant].whereNotNull().toList());

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
    if (ref.watch(appSettings.select((value) => value.autoEnableAndDisableDependencies)) ==
        false) {
      Fimber.d("Auto dependency validation is disabled.");
      return;
    }
    final modifiedModIds = modsToFreeze?.toSet() ?? {};
    var numModsChangedLastLoop = 0;
    final gameVersion = ref.read(AppState.starsectorVersion).valueOrNull;

    do {
      numModsChangedLastLoop = 0;
      final enabledMods =
          ref.read(AppState.enabledModsFile).valueOrNull?.enabledMods.toList();
      if (enabledMods == null) return;

      final allMods =
          AppState.getModsFromVariants(state.valueOrNull ?? [], enabledMods)
              .toList();
      final allVariants = state.valueOrNull ?? [];
      // final dependencyCheck = ref.read(AppState.modCompatibility);
      for (final mod in allMods) {
        if (!mod.isEnabledInGameSync(enabledMods)) continue;

        // Check for multiple enabled variants for the same mod.
        if (mod.enabledVariants.length > 1) {
          final highestEnabledVersion = mod.findHighestEnabledVersion;
          for (var value in mod.enabledVariants.where((variant) {
            return variant.smolId != highestEnabledVersion?.smolId;
          })) {
            Fimber.i(
                "Found multiple enabled versions for mod ${mod.id}. Disabling ${value.smolId}");
            try {
              _disableModVariant(
                value,
                brickModInfo: true,
                disableModInVanillaLauncher: false,
                reason:
                    "When validating ${mod.id}, found multiple enabled versions. Only keeping ${highestEnabledVersion?.modInfo.version} enabled.",
              );
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
    required String reason,
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

    if (mod.isEnabled(modVariant)) {
      Fimber.i("Variant ${modVariant.smolId} is already enabled.");
      return;
    }

    // Look for any disabled mod_info files in the folder.
    await _enableModInfoFile(modVariant);

    if (enableInVanillaLauncher && !mod.isEnabledInGame) {
      await _enableModInEnabledMods(modVariant.modInfo.id);
    }

    ref
        .read(AppState.modAudit.notifier)
        .addAuditEntry(modVariant.smolId, ModAction.enable, reason: reason);
    Fimber.i("Enabling ${modVariant.smolId}: success.");
  }

  Future<void> _enableModInfoFile(ModVariant modVariant) async {
    // Look for any disabled mod_info files in the folder.
    final disabledModInfoFiles = (await Constants.modInfoFileDisabledNames
            .map((it) => modVariant.modFolder.resolve(it).toFile())
            .whereAsync((it) async => await it.isWritable()))
        .toList();

    // And re-enable one.
    if (!modVariant.isModInfoEnabled) {
      disabledModInfoFiles.firstOrNull?.let((disabledModInfoFile) async {
        disabledModInfoFile.renameSync(
            modVariant.modFolder.resolve(Constants.modInfoFileName).path);
        Fimber.i(
            "Re-enabled ${modVariant.smolId}: renamed ${disabledModInfoFile.nameWithExtension} to ${Constants.modInfoFileName}.");
      });
    }
  }

  /// Use with caution. Prefer to use [changeActiveModVariant] instead.
  Future<void> _disableModVariant(
    ModVariant modVariant, {
    bool brickModInfo = false,
    bool disableModInVanillaLauncher = true,
    required String reason,
  }) async {
    final enabledMods = ref.read(AppState.enabledModIds).valueOrNull;
    final mods = AppState.getModsFromVariants(
        state.valueOrNull ?? [], enabledMods.orEmpty().toList());
    Fimber.i("Disabling variant '${modVariant.smolId}'");

    if (brickModInfo) {
      disableModInfoFile(modVariant.modFolder, modVariant.smolId);
    }

    if (disableModInVanillaLauncher) {
      final mod = modVariant.mod(mods)!;
      if (mod.isEnabledInGame) {
        Fimber.i(
            "Disabling mod '${modVariant.modInfo.id}' as part of disabling variant '${modVariant.smolId}'.");
        _disableModInEnabledMods(modVariant.modInfo.id);
      } else {
        Fimber.i(
            "Mod '${modVariant.modInfo.id}' was already disabled in enabled_mods.json and won't be disabled as part of disabling variant ${modVariant.smolId}.");
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

    ref
        .read(AppState.modAudit.notifier)
        .addAuditEntry(modVariant.smolId, ModAction.disable, reason: reason);
    Fimber.i("Disabling '${modVariant.smolId}': success.");
  }

  void disableModInfoFile(Directory modFolder, String smolId) {
    final modInfoFile = modFolder.resolve(Constants.unbrickedModInfoFileName);

    if (!modInfoFile.existsSync()) {
      throw Exception("mod_info.json not found in ${modFolder.absolute}");
    }

    modInfoFile.renameSync(modInfoFile.parent
        .resolve(Constants.modInfoFileDisabledNames.first)
        .path);
    Fimber.i(
        "Disabled '$smolId': renamed to '${Constants.modInfoFileDisabledNames.first}'.");
  }

  Future<void> _disableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).disableMod(modId);
  }

  Future<void> _enableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).enableMod(modId);
  }
}
