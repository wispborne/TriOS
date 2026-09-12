import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_store.dart';

import '../riverpod_test_helpers.dart';

/// A store with its file in a temp folder that doesn't touch the mod records
/// store.
class _TestModpackStore extends ModpackStore {
  _TestModpackStore(Directory folder) : super(storageFolder: folder);

  /// Every definition whose sources were written to mod records.
  final List<ModpackDefinition> sourcesWritten = [];

  @override
  Future<void> writeItemSourcesToRecords(ModpackDefinition definition) async {
    sourcesWritten.add(definition);
  }
}

typedef StoreHarness = ({
  ProviderContainer container,
  _TestModpackStore store,
  Directory folder,
});

ModpackDraftItem _item(
  String modId, {
  String? url,
  ModpackItemSourceType sourceType = ModpackItemSourceType.versionFile,
  String? label,
  String? note,
}) => ModpackDraftItem(
  modId: modId,
  url: url ?? 'https://example.com/$modId.version',
  sourceType: sourceType,
  label: label,
  note: note,
);

ModpackDefinition _definition({
  String id = 'N3qGd6c8R2mVx1ZaYkW0_A',
  int version = 1,
  String name = 'Incoming pack',
}) => ModpackDefinition(
  id: id,
  name: name,
  version: version,
  items: const [
    ModpackItem(
      modId: 'example_mod',
      url: 'https://example.com/Example.version',
      sourceType: ModpackItemSourceType.versionFile,
    ),
  ],
);

