import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/details_dialog/catalog_details_dialog.dart';
import 'package:trios/catalog/details_dialog/details_header.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';

/// Records what it was asked to download instead of touching the network.
class _RecordingDownloadManager extends TriOSDownloadManager {
  final List<String> requested = [];

  @override
  void downloadAndInstallMod(
    String displayName,
    String uri, {
    required bool activateVariantOnComplete,
    required DownloadSourceHint? sourceHint,
    ModInfo? modInfo,
    bool skipConfirmation = false,
  }) {
    requested.add(uri);
  }
}

/// Stands in for the real settings notifier so nothing touches the settings
/// file on disk.
class _FakeSettings extends AppSettingNotifier {
  _FakeSettings(this.initial);

  final Settings initial;

  @override
  Settings build() => initial;
}

CatalogMod _mod(
  String name, {
  List<String> authors = const ['Someone'],
  List<String> categories = const [],
  List<ModSource>? sources,
  Map<ModUrlType, String>? urls,
  ForumLlmMod? llmMod,
  String? aiParagraph,
  ForumLlmChangelog? changelog,
  CatalogExtras? extras,
}) => CatalogMod(
  entry: ModRepoEntry(
    id: name,
    name: name,
    authorsList: authors,
    categories: categories,
    sources: sources,
    urls: urls,
  ),
  title: name,
  authors: authors.join(', '),
  llmMod: llmMod,
  aiParagraph: aiParagraph,
  changelog: changelog,
  extras: extras,
);

