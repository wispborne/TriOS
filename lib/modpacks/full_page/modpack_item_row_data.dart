import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
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

  /// Required dependencies of the installed variant that the user's mods do
  /// not currently satisfy (not installed, disabled, or wrong version).
  /// Empty when the item isn't installed, since nothing can be checked yet.
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

  bool get installedVersionIsBelowRecordedVersion {
    final installed = installedVariant?.modInfo.version;
    final recorded = parsedRecordedVersion;
    return installed != null && recorded != null && installed < recorded;
  }

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

  String? get catalogRecoveryText {
    final catalog = item.catalog;
    if (catalog == null || catalog.isEmpty) return null;
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

/// A required dependency of an installed pack item that the user can't satisfy
/// with their current mods. Wraps the same check the Mods page grid uses.
class ModpackDependencyWarning {
  final ModDependencyCheckResult check;

  const ModpackDependencyWarning(this.check);

  Dependency get dependency => check.dependency;

  ModDependencySatisfiedState get state => check.satisfiedAmount;

  /// e.g. "LazyLib (missing)", "MagicLib 1.4.0 (disabled: 1.2.0)".
  ///
  /// The parenthetical matches `ModDependencySatisfiedStateExt
  /// .getDependencyStateText` in mod_manager_extensions.dart, the wording the
  /// Mods page and the dashboard use. Kept inline because that extension name
  /// collides with one in mod_manager_logic.dart, which this file needs.
  String get message {
    final have = state.modVariant?.modInfo.version;
    final status = switch (state) {
      Satisfied _ => '(found $have)',
      Missing _ => '(missing)',
      Disabled _ => '(disabled: $have)',
      VersionInvalid _ => '(wrong version: $have)',
      VersionWarning _ => '(found: $have)',
    };
    return '${dependency.formattedNameVersion} $status';
  }
}

/// Joins saved item data to the preferred installed variant without changing
/// the pack's manual order.
///
/// [modCompatibility] is `AppState.modCompatibility`: each installed variant's
/// dependency check against the user's enabled mods. The same map drives the
/// Mods page grid, so both screens agree on what's missing.
List<ModpackItemRowData> buildModpackItemRows(
  ModpackDefinition definition,
  List<Mod> installedMods, [
  Map<SmolId, DependencyCheck> modCompatibility = const {},
]) {
  final modsById = {for (final mod in installedMods) mod.id: mod};

  return [
    for (var index = 0; index < definition.items.length; index++)
      _buildRow(
        definition.items[index],
        index,
        modsById[definition.items[index].modId],
        modCompatibility,
      ),
  ];
}

ModpackItemRowData _buildRow(
  ModpackItem item,
  int packOrder,
  Mod? installedMod,
  Map<SmolId, DependencyCheck> modCompatibility,
) {
  final variant = installedMod?.findFirstEnabledOrHighestVersion;
  final checks =
      variant == null
      ? const <ModDependencyCheckResult>[]
      : modCompatibility[variant.smolId]?.dependencyChecks ??
            const <ModDependencyCheckResult>[];

  final warnings = [
    for (final check in checks)
      if (check.satisfiedAmount is! Satisfied) ModpackDependencyWarning(check),
  ];

  return ModpackItemRowData(
    item: item,
    packOrder: packOrder,
    installedMod: installedMod,
    dependencyWarnings: warnings,
  );
}
