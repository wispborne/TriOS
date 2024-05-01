import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';

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

  Future<bool> isEnabled(ModVariant variant) async {
    return isEnabledInGame && await variant.isModInfoEnabled;
  }

  Future<List<ModVariant>> get enabledVariants async {
    return (await modVariants.whereAsync((variant) => isEnabled(variant)))
        .toList();
  }

  Future<ModVariant?> get findFirstEnabled async {
    for (var variant in modVariants) {
      if (await isEnabled(variant)) {
        return variant;
      }
    }
    return null;
  }

  Future<ModVariant?> get findFirstDisabled async {
    // return modVariants.firstWhereOrNull((variant) => !isEnabled(variant));
    for (var variant in modVariants) {
      if (!(await isEnabled(variant))) {
        return variant;
      }
    }
    return null;
  }

  ModVariant? get findHighestVersion {
    return modVariants.maxByOrNull(
        (variant) => variant.bestVersion ?? Version.parse("0.0.0"));
  }

  Future<ModVariant?> get findFirstEnabledOrHighestVersion async {
    return await findFirstEnabled ?? findHighestVersion;
  }

  Future<bool> get hasEnabledVariant async {
    return (await findFirstEnabled) != null;
  }

  Future<bool> get hasDisabledVariant async {
    return (await findFirstDisabled) != null;
  }
}

extension ModListExtensions on List<Mod> {
  List<ModVariant> get variants {
    return expand((mod) => mod.modVariants).toList();
  }
}
