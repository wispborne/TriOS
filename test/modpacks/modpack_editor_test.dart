import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/modpacks/editor/modpack_editor.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

const packId = 'N3qGd6c8R2mVx1ZaYkW0_A';

class _MemoryStore extends ModpackStore {
  final ModpacksData initial;
  _MemoryStore(this.initial);
  @override
  Future<ModpacksData> build() async => initial;
  @override
  Future<ModpacksData> updateState(
    FutureOr<ModpacksData> Function(ModpacksData) mutator, {
    FutureOr<ModpacksData> Function(Object, StackTrace)? onError,
    bool skipChangeCheck = false,
  }) async {
    final next = await mutator(state.requireValue);
    state = AsyncData(next);
    return next;
  }

  @override
  Future<void> writeItemSourcesToRecords(ModpackDefinition definition) async {}
}

class _Settings extends AppSettingNotifier {
  @override
  Settings build() => Settings();
  @override
  Future<Settings> update(
    Settings Function(Settings) mutator, {
    Settings Function(Object, StackTrace)? onError,
  }) async => state = mutator(state);
}

class _Records extends ModRecordsStore {
  @override
  Future<ModRecords> build() async => const ModRecords();
}

class _Metadata extends ModMetadataStore {
  @override
  Future<ModsMetadata> build() async =>
      const ModsMetadata(baseMetadata: {}, userMetadata: {});
}

class _Vram extends VramEstimatorNotifier {
  @override
  Future<VramEstimatorManagerState> build() async =>
      VramEstimatorManagerState.initial();
}

