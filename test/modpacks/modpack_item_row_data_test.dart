import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';

Mod _mod(
  String id, {
  String? name,
  String? author,
  required String version,
  List<Dependency> dependencies = const [],
}) => Mod(
  id: id,
  isEnabledInGame: true,
  modVariants: [
    ModVariant(
      modInfo: ModInfo(
        id: id,
        name: name,
        author: author,
        version: Version.parse(version),
        dependencies: dependencies,
      ),
      versionCheckerInfo: null,
      modFolder: Directory('mods/$id'),
      hasNonBrickedModInfo: true,
      gameCoreFolder: Directory('core'),
    ),
  ],
);

ModpackItem _item(String id, {String? name, String? version}) => ModpackItem(
  modId: id,
  name: name,
  version: version,
  url: 'https://example.com/$id.version',
  sourceType: ModpackItemSourceType.versionFile,
);

ModpackDefinition _definition(List<ModpackItem> items) => ModpackDefinition(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: 'Test pack',
  version: 1,
  items: items,
);

void main() {
  test('item versions are parsed once and kept out of serialized fields', () {
    final item = _item('alpha', version: ' 1.2.3 ');
    final draft = ModpackDraftItem(version: '1.2.3');

    expect(item.parsedVersion, isNotNull);
    expect(item.parsedVersion, same(item.parsedVersion));
    expect(draft.parsedVersion, isNotNull);
    expect(draft.parsedVersion, same(draft.parsedVersion));
    expect(item.toMap(), isNot(contains('parsedVersion')));
    expect(draft.toMap(), isNot(contains('parsedVersion')));
  });

  test(
    'rows retain pack order and combine installed and recorded versions',
    () {
      final definition = _definition([
        _item('alpha', name: 'Recorded Alpha', version: '1.0.0'),
        _item('beta', version: '3.0.0'),
      ]);
      final rows = buildModpackItemRows(definition, [
        _mod('alpha', name: 'Local Alpha', author: 'Alice', version: '2.0.0'),
      ]);

      expect(rows.map((row) => row.key), ['alpha', 'beta']);
      expect(rows.first.packOrder, 0);
      expect(rows.first.displayName, 'Recorded Alpha');
      expect(rows.first.author, 'Alice');
      expect(rows.first.isInstalled, isTrue);
      expect(rows.first.combinedVersion, '2.0.0 (modpack: 1.0.0)');
      expect(rows.last.isInstalled, isFalse);
      expect(rows.last.combinedVersion, '3.0.0');
    },
  );

  test('a matching installed and recorded version is shown once', () {
    final rows = buildModpackItemRows(
      _definition([_item('alpha', version: '1.0.0')]),
      [_mod('alpha', version: '1.0.0')],
    );

    expect(rows.single.combinedVersion, '1.0.0');
  });

  test('required dependencies absent from the pack become warnings', () {
    final rows = buildModpackItemRows(
      _definition([_item('alpha'), _item('included')]),
      [
        _mod(
          'alpha',
          version: '1.0.0',
          dependencies: [
            Dependency(id: 'included', name: 'Included'),
            Dependency(id: 'missing', name: 'Missing Library'),
          ],
        ),
      ],
    );

    expect(rows.first.dependencyWarnings, hasLength(1));
    expect(
      rows.first.dependencyWarningText,
      'Requires Missing Library, which is not in this modpack.',
    );
    expect(rows.last.dependencyWarnings, isEmpty);
  });
}
