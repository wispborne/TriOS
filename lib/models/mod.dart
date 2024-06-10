import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';

import 'enabled_mods.dart';
import 'mod_variant.dart';

part '../generated/models/mod.freezed.dart';

@freezed
class Mod with _$Mod {
  const Mod._();

  const factory Mod({
    required String id,
    required bool isEnabledInGame,
    required List<ModVariant> modVariants,
  }) = _Mod;

  bool isEnabled(ModVariant variant) {
    return isEnabledInGame && variant.isModInfoEnabled;
  }

  bool isEnabledInGameSync(EnabledMods enabledMods) =>
      enabledMods.enabledMods.contains(id);

  List<ModVariant> get enabledVariants {
    return modVariants.where((variant) => isEnabled(variant)).toList();
  }

  ModVariant? get findFirstEnabled {
    for (var variant in modVariants) {
      if (isEnabled(variant)) {
        return variant;
      }
    }
    return null;
  }

  ModVariant? get findFirstDisabled {
    return modVariants.firstWhereOrNull((variant) => !isEnabled(variant));
  }

  ModVariant? get findHighestVersion => modVariants.findHighestVersion;

  ModVariant? get findFirstEnabledOrHighestVersion {
    return findFirstEnabled ?? findHighestVersion;
  }

  ModVariant? get findHighestEnabledVersion {
    return modVariants.where((v) => v.isModInfoEnabled).maxByOrNull(
        (variant) => variant.bestVersion ?? Version.parse("0.0.0"));
  }

  bool get hasEnabledVariant {
    return (findFirstEnabled) != null;
  }

  bool get hasDisabledVariant {
    return (findFirstDisabled) != null;
  }
}

extension ModListExtensions on List<Mod> {
  List<ModVariant> get variants {
    return expand((mod) => mod.modVariants).toList();
  }
}

extension ModVariantExt on ModVariant {
  /// Searches [modVariants] for the best possible match for this dependency.
  List<ModDependencyCheckResult> checkDependencies(
    List<ModVariant> modVariants,
    EnabledMods enabledMods,
    String? gameVersion,
  ) =>
      modInfo.checkDependencies(modVariants, enabledMods, gameVersion);

  GameCompatibility isCompatibleWithGameVersion(Version gameVersion) {
    return modInfo.isCompatibleWithGame(gameVersion.toString());
  }

  GameCompatibility isCompatibleWithGameVersionString(String gameVersion) {
    return modInfo.isCompatibleWithGame(gameVersion);
  }
}

extension ModVariantsExt on List<ModVariant> {
  ModVariant? highestVersionForGameVersion(Version gameVersion) {
    return where((it) =>
        it.isCompatibleWithGameVersion(gameVersion) !=
        GameCompatibility.incompatible).toList().findHighestVersion;
  }

  ModVariant? get findHighestVersion {
    return maxByOrNull(
        (variant) => variant.bestVersion ?? Version.parse("0.0.0"));
  }
}
