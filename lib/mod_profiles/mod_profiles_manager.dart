import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../utils/generic_settings_notifier.dart';
import 'models/mod_profile.dart';

/// Uses shared preferences to store mod profiles
// class ModProfilesSettings {
//   static const modProfilesKey = 'modProfiles';
//
//   static List<ModProfile>? _loadFromDisk() {
//     try {
//       final json = sharedPrefs.getString(modProfilesKey);
//       return json == null
//           ? null
//           : (jsonDecode(json) as List)
//               .map((e) => ModProfileMapper.fromJson(e))
//               .toList();
//     } catch (e) {
//       Fimber.e('Failed to load mod profiles from shared prefs', ex: e);
//       return null;
//     }
//   }
//
//   static Future<void> _saveToDisk(List<ModProfile> profiles) async {
//     await sharedPrefs.setString(modProfilesKey, jsonEncode(profiles));
//   }
// }

final modProfilesProvider =
    AsyncNotifierProvider<ModProfileManagerNotifier, ModProfiles>(
        ModProfileManagerNotifier.new);

class ModProfileManagerNotifier extends GenericSettingsNotifier<ModProfiles> {
  bool pauseAutomaticProfileUpdates = false;

  @override
  ModProfiles Function() get defaultStateFactory =>
      () => const ModProfiles(modProfiles: []);

  @override
  String get fileName => "trios_mod_profiles.json";

  @override
  ModProfiles Function(dynamic p1) get fromJson =>
      (json) => ModProfilesMapper.fromJson(json);

  @override
  Function(ModProfiles p1) get toJson => (state) => jsonEncode(state);

  ModProfile? getCurrentModProfile() {
    final currentProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    return state.valueOrNull?.modProfiles
        .firstWhereOrNull((profile) => profile.id == currentProfileId);
  }

  void updateFromModList() {
    final mods = ref.watch(AppState.enabledModVariants);
    final enabledModVariants = mods.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    if (pauseAutomaticProfileUpdates) return;
    Fimber.d("Updating mod profile with ${enabledModVariants.length} mods");
    // updateModProfile(getCurrentModProfile()?.copyWith(
    //     enabledModVariants: enabledModVariants, dateModified: DateTime.now()));
  }

  void createModProfile(
    String name, {
    String description = '',
    int? sortOrder,
    List<ShallowModVariant> enabledModVariants = const [],
  }) {
    final newModProfile = ModProfile.newProfile(
      name,
      enabledModVariants,
      description: description,
      sortOrder: sortOrder ??
          (state.valueOrNull?.modProfiles.map((e) => e.sortOrder).maxOrNull ??
                  0) +
              1,
    );

    update((prevState) => prevState.copyWith(
            modProfiles: [...?state.valueOrNull?.modProfiles, newModProfile]));
    // if (state.valueOrNull != null &&
    //     state.valueOrNull!.modProfiles.isNotEmpty) {
    //   ModProfilesSettings._saveToDisk(state.value!.modProfiles);
    // }
  }

  void updateModProfile(ModProfile? updatedProfile) {
    if (updatedProfile == null) {
      return;
    }
    final startingState =
        state.valueOrNull ?? const ModProfiles(modProfiles: []);

    // if (startingState.modProfiles.none((profile) => profile.id == updatedProfile.id)) {
    //   createModProfile();
    //   return;
    // }

    final newModProfiles = startingState.modProfiles
        .orEmpty()
        .map((profile) =>
            profile.id == updatedProfile.id ? updatedProfile : profile)
        .toList();

    update((oldState) => oldState.copyWith(modProfiles: newModProfiles));
    // ModProfilesSettings._saveToDisk(newModProfiles);
  }

  void removeModProfile(String modProfileId) {
    if (!state.hasValue || state.valueOrNull?.modProfiles.isEmpty == true) {
      return;
    }

    final newModProfiles = state.value!.modProfiles
        .orEmpty()
        .where((profile) => profile.id != modProfileId)
        .toList();
    update((oldState) => oldState.copyWith(modProfiles: newModProfiles));
    // ModProfilesSettings._saveToDisk(newModProfiles);
  }

