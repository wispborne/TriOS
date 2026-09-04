import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';

part 'modpack_library_entry.mapper.dart';

/// One item that failed to install. Kept until it installs or its source
/// changes: [sourceFingerprint] records the address and source type used, so
/// changing the source clears the failure.
@MappableClass()
class ModpackItemFailure with ModpackItemFailureMappable {
  final String modId;
  final String sourceFingerprint;
  final String message;
  final DateTime failedAt;

  const ModpackItemFailure({
    required this.modId,
    required this.sourceFingerprint,
    required this.message,
    required this.failedAt,
  });
}

/// What the last look at a pack's update address found.
///
/// The full online definition is kept, not just its version, so a comparison
/// can be shown without refetching. A failed check keeps the last success and
/// records the error.
@MappableClass()
class ModpackUpdateCheck with ModpackUpdateCheckMappable {
  final ModpackDefinition? onlineDefinition;
  final DateTime? succeededAt;
  final String? error;
  final DateTime? failedAt;

  const ModpackUpdateCheck({
    this.onlineDefinition,
    this.succeededAt,
    this.error,
    this.failedAt,
  });

  DateTime? get lastAttemptedAt {
    if (succeededAt == null) return failedAt;
    if (failedAt == null) return succeededAt;
    return failedAt!.isAfter(succeededAt!) ? failedAt : succeededAt;
  }
}

/// One modpack saved in the library, plus facts that belong only to this
/// machine.
///
/// Local-only fields never go into share links or exported files. Installed
/// coverage is computed from the current mod list instead.
@MappableClass()
class ModpackLibraryEntry with ModpackLibraryEntryMappable {
  final ModpackDefinition definition;
  final DateTime? savedAt;
  final ModpackUpdateCheck? updateCheck;

  /// Where the pack was last exported, so Export can suggest the same place.
  final String? lastExportPath;

  /// Failed installs, keyed by mod ID.
  final Map<String, ModpackItemFailure> itemFailures;

  const ModpackLibraryEntry({
    required this.definition,
    this.savedAt,
    this.updateCheck,
    this.lastExportPath,
    this.itemFailures = const {},
  });

  String get id => definition.id;

  /// The online version, when it's higher than the saved one.
  int? get onlineVersionAvailable {
    final online = updateCheck?.onlineDefinition;
    if (online == null) return null;
    if (online.id != definition.id) return null;
    return online.version > definition.version ? online.version : null;
  }
}

/// Everything the modpack store keeps on disk.
///
/// Packs and drafts are separate maps keyed by pack ID, so a pack can have one
/// without the other: a draft-only pack was never saved, and a saved pack
/// without a draft has no unsaved changes.
@MappableClass()
class ModpacksData with ModpacksDataMappable {
  final Map<String, ModpackLibraryEntry> packs;
  final Map<String, ModpackDraft> drafts;

  const ModpacksData({this.packs = const {}, this.drafts = const {}});

  Set<String> get allPackIds => {...packs.keys, ...drafts.keys};

  ModpackLibraryEntry? entry(String packId) => packs[packId];

  ModpackDraft? draft(String packId) => drafts[packId];

  /// Whether the pack has unsaved changes. A draft-only pack counts as
  /// unsaved.
  bool hasUnsavedChanges(String packId) => drafts.containsKey(packId);
}
