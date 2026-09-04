import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/modpacks/modpack_coverage.dart';
import 'package:trios/modpacks/modpack_install_progress.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';

part 'modpack_card_data.mapper.dart';

enum ModpackCardLabel {
  draft('Draft'),
  unsavedChanges('Unsaved changes'),
  updateAvailable('Update available'),
  failed('Failed'),
  installing('Installing');

  final String text;

  const ModpackCardLabel(this.text);
}

/// Display data for a modpack library card.
@MappableClass()
class ModpackCardData with ModpackCardDataMappable {
  final String packId;
  final String name;
  final String? author;
  final String? description;
  final String? gameVersion;
  final String? homepageUrl;
  final String? updateUrl;

  /// Null for unsaved drafts.
  final int? packVersion;

  final int installedCount;
  final int totalCount;
  final int missingCount;

  final bool isDraftOnly;

  final bool hasUnsavedChanges;

  /// Newer version reported by the update check.
  final int? onlineVersionAvailable;

  final bool hasFailures;

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

  /// Empty packs are not considered installed.
  bool get isFullyInstalled => totalCount > 0 && missingCount == 0;

  /// Draft-only packs show Draft instead of Unsaved changes.
  List<ModpackCardLabel> get labels => [
    if (isDraftOnly) ModpackCardLabel.draft,
    if (!isDraftOnly && hasUnsavedChanges) ModpackCardLabel.unsavedChanges,
    if (updateAvailable) ModpackCardLabel.updateAvailable,
    if (hasFailures) ModpackCardLabel.failed,
    if (isInstalling) ModpackCardLabel.installing,
  ];
}

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
