import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_notifier.dart';
import 'models/mod_profile.dart';

final modProfilesProvider =
    AsyncNotifierProvider<ModProfileManagerNotifier, ModProfiles>(
      ModProfileManagerNotifier.new,
    );

// isChangingProfile state
bool isChangingModProfileProvider = false;

/// The profile TriOS last applied, whether the enabled mods still match it, and
/// whether we know either of those things yet.
class TrackedProfileStatus {
  /// True until both the mods folder and the enabled-mods file have loaded.
  /// No profile action should be offered while this is true.
  final bool isLoading;

  /// The tracked profile, or null if none is tracked or the stored id is gone.
  final ModProfile? profile;

  /// True when the enabled mods differ from what the tracked profile saved.
  final bool isModified;

  const TrackedProfileStatus({
    required this.isLoading,
    required this.profile,
    required this.isModified,
  });

  const TrackedProfileStatus.loading()
    : isLoading = true,
      profile = null,
      isModified = false;

  const TrackedProfileStatus.notTracked()
    : isLoading = false,
      profile = null,
      isModified = false;

  bool get isTracking => profile != null;

  /// True when there are changes that Save changes would write to the profile.
  bool get hasUnsavedChanges => profile != null && isModified;
}

/// Works out the tracked profile and its Modified state from already-read
/// inputs.
///
/// Kept separate from the provider so [ModProfileManagerNotifier] can use it
/// too. The notifier can't read [trackedProfileStatusProvider], because that
/// provider watches the notifier.
TrackedProfileStatus computeTrackedProfileStatus({
  required bool modsHaveLoaded,
  required bool enabledModsFileIsReady,
  required ModProfiles? profiles,
  required String? trackedProfileId,
  required List<ModVariant> enabledModVariants,
}) {
  if (!modsHaveLoaded || !enabledModsFileIsReady || profiles == null) {
    return const TrackedProfileStatus.loading();
  }

  final profile = profiles.modProfiles.firstWhereOrNull(
    (profile) => profile.id == trackedProfileId,
  );
  // An id that doesn't name a loaded profile means nothing is tracked.
  if (profile == null) return const TrackedProfileStatus.notTracked();

  return TrackedProfileStatus(
    isLoading: false,
    profile: profile,
    isModified: !ModProfileManagerNotifier.doesLoadoutMatchProfile(
      profile,
      enabledModVariants,
    ),
  );
}

/// Single source of truth for the profile picker, the profile cards, and the
/// confirmation dialogs.
final trackedProfileStatusProvider = Provider<TrackedProfileStatus>((ref) {
  return computeTrackedProfileStatus(
    modsHaveLoaded: ref.watch(AppState.modsHaveLoaded),
    enabledModsFileIsReady: ref.watch(AppState.enabledModsFile).hasValue,
    profiles: ref.watch(modProfilesProvider).value,
    trackedProfileId: ref.watch(
      appSettings.select((s) => s.activeModProfileId),
    ),
    enabledModVariants: ref.watch(AppState.enabledModVariants),
  );
});

/// Stores [ModProfile]s, provides methods to manage them, observable state.
class ModProfilesSettingsManager
    extends GenericAsyncSettingsManager<ModProfiles> {
  @override
  String get fileName => "trios_mod_profiles-v2.json";

  @override
  ModProfiles Function(Map<String, dynamic> map) get fromMap =>
      (json) => ModProfilesMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(ModProfiles) get toMap =>
      (state) => state.toMap();

  @override
  FileFormat get fileFormat => FileFormat.json;
}

