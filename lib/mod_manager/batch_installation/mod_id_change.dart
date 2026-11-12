import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/trios/download_manager/download_manager.dart';

/// An update that installed a mod with a different ID from the mod it was
/// started from.
class ModIdChange {
  /// The mod the update was started from.
  final ModInfo oldModInfo;

  /// The mod the download actually contained.
  final ModInfo newModInfo;

  const ModIdChange({required this.oldModInfo, required this.newModInfo});
}

/// Returns the old and new mod when an update installed a mod with a different
/// ID. Returns null otherwise.
///
/// [download] is the batch entry's download. Only the update and redownload
/// buttons create a [ModDownload], because only they know which mod is being
/// updated. [modsInArchive] is how many mods the archive held.
/// [installedMods] are the mods that installed without errors.
///
/// Both counts must be one. If the archive held two mods and one failed, the
/// one left might be a library bundled with the renamed mod, not the mod
/// itself.
ModIdChange? detectModIdChange({
  required Download? download,
  required int modsInArchive,
  required List<ModInfo> installedMods,
}) {
  if (download is! ModDownload) return null;
  if (modsInArchive != 1 || installedMods.length != 1) return null;

  final newModInfo = installedMods.single;
  if (newModInfo.id == download.modInfo.id) return null;

  return ModIdChange(oldModInfo: download.modInfo, newModInfo: newModInfo);
}

/// The enabled mods that list [modId] as a dependency.
List<Mod> enabledModsDependingOn(List<Mod> mods, String modId) => mods
    .where(
      (mod) =>
          mod.findFirstEnabled?.modInfo.dependencies.any(
            (dependency) => dependency.id == modId,
          ) ==
          true,
    )
    .toList();
