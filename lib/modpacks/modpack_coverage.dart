import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';

/// What TriOS works out about one pack against the current mod list.
/// Nothing here is saved; it's recomputed on demand so it can't disagree with
/// what's installed.
class ModpackCoverage {
  /// How many items have a matching installed mod.
  final int installedCount;

  /// How many items the pack has. A draft-only pack counts its draft items.
  final int totalCount;

  /// Mod IDs with no installed variant, in pack order.
  final List<String> missingModIds;

  /// Items that cannot be shared yet because their source is missing or
  /// invalid. Only a draft can have these.
  final List<String> itemsNeedingSources;

  /// Mod IDs whose last install attempt failed.
  final List<String> failedModIds;

  /// The online version when it is newer than the saved one.
  final int? onlineVersionAvailable;

  const ModpackCoverage({
    required this.installedCount,
    required this.totalCount,
    this.missingModIds = const [],
    this.itemsNeedingSources = const [],
    this.failedModIds = const [],
    this.onlineVersionAvailable,
  });

  int get missingCount => missingModIds.length;

  bool get isFullyInstalled => totalCount > 0 && missingModIds.isEmpty;

  bool get hasSourceProblems => itemsNeedingSources.isNotEmpty;

  bool get hasFailures => failedModIds.isNotEmpty;

  bool get updateAvailable => onlineVersionAvailable != null;
}

/// Works out one pack's coverage.
///
/// Any installed variant satisfies an item; enabled state and exact version
/// don't matter. A [draft] stands in for the saved definition when the pack
/// was never saved, and its unfinished items count as source problems.
ModpackCoverage calculateModpackCoverage({
  ModpackDefinition? definition,
  ModpackDraft? draft,
  required Set<String> installedModIds,
  Map<String, ModpackItemFailure> itemFailures = const {},
  int? onlineVersionAvailable,
}) {
  final packModIds = <String>[];
  final needingSources = <String>[];

  if (definition != null) {
    packModIds.addAll(definition.modIds);
  }
  if (draft != null) {
    for (final item in draft.items) {
      final modId = item.modId?.trim();
      if (modId != null && modId.isNotEmpty && definition == null) {
        packModIds.add(modId);
      }
      if (!item.isComplete) {
        needingSources.add(
          modId?.isNotEmpty == true ? modId! : item.displayName,
        );
      }
    }
  }

  final missing = packModIds
      .where((modId) => !installedModIds.contains(modId))
      .toList();
  final failed = packModIds
      .where((modId) => itemFailures.containsKey(modId))
      .toList();

  return ModpackCoverage(
    installedCount: packModIds.length - missing.length,
    totalCount: packModIds.length,
    missingModIds: missing,
    itemsNeedingSources: needingSources,
    failedModIds: failed,
    onlineVersionAvailable: onlineVersionAvailable,
  );
}

/// Works out coverage for a library entry and its draft, if it has one.
ModpackCoverage calculateEntryCoverage({
  ModpackLibraryEntry? entry,
  ModpackDraft? draft,
  required Set<String> installedModIds,
}) => calculateModpackCoverage(
  definition: entry?.definition,
  draft: draft,
  installedModIds: installedModIds,
  itemFailures: entry?.itemFailures ?? const {},
  onlineVersionAvailable: entry?.onlineVersionAvailable,
);
