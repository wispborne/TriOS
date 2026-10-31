@Tags(['local-only'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/bulk_save_selection_dialog.dart';
import 'package:trios/save_archiver/models/archived_save.dart';
import 'package:trios/save_archiver/save_archive_manager.dart';
import 'package:trios/save_archiver/save_archive_runner_dialog.dart';
import 'package:trios/save_archiver/save_archives_dialog.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';

/// Captures dialogs in `readme_resources/save_archiver/`. Tagged `local-only`
/// because font rendering differs between machines. Regenerate the images with:
///
/// ```
/// fvm flutter test test/save_archiver/screenshots_test.dart --update-goldens
/// ```
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_screenshots',
    );

    // Widget tests need fonts loaded explicitly to render readable text.
    final roboto = FontLoader('Roboto')
      ..addFont(_load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(_load('assets/fonts/Roboto-Bold.ttf'));
    await roboto.load();

    final icons = FontLoader('MaterialIcons')
      ..addFont(_load(_materialIconsFontPath()));
    await icons.load();

    // Avoid Google Fonts network requests in tests.
    ThemeManager.appFont = AppFont.system;
  });

  ThemeData theme() {
    final base = ThemeManager.convertToThemeData(
      TriOSTheme(
        id: 'Wisp',
        displayName: 'Wisp',
        isDark: true,
        primary: Color(0xFF1080D6),
        secondary: Color(0xFF00C2FF),
        surface: Color(0xFF14181C),
        surfaceContainer: Color(0xFF1B2026),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../readme_resources/save_archiver/$name.png'),
    );
  }

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = size * 2.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('archived saves list', (tester) async {
    await sized(tester, const Size(880, 660));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettings.overrideWith(_InMemorySettings.new),
          saveArchiveFolderProvider.overrideWithValue(
            Directory(
              'C:/Program Files (x86)/Fractal Softworks/'
              'TriOS_Save_Archives',
            ),
          ),
          archivedSavesProvider.overrideWith(() => _StubArchives(_archives)),
          saveFileProvider.overrideWith(() => _StubSaves([_liveSave])),
          AppState.isGameRunning.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showSaveArchivesDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await shoot(tester, 'archived_saves_list');
  });

  testWidgets('picking saves to archive', (tester) async {
    await sized(tester, const Size(780, 780));

    await _pumpPicker(
      tester,
      theme(),
      title: 'Archive saves',
      explanation: 'Choose which saves to archive.',
      items: _savePickerItems,
      initiallySelected: _savePickerItems
          .skip(2)
          .map((item) => item.id)
          .toSet(),
      confirmLabel: (count) => 'Archive $count save${count == 1 ? '' : 's'}',
      confirmIcon: Icons.archive,
      estimateTooltip: 'Estimated from your other save archives.',
    );

    await shoot(tester, 'picking_saves_to_archive');
  });

  testWidgets('picking saves to restore', (tester) async {
    await sized(tester, const Size(780, 700));

    await _pumpPicker(
      tester,
      theme(),
      title: 'Restore saves',
      explanation: 'Choose which saves to restore.',
      checkboxLabel: 'Delete the archives afterwards',
      items: _restorePickerItems,
      initiallySelected: {_restorePickerItems.first.id},
      confirmLabel: (count) => 'Restore $count save${count == 1 ? '' : 's'}',
      confirmIcon: Icons.unarchive,
    );

    await shoot(tester, 'picking_saves_to_restore');
  });

  testWidgets('a batch running', (tester) async {
    await sized(tester, const Size(720, 560));
    final held = Completer<SaveArchiveJobResult>();
    addTearDown(() {
      if (!held.isCompleted) {
        held.complete(
          const SaveArchiveJobResult(succeeded: true, message: 'done'),
        );
      }
    });

    await _pumpRunner(tester, theme(), [
      SaveArchiveJobRequest(
        title: 'Cotton',
        subtitle: 'save_Cotton_2947619283746',
        run: (onStep) async => const SaveArchiveJobResult(
          succeeded: true,
          message: '',
          originalSizeInBytes: 412 * 1024 * 1024,
          archiveSizeInBytes: 38 * 1024 * 1024,
        ),
      ),
      SaveArchiveJobRequest(
        title: 'Andrada',
        subtitle: 'save_Andrada_8827364519283',
        run: (onStep) {
          onStep(SaveArchiveStep.compressing);
          return held.future;
        },
      ),
      SaveArchiveJobRequest(
        title: 'Kanta',
        subtitle: 'save_Kanta_1029384756102',
        run: (onStep) async =>
            const SaveArchiveJobResult(succeeded: true, message: 'done'),
      ),
      SaveArchiveJobRequest(
        title: 'Sebestyen',
        subtitle: 'save_Sebestyen_5647382910293',
        run: (onStep) async =>
            const SaveArchiveJobResult(succeeded: true, message: 'done'),
      ),
    ]);

    await tester.pump(const Duration(milliseconds: 200));

    await shoot(tester, 'batch_running');
  });

  testWidgets('a batch finished', (tester) async {
    await sized(tester, const Size(720, 620));

    await _pumpRunner(tester, theme(), [
      SaveArchiveJobRequest(
        title: 'Cotton',
        subtitle: 'save_Cotton_2947619283746',
        run: (onStep) async => const SaveArchiveJobResult(
          succeeded: true,
          message: '',
          originalSizeInBytes: 412 * 1024 * 1024,
          archiveSizeInBytes: 38 * 1024 * 1024,
        ),
      ),
      SaveArchiveJobRequest(
        title: 'Andrada',
        subtitle: 'save_Andrada_8827364519283',
        run: (onStep) async => const SaveArchiveJobResult(
          succeeded: true,
          message: '',
          originalSizeInBytes: 287 * 1024 * 1024,
          archiveSizeInBytes: 24 * 1024 * 1024,
        ),
      ),
      SaveArchiveJobRequest(
        title: 'Kanta',
        subtitle: 'save_Kanta_1029384756102',
        run: (onStep) async => const SaveArchiveJobResult(
          succeeded: true,
          needsAttention: true,
          message:
              'The archive is finished and checked, but the save folder could '
              'not be removed, so there are two copies.',
        ),
      ),
      SaveArchiveJobRequest(
        title: 'Sebestyen',
        subtitle: 'save_Sebestyen_5647382910293',
        run: (onStep) async => const SaveArchiveJobResult(
          succeeded: false,
          message:
              'The archive is missing "campaign.xml". The save was left alone.',
        ),
      ),
    ]);

    await tester.pumpAndSettle();

    await shoot(tester, 'batch_finished');
  });
}

