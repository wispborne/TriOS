import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version_checker_info.dart';

/// Tests the update decision: given a local `.version` and a fetched remote
/// `.version`, does the app correctly say "update" / "no update"?
///
/// The comparison is `< 0` -> remote is newer -> has update.
/// Both sides are `.version` files, never `mod_info.json`.
void main() {
  VersionCheckerInfo infoWithVersion(VersionObject version) => VersionCheckerInfo(
        masterVersionFile: 'https://example.com/version.json',
        modVersion: version,
      );

  RemoteVersionCheckResult remoteWithVersion(VersionObject version) =>
      RemoteVersionCheckResult(
        null,
        infoWithVersion(version),
        'https://example.com/version.json',
        timestamp: DateTime(2026, 1, 1),
      );

  int? compare(VersionObject local, VersionObject remote) =>
      VersionCheckComparison.compareLocalAndRemoteVersions(
        infoWithVersion(local),
        remoteWithVersion(remote),
      );

  group('compareLocalAndRemoteVersions', () {
    // Regression: preview05 parsed local "1.1.3d" as "1.1.3" while the cached
    // remote stayed "1.1.3d", so identical versions compared as different and
    // showed a fake update. Same version in, no update out.
    test('same version with a letter suffix reports no update', () {
      expect(compare(VersionObject(1, 1, '3d'), VersionObject(1, 1, '3d')), 0);
    });

    test('same plain numeric version reports no update', () {
      expect(compare(VersionObject(1, 2, '0'), VersionObject(1, 2, '0')), 0);
    });

    test('newer remote reports an update (negative)', () {
      expect(
        compare(VersionObject(1, 1, '3d'), VersionObject(1, 2, '0')),
        lessThan(0),
      );
    });

    test('newer local reports no update (positive, "time traveler")', () {
      expect(
        compare(VersionObject(1, 2, '0'), VersionObject(1, 1, '3d')),
        greaterThan(0),
      );
    });

    test('returns null when local is missing', () {
      expect(
        VersionCheckComparison.compareLocalAndRemoteVersions(
          null,
          remoteWithVersion(VersionObject(1, 0, '0')),
        ),
        isNull,
      );
    });

    test('returns null when remote is missing', () {
      expect(
        VersionCheckComparison.compareLocalAndRemoteVersions(
          infoWithVersion(VersionObject(1, 0, '0')),
          null,
        ),
        isNull,
      );
    });
  });
}
