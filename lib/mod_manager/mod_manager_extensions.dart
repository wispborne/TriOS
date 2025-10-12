import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

import '../models/mod.dart';
import '../models/mod_info.dart';
import 'mod_manager_logic.dart';

extension DependencyExt on Dependency {
  ModDependencySatisfiedState isSatisfiedBy(
    ModVariant variant,
    List<String> enabledModIds,
  ) {
    if (id != variant.modInfo.id) {
      return Missing();
    }

    if (version != null) {
      if (variant.modInfo.version?.major != version!.major) {
        return VersionInvalid(variant);
      } else if (variant.modInfo.version != null &&
          variant.modInfo.version?.minor != version!.minor &&
          variant.modInfo.version!.minor.compareRecognizingNumbers(
                version!.minor,
              ) <
              0) {
        return VersionWarning(variant);
      }
    }

    if (!variant.modInfo.isEnabled(enabledModIds)) {
      return Disabled(variant);
    }

    return Satisfied(variant);
  }

  /// Searches [allMods] for the best possible match for this dependency.
  ModDependencySatisfiedState isSatisfiedByAny(
    List<ModVariant> allMods,
    List<String> enabledModIds,
    String? gameVersion,
  ) {
    var foundDependencies = allMods.where((mod) => mod.modInfo.id == id);
    if (foundDependencies.isEmpty) {
      return Missing();
    }

    final satisfyResults = foundDependencies
        .map((variant) => isSatisfiedBy(variant, enabledModIds))
        .toList();

    // Return the least severe state.
    return getTopDependencySeverity(
      satisfyResults,
      gameVersion,
      sortLeastSevere: true,
    );
    // if (satisfyResults.contains(DependencyStateType.Satisfied)) {
    //   return DependencyStateType.Satisfied;
    // } else if (satisfyResults.contains(DependencyStateType.Disabled)) {
    //   return DependencyStateType.Disabled;
    // } else if (satisfyResults.contains(DependencyStateType.VersionWarning)) {
    //   return DependencyStateType.VersionWarning;
    // } else if (satisfyResults.contains(DependencyStateType.VersionInvalid)) {
    //   return DependencyStateType.VersionInvalid;
    // } else {
    //   return DependencyStateType.Missing;
    // }
  }
}

extension ModInfoExt on ModInfo {
  GameCompatibility isCompatibleWithGame(String? gameVersion) {
    return compareGameVersions(gameVersion, this.gameVersion);
  }

  bool isEnabled(List<String> enabledModIds) {
    return enabledModIds.contains(id);
  }

  /// Searches [modVariants] for the best possible match for this dependency.
  List<ModDependencyCheckResult> checkDependencies(
    List<ModVariant> modVariants,
    List<String> enabledModIds,
    String? gameVersion,
  ) {
    return dependencies.map((dep) {
      return ModDependencyCheckResult(
        dep,
        dep.isSatisfiedByAny(modVariants, enabledModIds, gameVersion),
      );
    }).toList();
  }
}

extension ModExt on Mod {
  // VersionCheckComparison? updateCheck(
  //     Map<String, RemoteVersionCheckResult> versionChecks) {
  //   return modVariants.updateCheck(versionChecks);
  // }

  VersionCheckComparison? updateCheck(VersionCheckerState? versionChecks) {
    return modVariants.updateCheck(
      versionChecks?.versionCheckResultsBySmolId ?? {},
    );
  }

  Comparable<num>? getSortValueForEnabled() => hasEnabledVariant ? 1 : 0;

  Comparable<String>? getSortValueForType() =>
      findFirstEnabledOrHighestVersion?.modInfo.isUtility == true
      ? "utility"
      : findFirstEnabledOrHighestVersion?.modInfo.isTotalConversion == true
      ? "total conversion"
      : "other";

  /// Returns the name of the mod, or the ID if no variant is enabled.
  /// If [useModLoadOrderSort] is true, the name will be sorted by the mod's load order
  /// instead of what the user would normally expect from an alphabetical sort.
  Comparable<String>? getSortValueForName(bool useModLoadOrderSort) =>
      useModLoadOrderSort
      ? findFirstEnabledOrHighestVersion?.modInfo.nameOrId
      : findFirstEnabledOrHighestVersion?.modInfo.nameOrId.trim().toLowerCase();

