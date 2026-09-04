import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_install_progress.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';

import '../riverpod_test_helpers.dart';

class _TestModpackStore extends ModpackStore {
  _TestModpackStore(Directory folder) : super(storageFolder: folder);

  @override
  Future<void> writeItemSourcesToRecords(ModpackDefinition definition) async {}
}

class _FakeSettings extends AppSettingNotifier {
  _FakeSettings(this.initial);

  final Settings initial;

  @override
  Settings build() => initial;
}

typedef Harness = ({
  ProviderContainer container,
  ModpacksPageController controller,
  _TestModpackStore store,
});

Mod _mod(String modId) => Mod(
  id: modId,
  isEnabledInGame: true,
  modVariants: [
    ModVariant(
      modInfo: ModInfo(id: modId, name: modId, version: Version.parse('1.0.0')),
      versionCheckerInfo: null,
      modFolder: Directory('mods/$modId'),
      hasNonBrickedModInfo: true,
      gameCoreFolder: Directory('core'),
    ),
  ],
);

ModpackDefinition _definition({
  required String id,
  required String name,
  String? author,
  String? gameVersion,
  List<String> modIds = const ['alpha', 'beta'],
}) => ModpackDefinition(
  id: id,
  name: name,
  version: 1,
  author: author,
  gameVersion: gameVersion,
  items: [
    for (final modId in modIds)
      ModpackItem(
        modId: modId,
        url: 'https://example.com/$modId.version',
        sourceType: ModpackItemSourceType.versionFile,
      ),
  ],
);

const _wispId = 'wisp_pack_id_000000000';
const _otherId = 'other_pack_id_00000000';

