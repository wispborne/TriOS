import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/utils/extensions.dart';

import 'mod_variant.dart';

part 'mod.mapper.dart';

@MappableClass()
class Mod with ModMappable implements Comparable<Mod>, WispGridItem {
  Mod({
    required this.id,
    required this.isEnabledInGame,
    required this.modVariants,
  });

  final String id;
  final bool isEnabledInGame;
  final List<ModVariant> modVariants;

  bool isEnabled(ModVariant variant) =>
      isEnabledInGame && variant.isModInfoEnabled;

  bool isEnabledInGameSync(List<String> enabledModIds) =>
      enabledModIds.contains(id);

  // Computed values below are `late final`: cached on first access per
  // instance. `Mod` is immutable (all fields final), so new values only
  // arrive via fresh instances and the caches stay correct for life.
  // dart_mappable serializes only constructor-declared fields, so these
  // extras don't affect serialization, ==, or hashCode.

  late final List<ModVariant> enabledVariants = modVariants
      .where((variant) => isEnabled(variant))
      .toList();

  late final ModVariant? findFirstEnabled = _findFirstEnabled();

  ModVariant? _findFirstEnabled() {
    for (var variant in modVariants) {
      if (isEnabled(variant)) {
        return variant;
      }
    }
    return null;
  }

  bool get isEnabledOnUi => findFirstEnabled != null;

  late final ModVariant? findFirstDisabled = modVariants.firstWhereOrNull(
    (variant) => !isEnabled(variant),
  );

  late final ModVariant? findHighestVersion = modVariants.findHighestVersion;

  late final ModVariant? findFirstEnabledOrHighestVersion =
      findFirstEnabled ?? findHighestVersion;

  late final ModVariant? findHighestEnabledVersion = modVariants
      .where((v) => v.isModInfoEnabled)
      .maxByOrNull((variant) => variant);

  bool get hasEnabledVariant => findFirstEnabled != null;

  bool get hasDisabledVariant => findFirstDisabled != null;

  @override
  int compareTo(Mod other) =>
      findFirstEnabledOrHighestVersion?.modInfo.nameOrId.compareTo(
        other.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? "",
      ) ??
      0;

  @override
  String get key => id;

  String get name => modVariants.first.modInfo.nameOrId;
}