  Comparable<String>? getSortValueForAuthor() =>
      findFirstEnabledOrHighestVersion?.modInfo.author?.toLowerCase() ?? "";

  Comparable<num>? getSortValueForUpdateStatus(
    WidgetRef ref,
    ModsMetadata? modsMetadata,
  ) {
    final versionCheckResultsNew = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;
    final versionCheckComparison = updateCheck(versionCheckResultsNew);
    final updateInt = versionCheckComparison?.comparisonInt;
    final metadata = modsMetadata?.getMergedModMetadata(id);
    final areUpdatesMuted = metadata != null && metadata.areUpdatesMuted;
    final changelogUrl = ref
        .read(AppState.changelogsProvider.notifier)
        .getChangelogUrl(
          versionCheckComparison?.variant.versionCheckerInfo,
          versionCheckComparison?.remoteVersionCheck,
        );

    if (updateInt == null) {
      // Missing version checker
      return -20;
    } else if (updateInt == -1 && !areUpdatesMuted) {
      // Needs update
      if (changelogUrl.isNotNullOrEmpty()) {
        return 21;
      } else {
        return 20;
      }
    } else if (updateInt >= 0 || areUpdatesMuted) {
      // Up to date or local newer than remote (time traveler)
      if (changelogUrl.isNotNullOrEmpty()) {
        return 1;
      } else {
        return 0;
      }
    } else {
      // ??????????
      return -30;
    }
  }

  Comparable<String>? getSortValueForModIcon() =>
      findFirstEnabledOrHighestVersion?.iconFilePath;

  Comparable<String>? getSortValueForVersion() =>
      findFirstEnabledOrHighestVersion?.modInfo.version?.toString();

  Comparable<num>? getSortValueForVram(
    VramEstimatorManagerState? vramEstState,
  ) =>
      vramEstState?.modVramInfo[findHighestEnabledVersion?.smolId]
          ?.imagesNotIncludingGraphicsLib()
          .sum() ??
      0;

  Comparable<String> getSortValueForGameVersion() =>
      findFirstEnabledOrHighestVersion?.modInfo.gameVersion ?? "";

  Comparable<num> getSortValueForFirstSeen(ModsMetadata? modsMetadata) =>
      modsMetadata?.getMergedModMetadata(id)?.firstSeen ?? 0;

  Comparable<num> getSortValueForLastEnabled(ModsMetadata? modsMetadata) =>
      modsMetadata?.getMergedModMetadata(id)?.lastEnabled ?? 0;
}

extension ModDependencySatisfiedStateExt on ModDependencySatisfiedState {
  String getDependencyStateText() {
    return switch (this) {
      Satisfied _ => "(found ${modVariant?.modInfo.version})",
      Missing _ => "(missing)",
      Disabled _ => "(disabled: ${modVariant?.modInfo.version})",
      VersionInvalid _ => "(wrong version: ${modVariant?.modInfo.version})",
      VersionWarning _ => "(found: ${modVariant?.modInfo.version})",
    };
  }
}

extension ModListExtensions on List<Mod> {
  List<ModVariant> get variants {
    return expand((mod) => mod.modVariants).toList();
  }

  List<Mod> get sortedByName {
    return sortedBy(
      (mod) =>
          mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
          "(no variant)",
    );
  }
}

extension ModListExtensionsNullable on List<Mod?> {
  List<Mod?> get sortedByName {
    return sortedBy(
      (mod) =>
          mod?.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
          "(no variant)",
    );
  }
}

extension ModVariantListExtensionsNullable on List<ModVariant?> {
  List<ModVariant?> get sortedByName {
    return sortedBy((variant) => variant?.modInfo.nameOrId ?? "");
  }
}

extension ModVariantListExtensions on List<ModVariant> {
  List<ModVariant> get sortedByName {
    return sortedBy((variant) => variant.modInfo.nameOrId);
  }

