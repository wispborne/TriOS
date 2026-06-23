// Unit tests for deep-link dependency minimum-version satisfaction.
//
// `isDependencySatisfied` is pure (takes the mods list directly), so these run
// without a live game install — fixtures are constructed in memory.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';

/// Builds an installed [Mod] with a single variant at [version]. When
/// [masterVersionFile] is given, the variant carries a Version Checker URL so it
/// can be matched by `.version` URL (no mod id needed).
Mod buildMod({
  required String id,
  required String version,
  String? masterVersionFile,
}) {
  final modInfo = ModInfo(id: id, name: id, version: Version.parse(version));
  final variant = ModVariant(
    modInfo: modInfo,
    versionCheckerInfo: masterVersionFile == null
        ? null
        : VersionCheckerInfo(masterVersionFile: masterVersionFile),
    modFolder: Directory('test_mod_$id'),
    hasNonBrickedModInfo: true,
    gameCoreFolder: Directory('test_game_core'),
  );
  return Mod(id: id, isEnabledInGame: true, modVariants: [variant]);
}

/// Builds a dependency entry. Source is auto-detected from the URL extension,
/// matching the real parser.
DeepLinkModEntry depEntry({
  required String url,
  String? id,
  String? version,
}) {
  return DeepLinkModEntry(
    url: Uri.parse(url),
    source: url.toLowerCase().endsWith('.version')
        ? DeepLinkModSource.versionFile
        : DeepLinkModSource.directDownload,
    modId: id,
    modVersion: version,
  );
}

void main() {
  group('isDependencySatisfied — minimum version', () {
    const depUrl = 'https://example.com/Lib.version';
    const depId = 'lib_mod';

    test('installed version above the minimum ⇒ satisfied', () {
      final mods = [buildMod(id: depId, version: '1.2.0')];
      final entry = depEntry(url: depUrl, id: depId, version: '1.0.0');
      expect(isDependencySatisfied(mods, entry), isTrue);
    });

    test('installed version equal to the minimum ⇒ satisfied (>=)', () {
      final mods = [buildMod(id: depId, version: '1.0.0')];
      final entry = depEntry(url: depUrl, id: depId, version: '1.0.0');
      expect(isDependencySatisfied(mods, entry), isTrue);
    });

    test('installed version below the minimum ⇒ not satisfied', () {
      final mods = [buildMod(id: depId, version: '0.9.0')];
      final entry = depEntry(url: depUrl, id: depId, version: '1.0.0');
      expect(isDependencySatisfied(mods, entry), isFalse);
    });

    test('not installed at all ⇒ not satisfied', () {
      final mods = [buildMod(id: 'something_else', version: '5.0.0')];
      final entry = depEntry(url: depUrl, id: depId, version: '1.0.0');
      expect(isDependencySatisfied(mods, entry), isFalse);
    });
  });

  group('isDependencySatisfied — no version (install only if missing)', () {
    const depUrl = 'https://example.com/Lib.version';
    const depId = 'lib_mod';

    test('installed at any version ⇒ satisfied', () {
      final mods = [buildMod(id: depId, version: '0.0.1')];
      final entry = depEntry(url: depUrl, id: depId);
      expect(isDependencySatisfied(mods, entry), isTrue);
    });

    test('not installed ⇒ not satisfied', () {
      final mods = <Mod>[];
      final entry = depEntry(url: depUrl, id: depId);
      expect(isDependencySatisfied(mods, entry), isFalse);
    });
  });

  group('isDependencySatisfied — matching without a mod id', () {
    const depUrl = 'https://example.com/Lib.version';

    test('matches by .version URL when no id is supplied', () {
      final mods = [
        buildMod(id: 'lib_mod', version: '2.0.0', masterVersionFile: depUrl),
      ];
      final entry = depEntry(url: depUrl, version: '1.5.0');
      expect(isDependencySatisfied(mods, entry), isTrue);
    });

    test('no id and no URL match ⇒ not satisfied', () {
      final mods = [buildMod(id: 'lib_mod', version: '2.0.0')];
      final entry = depEntry(url: depUrl, version: '1.5.0');
      expect(isDependencySatisfied(mods, entry), isFalse);
    });
  });
}
