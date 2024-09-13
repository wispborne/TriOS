import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/logging.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_notifier.dart';
import 'models/mod_profile.dart';

final modProfilesProvider =
    AsyncNotifierProvider<ModProfileManagerNotifier, ModProfiles>(
        ModProfileManagerNotifier.new);

class ModProfileManagerNotifier extends GenericSettingsNotifier<ModProfiles> {
  bool pauseAutomaticProfileUpdates = false;

  @override
  Future<ModProfiles> build() async {
    // Load the initial state
    final initialState = await super.build();

    // Set up the listener to watch enabled mod variants
    ref.listen<List<ModVariant>>(AppState.enabledModVariants, (previous, next) {
      updateFromModList();
    });

    return initialState;
  }

  @override
  ModProfiles Function() get defaultStateFactory =>
      () => const ModProfiles(modProfiles: []);

  @override
  String get fileName => "trios_mod_profiles.json";

  @override
  ModProfiles Function(dynamic json) get fromJson =>
      (json) => ModProfilesMapper.fromJson(json);

  @override
  dynamic Function(ModProfiles) get toJson => (state) => jsonEncode(state);

  ModProfile? getCurrentModProfile() {
    final currentProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    return state.valueOrNull?.modProfiles
        .firstWhereOrNull((profile) => profile.id == currentProfileId);
  }

  void updateFromModList() {
    if (pauseAutomaticProfileUpdates) return;

    final mods = ref.read(AppState.enabledModVariants);
    final enabledModVariants = mods.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();

    Fimber.d("Updating mod profile with ${enabledModVariants.length} mods");

    final currentProfile = getCurrentModProfile();
    if (currentProfile != null) {
      final updatedProfile = currentProfile.copyWith(
        enabledModVariants: enabledModVariants,
        dateModified: DateTime.now(),
      );
      updateModProfile(updatedProfile);
    } else {
      Fimber.w("No current mod profile to update.");
    }
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
  }

  void updateModProfile(ModProfile updatedProfile) {
    if (updatedProfile == null) {
      return;
    }

    final startingState =
        state.valueOrNull ?? const ModProfiles(modProfiles: []);

    final newModProfiles = startingState.modProfiles
        .map((profile) =>
            profile.id == updatedProfile.id ? updatedProfile : profile)
        .toList();

    update((oldState) => oldState.copyWith(modProfiles: newModProfiles));
  }

  void removeModProfile(String modProfileId) {
    if (!state.hasValue || state.valueOrNull?.modProfiles.isEmpty == true) {
      return;
    }

    final newModProfiles = state.value!.modProfiles
        .where((profile) => profile.id != modProfileId)
        .toList();
    update((oldState) => oldState.copyWith(modProfiles: newModProfiles));
  }

