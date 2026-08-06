import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/mods_grid_page_controller.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';

Mod _mod(
  String id, {
  required String name,
  String? author,
  List<Dependency> dependencies = const [],
}) {
  final variant = ModVariant(
    modInfo: ModInfo(
      id: id,
      name: name,
      author: author,
      version: Version.parse('1.0.0'),
      dependencies: dependencies,
    ),
    versionCheckerInfo: null,
    modFolder: Directory('mods/$id'),
    hasNonBrickedModInfo: true,
    gameCoreFolder: Directory('core'),
  );
  return Mod(id: id, isEnabledInGame: true, modVariants: [variant]);
}

/// The mods every test searches over: two that need LazyLib, one that doesn't.
final _nexerelin = _mod(
  'nexerelin',
  name: 'Nexerelin',
  author: 'Histidine',
  dependencies: [
    Dependency(id: 'lw_lazylib', name: 'LazyLib'),
    Dependency(id: 'MagicLib', name: 'MagicLib'),
  ],
);
final _diableAvionics = _mod(
  'diableavionics',
  name: 'Diable Avionics',
  author: 'Tartiflette',
  dependencies: [Dependency(id: 'lw_lazylib', name: 'LazyLib')],
);
final _lazyLib = _mod('lw_lazylib', name: 'LazyLib', author: 'LazyWizard');

List<String> _search(String query, {List<Mod>? mods}) {
  final container = ProviderContainer(
    overrides: [
      AppState.mods.overrideWithValue(
        mods ?? [_nexerelin, _diableAvionics, _lazyLib],
      ),
    ],
  );
  addTearDown(container.dispose);

  final controller = container.read(modsGridSearchControllerProvider.notifier);
  controller.updateSearchQuery(query);
  return container
      .read(modsGridSearchControllerProvider)
      .filteredMods
      .map((m) => m.id)
      .toList();
}

void main() {
  group('searching mods by what they depend on', () {
    test('an empty search shows everything', () {
      expect(_search(''), ['nexerelin', 'diableavionics', 'lw_lazylib']);
    });

    test('typing a dependency name finds the mods that need it', () {
      final results = _search('lazylib');

      expect(results, containsAll(['nexerelin', 'diableavionics']));
    });

    test('typing a dependency id finds the mods that need it', () {
      expect(_search('lw_lazylib'), containsAll(['nexerelin', 'diableavionics']));
    });

    test('a dependency only one mod has narrows to that mod', () {
      expect(_search('magiclib'), ['nexerelin']);
    });

    test('a dependency nobody has finds nothing', () {
      expect(_search('graphicslib'), isEmpty);
    });

    test('searching by name still works', () {
      expect(_search('diable'), ['diableavionics']);
    });

    test('searching by author still works', () {
      expect(_search('tartiflette'), ['diableavionics']);
    });
  });

  group('the dependency: search field', () {
    test('matches on the dependency name', () {
      expect(
        _search('dependency:lazylib'),
        containsAll(['nexerelin', 'diableavionics']),
      );
    });

    test('matches on the dependency id', () {
      expect(
        _search('dependency:lw_lazylib'),
        containsAll(['nexerelin', 'diableavionics']),
      );
    });

    test('matches on part of a dependency name', () {
      expect(_search('dependency:magic'), ['nexerelin']);
    });

    test('ignores case', () {
      expect(_search('dependency:LAZYLIB'), containsAll(['nexerelin']));
    });

    test('a mod with no dependencies never matches', () {
      expect(_search('dependency:lazylib'), isNot(contains('lw_lazylib')));
    });

    test('an unknown dependency matches nothing', () {
      expect(_search('dependency:nothing_needs_this'), isEmpty);
    });

    test('a mod that depends on nothing is not matched by an empty value', () {
      expect(_search('dependency:'), isEmpty);
    });
  });
}