class ModProfileManagerNotifier
    extends GenericSettingsAsyncNotifier<ModProfiles> {
  @override
  ModProfiles createDefaultState() => const ModProfiles(modProfiles: []);

  @override
  Future<ModProfiles> build() async {
    // Load the initial state
    var initialState = await super.build();
    final settingsFile = settingsManager.settingsFile;

    // Look for pre-1.0 double/triple encoded json files and migrate them to proper json
    initialState = await migrateFromV1(settingsFile, initialState);

    // Profiles are only written by an explicit save. Changing which mods are
    // enabled never rewrites the tracked profile.
    return initialState;
  }

  Future<ModProfiles> migrateFromV1(
    File settingsFile,
    ModProfiles initialState,
  ) async {
    // Look for pre-1.0 double/triple encoded json files and migrate them to proper json
    final existingJsonFile = settingsFile.parent
        .resolve("trios_mod_profiles.json")
        .toFile();
    if (initialState.modProfiles.isEmpty && existingJsonFile.existsSync()) {
      try {
        Fimber.i("Migrating mod profiles to proper json.");
        final jsonContents = existingJsonFile.readAsStringSync();
        final modProfiles = ModProfilesMapper.fromMap(
          jsonDecode(jsonDecode(jsonDecode(jsonContents))),
        );

        if (modProfiles.modProfiles.isNotEmpty) {
          await existingJsonFile.rename("${existingJsonFile.path}.bak");
          initialState = modProfiles;
          state = AsyncData(initialState);
          await settingsManager.scheduleWrite(initialState);
        }
      } catch (e, stack) {
        Fimber.e(
          "Failed to migrate mod profiles to proper json.",
          ex: e,
          stacktrace: stack,
        );
      }
    }
    return initialState;
  }

  @override
  GenericAsyncSettingsManager<ModProfiles> createSettingsManager() {
    return ModProfilesSettingsManager();
  }

  /// The tracked profile and its Modified state, right now.
  ///
  /// Same answer as [trackedProfileStatusProvider], which the notifier can't
  /// read because that provider watches this notifier.
  TrackedProfileStatus readTrackedProfileStatus() =>
      computeTrackedProfileStatus(
        modsHaveLoaded: ref.read(AppState.modsHaveLoaded),
        enabledModsFileIsReady: ref.read(AppState.enabledModsFile).hasValue,
        profiles: state.value,
        trackedProfileId: ref.read(appSettings).activeModProfileId,
        enabledModVariants: ref.read(AppState.enabledModVariants),
      );

  /// Whether the currently enabled mods are exactly what [profile] saved.
  ///
  /// Compares mod ids and exact variant ids. List order, mod names, and saved
  /// display versions are ignored.
  static bool doesLoadoutMatchProfile(
    ModProfile profile,
    List<ModVariant> enabledModVariants,
  ) {
    final profileVariantIdsByModId = {
      for (final member in profile.enabledModVariants)
        member.modId: member.smolVariantId,
    };
    final enabledVariantIdsByModId = {
      for (final variant in enabledModVariants)
        variant.modInfo.id: variant.smolId,
    };

    return const MapEquality<String, String>().equals(
      profileVariantIdsByModId,
      enabledVariantIdsByModId,
    );
  }

  void cloneModProfile(ModProfile profile) {
    createModProfile(
      '${profile.name} (Copy)',
      enabledModVariants: profile.enabledModVariants,
    );
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
      sortOrder:
          sortOrder ??
          (state.value?.modProfiles.map((e) => e.sortOrder).maxOrNull ?? 0) + 1,
    );

    updateState(
      (prevState) => prevState.copyWith(
        modProfiles: [...?state.value?.modProfiles, newModProfile],
      ),
    );
  }

  Future<void> updateModProfile(ModProfile updatedProfile) async {
    final startingState = state.value ?? const ModProfiles(modProfiles: []);

    final newModProfiles = startingState.modProfiles
        .map(
          (profile) =>
              profile.id == updatedProfile.id ? updatedProfile : profile,
        )
        .toList();

    await updateState(
      (oldState) => oldState.copyWith(modProfiles: newModProfiles),
    );
  }

  void removeModProfile(String modProfileId) {
    if (!state.hasValue || state.value?.modProfiles.isEmpty == true) {
      return;
    }

    final newModProfiles = state.value!.modProfiles
        .where((profile) => profile.id != modProfileId)
        .toList();
    updateState((oldState) => oldState.copyWith(modProfiles: newModProfiles));
  }

  /// Computes the differences between what mods are currently enabled and
  /// what mods are enabled within the specified [modProfileId], returning
  /// a list of changes (enable, disable, swap, missing).
  static List<ModChange> computeModProfileChanges(
    ModProfile profile,
    List<Mod> allMods,
    List<ModVariant> modVariants,
    List<ModVariant> currentlyEnabledModVariants,
  ) {
    final currentlyEnabledShallows = currentlyEnabledModVariants.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    final profileShallows = profile.enabledModVariants;

    // Look-up tables built once. Searching the lists directly meant scanning
    // every variant for every changed mod, and each comparison rebuilt the
    // variant's smolId string. That was the slowest part of toggling a mod.
    final variantsBySmolId = {for (final v in modVariants) v.smolId: v};
    final modsById = {for (final mod in allMods) mod.id: mod};

    // Map of modId to ShallowModVariant
    final currentModIdToShallow = {
      for (var item in currentlyEnabledShallows) item.modId: item,
    };

    final profileModIdToShallow = {
      for (final item in profileShallows) item.modId: item,
    };

    // Mods present in both current and profile
    final modIdsInBoth = currentModIdToShallow.keys.toSet().intersection(
      profileModIdToShallow.keys.toSet(),
    );

    // Mods to swap
    final toSwap = modIdsInBoth
        .where((modId) {
          final currentVariant = currentModIdToShallow[modId]!;
          final profileVariant = profileModIdToShallow[modId]!;
          return currentVariant.smolVariantId != profileVariant.smolVariantId;
        })
        .map((modId) {
          final mod = modsById[modId];
          final fromVariant =
              variantsBySmolId[currentModIdToShallow[modId]!.smolVariantId];
          final modProfileVariant = profileModIdToShallow[modId];
          final toVariant = variantsBySmolId[modProfileVariant!.smolVariantId];

          if (toVariant == null) {
            // Missing variant
            return ModChange(
              modId: modId,
              mod: mod,
              fromVariant: fromVariant,
              toVariant: null,
              variantAsShallowMod: modProfileVariant,
              toVariantAlternate: _calculateBestAlternateForMissingVariant(
                mod,
                modProfileVariant,
              ),
              changeType: ModChangeType.missingVariant,
            );
          }

          // Swap
          return ModChange(
            modId: modId,
            mod: mod,
            fromVariant: fromVariant,
            toVariant: toVariant,
            variantAsShallowMod: modProfileVariant,
            toVariantAlternate: null,
            changeType: ModChangeType.swap,
          );
        })
        .toList();

    // Mods to enable
    final modIdsToEnable = profileModIdToShallow.keys.toSet().difference(
      currentModIdToShallow.keys.toSet(),
    );

    final toEnable = modIdsToEnable.map((modId) {
      final mod = modsById[modId];
      final modProfileVariant = profileModIdToShallow[modId];
      final toVariant = variantsBySmolId[modProfileVariant!.smolVariantId];

      if (mod == null) {
        // Missing mod
        return ModChange(
          modId: modId,
          mod: mod,
          fromVariant: null,
          toVariant: null,
          variantAsShallowMod: modProfileVariant,
          toVariantAlternate: null,
          changeType: ModChangeType.missingMod,
        );
      }

      if (toVariant == null) {
        // Mod exists, but the requested variant doesn't.
        return ModChange(
          modId: modId,
          mod: mod,
          fromVariant: null,
          toVariant: null,
          variantAsShallowMod: modProfileVariant,
          toVariantAlternate: _calculateBestAlternateForMissingVariant(
            mod,
            modProfileVariant,
          ),
          changeType: ModChangeType.missingVariant,
        );
      }

      // Enable
      return ModChange(
        modId: modId,
        mod: mod,
        fromVariant: null,
        toVariant: toVariant,
        variantAsShallowMod: modProfileVariant,
        toVariantAlternate: null,
        changeType: ModChangeType.enable,
      );
    }).toList();

    // Mods to disable
    final modIdsToDisable = currentModIdToShallow.keys.toSet().difference(
      profileModIdToShallow.keys.toSet(),
    );

    final toDisable = modIdsToDisable.map((modId) {
      final mod = modsById[modId];
      final modProfileVariant = profileModIdToShallow[modId];
      final fromVariant = variantsBySmolId[modProfileVariant?.smolVariantId];

      // Disable
      return ModChange(
        modId: modId,
        mod: mod,
        fromVariant: fromVariant,
        toVariant: null,
        variantAsShallowMod: modProfileVariant,
        toVariantAlternate: null,
        changeType: ModChangeType.disable,
      );
    }).toList();

    return [...toSwap, ...toEnable, ...toDisable];
  }

  static ModVariant? _calculateBestAlternateForMissingVariant(
    Mod? mod,
    ShallowModVariant? modProfileVariant,
  ) {
    final highestVersion = mod?.findHighestVersion;
    final targetVersion = modProfileVariant?.version;

    final toVariantAlternate = highestVersion?.bestVersion == null
        ? null
        : targetVersion == null
        ? highestVersion
        : highestVersion!.bestVersion! > targetVersion
        ? highestVersion
        : null;
    return toVariantAlternate;
  }

  /// Enables exactly the mods saved in [modProfileId] and tracks that profile.
  ///
  /// Pass [allowReapply] to run even when the profile is already tracked. That
  /// is what Revert to profile does.
  Future<void> activateModProfile(
    String modProfileId, {
    bool allowReapply = false,
  }) async {
    Fimber.i("Activating mod profile $modProfileId.");
    final modVariantsNotifier = ref.read(AppState.modVariants.notifier);
    final modManagerNotifier = ref.read(modManager.notifier);

    try {
      final profile = state.value?.modProfiles.firstWhereOrNull(
        (profile) => profile.id == modProfileId,
      );
      if (profile == null) {
        Fimber.w("Profile $modProfileId not found.");
        return;
      }
      final activeProfileId = ref.read(
        appSettings.select((s) => s.activeModProfileId),
      );
      if (activeProfileId == modProfileId && !allowReapply) {
        Fimber.i("Profile $modProfileId is already tracked.");
        return;
      }

      final allMods = ref.read(AppState.mods);
      final modVariants = ref.read(AppState.modVariants).value ?? [];
      final currentlyEnabledModVariants = ref.read(AppState.enabledModVariants);
      final changes = computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledModVariants,
      );

      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = false;
      isChangingModProfileProvider = true;

      for (final change in changes) {
        if (change.changeType == ModChangeType.missingMod ||
            change.changeType == ModChangeType.missingVariant) {
          Fimber.w(
            "Cannot apply change for modId ${change.modId} due to missing mod or variant.",
          );
          continue; // Skip missing mods or variants
        }

        final mod = change.mod;
        if (mod == null) {
          Fimber.w("Mod not found for change ${change.toVariant?.smolId}.");
          continue;
        }

        Fimber.d(
          "Changing active mod variant for ${mod.id} to ${change.toVariant?.smolId}.",
        );
        // Should check for game version, but we don't have a WidgetRef here.
        await modManagerNotifier.changeActiveModVariant(
          mod,
          change.toVariant,
          notifyWatchers: false,
          validateDependencies: false,
        );
      }

      // Fimber.i("here1.");
      await modManagerNotifier.validateModDependencies();
      // Fimber.i("here2.");
      ref
          .read(appSettings.notifier)
          .update((s) => s.copyWith(activeModProfileId: modProfileId));
      // Fimber.i("here3.");
      Fimber.i("Finished activating mod profile $modProfileId.");
    } catch (e, stack) {
      Fimber.e(
        "Failed to activate mod profile $modProfileId.",
        ex: e,
        stacktrace: stack,
      );
    } finally {
      // Fimber.i("here4.");
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = true;
      isChangingModProfileProvider = false;
      // Reload all just in case.
      await modVariantsNotifier.reloadModVariants();
    }
  }

  /// Replaces [profileId]'s saved mods with whatever is enabled right now.
  ///
  /// Returns false if the profile is gone or the write failed, so callers that
  /// do something afterwards (like switching profiles) can stop.
  Future<bool> saveCurrentModListToProfile(String profileId) async {
    final profile = state.value?.modProfiles.firstWhereOrNull(
      (profile) => profile.id == profileId,
    );
    if (profile == null) {
      Fimber.w("No profile $profileId to save to.");
      return false;
    }

    final currentMods = ref.read(AppState.enabledModVariants);
    final currentShallows = currentMods.sortedByName
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    final newProfile = profile.copyWith(
      enabledModVariants: currentShallows,
      dateModified: DateTime.now(),
    );

    try {
      await updateModProfile(newProfile);
      Fimber.i(
        "Saved ${currentShallows.length} enabled mods to profile $profileId.",
      );
      return true;
    } catch (e, stack) {
      Fimber.e(
        "Failed to save current mods to profile $profileId.",
        ex: e,
        stacktrace: stack,
      );
      return false;
    }
  }

  /// Stops tracking a profile. Never changes which mods are enabled.
  Future<void> stopUsingProfile() async {
    Fimber.i("No longer tracking a mod profile.");
    await ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(activeModProfileId: null));
  }

  /// Asks whether to switch to [profile], then switches.
  ///
  /// Selecting the profile that is already tracked does nothing. Revert to
  /// profile is the way to reapply it.
  void showActivateDialog(ModProfile profile, BuildContext context) {
    final status = readTrackedProfileStatus();
    if (status.isLoading) return;
    if (status.profile?.id == profile.id) {
      Fimber.i("Profile ${profile.id} is already tracked; nothing to do.");
      return;
    }
    _showProfileChangeDialog(profile, context, isRevert: false);
  }

  /// Asks whether to reapply the tracked [profile], then reapplies it.
  void showRevertDialog(ModProfile profile, BuildContext context) {
    if (readTrackedProfileStatus().isLoading) return;
    _showProfileChangeDialog(profile, context, isRevert: true);
  }

  /// Stops tracking a profile, first asking what to do with unsaved changes.
  void showStopUsingProfileDialog(BuildContext context) {
    final status = readTrackedProfileStatus();
    if (status.isLoading || !status.isTracking) return;

    final trackedProfile = status.profile!;
    if (!status.isModified) {
      stopUsingProfile();
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Deactivate '${trackedProfile.name}'?"),
        content: Text(
          "Your enabled mods no longer match '${trackedProfile.name}'."
          "\n\nEither way, the mods you have enabled stay exactly as they are."
          " Only the saved profile is affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              stopUsingProfile();
            },
            child: const Text('Deactivate without saving'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final saved = await saveCurrentModListToProfile(
                trackedProfile.id,
              );
              if (!saved) {
                Fimber.w(
                  "Could not save '${trackedProfile.name}', so it is still tracked.",
                );
                return;
              }
              await stopUsingProfile();
            },
            child: const Text('Save and deactivate'),
          ),
        ],
      ),
    );
  }

  void _showProfileChangeDialog(
    ModProfile profile,
    BuildContext context, {
    required bool isRevert,
  }) {
    if (!context.mounted) {
      return;
    }

    final status = readTrackedProfileStatus();
    // Only a switch away from an edited profile needs the save/discard choice.
    final profileWithUnsavedChanges = isRevert ? null : status.profile;
    final hasUnsavedChanges = !isRevert && status.hasUnsavedChanges;

    final allMods = ref.read(AppState.mods);
    final modVariants = ref.read(AppState.modVariants).value ?? [];
    final currentlyEnabledModVariants = ref.read(AppState.enabledModVariants);
    final changes = computeModProfileChanges(
      profile,
      allMods,
      modVariants,
      currentlyEnabledModVariants,
    );

    // Group changes by type
    final modsToEnable = changes
        .where((c) => c.changeType == ModChangeType.enable)
        .toList();
    final modsToDisable = changes
        .where((c) => c.changeType == ModChangeType.disable)
        .toList();
    final modsToSwap = changes
        .where((c) => c.changeType == ModChangeType.swap)
        .toList();
    final missingMods = changes
        .where((c) => c.changeType == ModChangeType.missingMod)
        .toList();
    final missingVariants = changes
        .where((c) => c.changeType == ModChangeType.missingVariant)
        .toList();
    final latestVariants = (ref.read(
      AppState.mods,
    )).map((mod) => mod.findHighestVersion).nonNulls.toList();
    final modIconsById = Map.fromEntries(
      latestVariants.map((e) => MapEntry(e.modInfo.id, e.iconFilePath)),
    );

    showDialog(
      context: context,
      builder: (context) {
        final hasMissingModsOrVariants =
            missingMods.isNotEmpty || missingVariants.isNotEmpty;
        final theme = Theme.of(context);
        final iconColor = theme.iconTheme.color?.withOpacity(0.8);
        final unsavedChangesNotice = hasUnsavedChanges
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "Your enabled mods no longer match"
                  " '${profileWithUnsavedChanges!.name}'."
                  " Choose whether to save them to it before activating"
                  " '${profile.name}'.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const SizedBox.shrink();

        return AlertDialog(
          title: Text(
            isRevert
                ? "Revert to '${profile.name}'?"
                : "Activate '${profile.name}'?",
          ),
          content: changes.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    unsavedChangesNotice,
                    Text(
                      isRevert
                          ? "Your enabled mods already match this profile."
                          : "This profile has the same mods you already have enabled.",
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      unsavedChangesNotice,
                      Text(
                        "Mods Being Enabled, Disabled, or Changing Version",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // if (modsToEnable.isNotEmpty)
                      _buildChangeSection(
                        null,
                        "Enabling mod",
                        modsToEnable,
                        Icons.check,
                        iconColor,
                        modIconsById,
                        context,
                      ),
                      // if (modsToDisable.isNotEmpty)
                      const SizedBox(height: 8),
                      _buildChangeSection(
                        null,
                        "Disabling mod",
                        modsToDisable,
                        Icons.close,
                        iconColor,
                        modIconsById,
                        context,
                      ),
                      // if (modsToSwap.isNotEmpty)
                      const SizedBox(height: 8),
                      _buildChangeSection(
                        null,
                        "Swapping version",
                        modsToSwap,
                        Icons.swap_horiz,
                        iconColor,
                        modIconsById,
                        context,
                      ),
                      if (hasMissingModsOrVariants)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildMissingModsSection(
                              missingMods,
                              missingVariants,
                              iconColor,
                              modIconsById,
                              context,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            if (hasUnsavedChanges)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  activateModProfile(profile.id);
                },
                child: const Text('Activate without saving'),
              ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (hasUnsavedChanges) {
                  final saved = await saveCurrentModListToProfile(
                    profileWithUnsavedChanges!.id,
                  );
                  if (!saved) {
                    // Don't switch away from a profile we couldn't save.
                    Fimber.w(
                      "Could not save '${profileWithUnsavedChanges.name}', so the switch was cancelled.",
                    );
                    return;
                  }
                }
                await activateModProfile(profile.id, allowReapply: isRevert);
              },
              icon: hasMissingModsOrVariants ? const Icon(Icons.warning) : null,
              label: Text(
                isRevert
                    ? (hasMissingModsOrVariants
                          ? 'Revert (ignore missing mods)'
                          : 'Revert')
                    : hasUnsavedChanges
                    ? 'Save and activate'
                    : (hasMissingModsOrVariants
                          ? 'Activate (ignore missing mods)'
                          : 'Activate'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChangeSection(
    String? title,
    String? tooltip,
    List<ModChange> changes,
    IconData icon,
    Color? iconColor,
    Map<String, String?> modIconsById,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          TextWithIcon(
            text: title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
        if (title != null) const SizedBox(height: 8),
        ...changes.map((change) {
          final modName =
              change.mod?.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
              'Unknown Mod (${change.modId})';
          String description;
          switch (change.changeType) {
            case ModChangeType.enable:
              description =
                  change.toVariant?.modInfo.formattedNameVersion ?? modName;
              break;
            case ModChangeType.disable:
              description =
                  change.fromVariant?.modInfo.formattedNameVersion ?? modName;
              break;
            case ModChangeType.swap:
              final fromVersion =
                  change.fromVariant?.modInfo.version?.toString() ?? 'Unknown';
              final toVersion =
                  change.toVariant?.modInfo.version?.toString() ?? 'Unknown';
              description = '$modName $fromVersion → $toVersion';
              break;
            default:
              description = modName;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: TextWithIcon(
              leading: MovingTooltipWidget.text(
                message: tooltip,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              widget: TextWithIcon(
                leading: modIconsById[change.modId] != null
                    ? Image.file(
                        modIconsById[change.modId]!.toFile(),
                        width: 20,
                      )
                    : null,
                text: description,
                style: GoogleFonts.roboto(
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMissingModsSection(
    List<ModChange> missingMods,
    List<ModChange> missingVariants,
    Color? iconColor,
    Map<String, String?> modIconsById,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    Widget buildRow(
      ModChange change,
      String text,
      IconData icon,
      String tooltip,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: TextWithIcon(
          leading: MovingTooltipWidget.text(
            message: tooltip,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          widget: TextWithIcon(
            leading: modIconsById[change.modId] != null
                ? Image.file(modIconsById[change.modId]!.toFile(), width: 20)
                : null,
            text: text,
            style: GoogleFonts.roboto(
              textStyle: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missingMods.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWithIcon(
                text: 'Missing Mods',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...missingMods.map((change) {
                final modId = change.modId;
                return buildRow(
                  change,
                  'Mod "$modId" is missing.',
                  Icons.warning,
                  "Missing Mod",
                );
              }),
            ],
          ),
        if (missingMods.isNotEmpty && missingVariants.isNotEmpty)
          const SizedBox(height: 8),
        if (missingVariants.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWithIcon(
                text: 'Missing Versions',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...missingVariants.map((change) {
                final modName =
                    change
                        .mod
                        ?.findFirstEnabledOrHighestVersion
                        ?.modInfo
                        .nameOrId ??
                    'Unknown Mod (${change.modId})';
                final hasAlt = change.toVariantAlternate != null;
                final text = hasAlt
                    ? 'Version ${change.variantAsShallowMod?.version} of "$modName" is not available, so ${change.toVariantAlternate!.bestVersion} will be used instead.'
                    : 'Version ${change.variantAsShallowMod?.version} of "$modName" is not available.';
                return buildRow(
                  change,
                  text,
                  hasAlt ? Icons.upgrade : Icons.warning,
                  hasAlt ? "Version substituted" : "Version missing",
                );
              }),
            ],
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    (missingMods.map((e) => e.variantAsShallowMod).toList() +
                            missingVariants
                                .map((e) => e.variantAsShallowMod)
                                .toList())
                        .nonNulls
                        .joinToString(
                          separator: '\n',
                          transform: (ShallowModVariant e) =>
                              "${e.modName ?? e.modId} - ${e.version}",
                        ),
              ),
            );
          },
          child: const Text("Copy missing to clipboard"),
        ),
        const SizedBox(height: 8),
        if (missingMods.isNotEmpty ||
            missingVariants
                .where((vari) => vari.toVariantAlternate == null)
                .isNotEmpty)
          Text(
            "Missing mods can't be enabled, so they stay off. They are still"
            " saved in the profile.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        // const SizedBox(height: 8),
      ],
    );
  }
}

enum ModChangeType { enable, disable, swap, missingMod, missingVariant }

class ModChange {
  final String modId;
  final Mod? mod;
  final ModVariant? fromVariant;
  final ModVariant? toVariant;
  final ShallowModVariant? variantAsShallowMod;

  /// If desired variant is not available, this is an alternate that was found.
  final ModVariant? toVariantAlternate;
  final ModChangeType changeType;

  ModChange({
    required this.modId,
    required this.mod,
    required this.fromVariant,
    required this.toVariant,
    required this.variantAsShallowMod,
    required this.toVariantAlternate,
    required this.changeType,
  });

  @override
  String toString() {
    return 'ModChange{modId: $modId, mod: $mod, fromVariant: $fromVariant, toVariant: $toVariant, modProfileVariant: $variantAsShallowMod, toVariantAlternate: $toVariantAlternate, changeType: $changeType}';
  }
}
