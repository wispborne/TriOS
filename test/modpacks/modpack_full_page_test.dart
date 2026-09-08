import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/modpacks/full_page/modpack_full_page.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

class _FakeModMetadataStore extends ModMetadataStore {
  @override
  Future<ModsMetadata> build() async =>
      const ModsMetadata(baseMetadata: {}, userMetadata: {});
}

class _FakeVramEstimatorNotifier extends VramEstimatorNotifier {
  @override
  Future<VramEstimatorManagerState> build() async =>
      VramEstimatorManagerState.initial();
}

Mod _mod(String id, String version) => Mod(
  id: id,
  isEnabledInGame: true,
  modVariants: [
    ModVariant(
      modInfo: ModInfo(
        id: id,
        name: 'Installed $id',
        author: 'Local author',
        version: Version.parse(version),
      ),
      versionCheckerInfo: null,
      modFolder: Directory('mods/$id'),
      hasNonBrickedModInfo: true,
      gameCoreFolder: Directory('core'),
    ),
  ],
);

ModpackDefinition _definition() => const ModpackDefinition(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: 'Wisp\'s pack',
  version: 3,
  author: 'Wisp',
  description: 'A compact test pack.',
  gameVersion: '0.98a-RC8',
  homepageUrl: 'https://example.com/home',
  updateUrl: 'https://example.com/update.trios-modpack',
  items: [
    ModpackItem(
      modId: 'alpha',
      name: 'Alpha',
      version: '1.0.0',
      label: 'Core',
      note: 'Configure this after installing.',
      url: 'https://example.com/alpha.version',
      sourceType: ModpackItemSourceType.versionFile,
    ),
    ModpackItem(
      modId: 'beta',
      name: 'Beta',
      version: '2.0.0',
      url: 'https://example.com/beta.zip',
      sourceType: ModpackItemSourceType.directDownload,
    ),
  ],
);

Widget _wrap({
  required ModpackDefinition definition,
  required List<Mod> mods,
  VoidCallback? onBack,
  VoidCallback? onEdit,
}) => ProviderScope(
  overrides: [
    AppState.mods.overrideWithValue(mods),
    AppState.modCompatibility.overrideWithValue(const {}),
    AppState.modsMetadata.overrideWith(_FakeModMetadataStore.new),
    AppState.vramEstimatorProvider.overrideWith(_FakeVramEstimatorNotifier.new),
    AppState.isGameRunning.overrideWith((ref) async => false),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1400,
        height: 900,
        child: ModpackFullPage(
          entry: ModpackLibraryEntry(definition: definition),
          onBack: onBack ?? () {},
          onEdit: onEdit ?? () {},
          onDuplicate: () async {},
          onDelete: () async {},
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('shows ordered actions, pack information, and item columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(definition: _definition(), mods: [_mod('alpha', '2.0.0')]),
    );
    await tester.pumpAndSettle();

    final actionLabels = ['Back', 'Edit', 'Copy link', 'Export', 'Install'];
    final actionCenters = [
      for (final label in actionLabels) tester.getCenter(find.text(label)),
    ];
    for (var index = 1; index < actionCenters.length; index++) {
      expect(actionCenters[index].dx, greaterThan(actionCenters[index - 1].dx));
    }
    final overflowButton = find.byIcon(Icons.more_vert);
    expect(
      tester.getCenter(overflowButton).dx,
      greaterThan(actionCenters.last.dx),
    );

    await tester.tap(overflowButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    final packTitle = find.text("Wisp's pack");
    final packVersion = find.text('v3');
    expect(packVersion, findsOneWidget);
    expect(
      tester.getCenter(packVersion).dx,
      greaterThan(tester.getCenter(packTitle).dx),
    );
    expect(find.text('Starsector version'), findsOneWidget);
    expect(find.text('0.98a-RC8'), findsOneWidget);
    expect(find.text('1 of 2 installed'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('2.0.0 (modpack: 1.0.0)'), findsOneWidget);

    final grid = tester.widget<WispGrid<ModpackItemRowData>>(
      find.byType(WispGrid<ModpackItemRowData>),
    );
    expect(grid.defaultSortField, 'packOrder');
    expect(
      grid.columns
          .where((column) => column.defaultState.isVisible)
          .map((column) => column.key),
      [
        'icons',
        'name',
        'author',
        'label',
        'installed',
        'version',
        'dependencies',
      ],
    );
    expect(
      grid.columns
          .where((column) => !column.defaultState.isVisible)
          .map((column) => column.key),
      containsAll(['packOrder', 'modIcon', 'loadOrder', 'gameVersion']),
    );
  });

  testWidgets('supports several expanded rows and expand or collapse all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(definition: _definition(), mods: const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Expand all'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download URL:'), findsNWidgets(2));
    expect(
      find.textContaining('Configure this after installing.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Collapse all'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download URL:'), findsNothing);
  });

  testWidgets('Back and Edit use the page callbacks', (tester) async {
    var backCount = 0;
    var editCount = 0;
    await tester.pumpWidget(
      _wrap(
        definition: _definition(),
        mods: const [],
        onBack: () => backCount++,
        onEdit: () => editCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.tap(find.text('Edit'));

    expect(backCount, 1);
    expect(editCount, 1);
  });
}
