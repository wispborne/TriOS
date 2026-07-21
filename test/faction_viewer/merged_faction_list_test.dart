import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';

/// Stands in for the real scanner so tests can hand it a fixed set of files.
class _FakeFactionListNotifier extends FactionListNotifier {
  _FakeFactionListNotifier(this.files);

  final List<FactionFileData> files;

  @override
  Stream<List<FactionFileData>> build() => Stream.value(files);
}

ModVariant _variant(String modId) => ModVariant(
  modInfo: ModInfo(id: modId, name: modId, version: Version.parse('1.0.0')),
  versionCheckerInfo: null,
  modFolder: Directory('mods/$modId'),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

Mod _mod(ModVariant variant, {required bool enabled}) => Mod(
  id: variant.modInfo.id,
  isEnabledInGame: enabled,
  modVariants: [variant],
);

FactionFileData _vanillaFile(
  String mergeKey,
  Map<String, dynamic> json, {
  bool registers = true,
}) => FactionFileData(
  mergeKey: mergeKey,
  sourceName: 'Vanilla',
  sourceSmolId: null,
  registersFaction: registers,
  json: json,
);

FactionFileData _modFile(
  ModVariant variant,
  String mergeKey,
  Map<String, dynamic> json, {
  bool registers = false,
}) => FactionFileData(
  mergeKey: mergeKey,
  sourceName: variant.modInfo.id,
  sourceSmolId: variant.smolId,
  registersFaction: registers,
  json: json,
);

/// Builds a container whose faction files and mod list are fixed, then reads
/// the merged factions for both settings of the toggle.
Future<({List<Faction> all, List<Faction> enabledOnly})> _merge({
  required List<FactionFileData> files,
  required List<Mod> mods,
}) async {
  final container = ProviderContainer(
    overrides: [
      factionListNotifierProvider.overrideWith(
        () => _FakeFactionListNotifier(files),
      ),
      AppState.mods.overrideWithValue(mods),
    ],
  );
  addTearDown(container.dispose);

  await container.read(factionListNotifierProvider.future);
  return (
    all: container.read(mergedFactionListProvider(false)),
    enabledOnly: container.read(mergedFactionListProvider(true)),
  );
}

Faction? _byKey(List<Faction> factions, String key) =>
    factions.where((f) => f.mergeKey == key).firstOrNull;

void main() {
  group('mergedFactionListProvider', () {
    test('a faction only a disabled mod adds is dropped', () async {
      final variant = _variant('newfaction_mod');
      final result = await _merge(
        files: [
          _vanillaFile('hegemony', {'displayName': 'Hegemony'}),
          _modFile(variant, 'newbies', {
            'displayName': 'Newbies',
          }, registers: true),
        ],
        mods: [_mod(variant, enabled: false)],
      );

      expect(_byKey(result.all, 'newbies')?.displayName, 'Newbies');
      expect(_byKey(result.enabledOnly, 'newbies'), isNull);
      // Vanilla is never dropped.
      expect(_byKey(result.enabledOnly, 'hegemony'), isNotNull);
    });

    test('a faction an enabled mod adds is kept', () async {
      final variant = _variant('newfaction_mod');
      final result = await _merge(
        files: [
          _modFile(variant, 'newbies', {
            'displayName': 'Newbies',
          }, registers: true),
        ],
        mods: [_mod(variant, enabled: true)],
      );

      expect(_byKey(result.enabledOnly, 'newbies')?.displayName, 'Newbies');
    });

    test('a disabled mod patching vanilla leaves no trace', () async {
      final variant = _variant('patcher');
      final result = await _merge(
        files: [
          _vanillaFile('hegemony', {
            'displayName': 'Hegemony',
            'factionDoctrine': {'aggression': 3},
            'knownShips': {
              'hulls': ['onslaught'],
            },
          }),
          _modFile(variant, 'hegemony', {
            'factionDoctrine': {'aggression': 5},
            'knownShips': {
              'hulls': ['modded_ship'],
            },
          }),
        ],
        mods: [_mod(variant, enabled: false)],
      );

      // With the toggle off, the patch applies as it always has.
      final patched = _byKey(result.all, 'hegemony')!;
      expect(patched.doctrine?.aggression, 5);
      expect(patched.knownShipIds, ['onslaught', 'modded_ship']);
      expect(patched.sources.length, 2);

      // With it on, the faction is pure vanilla again — including the scalar
      // the mod had overwritten.
      final clean = _byKey(result.enabledOnly, 'hegemony')!;
      expect(clean.doctrine?.aggression, 3);
      expect(clean.knownShipIds, ['onslaught']);
      expect(clean.sources.length, 1);
      expect(clean.isVanilla, isTrue);
    });

    test('an enabled mod patching vanilla still applies', () async {
      final variant = _variant('patcher');
      final result = await _merge(
        files: [
          _vanillaFile('hegemony', {
            'displayName': 'Hegemony',
            'factionDoctrine': {'aggression': 3},
          }),
          _modFile(variant, 'hegemony', {
            'factionDoctrine': {'aggression': 5},
          }),
        ],
        mods: [_mod(variant, enabled: true)],
      );

      expect(_byKey(result.enabledOnly, 'hegemony')?.doctrine?.aggression, 5);
    });

    test('a file nobody registers is kept, since its owner is unknown',
        () async {
      final variant = _variant('orphan_mod');
      final result = await _merge(
        files: [
          _modFile(variant, 'mystery', {'displayName': 'Mystery'}),
        ],
        mods: [_mod(variant, enabled: true)],
      );

      // No factions.csv claims it, so we can't tell who added it. Keeping it
      // matches how the page behaved before the toggle existed.
      expect(_byKey(result.all, 'mystery'), isNotNull);
      expect(_byKey(result.enabledOnly, 'mystery'), isNotNull);
    });

    test('a disabled mod is the only source, so nothing is left to show',
        () async {
      final variant = _variant('orphan_mod');
      final result = await _merge(
        files: [
          _modFile(variant, 'mystery', {'displayName': 'Mystery'}),
        ],
        mods: [_mod(variant, enabled: false)],
      );

      expect(_byKey(result.all, 'mystery'), isNotNull);
      expect(_byKey(result.enabledOnly, 'mystery'), isNull);
    });

    test('mods later in load order win, and vanilla is merged first', () async {
      final first = _variant('aaa_mod');
      final second = _variant('zzz_mod');
      final result = await _merge(
        files: [
          _modFile(second, 'hegemony', {'displayName': 'Second'}),
          _vanillaFile('hegemony', {'displayName': 'Vanilla'}),
          _modFile(first, 'hegemony', {'displayName': 'First'}),
        ],
        mods: [_mod(first, enabled: true), _mod(second, enabled: true)],
      );

      final faction = _byKey(result.all, 'hegemony')!;
      expect(faction.displayName, 'Second');
      expect(
        faction.sources.map((s) => s.name),
        ['Vanilla', 'aaa_mod', 'zzz_mod'],
      );
    });
  });
}