Mod _mod(String id) => Mod(
  id: id,
  isEnabledInGame: true,
  modVariants: [
    ModVariant(
      modInfo: ModInfo(
        id: id,
        name: id,
        author: 'Author',
        version: Version.parse('1.0'),
      ),
      versionCheckerInfo: VersionCheckerInfo(
        masterVersionFile: 'https://example.com/$id.version',
      ),
      modFolder: Directory('mods/$id'),
      gameCoreFolder: Directory('core'),
      hasNonBrickedModInfo: true,
    ),
  ],
);

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<ProviderContainer> mountEditor(
  WidgetTester tester,
  ModpacksData data, {
  double width = 1400,
  ValueChanged<String>? onSaved,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      modpackStoreProvider.overrideWith(() => _MemoryStore(data)),
      modRecordsStore.overrideWith(_Records.new),
      appSettings.overrideWith(_Settings.new),
      AppState.mods.overrideWithValue([_mod('alpha'), _mod('beta')]),
      AppState.modCompatibility.overrideWithValue(const {}),
      AppState.modsMetadata.overrideWith(_Metadata.new),
      AppState.vramEstimatorProvider.overrideWith(_Vram.new),
      AppState.isGameRunning.overrideWith((ref) async => false),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: ModpackEditor(
            packId: packId,
            onBack: onBack ?? () {},
            onSaved: onSaved ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  late Directory configFolder;
  setUpAll(() {
    configFolder = Directory.systemTemp.createTempSync('trios-editor-tests-');
    Constants.configDataFolderPath = configFolder;
  });
  tearDownAll(() => configFolder.deleteSync(recursive: true));
  testWidgets('dragging between grids adds and removes without duplicates', (
    tester,
  ) async {
    final container = await mountEditor(
      tester,
      const ModpacksData(
        drafts: {packId: ModpackDraft(id: packId, name: 'Drag pack')},
      ),
    );
    final grids = find.byWidgetPredicate((widget) => widget is WispGrid);
    final installed = find.byType(WispGrid<Mod>);
    await tester.dragFrom(
      tester.getCenter(
        find.descendant(of: installed, matching: find.text('alpha')).first,
      ),
      const Offset(700, 0),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(modpackStoreProvider)
          .value!
          .drafts[packId]!
          .items
          .map((item) => item.modId),
      ['alpha'],
    );
    // Adding an already present mod is harmless.
    final rightTarget = tester
        .widgetList<DragTarget<WispGridDragPayload>>(
          find.descendant(
            of: grids.last,
            matching: find.byType(DragTarget<WispGridDragPayload>),
          ),
        )
        .first;
    rightTarget.onAcceptWithDetails!(
      DragTargetDetails(
        data: const WispGridDragPayload(
          itemKeys: ['alpha', 'beta'],
          dragDataType: 'modpack:$packId:installed',
        ),
        offset: Offset.zero,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(modpackStoreProvider)
          .value!
          .drafts[packId]!
          .items
          .map((item) => item.modId),
      ['alpha', 'beta'],
    );
    final handle = find
        .byWidgetPredicate(
          (widget) =>
              widget is Draggable<WispGridDragPayload> &&
              widget.data?.dragDataType == 'modpack:$packId:items',
        )
        .first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(installed));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      container
          .read(modpackStoreProvider)
          .value!
          .drafts[packId]!
          .items
          .map((item) => item.modId),
      ['beta'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discard removes a draft-only pack after confirmation', (
    tester,
  ) async {
    var closed = false;
    final container = await mountEditor(
      tester,
      const ModpacksData(drafts: {packId: ModpackDraft(id: packId)}),
      onBack: () => closed = true,
    );
    await tester.enterText(field('Name'), 'Throw away');
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(
      container.read(modpackStoreProvider).value!.drafts[packId],
      isNotNull,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Discard changes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(closed, true);
    expect(container.read(modpackStoreProvider).value!.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'new draft autosaves metadata, adds a selection, and commits version one',
    (tester) async {
      String? saved;
      final container = await mountEditor(
        tester,
        const ModpacksData(drafts: {packId: ModpackDraft(id: packId)}),
        onSaved: (id) => saved = id,
      );
      expect(field('Name'), findsOneWidget);
      await tester.enterText(field('Name'), 'My pack');
      await tester.pumpAndSettle();
      expect(
        container.read(modpackStoreProvider).value!.drafts[packId]!.name,
        'My pack',
      );
      final installedGrid = find.byType(WispGrid<Mod>);
      await tester.tap(
        find
            .descendant(of: installedGrid, matching: find.byType(Checkbox))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(modpackStoreProvider)
            .value!
            .drafts[packId]!
            .items
            .single
            .modId,
        'alpha',
      );
      await tester.tap(find.text('Save changes · v1'));
      await tester.pumpAndSettle();
      expect(saved, packId);
      expect(
        container
            .read(modpackStoreProvider)
            .value!
            .packs[packId]!
            .definition
            .version,
        1,
      );
      expect(container.read(modpackStoreProvider).value!.drafts, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved fields start collapsed, editing keeps unknown fields and Back keeps a draft',
    (tester) async {
      var backed = false;
      const definition = ModpackDefinition(
        id: packId,
        name: 'Original',
        version: 3,
        unknownFields: {'future': 'keep'},
        items: [
          ModpackItem(
            modId: 'remote',
            name: 'Remote',
            url: 'https://example.com/mod.zip',
            sourceType: ModpackItemSourceType.directDownload,
            unknownFields: {'futureItem': true},
          ),
        ],
      );
      final container = await mountEditor(
        tester,
        const ModpacksData(
          packs: {packId: ModpackLibraryEntry(definition: definition)},
        ),
        onBack: () => backed = true,
      );
      expect(field('Name'), findsNothing);
      await tester.tap(find.text('Pack details'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Name'), 'Changed');
      await tester.pumpAndSettle();
      expect(find.text('Save changes · v4'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backed, true);
      final data = container.read(modpackStoreProvider).value!;
      expect(data.packs[packId]!.definition.name, 'Original');
      expect(data.drafts[packId]!.name, 'Changed');
      expect(data.drafts[packId]!.unknownFields, {'future': 'keep'});
      expect(data.drafts[packId]!.items.single.unknownFields, {
        'futureItem': true,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow editor keeps grids side by side and exposes repair for missing sources',
    (tester) async {
      final container = await mountEditor(
        tester,
        const ModpacksData(
          drafts: {
            packId: ModpackDraft(
              id: packId,
              name: 'Draft',
              items: [ModpackDraftItem(modId: 'alpha', name: 'Alpha')],
            ),
          },
        ),
        width: 800,
      );
      final grids = find.byWidgetPredicate((widget) => widget is WispGrid);
      expect(grids, findsNWidgets(2));
      expect(
        tester.getTopLeft(grids.first).dx,
        lessThan(tester.getTopLeft(grids.last).dx),
      );
      final expand = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.expand_more,
      );
      await tester.tap(expand.last);
      await tester.pumpAndSettle();
      expect(field('Download URL'), findsOneWidget);
      expect(find.text('Enter a download URL.'), findsOneWidget);
      await tester.ensureVisible(find.text('Find source again'));
      await tester.tap(find.text('Find source again'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(modpackStoreProvider)
            .value!
            .drafts[packId]!
            .items
            .single
            .url,
        'https://example.com/alpha.version',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