  List<ModChange> computeModProfileChanges(String modProfileId) {
    final profile = state.valueOrNull?.modProfiles
        .firstWhereOrNull((profile) => profile.id == modProfileId);
    if (profile == null) {
      Fimber.w("Profile $modProfileId not found.");
      return [];
    }

    final allMods = ref.read(AppState.mods);
    final modVariants = ref.read(AppState.modVariants).valueOrNull ?? [];
    final currentlyEnabledModVariants = ref.read(AppState.enabledModVariants);

    final currentlyEnabledShallows = currentlyEnabledModVariants.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    final profileShallows = profile.enabledModVariants;

    // Map of modId to ShallowModVariant
    final currentModIdToShallow = Map<String, ShallowModVariant>.fromIterable(
      currentlyEnabledShallows,
      key: (item) => item.modId,
      value: (item) => item,
    );

    final profileModIdToShallow = Map<String, ShallowModVariant>.fromIterable(
      profileShallows,
      key: (item) => item.modId,
      value: (item) => item,
    );

    // Mods present in both current and profile
    final modIdsInBoth = currentModIdToShallow.keys.toSet().intersection(
          profileModIdToShallow.keys.toSet(),
        );

    // Mods to swap
    final toSwap = modIdsInBoth.where((modId) {
      final currentVariant = currentModIdToShallow[modId]!;
      final profileVariant = profileModIdToShallow[modId]!;
      return currentVariant.smolVariantId != profileVariant.smolVariantId;
    }).map((modId) {
      final mod = allMods.firstWhereOrNull((mod) => mod.id == modId);
      final fromVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == currentModIdToShallow[modId]!.smolVariantId);
      final toVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == profileModIdToShallow[modId]!.smolVariantId);

      // If the toVariant is null, it means the variant is missing
      if (toVariant == null) {
        return ModChange(
          modId: modId,
          mod: mod,
          fromVariant: fromVariant,
          toVariant: null,
          changeType: ModChangeType.missingVariant,
        );
      }

      return ModChange(
        modId: modId,
        mod: mod,
        fromVariant: fromVariant,
        toVariant: toVariant,
        changeType: ModChangeType.swap,
      );
    }).toList();

    // Mods to enable
    final modIdsToEnable = profileModIdToShallow.keys.toSet().difference(
          currentModIdToShallow.keys.toSet(),
        );

    final toEnable = modIdsToEnable.map((modId) {
      final mod = allMods.firstWhereOrNull((mod) => mod.id == modId);
      final toVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == profileModIdToShallow[modId]!.smolVariantId);

      if (mod == null || toVariant == null) {
        return ModChange(
          modId: modId,
          mod: mod,
          fromVariant: null,
          toVariant: null,
          changeType: ModChangeType.missingMod,
        );
      }

      return ModChange(
        modId: modId,
        mod: mod,
        fromVariant: null,
        toVariant: toVariant,
        changeType: ModChangeType.enable,
      );
    }).toList();

    // Mods to disable
    final modIdsToDisable = currentModIdToShallow.keys.toSet().difference(
          profileModIdToShallow.keys.toSet(),
        );

    final toDisable = modIdsToDisable.map((modId) {
      final mod = allMods.firstWhereOrNull((mod) => mod.id == modId);
      final fromVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == currentModIdToShallow[modId]!.smolVariantId);

      return ModChange(
        modId: modId,
        mod: mod,
        fromVariant: fromVariant,
        toVariant: null,
        changeType: ModChangeType.disable,
      );
    }).toList();

    return [...toSwap, ...toEnable, ...toDisable];
  }

  Future<void> activateModProfile(String modProfileId) async {
    Fimber.i("Activating mod profile $modProfileId.");
    var modVariantsNotifier = ref.read(AppState.modVariants.notifier);

    try {
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

      final changes = computeModProfileChanges(modProfileId);

      // Pause automatic profile updates while swapping
      Fimber.i("Pausing profile updates while swapping.");
      pauseAutomaticProfileUpdates = true;
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = false;

      for (final change in changes) {
        if (change.changeType == ModChangeType.missingMod ||
            change.changeType == ModChangeType.missingVariant) {
          Fimber.w(
              "Cannot apply change for modId ${change.modId} due to missing mod or variant.");
          continue; // Skip missing mods or variants
        }

        final mod = change.mod;
        if (mod == null) {
          Fimber.w("Mod not found for change ${change.toVariant?.smolId}.");
          continue;
        }

        Fimber.d(
            "Changing active mod variant for ${mod.id} to ${change.toVariant?.smolId}.");
        await modVariantsNotifier.changeActiveModVariant(
          mod,
          change.toVariant,
          validateDependencies: false,
        );
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
      await modVariantsNotifier.reloadModVariants();
      Fimber.i("Resuming profile updates.");
    }
  }

  Future<void> saveCurrentModListToProfile(String profileId) async {
    final currentProfile = getCurrentModProfile();
    if (currentProfile == null) {
      Fimber.w("No current profile to save to.");
      return;
    }
    final currentMods = ref.read(AppState.enabledModVariants);
    final currentShallows = currentMods.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    final newProfile = currentProfile.copyWith(
      enabledModVariants: currentShallows,
      dateModified: DateTime.now(),
    );
    updateModProfile(newProfile);
  }
}

enum ModChangeType { enable, disable, swap, missingMod, missingVariant }

class ModChange {
  final String modId;
  final Mod? mod;
  final ModVariant? fromVariant;
  final ModVariant? toVariant;
  final ModChangeType changeType;

  ModChange({
    required this.modId,
    required this.mod,
    required this.fromVariant,
    required this.toVariant,
    required this.changeType,
  });
}