void main() {
  late Directory folder;
  late Harness harness;

  setUpAll(() {
    // Keep settings writes out of the user's config directory.
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_modpacks_page_test',
    );
  });

  Future<Harness> open({
    List<Mod> mods = const [],
    Settings? settings,
    Map<String, ModpackInstallProgress> installations = const {},
  }) async {
    final store = _TestModpackStore(folder);
    final container = createTestContainer(
      overrides: [
        modpackStoreProvider.overrideWith(() => store),
        AppState.mods.overrideWithValue(mods),
        appSettings.overrideWith(() => _FakeSettings(settings ?? Settings())),
        runningModpackInstallationsProvider.overrideWithValue(installations),
      ],
    );
    // Keep the controller subscribed to store updates.
    container.listen(
      modpacksPageControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await awaitFirstValue(container, modpackStoreProvider);
    // Wait for the store build before writing in a test.
    await container.read(modpackStoreProvider.future);
    return (
      container: container,
      controller: container.read(modpacksPageControllerProvider.notifier),
      store: store,
    );
  }

  ModpacksPageState state() =>
      harness.container.read(modpacksPageControllerProvider);

  List<String> visibleNames() =>
      state().visibleCards.map((card) => card.name).toList();

  Future<void> saveTwoPacks() async {
    await harness.store.saveIncomingDefinition(
      _definition(
        id: _wispId,
        name: 'Wisp\'s pack',
        author: 'Wisp',
        gameVersion: '0.98a-RC8',
      ),
    );
    await harness.store.saveIncomingDefinition(
      _definition(
        id: _otherId,
        name: 'Another pack',
        author: 'Someone',
        modIds: ['alpha', 'missing_mod'],
      ),
    );
  }

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('trios-modpacks-page-test');
    harness = await open(mods: [_mod('alpha'), _mod('beta')]);
  });

  tearDown(() async {
    try {
      await harness.store.settingsManager.waitForPendingWrites();
    } catch (_) {}
    harness.container.dispose();
    try {
      await folder.delete(recursive: true);
    } catch (_) {}
  });

  group('cards', () {
    test('an empty library has no cards and is not loading', () {
      expect(state().allCards, isEmpty);
      expect(state().isLoading, isFalse);
    });

    test('saved packs and drafts both get cards', () async {
      await saveTwoPacks();
      await harness.store.createDraft(name: 'Unfinished');

      expect(visibleNames(), ['Another pack', 'Unfinished', 'Wisp\'s pack']);
      final draft = state().allCards.singleWhere(
        (card) => card.name == 'Unfinished',
      );
      expect(draft.isDraftOnly, isTrue);
    });

    test('installed counts come from the current mod list', () async {
      await saveTwoPacks();

      final wisp = state().allCards.singleWhere((c) => c.packId == _wispId);
      final other = state().allCards.singleWhere((c) => c.packId == _otherId);
      expect(wisp.installedCount, 2);
      expect(wisp.missingCount, 0);
      expect(other.installedCount, 1);
      expect(other.missingCount, 1);
    });
  });

  group('search', () {
    test('plain text matches the name', () async {
      await saveTwoPacks();

      harness.controller.updateSearchQuery('wisp');
      expect(visibleNames(), ['Wisp\'s pack']);

      harness.controller.clearSearch();
      expect(visibleNames().length, 2);
      expect(state().searchQuery, '');
    });

    test('a field token matches its field', () async {
      await saveTwoPacks();

      harness.controller.updateSearchQuery('author:someone');
      expect(visibleNames(), ['Another pack']);

      harness.controller.updateSearchQuery('missing:>0');
      expect(visibleNames(), ['Another pack']);
    });

    test('submitting a search adds it to the history', () async {
      harness.controller.updateSearchQuery('wisp');
      harness.controller.submitSearchQuery();

      expect(harness.container.read(appSettings).modpacksSearchHistory, [
        'wisp',
      ]);
    });
  });

  group('filters', () {
    BoolField<ModpackCardData> field(String id) {
      final group = harness.controller.filterGroups.firstWhere(
        (g) => g.id == 'state',
      ) as CompositeFilterGroup<ModpackCardData>;
      return group.fields.singleWhere((f) => f.id == id)
          as BoolField<ModpackCardData>;
    }

    test('Draft shows only never-saved packs', () async {
      await saveTwoPacks();
      await harness.store.createDraft(name: 'Unfinished');

      field('draft').value = true;
      harness.controller.onGroupChanged('state');

      expect(visibleNames(), ['Unfinished']);
      expect(harness.controller.activeFilterCount, 1);

      harness.controller.clearAllFilters();
      expect(visibleNames().length, 3);
      expect(harness.controller.activeFilterCount, 0);
    });

    test('Missing mods shows packs with a mod that is not installed', () async {
      await saveTwoPacks();

      field('missingMods').value = true;
      harness.controller.onGroupChanged('state');

      expect(visibleNames(), ['Another pack']);
    });

    test('Game version narrows to packs with that label', () async {
      await saveTwoPacks();
      await harness.store.createDraft(name: 'Unfinished');

      final group = harness.controller.filterGroups.firstWhere(
        (g) => g.id == 'gameVersion',
      ) as ChipFilterGroup<ModpackCardData>;
      group.filterStates['0.98a-RC8'] = true;
      harness.controller.onGroupChanged('gameVersion');
      expect(visibleNames(), ['Wisp\x27s pack']);

      group.setSelections({'Not set': true});
      harness.controller.onGroupChanged('gameVersion');
      expect(visibleNames(), ['Another pack', 'Unfinished']);
    });

    test('showing the filter panel is remembered in settings', () async {
      expect(state().showFilters, isFalse);

      harness.controller.toggleShowFilters();

      expect(state().showFilters, isTrue);
      expect(
        harness.container.read(appSettings).modpacksPageState?.showFilters,
        isTrue,
      );
    });
  });

  group('sorting', () {
    test('name ascending is the default', () async {
      await saveTwoPacks();

      expect(state().sortField, ModpackSortField.name);
      expect(state().sortAscending, isTrue);
      expect(visibleNames(), ['Another pack', 'Wisp\'s pack']);
    });

    test('the sort field and direction are remembered in settings', () async {
      await saveTwoPacks();

      harness.controller.setSortField(ModpackSortField.installedCount);
      harness.controller.toggleSortDirection();

      expect(visibleNames(), ['Wisp\'s pack', 'Another pack']);
      final saved = harness.container.read(appSettings).modpacksPageState;
      expect(saved?.sortField, ModpackSortField.installedCount);
      expect(saved?.sortAscending, isFalse);
    });

    test('a pack being installed is listed first', () async {
      harness.container.dispose();
      harness = await open(
        mods: [_mod('alpha'), _mod('beta')],
        installations: {
          _wispId: const ModpackInstallProgress(
            finishedCount: 0,
            totalCount: 2,
          ),
        },
      );
      await saveTwoPacks();

      expect(visibleNames(), ['Wisp\'s pack', 'Another pack']);
      expect(state().visibleCards.first.isInstalling, isTrue);
    });
  });

  group('opening packs', () {
    test('a saved card opens on its full page', () async {
      await saveTwoPacks();
      final card = state().allCards.singleWhere((c) => c.packId == _wispId);

      harness.controller.openCard(card);

      expect(state().openPackId, _wispId);
      expect(state().isEditing, isFalse);
    });

    test('a draft-only card opens in the editor', () async {
      final draft = await harness.store.createDraft(name: 'Unfinished');
      final card = state().allCards.single;

      harness.controller.openCard(card);

      expect(state().openPackId, draft.id);
      expect(state().isEditing, isTrue);
    });

    test('Back returns to the library', () async {
      await saveTwoPacks();
      harness.controller.viewPack(_wispId);

      harness.controller.closePack();

      expect(state().openPackId, isNull);
    });

    test('deleting the open pack returns to the library', () async {
      await saveTwoPacks();
      harness.controller.viewPack(_wispId);

      await harness.controller.deletePack(_wispId);

      expect(state().openPackId, isNull);
      expect(visibleNames(), ['Another pack']);
    });
  });

  group('library actions', () {
    test('New modpack starts a draft labelled with the game version', () async {
      harness.container.dispose();
      harness = await open(
        settings: Settings(lastStarsectorVersion: '0.98a-RC8'),
      );

      final packId = await harness.controller.createNewPack();

      final draft = harness.container
          .read(modpackStoreProvider)
          .requireValue
          .drafts[packId];
      expect(draft?.gameVersion, '0.98a-RC8');
      expect(state().openPackId, packId);
      expect(state().isEditing, isTrue);
    });

    test('Duplicate adds a copy with its own ID', () async {
      await saveTwoPacks();

      await harness.controller.duplicatePack(_wispId);

      expect(visibleNames(), ['Another pack', 'Wisp\'s pack', 'Wisp\'s pack']);
      expect(state().allCards.map((c) => c.packId).toSet().length, 3);
    });

    test('Delete removes the pack and its draft', () async {
      await saveTwoPacks();
      await harness.store.openDraft(_wispId);

      await harness.controller.deletePack(_wispId);

      final data = harness.container.read(modpackStoreProvider).requireValue;
      expect(data.packs.keys, [_otherId]);
      expect(data.drafts, isEmpty);
    });
  });

  group('importing a file', () {
    late File file;

    Future<void> writeFile(ModpackDefinition definition) =>
        file.writeAsString(encodeModpackDefinitionFileJson(definition));

    setUp(() {
      file = File('${folder.path}/pack.trios-modpack');
    });

    test('a new pack is added to the library', () async {
      await writeFile(_definition(id: _wispId, name: 'From a file'));

      final result = await harness.controller.importFile(file);

      expect(result.outcome, ModpackImportOutcome.added);
      expect(result.packId, _wispId);
      expect(visibleNames(), ['From a file']);
    });

    test('the same pack again is reported as already there', () async {
      await writeFile(_definition(id: _wispId, name: 'From a file'));
      await harness.controller.importFile(file);

      final result = await harness.controller.importFile(file);

      expect(result.outcome, ModpackImportOutcome.alreadyInLibrary);
      expect(visibleNames(), ['From a file']);
    });

    test('a different pack with the same ID is left alone', () async {
      await writeFile(_definition(id: _wispId, name: 'From a file'));
      await harness.controller.importFile(file);
      await writeFile(_definition(id: _wispId, name: 'Changed elsewhere'));

      final result = await harness.controller.importFile(file);

      expect(result.outcome, ModpackImportOutcome.conflictsWithLibrary);
      expect(visibleNames(), ['From a file']);
    });

    test('a draft with the same ID also counts as a conflict', () async {
      final draft = await harness.store.createDraft(name: 'Unfinished');
      await writeFile(_definition(id: draft.id, name: 'From a file'));

      final result = await harness.controller.importFile(file);

      expect(result.outcome, ModpackImportOutcome.conflictsWithLibrary);
      expect(
        harness.container.read(modpackStoreProvider).requireValue.packs,
        isEmpty,
      );
    });

    test('a file that is not a modpack is reported, not thrown', () async {
      await file.writeAsString('{"formatVersion": 1, "name": "no id"}');

      final result = await harness.controller.importFile(file);

      expect(result.outcome, ModpackImportOutcome.unreadable);
      expect(result.error, isNotNull);
      expect(state().allCards, isEmpty);
    });

    test('a missing file is reported, not thrown', () async {
      final result = await harness.controller.importFile(
        File('${folder.path}/does-not-exist.trios-modpack'),
      );

      expect(result.outcome, ModpackImportOutcome.unreadable);
    });
  });

  test('a draft item without a source marks the pack Needs sources', () async {
    final draft = await harness.store.createDraft(name: 'Unfinished');
    await harness.store.saveDraft(
      draft.copyWith(items: [const ModpackDraftItem(modId: 'alpha')]),
    );

    expect(state().allCards.single.needsSources, isTrue);
  });

  group('importing a link', () {
    test('a share link adds the pack', () async {
      final link = buildModpackShareLink(
        _definition(id: _wispId, name: 'From a link'),
      );

      final result = await harness.controller.importLink(link);

      expect(result.outcome, ModpackImportOutcome.added);
      expect(visibleNames(), ['From a link']);
    });

    test('text that is not a link is reported, not thrown', () async {
      final result = await harness.controller.importLink('not a link');

      expect(result.outcome, ModpackImportOutcome.unreadable);
      expect(state().allCards, isEmpty);
    });
  });
}
