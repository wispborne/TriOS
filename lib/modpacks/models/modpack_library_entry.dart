import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';

part 'modpack_library_entry.mapper.dart';

/// One item that failed to install, kept until it installs or its source
/// changes.
///
/// [sourceFingerprint] is the address and source type the attempt used, so
/// changing the source clears the failure instead of carrying it over.
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
/// The complete online definition is kept, not just its version, so a
/// comparison can be shown without fetching again. A failed check is quiet:
/// it keeps the last success and records the error for update details.
@MappableClass()
class ModpackUpdateCheck with ModpackUpdateCheckMappable {
  /// The last definition successfully read from the update address.
  final ModpackDefinition? onlineDefinition;

  /// When that definition was read.
  final DateTime? succeededAt;

  /// Why the most recent check failed, if it did.
  final String? error;

  final DateTime? failedAt;

  const ModpackUpdateCheck({
    this.onlineDefinition,
    this.succeededAt,
    this.error,
    this.failedAt,
  });

  /// When TriOS last tried, whether or not it worked.
  DateTime? get lastAttemptedAt {
    if (succeededAt == null) return failedAt;
    if (failedAt == null) return succeededAt;
    return failedAt!.isAfter(succeededAt!) ? failedAt : succeededAt;
  }
}

/// One modpack saved in the library, plus the facts that belong only to this
/// computer's copy.
///
/// Local-only fields never go into a share link or an exported file. Installed
/// coverage is calculated from the current mod list instead of being stored.
@MappableClass()
class ModpackLibraryEntry with ModpackLibraryEntryMappable {
  final ModpackDefinition definition;

  /// When this definition was committed to the library.
  final DateTime? savedAt;

  final ModpackUpdateCheck? updateCheck;

  /// Where the pack was last exported, so Export can offer the same place.
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

  /// The online definition's version when it is higher than the saved one.
  int? get onlineVersionAvailable {
    final online = updateCheck?.onlineDefinition;
    if (online == null) return null;
    if (online.id != definition.id) return null;
    return online.version > definition.version ? online.version : null;
  }
}

/// Everything the modpack store keeps on disk.
///
/// Saved packs and drafts are separate maps, both keyed by pack ID, so a pack
/// can have one without the other: a draft-only pack has never been saved, and
/// a saved pack without a draft has no unsaved changes.
@MappableClass()
class ModpacksData with ModpacksDataMappable {
  final Map<String, ModpackLibraryEntry> packs;
  final Map<String, ModpackDraft> drafts;

  const ModpacksData({this.packs = const {}, this.drafts = const {}});

  /// Every pack ID with a saved pack, a draft, or both.
  Set<String> get allPackIds => {...packs.keys, ...drafts.keys};

  ModpackLibraryEntry? entry(String packId) => packs[packId];

  ModpackDraft? draft(String packId) => drafts[packId];

  /// Whether this pack has a draft that differs from what was saved. A
  /// draft-only pack counts as unsaved.
  bool hasUnsavedChanges(String packId) => drafts.containsKey(packId);
}