  List<Mod> getAsMods(List<Mod> allMods) {
    return allMods
        .where((mod) => any((variant) => variant.modInfo.id == mod.id))
        .toList();
  }
}

extension ModVariantExt on ModVariant {
  /// Searches [modVariants] for the best possible match for this dependency.
  List<ModDependencyCheckResult> checkDependencies(
    List<ModVariant> modVariants,
    List<String> enabledModIds,
    String? gameVersion,
  ) => modInfo.checkDependencies(modVariants, enabledModIds, gameVersion);

  GameCompatibility isCompatibleWithGameVersion(String gameVersion) {
    return modInfo.isCompatibleWithGame(gameVersion);
  }

  VersionCheckComparison? updateCheck(VersionCheckerState? versionChecks) {
    return VersionCheckComparison(
      this,
      versionChecks?.versionCheckResultsBySmolId ?? {},
    );
  }
}

extension ModVariantsExt on List<ModVariant> {
  /// Finds the highest version of the mod variant that is compatible with the specified game version.
  ///
  /// This method filters the list of `ModVariant` objects to only include those that are
  /// compatible with the given `gameVersion`. It then returns the highest version among
  /// those compatible variants.
  ///
  /// Returns `null` if no compatible variant is found.
  ModVariant? highestVersionForGameVersion(String gameVersion) {
    return where(
      (it) =>
          it.isCompatibleWithGameVersion(gameVersion) !=
          GameCompatibility.incompatible,
    ).toList().findHighestVersion;
  }

  /// Prefers the highest version of the mod variant that is compatible with the specified game version,
  /// or the highest version overall if no specific game version is provided or if no compatible variant is found.
  ///
  /// This method first attempts to find the highest version for the given `gameVersion`.
  /// If none is found, or if `gameVersion` is `null`, it defaults to returning the highest version overall.
  ModVariant? preferHighestVersionForGameVersion(String? gameVersion) {
    if (gameVersion == null) {
      return findHighestVersion;
    }
    return highestVersionForGameVersion(gameVersion) ?? findHighestVersion;
  }

  /// Finds the highest version of the mod variant in the list.
  ///
  /// This method returns the mod variant with the highest version
  /// by comparing the `ModVariant` objects in the list.
  ModVariant? get findHighestVersion {
    return maxByOrNull((variant) => variant);
  }

  /// Checks for updates of the mod variants against the provided version checks.
  ///
  /// This method iterates through the list of mod variants in their sorted order,
  /// comparing each one against the corresponding `RemoteVersionCheckResult`
  /// in the `versionChecks` map. If a valid comparison is found, it is returned.
  ///
  /// Returns `null` if no valid comparison result is found.
  VersionCheckComparison? updateCheck(
    Map<String, RemoteVersionCheckResult> versionCheckCache,
  ) {
    for (final variant in sortedDescending()) {
      final RemoteVersionCheckResult? versionCheck =
          versionCheckCache[variant.smolId];
      if (versionCheck == null || variant.versionCheckerInfo == null) continue;
      // Now, we have a mod variant with a version checker info and a remote version check result.

      // See if the remote version is newer than ALL local versions,
      // not just the one with the .version file we're checking.
      final List<VersionCheckComparison> versionChecks = map(
        (v) => versionCheck.compareToLocal(v),
      ).nonNulls.toList();
      if (versionChecks.isEmpty) continue;
      // If the remote version is newer than all local versions with a VC file, we have an update.
      final isRemoteNewerThanAllLocal = versionChecks.all(
        (comparison) =>
            comparison.hasUpdate || comparison.comparisonInt == null,
      );

      if (isRemoteNewerThanAllLocal) {
        // If there's an update, return the comparison for the variant that had the .version file with the update.
        // That way, code that shows/downloads the update knows which variant has the urls it needs.
        return versionCheck.compareToLocal(variant);
      } else {
        return versionCheck.compareToLocal(findHighestVersion!);
        // // Otherwise, just return the highest version comparison file like usual.
        // return highestVersionWithVersionChecker == null
        //     ? null
        //     : versionCheck.compareToLocal(highestVersionWithVersionChecker);
      }
    }

    return null;
  }
}
