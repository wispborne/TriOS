import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/incoming/incoming_modpack.dart';
import 'package:trios/modpacks/incoming/incoming_modpack_dialog.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

import 'incoming_modpack_test.dart' show incomingPack;

class _Settings extends AppSettingNotifier {
  @override
  Settings build() => Settings();
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

class _MemoryManager extends ModpacksSettingsManager {
  @override
  Future<void> scheduleWrite(ModpacksData newState) async {}
}

class _MemoryStore extends ModpackStore {
  @override
  ModpacksSettingsManager createSettingsManager() => _MemoryManager();
  @override
  Future<ModpacksData> build() async => const ModpacksData();
}

void main() {
  late Directory folder;
  late ProviderContainer container;
  late ModpackStore store;
  IncomingModpackResult? result;
  setUpAll(() {
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'incoming-dialog-settings',
    );
  });
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('incoming-dialog');
    store = _MemoryStore();
    container = ProviderContainer(
      overrides: [
        modpackStoreProvider.overrideWith(() => store),
        appSettings.overrideWith(_Settings.new),
        AppState.mods.overrideWithValue(const []),
        AppState.modCompatibility.overrideWithValue(const {}),
        AppState.modsMetadata.overrideWith(_Metadata.new),
        AppState.vramEstimatorProvider.overrideWith(_Vram.new),
        AppState.isGameRunning.overrideWith((ref) async => true),
        AppState.canWriteToModsFolder.overrideWith((ref) async => false),
      ],
    );
    await container.read(modpackStoreProvider.future);
    result = null;
  });
  tearDown(() async {
    container.dispose();
    await folder.delete(recursive: true);
  });

  Future<void> open(WidgetTester tester, {IncomingModpackFetch? fetch}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(extensions: const [TriOSThemeExtension()]),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<IncomingModpackResult>(
                    context: context,
                    builder: (_) => IncomingModpackDialog(
                      definition: incomingPack,
                      fetch: fetch,
                    ),
                  );
                },
                child: const Text('Open incoming'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open incoming'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'preview can be cancelled without fetching, saving, or installing',
    (tester) async {
      var fetched = false;
      await open(
        tester,
        fetch: (_, _) async {
          fetched = true;
          return incomingPack;
        },
      );
      expect(find.text('Add to library'), findsOneWidget);
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Core'), findsWidgets);
      expect(find.text('Check for update'), findsOneWidget);
      expect(fetched, false);
      expect(container.read(modpackStoreProvider).requireValue.packs, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(container.read(modpackStoreProvider).requireValue.packs, isEmpty);
    },
  );

  testWidgets('Add works while the game runs and does not await an update', (
    tester,
  ) async {
    final online = Completer<ModpackDefinition>();
    await open(tester, fetch: (_, _) => online.future);
    await tester.tap(find.text('Check for update'));
    await tester.pump();
    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();
    online.complete(incomingPack.copyWith(version: 9));
    await tester.pumpAndSettle();
    expect(
      result?.packId,
      incomingPack.id,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? w.textSpan?.toPlainText())
          .join(' | '),
    );
    expect(
      container
          .read(modpackStoreProvider)
          .requireValue
          .packs[incomingPack.id]
          ?.definition
          .version,
      3,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft conflicts offer cancel, copy, and explicit discard', (
    tester,
  ) async {
    await store.saveIncomingDefinition(
      incomingPack.copyWith(name: 'Saved name'),
    );
    final draft = await store.openDraft(incomingPack.id);
    await store.saveDraft(draft!.copyWith(name: 'Unfinished work'));
    await open(tester);
    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();
    expect(find.text('Discard draft and replace'), findsOneWidget);
    expect(find.text('Pack information'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(
      container
          .read(modpackStoreProvider)
          .requireValue
          .drafts[incomingPack.id]
          ?.name,
      'Unfinished work',
    );
    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add as copy'));
    await tester.pumpAndSettle();
    expect(result?.packId, isNot(incomingPack.id));
    expect(
      container
          .read(modpackStoreProvider)
          .requireValue
          .drafts[incomingPack.id]
          ?.name,
      'Unfinished work',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('online changes require review and explicit selection', (
    tester,
  ) async {
    await open(
      tester,
      fetch: (_, _) async => incomingPack.copyWith(
        version: 4,
        updateUrl: 'https://example.com/new',
      ),
    );
    await tester.tap(find.text('Check for update'));
    await tester.pumpAndSettle();
    expect(find.text('Incoming pack · v3'), findsOneWidget);
    await tester.tap(find.text('Review online definition'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The update address changes'), findsOneWidget);
    await tester.tap(find.text('Use online definition'));
    await tester.pumpAndSettle();
    expect(find.text('Incoming pack · v4'), findsOneWidget);
    await tester.tap(find.text('Add to library'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(modpackStoreProvider)
          .requireValue
          .packs[incomingPack.id]
          ?.definition
          .version,
      4,
    );
  });
}
