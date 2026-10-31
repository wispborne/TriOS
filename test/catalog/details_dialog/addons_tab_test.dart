import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/details_dialog/addons_tab.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/themes/theme.dart';

DownloadGroup _group({
  required String? name,
  required LlmModRole role,
  bool isDialogMod = false,
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

Future<void> _pumpTab(WidgetTester tester, List<DownloadGroup> groups) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(extensions: const [TriOSThemeExtension()]),
          home: Scaffold(
            body: AddonsTab(
              rows: threadModRows(groups),
              dialogModName: 'Oculian Armada',
              onDownload: (_, _) {},
            ),
          ),
        ),
      ),
    );

void main() {
  test("the dialog's own row and the unnamed post row are left out", () {
    final rows = threadModRows([
      _group(name: 'Oculian Armada', role: LlmModRole.main, isDialogMod: true),
      _group(name: null, role: LlmModRole.unknown),
      _group(name: 'Ocutek Pirates Addon', role: LlmModRole.addon),
    ]);

    expect([for (final r in rows) r.modName], ['Ocutek Pirates Addon']);
  });

  testWidgets('an add-on row names the mod it downloads', (tester) async {
    await _pumpTab(tester, [
      _group(name: 'Ocutek Pirates Addon', role: LlmModRole.addon),
    ]);

    expect(find.text('Add-ons in the same thread'), findsOneWidget);
    expect(find.text('add-on'), findsOneWidget);
    expect(find.text('Ocutek Pirates Addon'), findsOneWidget);
  });

  testWidgets('a row with the same name is another version of the mod', (
    tester,
  ) async {
    await _pumpTab(tester, [
      _group(name: 'Oculian Armada (0.97a)', role: LlmModRole.main),
    ]);

    expect(find.text('Other versions of this mod'), findsOneWidget);
    expect(find.text('Add-ons in the same thread'), findsNothing);
  });
}
