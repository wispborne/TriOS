import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/download_manager/download_manager.dart';

/// A download manager that records what it was asked to download instead of
/// touching the network.
class RecordingDownloadManager extends TriOSDownloadManager {
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

void main() {
  testWidgets('card button with two equal downloads starts the picked one', (
    tester,
  ) async {
    final manager = RecordingDownloadManager();
    final mod = ModRepoEntry(
      name: 'Ocutek Pirates Addon',
      urls: const {ModUrlType.Forum: 'https://example.com/forum/topic=1'},
    );
    final llmMod = ForumLlmMod(
      name: 'Ocutek Pirates Addon',
      role: LlmModRole.addon,
      downloads: [
        ForumLlmDownload(
          url: 'https://example.com/addon.rar',
          label: 'Rar',
          kind: LlmDownloadKind.direct,
          confidence: LlmDownloadConfidence.high,
        ),
        ForumLlmDownload(
          url: 'https://example.com/addon.zip',
          label: 'Zip',
          kind: LlmDownloadKind.direct,
          confidence: LlmDownloadConfidence.high,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [downloadManager.overrideWith(() => manager)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [TriOSThemeExtension()]),
          home: Scaffold(
            body: Center(
              child: CatalogDownloadButton(
                mod: mod,
                installedMod: null,
                versionCheckComparison: null,
                linkLoader: (_) {},
                llmMainMod: llmMod,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The button offers a choice, so clicking it opens the menu.
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();
    expect(find.text('Zip'), findsOneWidget);

    await tester.tap(find.text('Zip'));
    await tester.pumpAndSettle();

    expect(manager.requested, ['https://example.com/addon.zip']);
  });
}
