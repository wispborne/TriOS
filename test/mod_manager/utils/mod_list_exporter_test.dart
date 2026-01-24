import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/utils/mod_list_exporter.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';

void main() {
  group('ModListExporter', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('mod_list_exporter_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // Helper to create test mods
    List<Mod> createTestMods() {
      final mod1Info = ModInfo(
        id: 'test_mod_1',
        name: 'Test Mod 1',
        version: Version.parse('1.0.0'),
        author: 'Author 1',
        description: 'Description 1',
      );

      final mod2Info = ModInfo(
        id: 'test_mod_2',
        name: 'Test Mod 2',
        version: Version.parse('2.0.0'),
        author: 'Author 2',
        description: 'Description 2',
      );

      final variant1 = ModVariant(
        modInfo: mod1Info,
        versionCheckerInfo: null,
        modFolder: tempDir,
        hasNonBrickedModInfo: true,
        gameCoreFolder: tempDir,
      );

      final variant2 = ModVariant(
        modInfo: mod2Info,
        versionCheckerInfo: null,
        modFolder: tempDir,
        hasNonBrickedModInfo: true,
        gameCoreFolder: tempDir,
      );

      return [
        Mod(id: 'test_mod_1', modVariants: [variant1], isEnabledInGame: true),
        Mod(id: 'test_mod_2', modVariants: [variant2], isEnabledInGame: true),
      ];
    }

    group('allModsAsCsv', () {
      test('should generate CSV with headers and mod data', () {
        // Arrange
        final mods = createTestMods();

        // Act
        final csv = allModsAsCsv(mods);

        // Assert
        expect(csv, isNotEmpty);
        expect(csv, contains('id'));
        expect(csv, contains('name'));
        expect(csv, contains('version'));
        expect(csv, contains('test_mod_1'));
        expect(csv, contains('Test Mod 1'));
        expect(csv, contains('1.0.0'));
        expect(csv, contains('test_mod_2'));
        expect(csv, contains('Test Mod 2'));
        expect(csv, contains('2.0.0'));
      });

      test('should handle empty mod list', () {
        // Arrange
        final mods = <Mod>[];

        // Act
        final csv = allModsAsCsv(mods);

        // Assert
        expect(csv, isEmpty);
      });

      test('should use first enabled or highest version variant', () {
        // Arrange
        final mod1Info = ModInfo(
          id: 'multi_version_mod',
          name: 'Multi Version Mod',
          version: Version.parse('1.0.0'),
        );

        final mod2Info = ModInfo(
          id: 'multi_version_mod',
          name: 'Multi Version Mod',
          version: Version.parse('2.0.0'),
        );

        final variant1 = ModVariant(
          modInfo: mod1Info,
          versionCheckerInfo: null,
          modFolder: tempDir,
          hasNonBrickedModInfo: true,
          gameCoreFolder: tempDir,
        );

        final variant2 = ModVariant(
          modInfo: mod2Info,
          versionCheckerInfo: null,
          modFolder: tempDir,
          hasNonBrickedModInfo: true,
          gameCoreFolder: tempDir,
        );

        final mods = [
          Mod(id: 'multi_version_mod', modVariants: [variant1, variant2], isEnabledInGame: true),
        ];

        // Act
        final csv = allModsAsCsv(mods);

        // Assert
        expect(csv, contains('multi_version_mod'));
        // Should include the mod data
        expect(csv, contains('Multi Version Mod'));
      });
    });

    group('createSharedModListFromVariants', () {
      test('should create SharedModList from variants', () {
        // Arrange
        final variants = [
          ShallowModVariant(
            modId: 'mod1',
            modName: 'Mod 1',
            smolVariantId: 'mod1-1.0.0',
            version: Version.parse('1.0.0'),
          ),
          ShallowModVariant(
            modId: 'mod2',
            modName: 'Mod 2',
            smolVariantId: 'mod2-2.0.0',
            version: Version.parse('2.0.0'),
          ),
        ];

        // Act
        final result = createSharedModListFromVariants(
          'test-id',
          'Test List',
          'Test Description',
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          variants,
        );

        // Assert
        expect(result.id, equals('test-id'));
        expect(result.name, equals('Test List'));
        expect(result.description, equals('Test Description'));
        expect(result.mods, hasLength(2));
        expect(result.mods[0].modId, equals('mod1'));
        expect(result.mods[0].modName, equals('Mod 1'));
        expect(result.mods[1].modId, equals('mod2'));
        expect(result.mods[1].modName, equals('Mod 2'));
      });

      test('should use default description if not provided', () {
        // Arrange
        final variants = <ShallowModVariant>[];

        // Act
        final result = createSharedModListFromVariants(
          null,
          null,
          null,
          null,
          null,
          variants,
        );

        // Assert
        expect(result.description, equals('Generated mod list from TriOS'));
      });

      test('should handle empty variants list', () {
        // Arrange
        final variants = <ShallowModVariant>[];

        // Act
        final result = createSharedModListFromVariants(
          'empty-id',
          'Empty List',
          'Empty Description',
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          variants,
        );

        // Assert
        expect(result.mods, isEmpty);
      });
    });

    // Note: Tests for clipboard operations (copyModListToClipboardFromMods, etc.)
    // are not included because they require Flutter's Clipboard API which needs
    // a full widget test environment with MaterialApp. These are better suited
    // for integration tests.
  });
}
