import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_page_controller.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/mod_metadata.dart';

/// The Catalog leaves muted mods out of its "Has Update" filter and out of the
/// count on that filter's badge. Both go through
/// [hasUpdateToShowInCatalog], so that's what these check.

const _modId = 'nexerelin';

VersionCheckerInfo _versionInfo(String version) {
  final parts = version.split('.');
  return VersionCheckerInfo(
    masterVersionFile: 'https://example.com/version.json',
    modVersion: VersionObject(parts[0], parts[1], parts[2]),
  );
}

Mod _mod(String localVersion) {
  final variant = ModVariant(
    modInfo: ModInfo(
      id: _modId,
      name: 'Nexerelin',
      version: Version.parse(localVersion),
    ),
    versionCheckerInfo: _versionInfo(localVersion),
    modFolder: Directory('mods/$_modId'),
    hasNonBrickedModInfo: true,
    gameCoreFolder: Directory('core'),
  );
  return Mod(id: _modId, isEnabledInGame: true, modVariants: [variant]);
}

/// A finished version check saying the mod's newest release is [remoteVersion].
VersionCheckerState _remoteSays(Mod mod, String remoteVersion) =>
    VersionCheckerState({
      mod.modVariants.first.smolId: RemoteVersionCheckResult(
        mod.modVariants.first.versionCheckerInfo,
        _versionInfo(remoteVersion),
        'https://example.com/version.json',
        timestamp: DateTime(2026, 1, 1),
      ),
    });

ModsMetadata _metadata({bool muteMod = false, String? mutedVersion}) =>
    ModsMetadata(
      baseMetadata: const {},
      userMetadata: {
        _modId: ModMetadata(
          firstSeen: 0,
          areUpdatesMuted: muteMod,
          mutedUpdateVersion: mutedVersion,
        ),
      },
    );

void main() {
  group('hasUpdateToShowInCatalog', () {
    final mod = _mod('1.5.0');
    final remoteHasNewer = _remoteSays(mod, '1.6.0');

    test('an unmuted update shows', () {
      expect(hasUpdateToShowInCatalog(mod, remoteHasNewer, null), isTrue);
      expect(
        hasUpdateToShowInCatalog(mod, remoteHasNewer, _metadata()),
        isTrue,
      );
    });

    test('no update means nothing to show', () {
      expect(
        hasUpdateToShowInCatalog(mod, _remoteSays(mod, '1.5.0'), null),
        isFalse,
      );
    });

    test('a mod muted outright shows no update', () {
      expect(
        hasUpdateToShowInCatalog(
          mod,
          remoteHasNewer,
          _metadata(muteMod: true),
        ),
        isFalse,
      );
    });

    test('muting this version shows no update', () {
      expect(
        hasUpdateToShowInCatalog(
          mod,
          remoteHasNewer,
          _metadata(mutedVersion: '1.6.0'),
        ),
        isFalse,
      );
    });

    test('muting an older version still shows the newer update', () {
      expect(
        hasUpdateToShowInCatalog(
          mod,
          remoteHasNewer,
          _metadata(mutedVersion: '1.5.5'),
        ),
        isTrue,
      );
    });

    test('a mute on another mod leaves this one alone', () {
      final otherMuted = ModsMetadata(
        baseMetadata: const {},
        userMetadata: {
          'lw_lazylib': ModMetadata(firstSeen: 0, areUpdatesMuted: true),
        },
      );
      expect(hasUpdateToShowInCatalog(mod, remoteHasNewer, otherMuted), isTrue);
    });
  });
}