void main() {
  late Directory folder;
  late ProviderContainer container;
  late _TestModpackStore store;

  /// Builds a store on [folder] and waits for its first load.
  Future<void> openStore() async {
    store = _TestModpackStore(folder);
    container = createTestContainer(
      overrides: [modpackStoreProvider.overrideWith(() => store)],
    );
    await awaitFirstValue(container, modpackStoreProvider);
  }

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('trios-modpack-store-test');
    await openStore();
  });

  tearDown(() async {
    // Let any debounced write finish before the folder disappears, so it
    // can't fail inside the next test.
    try {
      await store.settingsManager.waitForPendingWrites();
    } catch (_) {}
    container.dispose();
    try {
      await folder.delete(recursive: true);
    } catch (_) {}
  });

  ModpacksData data() => container.read(modpackStoreProvider).requireValue;

  File storageFile() => File('${folder.path}/modpacks.json');

  Future<void> flushWrites() => store.settingsManager.waitForPendingWrites();

  /// Makes a finished draft ready to save.
  Future<ModpackDraft> newFinishedDraft({String name = 'My pack'}) async {
    final draft = await store.createDraft();
    final finished = draft.copyWith(
      name: name,
      items: [_item('alpha_mod'), _item('beta_mod')],
    );
    await store.saveDraft(finished);
    return finished;
  }

  group('drafts', () {
    test('a new draft gets an ID and is saved right away', () async {
      final draft = await store.createDraft();

      expect(isValidModpackId(draft.id), isTrue);
      expect(data().drafts.keys, [draft.id]);
      expect(data().packs, isEmpty);
      expect(data().hasUnsavedChanges(draft.id), isTrue);
    });

    test('several unfinished new packs can exist at once', () async {
      final first = await store.createDraft();
      final second = await store.createDraft();

      expect(first.id, isNot(second.id));
      expect(data().drafts.length, 2);
    });

    test('an empty or unfinished draft is still saved', () async {
      final draft = await store.createDraft();
      await store.saveDraft(draft.copyWith(items: [const ModpackDraftItem()]));

      final saved = data().drafts[draft.id]!;
      expect(saved.isCommittable, isFalse);
      expect(saved.items.length, 1);
    });

    test('editing a saved pack starts from what was saved', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);
      expect(data().drafts, isEmpty);

      final reopened = await store.openDraft(draft.id);

      expect(reopened!.name, 'My pack');
      expect(reopened.items.map((item) => item.modId), [
        'alpha_mod',
        'beta_mod',
      ]);
    });

    test(
      'discarding a saved pack\'s draft leaves the saved pack alone',
      () async {
        final draft = await newFinishedDraft();
        final entry = await store.commitDraft(draft.id);

        final editing = (await store.openDraft(draft.id))!;
        await store.saveDraft(editing.copyWith(name: 'Half-typed name'));
        await store.discardDraft(draft.id);

        expect(data().drafts, isEmpty);
        expect(data().packs[draft.id]!.definition.name, entry.definition.name);
      },
    );

    test('discarding a draft-only pack removes it', () async {
      final draft = await newFinishedDraft();
      await store.discardDraft(draft.id);

      expect(data().drafts, isEmpty);
      expect(data().packs, isEmpty);
    });

    test('a draft autosave never changes a saved version', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      final editing = (await store.openDraft(draft.id))!;
      await store.saveDraft(editing.copyWith(name: 'Renamed but not saved'));

      expect(data().packs[draft.id]!.definition.version, 1);
      expect(data().packs[draft.id]!.definition.name, 'My pack');
    });
  });

  group('saving', () {
    test('a first save starts at version 1', () async {
      final draft = await newFinishedDraft();
      final entry = await store.commitDraft(draft.id);

      expect(entry.definition.version, 1);
      expect(entry.definition.id, draft.id);
      expect(entry.savedAt, isNotNull);
      expect(data().drafts, isEmpty);
      expect(data().packs.keys, [draft.id]);
    });

    test('a changed save raises the version once', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      final editing = (await store.openDraft(draft.id))!;
      await store.saveDraft(editing.copyWith(description: 'Now with a note'));
      final second = await store.commitDraft(draft.id);

      expect(second.definition.version, 2);
    });

    test('a save that changes nothing leaves the version alone', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      await store.saveDraft((await store.openDraft(draft.id))!);
      final again = await store.commitDraft(draft.id);

      expect(again.definition.version, 1);
    });

    test('changed item order counts as a change', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      final editing = (await store.openDraft(draft.id))!;
      await store.saveDraft(
        editing.copyWith(items: editing.items.reversed.toList()),
      );
      final reordered = await store.commitDraft(draft.id);

      expect(reordered.definition.version, 2);
      expect(reordered.definition.modIds, ['beta_mod', 'alpha_mod']);
    });

    test('a changed label or note counts as a change', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      var editing = (await store.openDraft(draft.id))!;
      await store.saveDraft(
        editing.copyWith(
          items: [
            editing.items.first.copyWith(label: 'Core'),
            editing.items.last,
          ],
        ),
      );
      expect((await store.commitDraft(draft.id)).definition.version, 2);

      editing = (await store.openDraft(draft.id))!;
      await store.saveDraft(
        editing.copyWith(
          items: [
            editing.items.first.copyWith(note: 'Install this one first.'),
            editing.items.last,
          ],
        ),
      );
      expect((await store.commitDraft(draft.id)).definition.version, 3);
    });

    test('an unfinished draft cannot be saved', () async {
      final draft = await store.createDraft();
      await store.saveDraft(draft.copyWith(items: [const ModpackDraftItem()]));

      expect(() => store.commitDraft(draft.id), throwsStateError);
      expect(data().packs, isEmpty);
    });

    test(
      'saving as a new pack gets a new ID, version 1, and no update address',
      () async {
        final draft = await store.createDraft();
        await store.saveDraft(
          draft.copyWith(
            name: 'Tracked pack',
            updateUrl: 'https://example.com/pack.trios-modpack',
            items: [_item('alpha_mod')],
          ),
        );
        final original = await store.commitDraft(draft.id);

        final editing = (await store.openDraft(draft.id))!;
        await store.saveDraft(editing.copyWith(name: 'My own version'));
        final copy = await store.commitDraftAsNewPack(draft.id);

        expect(copy.definition.id, isNot(original.definition.id));
        expect(copy.definition.version, 1);
        expect(copy.definition.updateUrl, isNull);
        expect(copy.definition.name, 'My own version');
        // The original is untouched, and its draft is left where it was.
        expect(
          data().packs[original.definition.id]!.definition.name,
          'Tracked pack',
        );
      },
    );

    test('duplicating a pack gets a new ID and version 1', () async {
      final draft = await newFinishedDraft();
      final entry = await store.commitDraft(draft.id);
      final bumped = await (() async {
        final editing = (await store.openDraft(draft.id))!;
        await store.saveDraft(editing.copyWith(description: 'Second version'));
        return store.commitDraft(draft.id);
      })();
      expect(bumped.definition.version, 2);

      final copy = await store.duplicatePack(entry.definition.id);

      expect(copy.definition.id, isNot(entry.definition.id));
      expect(copy.definition.version, 1);
      expect(copy.definition.description, 'Second version');
      expect(data().packs.length, 2);
    });

    test('deleting a pack removes its draft too', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);
      await store.openDraft(draft.id);

      await store.deletePack(draft.id);

      expect(data().packs, isEmpty);
      expect(data().drafts, isEmpty);
    });
  });

  group('incoming definitions', () {
    test('keep their own ID and version', () async {
      final entry = await store.acceptIncomingDefinition(
        _definition(version: 7),
        expectedEntry: null,
        expectedDraft: null,
      );

      expect(entry.definition.id, 'N3qGd6c8R2mVx1ZaYkW0_A');
      expect(entry.definition.version, 7);
    });

    test('can be saved as a copy without touching the existing pack', () async {
      await store.acceptIncomingDefinition(
        _definition(version: 7),
        expectedEntry: null,
        expectedDraft: null,
      );
      final copy = await store.saveIncomingDefinitionAsCopy(
        _definition(version: 7, name: 'Their pack'),
      );

      expect(copy.definition.id, isNot('N3qGd6c8R2mVx1ZaYkW0_A'));
      expect(copy.definition.version, 1);
      expect(data().packs.length, 2);
      expect(data().packs['N3qGd6c8R2mVx1ZaYkW0_A']!.definition.version, 7);
    });

    test('are refused when the format is too new', () async {
      expect(
        () => store.acceptIncomingDefinition(
          _definition().copyWith(formatVersion: 99),
          expectedEntry: null,
          expectedDraft: null,
        ),
        throwsA(
          isA<ModpackFormatException>().having(
            (e) => e.needsNewerTriOS,
            'needsNewerTriOS',
            isTrue,
          ),
        ),
      );
    });
  });

  group('mod records', () {
    test('are written when a draft is saved, not while editing', () async {
      final draft = await newFinishedDraft();
      expect(store.sourcesWritten, isEmpty);

      await store.commitDraft(draft.id);

      expect(store.sourcesWritten.length, 1);
      expect(store.sourcesWritten.single.modIds, ['alpha_mod', 'beta_mod']);
    });
  });

  group('local-only facts', () {
    test('keep the whole last successful online definition', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      final online = _definition(id: draft.id, version: 5, name: 'Newer name');
      await store.recordUpdateCheckSuccess(draft.id, online);

      final entry = data().packs[draft.id]!;
      expect(entry.updateCheck!.onlineDefinition!.name, 'Newer name');
      expect(entry.updateCheck!.succeededAt, isNotNull);
      expect(entry.onlineVersionAvailable, 5);
    });

    test('report no update when the online copy is not newer', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      await store.recordUpdateCheckSuccess(
        draft.id,
        _definition(id: draft.id, version: 1),
      );

      expect(data().packs[draft.id]!.onlineVersionAvailable, isNull);
    });

    test('report no update when the online copy has another pack ID', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      await store.recordUpdateCheckSuccess(
        draft.id,
        _definition(id: 'aaaaaaaaaaaaaaaaaaaaaa', version: 9),
      );

      expect(data().packs[draft.id]!.onlineVersionAvailable, isNull);
    });

    test('keep a failed check quiet and keep the last success', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);
      await store.recordUpdateCheckSuccess(
        draft.id,
        _definition(id: draft.id, version: 4),
      );

      await store.recordUpdateCheckFailure(draft.id, 'Host did not answer');

      final check = data().packs[draft.id]!.updateCheck!;
      expect(check.error, 'Host did not answer');
      expect(check.onlineDefinition!.version, 4);
      expect(check.failedAt, isNotNull);
      expect(check.lastAttemptedAt, check.failedAt);
    });

    test('remember where a pack was exported', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);

      await store.recordExportLocation(
        draft.id,
        'C:/packs/my-pack.trios-modpack',
      );

      expect(
        data().packs[draft.id]!.lastExportPath,
        'C:/packs/my-pack.trios-modpack',
      );
    });
  });

  group('item failures', () {
    Future<ModpackDraft> savedPack() async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);
      return draft;
    }

    test('are kept by mod ID and cleared after a successful install', () async {
      final draft = await savedPack();

      await store.recordItemFailure(
        packId: draft.id,
        modId: 'alpha_mod',
        sourceFingerprint: 'versionFile|https://example.com/alpha_mod.version',
        message: 'Download failed',
      );
      expect(data().packs[draft.id]!.itemFailures.keys, ['alpha_mod']);

      await store.clearItemFailure(draft.id, 'alpha_mod');
      expect(data().packs[draft.id]!.itemFailures, isEmpty);
    });

    test('are dropped when the item source changes', () async {
      final draft = await savedPack();
      await store.recordItemFailure(
        packId: draft.id,
        modId: 'alpha_mod',
        sourceFingerprint: 'versionFile|https://old.example.com/alpha.version',
        message: 'Download failed',
      );

      await store.clearFailuresForChangedSources(draft.id);

      expect(data().packs[draft.id]!.itemFailures, isEmpty);
    });

    test('are kept while the item source is unchanged', () async {
      final draft = await savedPack();
      final item = data().packs[draft.id]!.definition.items.first;
      await store.recordItemFailure(
        packId: draft.id,
        modId: item.modId,
        sourceFingerprint: modpackItemSourceFingerprint(item),
        message: 'Download failed',
      );

      await store.clearFailuresForChangedSources(draft.id);

      expect(data().packs[draft.id]!.itemFailures.keys, [item.modId]);
    });
  });

  group('storage', () {
    test('writes one modpacks.json and reads it back', () async {
      final draft = await newFinishedDraft(name: 'Saved to disk');
      await store.commitDraft(draft.id);
      await flushWrites();

      expect(await storageFile().exists(), isTrue);
      final written = jsonDecode(await storageFile().readAsString());
      expect(written['packs'], isA<Map>());
      expect(written['drafts'], isA<Map>());

      container.dispose();
      await openStore();

      expect(data().packs[draft.id]!.definition.name, 'Saved to disk');
      expect(data().packs[draft.id]!.definition.items.length, 2);
    });

    test('keeps unknown fields through a save and reload', () async {
      final incoming = _definition().copyWith(
        unknownFields: {'futureField': 'kept'},
      );
      await store.acceptIncomingDefinition(
        incoming,
        expectedEntry: null,
        expectedDraft: null,
      );
      await flushWrites();

      container.dispose();
      await openStore();

      expect(
        data().packs[incoming.id]!.definition.unknownFields['futureField'],
        'kept',
      );
    });

    test('an unreadable file keeps a copy and offers a choice', () async {
      final draft = await newFinishedDraft();
      await store.commitDraft(draft.id);
      await flushWrites();
      container.dispose();

      await storageFile().writeAsString('{ this is not json');
      await openStore();

      final problem = store.storageProblem;
      expect(problem, isNotNull);
      expect(data().packs, isEmpty);
      expect(await problem!.keptCopy.exists(), isTrue);
      // The unreadable file itself is left where it was.
      expect(await storageFile().readAsString(), '{ this is not json');
    });

    test('restore backup loads the saved backup', () async {
      final draft = await newFinishedDraft(name: 'From the backup');
      await store.commitDraft(draft.id);
      await flushWrites();
      final good = await storageFile().readAsString();
      container.dispose();

      await File('${folder.path}/modpacks.json_backup.bak').writeAsString(good);
      await storageFile().writeAsString('not json at all');
      await openStore();
      expect(store.storageProblem, isNotNull);

      final restored = await store.restoreBackup();

      expect(restored, isTrue);
      expect(store.storageProblem, isNull);
      expect(data().packs[draft.id]!.definition.name, 'From the backup');
    });

    test('restore backup says no when there is no backup', () async {
      await storageFile().writeAsString('not json at all');
      container.dispose();
      await openStore();

      expect(await store.restoreBackup(), isFalse);
      expect(store.storageProblem, isNotNull);
    });

    test('starting empty replaces the unreadable file', () async {
      await storageFile().writeAsString('not json at all');
      container.dispose();
      await openStore();

      await store.startEmptyLibrary();
      await flushWrites();

      expect(store.storageProblem, isNull);
      expect(data().packs, isEmpty);
      expect(jsonDecode(await storageFile().readAsString()), {
        'packs': <String, Object?>{},
        'drafts': <String, Object?>{},
      });
    });
  });
}
