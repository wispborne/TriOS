import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/modpack_format.dart';

/// Source discovery never changes global records or contacts a remote server.
ModpackDraftItem discoverModpackItem(ModVariant variant, ModRecord? record) {
  final vc = variant.versionCheckerInfo;
  final candidates = <ModRecordSource?>[
    record?.modpackSource,
    record?.userOverrides['versionChecker'],
    record?.userOverrides['catalog'],
    record?.userOverrides['downloadHistory'],
    VersionCheckerSource(masterVersionFileUrl: vc?.masterVersionFile),
    record?.catalog,
    record?.downloadHistory,
  ];
  String? url;
  ModpackItemSourceType? type;
  for (final source in candidates) {
    final address = switch (source) {
      VersionCheckerSource s => s.masterVersionFileUrl,
      CatalogSource s => s.directDownloadUrl,
      DownloadHistorySource s => s.lastDownloadedFrom,
      _ => null,
    };
    if (address == null || !isSafeModpackUrl(address)) continue;
    url = fixUrl(address.trim());
    type = source is VersionCheckerSource ? .versionFile : .directDownload;
    break;
  }
  return ModpackDraftItem(
    modId: variant.modInfo.id,
    name: variant.modInfo.name,
    version: variant.modInfo.version?.toString(),
    url: url,
    sourceType: type,
    catalog: ModpackCatalogClues(
      name: record?.catalog?.name,
      forumTopicId: record?.forumThreadId ?? vc?.modThreadId,
      nexusModsId: record?.nexusModsId ?? vc?.modNexusId,
    ),
  );
}

/// Includes transitive required dependencies, even through cycles. Missing
/// local mods remain warnings; only installed variants can be offered to add.
class ModpackDependencies {
  final List<ModVariant> available;
  final List<String> warnings;

  const ModpackDependencies(this.available, this.warnings);
}

ModpackDependencies findModpackDependencies(
  List<ModpackDraftItem> items,
  List<Mod> mods,
) {
  final byId = {
    for (final mod in mods) mod.id: mod.findFirstEnabledOrHighestVersion,
  };
  final packIds = items.map((item) => item.modId).toSet();
  final seen = <String>{};
  final available = <String, ModVariant>{};
  final warnings = <String>{};
  void visit(String? id) {
    if (id == null || !seen.add(id)) return;
    final variant = byId[id];
    if (variant == null) return;
    for (final dependency in variant.modInfo.dependencies) {
      final target = byId[dependency.id];
      if (!packIds.contains(dependency.id)) {
        warnings.add(
          '${variant.modInfo.nameOrId} requires ${dependency.formattedNameVersion} (not in this pack).',
        );
        if (target != null) available[target.modInfo.id] = target;
      }
      if (target == null) {
        warnings.add('${dependency.nameOrId} is not installed locally.');
      } else if (dependency.version != null &&
          (target.modInfo.version == null ||
              target.modInfo.version! < dependency.version!)) {
        warnings.add(
          '${dependency.nameOrId} needs ${dependency.version}; installed: ${target.modInfo.version ?? 'unknown'}.',
        );
      }
      visit(dependency.id);
    }
  }

  for (final item in items) {
    visit(item.modId);
  }
  return ModpackDependencies(available.values.toList(), warnings.toList());
}

String? modpackLabelError(String value) {
  final label = value.trim();
  if (label.isEmpty) return 'Enter a label, or choose None.';
  if (label.length > ModpackLimits.maxLabelLength) {
    return 'Use at most 40 characters.';
  }
  if (RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(value)) {
    return 'Use a single line without control characters.';
  }
  return null;
}

List<T> moveModpackItems<T>(
  List<T> items,
  Set<int> movingIndices,
  int beforeIndex,
) {
  final moving = [
    for (var i = 0; i < items.length; i++)
      if (movingIndices.contains(i)) items[i],
  ];
  final result = [
    for (var i = 0; i < items.length; i++)
      if (!movingIndices.contains(i)) items[i],
  ];
  final insertion =
      beforeIndex - movingIndices.where((i) => i < beforeIndex).length;
  result.insertAll(insertion.clamp(0, result.length), moving);
  return result;
}
