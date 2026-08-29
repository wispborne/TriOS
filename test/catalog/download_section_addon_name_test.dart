import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_header.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/themes/theme.dart';

CatalogMod _catalogMod(String title) => CatalogMod(
  entry: ModRepoEntry(name: title),
  title: title,
  authors: 'Someone',
);

DownloadGroup _group({
  required String name,
  required LlmModRole role,
  required bool isDialogMod,
}) => DownloadGroup(
  modName: name,
  rawModName: name,
  role: role,
  isDialogMod: isDialogMod,
  installsDependencies: false,
  candidates: const [
    DownloadCandidate(
      url: 'https://example.com/mod.zip',
      label: 'Download',
      kind: DownloadCandidateKind.forumDirect,
    ),
  ],
);

Future<void> _pumpHeader(WidgetTester tester, List<DownloadGroup> groups) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [TriOSThemeExtension()]),
          home: Scaffold(
            body: ForumPostHeader(
              data: _catalogMod('Oculian Armada'),
              showSummary: false,
              downloadGroups: groups,
              onDownload: (_, _) {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('an add-on row names the mod it downloads', (tester) async {
    await _pumpHeader(tester, [
      _group(
        name: 'Ocutek Pirates Addon',
        role: LlmModRole.addon,
        isDialogMod: true,
      ),
    ]);

    expect(find.text('add-on'), findsOneWidget);
    expect(find.text('Ocutek Pirates Addon'), findsOneWidget);
  });

  testWidgets('a plain mod row leaves the name to the dialog title', (
    tester,
  ) async {
    await _pumpHeader(tester, [
      _group(name: 'Oculian Armada', role: LlmModRole.main, isDialogMod: true),
    ]);

    expect(find.text('Oculian Armada'), findsOneWidget); // the title only
  });
}
