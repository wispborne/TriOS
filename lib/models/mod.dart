import 'package:collection/collection.dart';
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
    required List<ModVariant> modVariants,
  }) = _Mod;

  bool isEnabled(ModVariant variant) {
    return modVariants.contains(variant);
  }

  List<ModVariant> get enabledVariants {
    return modVariants.where((variant) => isEnabled(variant)).toList();
  }

  ModVariant? get findFirstEnabled {
    return modVariants.firstWhereOrNull((variant) => isEnabled(variant));
  }

  ModVariant? get findFirstDisabled {
    return modVariants.firstWhereOrNull((variant) => !isEnabled(variant));
  }

  ModVariant? get findHighestVersion {
    return modVariants.maxByOrNull(
        (variant) => variant.bestVersion ?? Version.parse("0.0.0"));
  }

  ModVariant? get findFirstEnabledOrHighestVersion {
    return findFirstEnabled ?? findHighestVersion;
  }

  bool get hasEnabledVariant {
    return findFirstEnabled != null;
  }

  bool get hasDisabledVariant {
    return findFirstDisabled != null;
  }
}

extension ModListExtensions on List<Mod> {
  List<ModVariant> get variants {
    return expand((mod) => mod.modVariants).toList();
  }
}