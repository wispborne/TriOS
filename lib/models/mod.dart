import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';

import 'enabled_mods.dart';
import 'mod_variant.dart';

part '../generated/models/mod.freezed.dart';

@freezed
class Mod with _$Mod implements Comparable<Mod> {
  const Mod._();

  const factory Mod({
    required String id,
    required bool isEnabledInGame,
    required List<ModVariant> modVariants,
  }) = _Mod;

  bool isEnabled(ModVariant variant) {
    return isEnabledInGame && variant.isModInfoEnabled;
  }

  bool isEnabledInGameSync(List<String> enabledModIds) =>
      enabledModIds.contains(id);

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
    return modVariants
        .where((v) => v.isModInfoEnabled)
        .maxByOrNull((variant) => variant);
  }

  bool get hasEnabledVariant {
    return (findFirstEnabled) != null;
  }

  bool get hasDisabledVariant {
    return (findFirstDisabled) != null;
  }

  @override
  int compareTo(Mod other) =>
      findFirstEnabledOrHighestVersion?.modInfo.nameOrId.compareTo(
          other.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? "") ??
      0;
}
