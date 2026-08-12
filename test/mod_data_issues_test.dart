import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/mod_data_issues.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';

ModVariant _makeVariant({
  required String modInfoVersion,
  VersionObject? versionCheckerVersion,
}) {
  return ModVariant(
    modInfo: ModInfo(
      id: 'test_mod',
      name: 'Test Mod',
      version: Version.parse(modInfoVersion),
    ),
    versionCheckerInfo: versionCheckerVersion == null
        ? null
        : VersionCheckerInfo(modVersion: versionCheckerVersion),
    modFolder: Directory('test_mod'),
    hasNonBrickedModInfo: true,
    gameCoreFolder: Directory('test_game_core'),
  );
}

void main() {
  group('checkModDataIssues version mismatch', () {
    test('flags 0.35 vs 0.3.5', () {
      final variant = _makeVariant(
        modInfoVersion: '0.35',
        versionCheckerVersion: VersionObject(0, 3, 5),
      );
      final issues = checkModDataIssues(variant);
      expect(issues, hasLength(1));
      expect(issues.single.type, ModDataIssueType.versionCheckerMismatch);
      expect(issues.single.summary, contains('0.3.5'));
      expect(issues.single.summary, contains('0.35'));
    });

    test('no issue when versions match exactly', () {
      final variant = _makeVariant(
        modInfoVersion: '1.2.3',
        versionCheckerVersion: VersionObject(1, 2, 3),
      );
      expect(checkModDataIssues(variant), isEmpty);
    });

    test('no issue when versions differ only in formatting', () {
      // mod_info.json has "v1.2.3"; parsing strips the letter, so the
      // versions compare equal.
      final variant = _makeVariant(
        modInfoVersion: 'v1.2.3',
        versionCheckerVersion: VersionObject(1, 2, 3),
      );
      expect(checkModDataIssues(variant), isEmpty);
    });

    test('no issue when one side just omits a trailing zero', () {
      final variant = _makeVariant(
        modInfoVersion: '1.2',
        versionCheckerVersion: VersionObject(1, 2, 0),
      );
      expect(checkModDataIssues(variant), isEmpty);
    });

    test('no issue when there is no Version Checker info', () {
      final variant = _makeVariant(modInfoVersion: '1.0.0');
      expect(checkModDataIssues(variant), isEmpty);
    });

    test('flags a plainly different version', () {
      final variant = _makeVariant(
        modInfoVersion: '1.0.0',
        versionCheckerVersion: VersionObject(1, 1, 0),
      );
      final issues = checkModDataIssues(variant);
      expect(issues, hasLength(1));
      expect(issues.single.type, ModDataIssueType.versionCheckerMismatch);
    });
  });
}