Future<void> _pumpPicker(
  WidgetTester tester,
  ThemeData theme, {
  required String title,
  required String explanation,
  required List<SaveSelectionItem> items,
  required Set<String> initiallySelected,
  required String Function(int) confirmLabel,
  required IconData confirmIcon,
  String? estimateTooltip,
  String? checkboxLabel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showBulkSaveSelectionDialog(
                context: context,
                title: title,
                explanation: explanation,
                items: items,
                initiallySelected: initiallySelected,
                confirmLabel: confirmLabel,
                confirmIcon: confirmIcon,
                estimateTooltip: estimateTooltip,
                checkboxLabel: checkboxLabel,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _pumpRunner(
  WidgetTester tester,
  ThemeData theme,
  List<SaveArchiveJobRequest> jobs,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSaveArchiveRunnerDialog(
                context: context,
                title: 'Archiving ${jobs.length} saves',
                finishedTitle: 'Archived ${jobs.length} saves',
                jobs: jobs,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  // Finish the route transition while the held job remains pending.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The icon font shipped with the Flutter SDK running the tests. Some SDK
/// versions name the file in lowercase, so the name is matched ignoring case.
String _materialIconsFontPath() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is not set. Run this with flutter test.');
  }
  final fontsFolder = Directory(
    p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
  );
  return fontsFolder
      .listSync()
      .whereType<File>()
      .firstWhere(
        (file) =>
            p.basename(file.path).toLowerCase() == 'materialicons-regular.otf',
        orElse: () => throw StateError(
          'No MaterialIcons-Regular.otf in ${fontsFolder.path}.',
        ),
      )
      .path;
}

Future<ByteData> _load(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}

class _InMemorySettings extends AppSettingNotifier {
  @override
  Settings build() => Settings();
}

class _StubArchives extends ArchivedSavesNotifier {
  final List<ArchivedSaveEntry> entries;

  _StubArchives(this.entries);

  @override
  Future<List<ArchivedSaveEntry>> build() async => entries;
}

class _StubSaves extends SaveFileNotifier {
  final List<SaveFile> saves;

  _StubSaves(this.saves);

  @override
  Future<List<SaveFile>> build() async => saves;
}

ArchivedSaveEntry _entry({
  required String folder,
  required String character,
  required int level,
  required DateTime saved,
  required int mods,
  required int original,
  required int compressed,
  bool ironMode = false,
}) => ArchivedSaveEntry(
  archiveFile: File('/archives/$folder.7z'),
  info: ArchivedSave(
    saveFolderName: folder,
    characterName: character,
    characterLevel: level,
    saveDate: saved,
    isIronMode: ironMode,
    modNames: List.generate(mods, (index) => 'Mod $index'),
    fileCount: 9,
    originalSizeInBytes: original,
    archiveSizeInBytes: compressed,
    archivedDate: DateTime(2026, 9, 20, 14, 3),
  ),
  sizeOnDiskInBytes: compressed,
  fileModified: DateTime(2026, 9, 20, 14, 3),
);

final _archives = [
  _entry(
    folder: 'save_Cotton_2947619283746',
    character: 'Cotton',
    level: 15,
    saved: DateTime(2026, 9, 14, 21, 40),
    mods: 87,
    original: 412 * 1000 * 1000,
    compressed: 38 * 1000 * 1000,
  ),
  _entry(
    folder: 'save_Andrada_8827364519283',
    character: 'Andrada',
    level: 42,
    saved: DateTime(2026, 8, 30, 9, 12),
    mods: 63,
    original: 287 * 1000 * 1000,
    compressed: 24 * 1000 * 1000,
    ironMode: true,
  ),
  _entry(
    folder: 'save_Kanta_1029384756102',
    character: 'Kanta',
    level: 7,
    saved: DateTime(2026, 7, 2, 18, 55),
    mods: 12,
    original: 96 * 1000 * 1000,
    compressed: 9 * 1000 * 1000,
  ),
  ArchivedSaveEntry(
    archiveFile: File('/archives/old_campaign_backup.7z'),
    info: null,
    sizeOnDiskInBytes: 51 * 1000 * 1000,
    fileModified: DateTime(2026, 3, 11, 8, 20),
  ),
];

final _liveSave = SaveFile(
  id: 'save_Kanta_1029384756102',
  folder: Directory('/saves/save_Kanta_1029384756102'),
  characterName: 'Kanta',
  characterLevel: 7,
  saveDate: DateTime(2026, 7, 2, 18, 55),
  mods: const [],
  compressed: true,
  isIronMode: false,
  difficulty: 'normal',
  gameTimestamp: 0,
  secondsPerDay: 10,
);

final _savePickerItems = [
  const SaveSelectionItem(
    id: 'a',
    title: 'Sebestyen',
    subtitle: 'save_Sebestyen_5520193847561 · level 31 · saved 21/09/2026 6:12 PM · 94 mods',
    sizeInBytes: 503 * 1000 * 1000,
    estimatedSavingsInBytes: 458 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'b',
    title: 'Cotton',
    subtitle: 'save_Cotton_2947619283746 · level 15 · saved 14/09/2026 9:40 PM · 87 mods',
    sizeInBytes: 412 * 1000 * 1000,
    estimatedSavingsInBytes: 375 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'c',
    title: 'Andrada',
    subtitle: 'save_Andrada_8827364519283 · level 42 · saved 30/08/2026 9:12 AM · 63 mods',
    sizeInBytes: 287 * 1000 * 1000,
    estimatedSavingsInBytes: 261 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'd',
    title: 'Kanta',
    subtitle: 'save_Kanta_1029384756102 · level 7 · saved 02/07/2026 6:55 PM · 12 mods',
    sizeInBytes: 96 * 1000 * 1000,
    estimatedSavingsInBytes: 87 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'e',
    title: 'Daud',
    subtitle: 'save_Daud_6610298374655 · level 22 · saved 11/03/2026 8:20 AM · 51 mods',
    sizeInBytes: 188 * 1000 * 1000,
    estimatedSavingsInBytes: 171 * 1000 * 1000,
  ),
];

final _restorePickerItems = [
  const SaveSelectionItem(
    id: 'a',
    title: 'Cotton',
    subtitle: 'save_Cotton_2947619283746 · level 15 · 87 mods',
    sizeInBytes: 38 * 1000 * 1000,
    restoredSizeInBytes: 412 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'b',
    title: 'Andrada',
    subtitle: 'save_Andrada_8827364519283 · level 42 · 63 mods',
    sizeInBytes: 24 * 1000 * 1000,
    restoredSizeInBytes: 287 * 1000 * 1000,
  ),
  const SaveSelectionItem(
    id: 'c',
    title: 'Kanta',
    subtitle: 'save_Kanta_1029384756102 · level 7 · 12 mods',
    sizeInBytes: 9 * 1000 * 1000,
    restoredSizeInBytes: 96 * 1000 * 1000,
    selectable: false,
    blockedReason:
        'A save folder named "save_Kanta_1029384756102" already exists. '
        'Move or archive it before restoring this save.',
  ),
  const SaveSelectionItem(
    id: 'd',
    title: 'old_campaign_backup',
    subtitle:
        'old_campaign_backup · details unreadable — can still be restored',
    sizeInBytes: 51 * 1000 * 1000,
  ),
];
