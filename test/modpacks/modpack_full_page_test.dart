import 'package:trios/models/version_checker_info.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:flutter/services.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/utils/http_probe.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';

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
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

class _ExportPicker extends FilePicker {
  final String destination;
  String? suggestedDirectory;
  String? suggestedName;
  _ExportPicker(this.destination);
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    suggestedDirectory = initialDirectory;
    suggestedName = fileName;
    return destination;
  }
}

class _ExportStore extends ModpackStore {
  String? exportedPath;
  final recorded = Completer<void>();
  @override
  Future<ModpacksData> build() async => const ModpacksData();
  @override
  Future<void> recordExportLocation(String packId, String path) async {
    exportedPath = path;
    recorded.complete();
  }
}

class _FakeModMetadataStore extends ModMetadataStore {
  @override
  Future<ModsMetadata> build() async =>
      const ModsMetadata(baseMetadata: {}, userMetadata: {});
}

class _FakeSettings extends AppSettingNotifier {
  @override
  Settings build() => Settings();
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
  ModpackSourceValidator? validator,
  _ExportStore? exportStore,
  String? lastExportPath,
}) => ProviderScope(
  overrides: [
    if (exportStore != null)
      modpackStoreProvider.overrideWith(() => exportStore),
    if (validator != null)
      modpackSourceValidatorProvider.overrideWithValue(validator),
    appSettings.overrideWith(_FakeSettings.new),
    AppState.mods.overrideWithValue(mods),
    AppState.modCompatibility.overrideWithValue(const {}),
    AppState.modsMetadata.overrideWith(_FakeModMetadataStore.new),
    AppState.vramEstimatorProvider.overrideWith(_FakeVramEstimatorNotifier.new),
    AppState.isGameRunning.overrideWith((ref) async => false),
  ],
  child: MaterialApp(
    theme: ThemeData(extensions: const [TriOSThemeExtension()]),
    home: Scaffold(
      body: SizedBox(
        width: 1400,
        height: 900,
        child: ModpackFullPage(
          entry: ModpackLibraryEntry(
            definition: definition,
            lastExportPath: lastExportPath,
          ),
          onBack: onBack ?? () {},
          onEdit: onEdit ?? () {},
          onDuplicate: () async {},
          onDelete: () async {},
        ),
      ),
    ),
  ),
);

ModpackSourceValidator _validator(
  ModpackSourceProbe probe, {
  DateTime Function()? now,
  Future<VersionCheckerInfo> Function(String)? fetchVersionInfo,
}) => ModpackSourceValidator(
  probe,
  now: now,
  fetchVersionInfo:
      fetchVersionInfo ??
      (url) async => throw StateError('Unexpected Version Checker fetch: $url'),
);

void main() {
  late Directory configFolder;
  setUpAll(() {
    FilePicker.platform = _ExportPicker('');
    configFolder = Directory.systemTemp.createTempSync(
      'trios-full-page-tests-',
    );
    Constants.configDataFolderPath = configFolder;
  });
  tearDownAll(() => configFolder.deleteSync(recursive: true));
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Copy waits for checks and completes automatically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<HttpProbeResult>();
    final validator = _validator(
      (url, {required maxBytes, required prefixOnly, required cancellation}) =>
          pending.future,
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final pack = _definition().copyWith(items: [_definition().items.last]);
    await tester.pumpWidget(
      _wrap(definition: pack, mods: [], validator: validator),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);
    expect(copied, isNull);
    pending.complete(
      HttpProbeResult(
        Uri.parse(pack.items.single.url),
        [80, 75, 3, 4],
        'application/zip',
      ),
    );
    await tester.pumpAndSettle();
    expect(copied, buildModpackShareLink(pack));
    expect(find.text('Passed'), findsOneWidget);
  });

  testWidgets(
    'failed checks stay inline with repair and cancellation stops Copy',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<HttpProbeResult>();
      var first = true;
      var repairs = 0;
      final validator = _validator((
        url, {
        required maxBytes,
        required prefixOnly,
        required cancellation,
      }) async {
        if (first) {
          first = false;
          throw const FormatException('Download unavailable');
        }
        return pending.future;
      });
      final pack = _definition().copyWith(items: [_definition().items.last]);
      await tester.pumpWidget(
        _wrap(
          definition: pack,
          mods: [],
          validator: validator,
          onEdit: () => repairs++,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Download unavailable'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Repair sources'));
      expect(repairs, 1);
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      await tester.tap(find.text('Cancel checks'));
      await tester.pump();
      pending.complete(
        HttpProbeResult(
          Uri.parse(pack.items.single.url),
          [80, 75],
          'application/zip',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Modpack link copied.'), findsNothing);
    },
  );

  testWidgets(
    'Export remembers the path and asks before replacing pretty JSON',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final file = File('${configFolder.path}/export.trios-modpack')
        ..writeAsStringSync('original');
      final picker = _ExportPicker(file.path);
      final previousPicker = FilePicker.platform;
      FilePicker.platform = picker;
      addTearDown(() => FilePicker.platform = previousPicker);
      final store = _ExportStore();
      final validator = _validator(
        (
          url, {
          required maxBytes,
          required prefixOnly,
          required cancellation,
        }) async =>
            HttpProbeResult(url, [80, 75, 3, 4], 'application/zip'),
      );
      final pack = _definition().copyWith(items: [_definition().items.last]);
      await tester.pumpWidget(
        _wrap(
          definition: pack,
          mods: [],
          validator: validator,
          exportStore: store,
          lastExportPath: file.path,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Replace exported modpack?'), findsOneWidget);
      expect(picker.suggestedName, 'export.trios-modpack');
      expect(picker.suggestedDirectory, configFolder.path);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(file.readAsStringSync(), 'original');
      expect(store.exportedPath, isNull);
      await tester.tap(find.text('Export'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 20 && store.exportedPath == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pumpAndSettle();
      }
      final json = file.readAsStringSync();
      expect(json, contains('\n  "formatVersion"'));
      expect(jsonDecode(json)['id'], pack.id);
      expect(store.exportedPath, file.path);
    },
  );

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
        'installed',
        'icons',
        'name',
        'author',
        'label',
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