  void activateModProfile(String modProfileId) async {
    Fimber.i("Activating mod profile $modProfileId.");
    var modVariantsNotifier = ref.read(AppState.modVariants.notifier);

    try {
      // Bail if the profile doesn't exist or is already active
      final profile = state.valueOrNull?.modProfiles
          .firstWhereOrNull((profile) => profile.id == modProfileId);
      if (profile == null) {
        Fimber.w("Profile $modProfileId not found.");
        return;
      }
      final activeProfileId =
          ref.read(appSettings.select((s) => s.activeModProfileId));
      if (activeProfileId == modProfileId) {
        Fimber.i("Profile $modProfileId is already active.");
        return;
      }

      final allMods = ref.read(AppState.mods);
      final modVariants = ref.read(AppState.modVariants).valueOrNull ?? [];
      final currentlyEnabledModVariants = ref.read(AppState.enabledModVariants);
      final currentlyEnabledShallows = currentlyEnabledModVariants.sortedByName
          .map((variant) => ShallowModVariant.fromModVariant(variant))
          .toList();
      final profileShallows = profile.enabledModVariants;

      final toSwapToDifferentVersion = currentlyEnabledShallows
          .where((current) => profileShallows.any((profile) =>
              current.modId == profile.modId &&
              current.smolVariantId != profile.smolVariantId))
          .map((shallow) => (
                mod: allMods.firstWhereOrNull((mod) => mod.id == shallow.modId),
                variant: modVariants
                    .firstWhereOrNull((v) => v.smolId == shallow.smolVariantId),
              ))
          .toList();
      final toEnable = profileShallows
          .where((profile) => currentlyEnabledShallows.every(
              (current) => current.smolVariantId != profile.smolVariantId))
          .map((shallow) => (
                mod: allMods.firstWhereOrNull((mod) => mod.id == shallow.modId),
                variant: modVariants
                    .firstWhereOrNull((v) => v.smolId == shallow.smolVariantId),
              ))
          .toList();
      final toDisable = currentlyEnabledShallows
          .where((current) => profileShallows.every(
              (profile) => current.smolVariantId != profile.smolVariantId))
          .map((shallow) => (
                mod: allMods.firstWhereOrNull((mod) => mod.id == shallow.modId),
                variant: null,
              ))
          .toList();

      final mergedList = [
        ...toSwapToDifferentVersion,
        ...toEnable,
        ...toDisable
      ];

      // No active profile while swapping, otherwise it'll try to update while swapping.
      // ref.read(appSettings.notifier).update((s) => s.copyWith(
      //       activeModProfileId: null,
      //     ));
      Fimber.i("Pausing profile updates while swapping.");
      pauseAutomaticProfileUpdates = true;
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = false;

      for (final pair in mergedList) {
        final mod = pair.mod;
        final variant = pair.variant;
        if (mod == null) {
          Fimber.w("Mod not found for variant ${pair.variant?.smolId}.");
          continue;
        }

        Fimber.d(
            "Changing active mod variant for ${mod.id} to ${variant?.smolId}.");
        await modVariantsNotifier.changeActiveModVariant(mod, variant,
            validateDependencies: false);
      }

      await modVariantsNotifier.validateModDependencies();
      ref.read(appSettings.notifier).update((s) => s.copyWith(
            activeModProfileId: modProfileId,
          ));
      Fimber.i("Finished activating mod profile $modProfileId.");
    } catch (e, stack) {
      Fimber.e("Failed to activate mod profile $modProfileId.",
          ex: e, stacktrace: stack);
    } finally {
      pauseAutomaticProfileUpdates = false;
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = true;
      // Reload all just in case.
      // TODO make it so this isn't needed.
      await modVariantsNotifier.reloadModVariants();
      Fimber.i("Resuming profile updates.");
    }
  }
}