/// Shows a button that opens the dialog on [grid]'s first mod, with every mod
/// in [allMods] in the catalog.
Future<_RecordingDownloadManager> _pumpDialog(
  WidgetTester tester, {
  required List<CatalogMod> grid,
  List<CatalogMod>? allMods,
  bool aiEnabled = true,
}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final manager = _RecordingDownloadManager();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        downloadManager.overrideWith(() => manager),
        appSettings.overrideWith(
          () => _FakeSettings(Settings(enableAiFeatures: aiEnabled)),
        ),
        catalogModsProvider.overrideWithValue(allMods ?? grid),
        catalogLinksProvider.overrideWithValue(CatalogLinks(const [])),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [TriOSThemeExtension()]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCatalogDetailsDialog(
                context,
                mod: grid.first,
                mods: grid,
                linkLoader: (_) {},
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
  return manager;
}

Finder _headerTitle(String name) =>
    find.descendant(of: find.byType(DetailsHeader), matching: find.text(name));

void main() {
  setUpAll(() {
    // The settings manager resolves its file on construction, so point it at a
    // throwaway folder rather than the user's real config.
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'trios_details_dialog_test',
    );
  });

  testWidgets("a Discord-only mod's dialog offers the card's main download", (
    tester,
  ) async {
    final llmMod = ForumLlmMod(
      name: 'Discord Mod',
      role: LlmModRole.main,
      downloads: [
        ForumLlmDownload(
          url: 'https://example.com/discord-mod.zip',
          label: 'Zip',
          kind: LlmDownloadKind.direct,
          confidence: LlmDownloadConfidence.high,
        ),
      ],
    );
    final mod = _mod(
      'Discord Mod',
      sources: const [ModSource.Discord],
      urls: const {ModUrlType.Discord: 'https://discord.com/channels/1/2'},
      llmMod: llmMod,
    );
    final cardPrimary = primaryCandidate(
      resolveDownloadCandidates(mod.entry, llmMod),
    );

    final manager = await _pumpDialog(tester, grid: [mod]);
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(cardPrimary, isNotNull);
    expect(manager.requested, [cardPrimary!.url]);
  });

  testWidgets('following a link, Back, and Next', (tester) async {
    final a = _mod('Mod A', authors: ['Alex'], categories: ['Ships']);
    final b = _mod('Mod B', authors: ['Bea'], categories: ['Weapons']);
    final c = _mod('Mod C', authors: ['Cy'], categories: ['Portraits']);
    // Not in the grid, but in the catalog, and similar to Mod A.
    final d = _mod('Mod D', authors: ['Dee'], categories: ['Ships']);

    await _pumpDialog(tester, grid: [a, b, c], allMods: [a, b, c, d]);
    expect(_headerTitle('Mod A'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    // Follow the Similar mods link.
    await tester.tap(find.text('Mod D'));
    await tester.pumpAndSettle();
    expect(_headerTitle('Mod D'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Back undoes it.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(_headerTitle('Mod A'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    // Next steps through the grid from Mod A and clears the Back history.
    await tester.tap(find.text('Mod D'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(_headerTitle('Mod B'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  group('with AI features', () {
    final mod = _mod(
      'AI Mod',
      aiParagraph: 'An AI-written paragraph.',
      extras: CatalogExtras(
        gallery: [
          CatalogGalleryPicture(
            url: 'https://example.com/shot.png',
            aiCaption: 'A ship in space.',
          ),
        ],
        aiUse: CatalogAiUse(usesAi: false),
      ),
    );

    Future<void> openFirstPicture(WidgetTester tester) async {
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
    }

    testWidgets('off, there is no AI summary or caption, but AI use stays', (
      tester,
    ) async {
      await _pumpDialog(tester, grid: [mod], aiEnabled: false);

      expect(find.text('An AI-written paragraph.'), findsNothing);
      expect(find.text('AI use:'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      // Only the Gallery tab is left, so there's no tab bar to click.
      expect(find.text('Gallery'), findsNothing);
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('AI description'), findsNothing);
    });

    testWidgets('on, the AI summary and caption show', (tester) async {
      await _pumpDialog(tester, grid: [mod]);

      expect(find.text('An AI-written paragraph.'), findsOneWidget);
      await openFirstPicture(tester);
      expect(find.text('AI description: A ship in space.'), findsOneWidget);
    });
  });

  testWidgets('the AI summary card shows next to the author summary', (
    tester,
  ) async {
    final mod = CatalogMod(
      entry: ModRepoEntry(id: 'both', name: 'Both'),
      title: 'Both',
      authors: 'Someone',
      summaryText: 'The author summary.',
      aiParagraph: 'The AI paragraph.',
    );

    await _pumpDialog(tester, grid: [mod]);

    expect(find.text('The author summary.'), findsOneWidget);
    expect(find.text('The AI paragraph.'), findsOneWidget);
  });

  testWidgets("the header shows the extras record's summary", (tester) async {
    final mod = gatherCatalogMod(
      mod: ModRepoEntry(
        id: 'summary-mod',
        name: 'Summary Mod',
        summary: 'The catalog summary.',
      ),
      extras: CatalogExtras(summary: "Starmodder's summary."),
    );

    await _pumpDialog(tester, grid: [mod]);

    expect(
      find.descendant(
        of: find.byType(DetailsHeader),
        matching: find.text("Starmodder's summary."),
      ),
      findsOneWidget,
    );
    expect(find.text('The catalog summary.'), findsNothing);
  });

  testWidgets('the Compatibility panel lists conflicts with author quotes', (
    tester,
  ) async {
    final mod = _mod(
      'Fast Rendering',
      extras: CatalogExtras(
        conflicts: [
          CatalogConflict(
            name: 'Particle Engine',
            quote: 'Particle Engine may rarely crash in very large battles.',
          ),
        ],
      ),
    );

    await _pumpDialog(tester, grid: [mod]);

    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Particle Engine'), findsOneWidget);
    expect(
      find.text('“Particle Engine may rarely crash in very large battles.”'),
      findsOneWidget,
    );
  });

  testWidgets('without extras, the extras-only parts are hidden', (
    tester,
  ) async {
    final mod = _mod(
      'Plain Mod',
      changelog: ForumLlmChangelog(entries: {'1.0': 'First release.'}),
    );

    await _pumpDialog(tester, grid: [mod]);

    expect(_headerTitle('Plain Mod'), findsOneWidget);
    expect(find.text('Other mods have the same name'), findsNothing);
    expect(find.text('Discord post'), findsNothing);

    // The changelog from the AI answer still shows, with no release history.
    expect(find.text('Updates'), findsNothing); // the only tab, so no bar
    expect(find.text('Release history'), findsNothing);
    expect(find.text('1.0'), findsOneWidget);
  });
}
