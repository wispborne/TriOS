import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod.dart';

part 'enabled_mods.mapper.dart';

@MappableClass()
class EnabledMods with EnabledModsMappable {
  final Set<String> enabledMods;

  const EnabledMods(this.enabledMods);

  /// Returns only the mod ids that are in both the `enabled_mods.json` file and the provided mod list.
  EnabledMods filterOutMissingMods(List<Mod> mods) {
    return EnabledMods(
      enabledMods
          .where((enabledModId) => mods.any((mod) => mod.id == enabledModId))
          .toSet(),
    );
  }
}
