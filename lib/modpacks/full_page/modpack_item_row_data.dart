import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';

/// One read-only row on a saved modpack's full page.
class ModpackItemRowData implements WispGridItem {
  final ModpackItem item;
  final int packOrder;
  final Mod? installedMod;
  final List<ModpackDependencyWarning> dependencyWarnings;

  const ModpackItemRowData({
    required this.item,
    required this.packOrder,
    required this.installedMod,
    this.dependencyWarnings = const [],
  });

  @override
  String get key => item.modId;

  ModVariant? get installedVariant =>
      installedMod?.findFirstEnabledOrHighestVersion;

  bool get isInstalled => installedVariant != null;

  String get displayName {
    final recordedName = item.name?.trim();
    if (recordedName != null && recordedName.isNotEmpty) return recordedName;
    return installedVariant?.modInfo.nameOrId ?? item.modId;
  }

  String? get author {
    final value = installedVariant?.modInfo.author?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get installedVersion => installedVariant?.modInfo.version?.toString();

  String? get recordedVersion {
    final value = item.version?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Version? get parsedRecordedVersion => item.parsedVersion;

  /// Shows the installed version once, adding the recorded version only when
  /// the two differ.
  String get combinedVersion {
    final installed = installedVersion;
    final recorded = recordedVersion;
    if (installed == null) return recorded ?? '—';
    if (recorded == null ||
        installedVariant?.modInfo.version == parsedRecordedVersion) {
      return installed;
    }
    return '$installed (modpack: $recorded)';
  }

  String get sourceTypeLabel => switch (item.sourceType) {
    ModpackItemSourceType.versionFile => 'Version Checker',
    ModpackItemSourceType.directDownload => 'Fixed download',
  };

  String get dependencyWarningText =>
      dependencyWarnings.map((warning) => warning.message).join('\n');

  String get catalogRecoveryText {
    final catalog = item.catalog;
    if (catalog == null || catalog.isEmpty) return 'None';
    return [
      if (catalog.name?.trim().isNotEmpty == true)
        'Name: ${catalog.name!.trim()}',
      if (catalog.forumTopicId?.trim().isNotEmpty == true)
        'Forum topic: ${catalog.forumTopicId!.trim()}',
      if (catalog.nexusModsId?.trim().isNotEmpty == true)
        'Nexus Mods: ${catalog.nexusModsId!.trim()}',
      if (catalog.unknownFields.isNotEmpty)
        'Additional fields: ${catalog.unknownFields.keys.join(', ')}',
    ].join(' • ');
  }
}

class ModpackDependencyWarning {
  final Dependency dependency;
  final String message;

  const ModpackDependencyWarning({
    required this.dependency,
    required this.message,
  });
}

/// Joins saved item data to the preferred installed variant without changing
/// the pack's manual order.
List<ModpackItemRowData> buildModpackItemRows(
  ModpackDefinition definition,
  List<Mod> installedMods,
) {
  final modsById = {for (final mod in installedMods) mod.id: mod};
  final packModIds = definition.items.map((item) => item.modId).toSet();

  return [
    for (var index = 0; index < definition.items.length; index++)
      _buildRow(
        definition.items[index],
        index,
        modsById[definition.items[index].modId],
        packModIds,
      ),
  ];
}

ModpackItemRowData _buildRow(
  ModpackItem item,
  int packOrder,
  Mod? installedMod,
  Set<String> packModIds,
) {
  final dependencies =
      installedMod?.findFirstEnabledOrHighestVersion?.modInfo.dependencies ??
      const <Dependency>[];
  final warnings = <ModpackDependencyWarning>[];

  for (final dependency in dependencies) {
    final dependencyId = dependency.id;
    if (dependencyId != null && packModIds.contains(dependencyId)) continue;

    final displayName = dependency.formattedNameVersion;
    final message = dependencyId == null
        ? 'Requires $displayName, but its mod ID is unknown.'
        : 'Requires $displayName, which is not in this modpack.';
    warnings.add(
      ModpackDependencyWarning(dependency: dependency, message: message),
    );
  }

  return ModpackItemRowData(
    item: item,
    packOrder: packOrder,
    installedMod: installedMod,
    dependencyWarnings: warnings,
  );
}
