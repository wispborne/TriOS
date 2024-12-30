import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';

import '../models/mod_variant.dart';
import '../utils/generic_settings_notifier.dart';
import '../widgets/svg_image_icon.dart';
import 'models/mod_profile.dart';

final modProfilesProvider =
    AsyncNotifierProvider<ModProfileManagerNotifier, ModProfiles>(
        ModProfileManagerNotifier.new);

// isChangingProfile state
bool isChangingModProfileProvider = false;

/// Stores [ModProfile]s, provides methods to manage them, observable state.
class ModProfilesSettingsManager
    extends GenericAsyncSettingsManager<ModProfiles> {
  @override
  ModProfiles Function() get createDefaultState =>
      () => const ModProfiles(modProfiles: []);

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
  bool _pauseAutomaticProfileUpdates = false;

  @override
  Future<ModProfiles> build() async {
    // Load the initial state
    var initialState = await super.build();
    final settingsFile = settingsManager.settingsFile;

    // Look for pre-1.0 double/triple encoded json files and migrate them to proper json
    initialState = await migrateFromV1(settingsFile, initialState);

    // Set up the listener to watch enabled mod variants
    ref.listen<List<ModVariant>>(AppState.enabledModVariants, (previous, next) {
      updateFromModList();
    });

    return initialState;
  }

  Future<ModProfiles> migrateFromV1(
      File settingsFile, ModProfiles initialState) async {
    // Look for pre-1.0 double/triple encoded json files and migrate them to proper json
    final existingJsonFile =
        settingsFile.parent.resolve("trios_mod_profiles.json").toFile();
    if (initialState.modProfiles.isEmpty && existingJsonFile.existsSync()) {
      try {
        Fimber.i("Migrating mod profiles to proper json.");
        final jsonContents = existingJsonFile.readAsStringSync();
        final modProfiles = ModProfilesMapper.fromMap(
            jsonDecode(jsonDecode(jsonDecode(jsonContents))));

        if (modProfiles.modProfiles.isNotEmpty) {
          await existingJsonFile.rename("${existingJsonFile.path}.bak");
          initialState = modProfiles;
          state = AsyncData(initialState);
          await settingsManager.writeSettingsToDisk(initialState);
        }
      } catch (e, stack) {
        Fimber.e("Failed to migrate mod profiles to proper json.",
            ex: e, stacktrace: stack);
      }
    }
    return initialState;
  }

  @override
  GenericAsyncSettingsManager<ModProfiles> createSettingsManager() {
    return ModProfilesSettingsManager();
  }

  ModProfile? getCurrentModProfile() {
    final currentProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    return state.valueOrNull?.modProfiles
        .firstWhereOrNull((profile) => profile.id == currentProfileId);
  }

  void updateFromModList() {
    if (_pauseAutomaticProfileUpdates) return;

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

  void cloneModProfile(ModProfile profile) {
    createModProfile('${profile.name} (Copy)',
        enabledModVariants: profile.enabledModVariants);
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
    final currentModIdToShallow = {
      for (var item in currentlyEnabledShallows) item.modId: item
    };

    final profileModIdToShallow = {
      for (var item in profileShallows) item.modId: item
    };

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
      final modProfileVariant = profileModIdToShallow[modId];
      final toVariant = modVariants.firstWhereOrNull((v) {
        return v.smolId == modProfileVariant!.smolVariantId;
      });

      if (toVariant == null) {
        final highestVersion = mod?.findHighestVersion;
        final targetVersion = modProfileVariant?.version;

        final toVariantAlternate = highestVersion?.bestVersion == null
            ? null
            : targetVersion == null
                ? highestVersion
                : highestVersion!.bestVersion! > targetVersion
                    ? highestVersion
                    : null;

        // Missing variant
        return ModChange(
          modId: modId,
          mod: mod,
          fromVariant: fromVariant,
          toVariant: null,
          variantAsShallowMod: modProfileVariant,
          toVariantAlternate: toVariantAlternate,
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
    }).toList();

    // Mods to enable
    final modIdsToEnable = profileModIdToShallow.keys.toSet().difference(
          currentModIdToShallow.keys.toSet(),
        );

    final toEnable = modIdsToEnable.map((modId) {
      final mod = allMods.firstWhereOrNull((mod) => mod.id == modId);
      final modProfileVariant = profileModIdToShallow[modId];
      final toVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == modProfileVariant!.smolVariantId);

      if (mod == null || toVariant == null) {
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
      final mod = allMods.firstWhereOrNull((mod) => mod.id == modId);
      final modProfileVariant = profileModIdToShallow[modId];
      final fromVariant = modVariants.firstWhereOrNull(
          (v) => v.smolId == modProfileVariant?.smolVariantId);

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
      _pauseAutomaticProfileUpdates = true;
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = false;
      isChangingModProfileProvider = true;

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

      Fimber.i("here1.");
      await modVariantsNotifier.validateModDependencies();
      Fimber.i("here2.");
      ref.read(appSettings.notifier).update((s) => s.copyWith(
            activeModProfileId: modProfileId,
          ));
      Fimber.i("here3.");
      Fimber.i("Finished activating mod profile $modProfileId.");
    } catch (e, stack) {
      Fimber.e("Failed to activate mod profile $modProfileId.",
          ex: e, stacktrace: stack);
    } finally {
      Fimber.i("here4.");
      _pauseAutomaticProfileUpdates = false;
      modVariantsNotifier.shouldAutomaticallyReloadOnFilesChanged = true;
      isChangingModProfileProvider = false;
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

  void showActivateDialog(ModProfile profile, BuildContext context) {
    if (!context.mounted) {
      return;
    }

    final modProfileManager = ref.read(modProfilesProvider.notifier);
    final changes = modProfileManager.computeModProfileChanges(profile.id);

    // Group changes by type
    final modsToEnable =
        changes.where((c) => c.changeType == ModChangeType.enable).toList();
    final modsToDisable =
        changes.where((c) => c.changeType == ModChangeType.disable).toList();
    final modsToSwap =
        changes.where((c) => c.changeType == ModChangeType.swap).toList();
    final missingMods =
        changes.where((c) => c.changeType == ModChangeType.missingMod).toList();
    final missingVariants = changes
        .where((c) => c.changeType == ModChangeType.missingVariant)
        .toList();
    final latestVariants = (ref.read(AppState.mods))
        .map((mod) => mod.findHighestVersion)
        .nonNulls
        .toList();
    final modIconsById = Map.fromEntries(
        latestVariants.map((e) => MapEntry(e.modInfo.id, e.iconFilePath)));

    showDialog(
      context: context,
      builder: (context) {
        final hasMissingModsOrVariants =
            missingMods.isNotEmpty || missingVariants.isNotEmpty;
        final theme = Theme.of(context);
        final iconColor = theme.iconTheme.color?.withOpacity(0.8);
        return AlertDialog(
          title: Text("Activate '${profile.name}'?"),
          content: changes.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("This will not change which mods are enabled."),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mods Being Enabled, Disabled, or Changing Version",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // if (modsToEnable.isNotEmpty)
                      _buildChangeSection(null, "Enabling mod", modsToEnable,
                          Icons.check, iconColor, modIconsById, context),
                      // if (modsToDisable.isNotEmpty)
                      const SizedBox(height: 8),
                      _buildChangeSection(null, "Disabling mod", modsToDisable,
                          Icons.close, iconColor, modIconsById, context),
                      // if (modsToSwap.isNotEmpty)
                      const SizedBox(height: 8),
                      _buildChangeSection(null, "Swapping version", modsToSwap,
                          Icons.swap_horiz, iconColor, modIconsById, context),
                      if (hasMissingModsOrVariants)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildMissingModsSection(missingMods,
                                missingVariants, iconColor, context),
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
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(modProfilesProvider.notifier)
                    .activateModProfile(profile.id);
              },
              icon: hasMissingModsOrVariants ? const Icon(Icons.warning) : null,
              label: Text(hasMissingModsOrVariants
                  ? 'Activate (ignore missing)'
                  : 'Activate'),
            ),
            if (hasMissingModsOrVariants)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();

                  ref.read(modProfilesProvider.notifier)
                    ..cloneModProfile(profile)
                    ..activateModProfile(profile.id);
                },
                icon: const SvgImageIcon("assets/images/icon-clone.svg"),
                label: const Text('Back up Profile & Activate'),
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
      BuildContext context) {
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
                  child: Icon(icon, color: iconColor, size: 20)),
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
                )),
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
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    const Color? color = null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missingMods.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Missing Mods',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              ...missingMods.map((change) {
                final modId = change.modId;
                return ListTile(
                  leading: const Icon(Icons.warning, color: color),
                  title: Text('Mod "$modId" is missing.'),
                  dense: true,
                );
              }),
            ],
          ),
        if (missingVariants.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Missing Versions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              ...missingVariants.map((change) {
                final modName = change.mod?.findFirstEnabledOrHighestVersion
                        ?.modInfo.nameOrId ??
                    'Unknown Mod (${change.modId})';
                final hasAlt = change.toVariantAlternate != null;
                return ListTile(
                  leading: Icon(hasAlt ? Icons.upgrade : Icons.warning,
                      color: iconColor),
                  title: Text(hasAlt
                      ? 'Version ${change.variantAsShallowMod?.version} of "$modName" is not available, so ${change.toVariantAlternate!.bestVersion} will be used instead.'
                      : 'Version ${change.variantAsShallowMod?.version} of "$modName" is not available.'),
                  dense: true,
                );
              }),
            ],
          ),
        const SizedBox(height: 24),
        OutlinedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text:
                      (missingMods.map((e) => e.variantAsShallowMod).toList() +
                              missingVariants
                                  .map((e) => e.variantAsShallowMod)
                                  .toList())
                          .nonNulls
                          .joinToString(
                              separator: '\n',
                              transform: (ShallowModVariant e) =>
                                  "${e.modName ?? e.modId} - ${e.version}")));
            },
            child: const Text("Copy missing to clipboard")),
        const SizedBox(height: 8),
        if (missingMods.isNotEmpty ||
            missingVariants
                .where((vari) => vari.toVariantAlternate == null)
                .isNotEmpty)
          Text(
              "Missing mods will be discarded from your profile after activating.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
