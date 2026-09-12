import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_id.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';

/// The one place saved modpacks and drafts live.
final modpackStoreProvider = AsyncNotifierProvider<ModpackStore, ModpacksData>(
  ModpackStore.new,
);

/// An unreadable `modpacks.json` and what can be done about it.
///
/// TriOS keeps a copy of the unreadable file and leaves any existing backup
/// alone, so nothing is lost.
class ModpackStorageProblem {
  /// Where the unreadable file was copied to.
  final File keptCopy;

  /// The backup Restore backup would read.
  final File? backup;

  final String message;

  const ModpackStorageProblem({
    required this.keptCopy,
    required this.backup,
    required this.message,
  });

  bool get canRestoreBackup => backup != null;
}

/// Reads and writes `modpacks.json`.
///
/// Unlike other settings files, an unreadable modpacks file is not replaced:
/// the user is asked first, because a wiped library can't be rebuilt anywhere.
class ModpacksSettingsManager
    extends GenericAsyncSettingsManager<ModpacksData> {
  ModpacksSettingsManager({this.storageFolder});

  /// Where `modpacks.json` goes. Only tests set this.
  final Directory? storageFolder;

  /// Set when the file couldn't be read; cleared by a successful read, a
  /// restore, or starting empty.
  ModpackStorageProblem? storageProblem;

  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'modpacks.json';

  @override
  ModpacksData Function(Map<String, dynamic> map) get fromMap =>
      ModpacksDataMapper.fromMap;

  @override
  Map<String, dynamic> Function(ModpacksData obj) get toMap =>
      (obj) => obj.toMap();

  @override
  Future<Directory> getConfigDataFolderPath() async =>
      storageFolder ?? await super.getConfigDataFolderPath();

  @override
  Future<ModpacksData> read(
    ModpacksData fallback, {
    bool forceLoadFromDisk = false,
  }) async {
    if (!forceLoadFromDisk && lastKnownValue != null) {
      return lastKnownValue!;
    }

    final folder = await getConfigDataFolderPath();
    await folder.create(recursive: true);
    settingsFile = File(p.join(folder.path, fileName));

    if (!await settingsFile.exists()) {
      lastKnownValue = fallback;
      return fallback;
    }

    try {
      final loaded = await deserialize(await settingsFile.readAsBytes());
      storageProblem = null;
      lastKnownValue = loaded;
      return loaded;
    } catch (e, stacktrace) {
      Fimber.e(
        "Could not read $fileName. Keeping it and starting with an empty "
        "library until the person chooses what to do.",
        ex: e,
        stacktrace: stacktrace,
      );
      storageProblem = await _keepUnreadableFile(e);
      lastKnownValue = fallback;
      return fallback;
    }
  }

  Future<ModpackStorageProblem> _keepUnreadableFile(Object error) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final keptCopy = File('${settingsFile.path}.unreadable-$stamp');
    try {
      await settingsFile.copy(keptCopy.path);
    } catch (e) {
      Fimber.w("Could not keep a copy of the unreadable $fileName: $e");
    }

    File? backup;
    for (final candidate in [getBackupArchiveFile(), getBackupFile()]) {
      if (await candidate.exists()) {
        backup = candidate;
        break;
      }
    }

    return ModpackStorageProblem(
      keptCopy: keptCopy,
      backup: backup,
      message: 'TriOS could not read your saved modpacks: $error',
    );
  }

  /// Never backs up an unreadable file; that would throw away the last good
  /// copy.
  @override
  Future<void> createBackup() async {
    if (storageProblem != null) {
      Fimber.i("Skipping $fileName backup while its file is unreadable.");
      return;
    }
    if (!await settingsFile.exists()) return;
    try {
      await super.createBackup();
    } catch (e, stacktrace) {
      // Backups run in the background; a missed one isn't worth
      // interrupting the library load.
      Fimber.w("Could not back up $fileName", ex: e, stacktrace: stacktrace);
    }
  }

  /// Reads the saved backup, unpacking it when compressed. Returns null when
  /// there's no readable backup.
  Future<ModpacksData?> readBackup({SevenZip? sevenZip}) async {
    final plainBackup = getBackupFile();
    if (await plainBackup.exists()) {
      return _tryDeserializeFile(plainBackup);
    }

    final archive = getBackupArchiveFile();
    if (!await archive.exists()) return null;

    final tempFolder = await Directory.systemTemp.createTemp('trios-modpacks');
    try {
      await (sevenZip ?? SevenZip()).extractAll(archive, tempFolder);
      final extracted = File(
        p.join(tempFolder.path, getBackupFile().uri.pathSegments.last),
      );
      if (await extracted.exists()) {
        return await _tryDeserializeFile(extracted);
      }
      for (final entity in tempFolder.listSync()) {
        if (entity is File) {
          final data = await _tryDeserializeFile(entity);
          if (data != null) return data;
        }
      }
      return null;
    } catch (e, stacktrace) {
      Fimber.w(
        "Could not read the modpacks backup",
        ex: e,
        stacktrace: stacktrace,
      );
      return null;
    } finally {
      try {
        await tempFolder.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<ModpacksData?> _tryDeserializeFile(File file) async {
    try {
      return await deserialize(await file.readAsBytes());
    } catch (e) {
      Fimber.w("Modpacks backup ${file.path} is not readable either: $e");
      return null;
    }
  }
}

/// Owns every saved modpack and draft. The only code that allocates pack IDs
/// and versions, or commits, copies, replaces, and deletes packs.
class ModpackStore extends GenericSettingsAsyncNotifier<ModpacksData> {
  ModpackStore({this.storageFolder});

  /// Where `modpacks.json` goes. Only tests set this.
  final Directory? storageFolder;

  @override
  GenericAsyncSettingsManager<ModpacksData> createSettingsManager() =>
      ModpacksSettingsManager(storageFolder: storageFolder);

  @override
  ModpacksData createDefaultState() => const ModpacksData();

  ModpacksSettingsManager get _manager =>
      settingsManager as ModpacksSettingsManager;

  /// Set when `modpacks.json` couldn't be read, so the UI can offer Restore
  /// backup or Start empty.
  ModpackStorageProblem? get storageProblem => _manager.storageProblem;

  ModpacksData get _data => state.value ?? createDefaultState();

  // --- Drafts ---------------------------------------------------------------

  /// Starts a new pack. The ID is allocated now, so an unfinished pack has a
  /// stable identity and its own autosaved draft.
  Future<ModpackDraft> createDraft({
    String name = '',
    String? gameVersion,
    List<ModpackDraftItem> items = const [],
  }) async {
    final draft = ModpackDraft(
      id: _unusedPackId(),
      name: name,
      gameVersion: gameVersion,
      items: items,
      updatedAt: DateTime.now(),
    );
    await _write(
      (data) => data.copyWith(drafts: {...data.drafts, draft.id: draft}),
    );
    return draft;
  }

  /// The draft for [packId], creating one from the saved definition if the
  /// pack hasn't been edited yet.
  Future<ModpackDraft?> openDraft(String packId) async {
    final existing = _data.drafts[packId];
    if (existing != null) return existing;

    final entry = _data.packs[packId];
    if (entry == null) return null;
    _requireSupportedFormat(entry.definition);

    final draft = ModpackDraft.fromDefinition(
      entry.definition,
      updatedAt: DateTime.now(),
    );
    await _write(
      (data) => data.copyWith(drafts: {...data.drafts, packId: draft}),
    );
    return draft;
  }

  /// Autosaves editor changes. Never changes the pack's version; the draft
  /// may be empty or invalid.
  Future<void> saveDraft(ModpackDraft draft) async {
    final stamped = draft.copyWith(updatedAt: DateTime.now());
    await _write(
      (data) => data.copyWith(drafts: {...data.drafts, draft.id: stamped}),
    );
  }

  /// Throws away unsaved changes. A never-saved pack disappears with its
  /// draft.
  Future<void> discardDraft(String packId) async {
    await _write((data) {
      final drafts = Map<String, ModpackDraft>.of(data.drafts)..remove(packId);
      return data.copyWith(drafts: drafts);
    });
  }

  // --- Saving ---------------------------------------------------------------

  int versionAfterSaving(ModpackDraft draft) {
    final saved = _data.packs[draft.id]?.definition;
    return saved == null ? 1 : _nextVersion(draft, saved);
  }

  /// Saves a draft into the library.
  ///
  /// The version bumps by one when the shared content changed; a first save
  /// starts at 1, and a no-op save leaves it alone.
  ///
  /// Throws [StateError] when there's no draft for [packId] or it isn't
  /// finished. Callers should check [ModpackDraft.isCommittable] first and
  /// keep Save disabled.
  Future<ModpackLibraryEntry> commitDraft(String packId) async {
    final draft = _data.drafts[packId];
    if (draft == null) {
      throw StateError('There is no modpack draft for $packId to save.');
    }
    if (!draft.isCommittable) {
      throw StateError(
        'This modpack draft cannot be saved yet: ${draft.issues.length} '
        'problems remain.',
      );
    }

    final existing = _data.packs[packId];
    final version = existing == null
        ? 1
        : _nextVersion(draft, existing.definition);
    final definition = draft.toDefinition(version: version);

    final entry = (existing ?? ModpackLibraryEntry(definition: definition))
        .copyWith(definition: definition, savedAt: DateTime.now());

    await _write((data) {
      final drafts = Map<String, ModpackDraft>.of(data.drafts)..remove(packId);
      return data.copyWith(
        packs: {...data.packs, packId: entry},
        drafts: drafts,
      );
    });

    await writeItemSourcesToRecords(definition);
    return entry;
  }

  /// Saves a draft as a brand-new pack: new ID, version 1, and no update
  /// address, since the old one belongs to the original pack.
  Future<ModpackLibraryEntry> commitDraftAsNewPack(String packId) async {
    final draft = _data.drafts[packId];
    if (draft == null) {
      throw StateError('There is no modpack draft for $packId to save.');
    }

    final copy = draft.copyWith(id: _unusedPackId(), updateUrl: null);
    await _write(
      (data) => data.copyWith(drafts: {...data.drafts, copy.id: copy}),
    );
    return commitDraft(copy.id);
  }

  /// Copies a saved pack. The copy gets a new ID and starts at version 1.
  Future<ModpackLibraryEntry> duplicatePack(String packId) async {
    final existing = _data.packs[packId];
    if (existing == null) {
      throw StateError('There is no saved modpack $packId to duplicate.');
    }
    return _saveAsNewPack(existing.definition);
  }

  /// Saves an incoming definition as a separate pack, leaving any existing
  /// pack with the same ID alone.
  Future<ModpackLibraryEntry> saveIncomingDefinitionAsCopy(
    ModpackDefinition definition,
  ) async {
    _requireSupportedFormat(definition);
    return _saveAsNewPack(definition);
  }

  /// Applies a reviewed incoming definition only if the saved work still
  /// matches what the person reviewed. Draft removal and replacement are atomic.
  Future<ModpackLibraryEntry> acceptIncomingDefinition(
    ModpackDefinition definition, {
    required ModpackLibraryEntry? expectedEntry,
    required ModpackDraft? expectedDraft,
    bool discardDraft = false,
  }) async {
    _requireSupportedFormat(definition);
    late ModpackLibraryEntry accepted;
    await _write((data) {
      if (data.packs[definition.id] != expectedEntry ||
          data.drafts[definition.id] != expectedDraft) {
        throw StateError(
          'This pack changed while you were reviewing it. Review it again.',
        );
      }
      if (expectedDraft != null && !discardDraft) {
        throw StateError('Discard the draft explicitly before replacing it.');
      }
      accepted = (expectedEntry ?? ModpackLibraryEntry(definition: definition))
          .copyWith(
            definition: definition,
            savedAt: DateTime.now(),
            itemFailures: {
              for (final failure
                  in expectedEntry?.itemFailures.values ??
                      <ModpackItemFailure>[])
                if (definition.items.any(
                  (item) =>
                      item.modId == failure.modId &&
                      modpackItemSourceFingerprint(item) ==
                          failure.sourceFingerprint,
                ))
                  failure.modId: failure,
            },
          );
      return data.copyWith(
        packs: {...data.packs, definition.id: accepted},
        drafts: {...data.drafts}..remove(definition.id),
      );
    });
    return accepted;
  }

  Future<ModpackLibraryEntry> _saveAsNewPack(
    ModpackDefinition definition,
  ) async {
    final copy = definition.copyWith(id: _unusedPackId(), version: 1);
    final entry = ModpackLibraryEntry(
      definition: copy,
      savedAt: DateTime.now(),
    );
    await _write(
      (data) => data.copyWith(packs: {...data.packs, copy.id: entry}),
    );
    return entry;
  }

  /// Removes a saved pack and its draft. No mods are disabled or uninstalled.
  Future<void> deletePack(String packId) async {
    await _write((data) {
      final packs = Map<String, ModpackLibraryEntry>.of(data.packs)
        ..remove(packId);
      final drafts = Map<String, ModpackDraft>.of(data.drafts)..remove(packId);
      return ModpacksData(packs: packs, drafts: drafts);
    });
  }

  // --- Local-only facts -----------------------------------------------------

  /// Records a successful update check, keeping the full online definition
  /// for comparison.
  Future<void> recordUpdateCheckSuccess(
    String packId,
    ModpackDefinition onlineDefinition,
  ) async {
    await _updateEntry(
      packId,
      (entry) => entry.copyWith(
        updateCheck: (entry.updateCheck ?? const ModpackUpdateCheck()).copyWith(
          onlineDefinition: onlineDefinition,
          succeededAt: DateTime.now(),
          error: null,
        ),
      ),
    );
  }

  /// Records a failed check without disturbing the last successful one.
  Future<void> recordUpdateCheckFailure(String packId, String error) async {
    await _updateEntry(
      packId,
      (entry) => entry.copyWith(
        updateCheck: (entry.updateCheck ?? const ModpackUpdateCheck()).copyWith(
          error: error,
          failedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> recordExportLocation(String packId, String path) =>
      _updateEntry(packId, (entry) => entry.copyWith(lastExportPath: path));

  /// Records one item that failed to install.
  Future<void> recordItemFailure({
    required String packId,
    required String modId,
    required String sourceFingerprint,
    required String message,
  }) => _updateEntry(
    packId,
    (entry) => entry.copyWith(
      itemFailures: {
        ...entry.itemFailures,
        modId: ModpackItemFailure(
          modId: modId,
          sourceFingerprint: sourceFingerprint,
          message: message,
          failedAt: DateTime.now(),
        ),
      },
    ),
  );

  /// Clears a failure after the item installs.
  Future<void> clearItemFailure(String packId, String modId) => _updateEntry(
    packId,
    (entry) => entry.copyWith(
      itemFailures: Map<String, ModpackItemFailure>.of(entry.itemFailures)
        ..remove(modId),
    ),
  );

  /// Drops failures whose source no longer matches the saved item.
  Future<void> clearFailuresForChangedSources(String packId) =>
      _updateEntry(packId, (entry) {
        final kept = <String, ModpackItemFailure>{};
        for (final failure in entry.itemFailures.values) {
          final item = entry.definition.itemForModId(failure.modId);
          if (item == null) continue;
          if (modpackItemSourceFingerprint(item) == failure.sourceFingerprint) {
            kept[failure.modId] = failure;
          }
        }
        return entry.copyWith(itemFailures: kept);
      });

  // --- Unreadable storage ---------------------------------------------------

  /// Loads the backup over the current library. Returns false when there's no
  /// readable backup.
  Future<bool> restoreBackup() async {
    final restored = await _manager.readBackup();
    if (restored == null) return false;

    _manager.storageProblem = null;
    await updateState((_) => restored, skipChangeCheck: true);
    return true;
  }

  /// Replaces the unreadable file with an empty library. The kept copy of the
  /// old file stays on disk.
  Future<void> startEmptyLibrary() async {
    _manager.storageProblem = null;
    await updateState((_) => createDefaultState(), skipChangeCheck: true);
  }

  // --- Internals ------------------------------------------------------------

  /// Writes each item's chosen source to the mod's record. Happens on save
  /// only; editing a draft never touches mod records.
  ///
  /// Tests override this to keep the mod records store out of the way.
  @protected
  @visibleForTesting
  Future<void> writeItemSourcesToRecords(ModpackDefinition definition) async {
    await ref.read(modRecordsStore.future);
    final records = ref.read(modRecordsStore.notifier);
    for (final item in definition.items) {
      await records.updateRecord(item.modId, (existing) {
        final overrides = Map<String, ModRecordSource>.of(
          existing?.userOverrides ?? const {},
        );
        switch (item.sourceType) {
          case ModpackItemSourceType.versionFile:
            final current = overrides['versionChecker'];
            overrides['versionChecker'] =
                (current is VersionCheckerSource ? current : null)?.copyWith(
                  masterVersionFileUrl: item.url,
                ) ??
                VersionCheckerSource(masterVersionFileUrl: item.url);
          case ModpackItemSourceType.directDownload:
            final current = overrides['catalog'];
            overrides['catalog'] =
                (current is CatalogSource ? current : null)?.copyWith(
                  directDownloadUrl: item.url,
                ) ??
                CatalogSource(directDownloadUrl: item.url);
        }
        return (existing ??
                ModRecord(
                  recordKey: item.modId,
                  modId: item.modId,
                  firstSeen: DateTime.now(),
                ))
            .copyWith(
              userOverrides: overrides,
              modpackSource: switch (item.sourceType) {
                .versionFile => VersionCheckerSource(
                  masterVersionFileUrl: item.url,
                ),
                .directDownload => CatalogSource(directDownloadUrl: item.url),
              },
            );
      });
    }
  }

  int _nextVersion(ModpackDraft draft, ModpackDefinition saved) {
    final candidate = draft.toDefinition(version: saved.version);
    if (modpackSharedContentMatches(candidate, saved)) return saved.version;
    if (saved.version >= ModpackLimits.maxSafeInteger) return saved.version;
    return saved.version + 1;
  }

  String _unusedPackId() {
    final taken = _data.allPackIds;
    var id = generateModpackId();
    while (taken.contains(id)) {
      id = generateModpackId();
    }
    return id;
  }

  void _requireSupportedFormat(ModpackDefinition definition) {
    if (!definition.isSupportedFormat) {
      throw ModpackFormatException(
        ModpackFormatError.unsupportedDefinitionFormat,
        'This modpack uses format version ${definition.formatVersion}. '
        'Update TriOS to use it.',
      );
    }
  }

  Future<void> _updateEntry(
    String packId,
    ModpackLibraryEntry Function(ModpackLibraryEntry entry) change,
  ) async {
    final existing = _data.packs[packId];
    if (existing == null) return;
    await _write(
      (data) => data.copyWith(packs: {...data.packs, packId: change(existing)}),
    );
  }

  Future<void> _write(ModpacksData Function(ModpacksData data) change) =>
      updateState((current) => change(current), skipChangeCheck: true);
}

/// Identifies the source one install attempt used, so a changed address
/// clears the old failure.
String modpackItemSourceFingerprint(ModpackItem item) =>
    '${item.sourceType.name}|${item.url}';
