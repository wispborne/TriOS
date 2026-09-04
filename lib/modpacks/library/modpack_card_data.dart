import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/modpacks/modpack_coverage.dart';
import 'package:trios/modpacks/modpack_install_progress.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';

part 'modpack_card_data.mapper.dart';

/// The labels a library card can carry. A card shows every one that applies.
enum ModpackCardLabel {
  draft('Draft'),
  unsavedChanges('Unsaved changes'),
  updateAvailable('Update available'),
  failed('Failed'),
  installing('Installing');

  final String text;

  const ModpackCardLabel(this.text);
}

/// Everything one library card shows. Built fresh from the library, the
/// current mod list, and any running installation; never saved.
@MappableClass()
class ModpackCardData with ModpackCardDataMappable {
  final String packId;
  final String name;
  final String? author;
  final String? description;
  final String? gameVersion;
  final String? homepageUrl;
  final String? updateUrl;

  /// The saved version. Null for a pack that has never been saved.
  final int? packVersion;

  final int installedCount;
  final int totalCount;
  final int missingCount;

  /// The pack has a draft but no saved definition.
  final bool isDraftOnly;

  /// The pack is saved and also has a draft with changes.
  final bool hasUnsavedChanges;

  /// The online version, when it's newer than the saved one.
  final int? onlineVersionAvailable;

  /// At least one item failed to install last time.
  final bool hasFailures;

  /// At least one item has no usable source yet. Only a draft can.
  final bool needsSources;

  final ModpackInstallProgress? installProgress;

  const ModpackCardData({
    required this.packId,
    required this.name,
    this.author,
    this.description,
    this.gameVersion,
    this.homepageUrl,
    this.updateUrl,
    this.packVersion,
    this.installedCount = 0,
    this.totalCount = 0,
    this.missingCount = 0,
    this.isDraftOnly = false,
    this.hasUnsavedChanges = false,
    this.onlineVersionAvailable,
    this.hasFailures = false,
    this.needsSources = false,
    this.installProgress,
  });

  bool get isInstalling => installProgress != null;

  bool get updateAvailable => onlineVersionAvailable != null;

  /// Whether every item has an installed mod. An empty pack is not.
  bool get isFullyInstalled => totalCount > 0 && missingCount == 0;

  /// A draft-only pack is unsaved by definition, so it shows Draft alone.
  List<ModpackCardLabel> get labels => [
    if (isDraftOnly) ModpackCardLabel.draft,
    if (!isDraftOnly && hasUnsavedChanges) ModpackCardLabel.unsavedChanges,
    if (updateAvailable) ModpackCardLabel.updateAvailable,
    if (hasFailures) ModpackCardLabel.failed,
    if (isInstalling) ModpackCardLabel.installing,
  ];
}

/// Builds one card per pack in [data]: every saved pack, plus every draft
/// that has never been saved.
///
/// A saved pack with a draft is described by its saved definition, because
/// the library's actions work on that. The draft only adds the Unsaved
/// changes label and any items that still need sources.
List<ModpackCardData> buildModpackCardData(
  ModpacksData data, {
  required Set<String> installedModIds,
  Map<String, ModpackInstallProgress> installations = const {},
}) {
  final cards = <ModpackCardData>[];

  for (final packId in data.allPackIds) {
    final entry = data.packs[packId];
    final draft = data.drafts[packId];
    final coverage = calculateEntryCoverage(
      entry: entry,
      draft: draft,
      installedModIds: installedModIds,
    );

    if (entry != null) {
      final definition = entry.definition;
      cards.add(
        ModpackCardData(
          packId: packId,
          name: definition.name,
          author: definition.author,
          description: definition.description,
          gameVersion: definition.gameVersion,
          homepageUrl: definition.homepageUrl,
          updateUrl: definition.updateUrl,
          packVersion: definition.version,
          installedCount: coverage.installedCount,
          totalCount: coverage.totalCount,
          missingCount: coverage.missingCount,
          hasUnsavedChanges: draft != null,
          onlineVersionAvailable: coverage.onlineVersionAvailable,
          hasFailures: coverage.hasFailures,
          needsSources: coverage.hasSourceProblems,
          installProgress: installations[packId],
        ),
      );
    } else if (draft != null) {
      cards.add(
        ModpackCardData(
          packId: packId,
          name: draft.name.trim(),
          author: _blankToNull(draft.author),
          description: _blankToNull(draft.description),
          gameVersion: _blankToNull(draft.gameVersion),
          homepageUrl: _blankToNull(draft.homepageUrl),
          updateUrl: _blankToNull(draft.updateUrl),
          installedCount: coverage.installedCount,
          totalCount: coverage.totalCount,
          missingCount: coverage.missingCount,
          isDraftOnly: true,
          hasUnsavedChanges: true,
          needsSources: coverage.hasSourceProblems,
          installProgress: installations[packId],
        ),
      );
    }
  }

  return cards;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
