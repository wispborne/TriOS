import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/services/_mod_variant_core.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('ModVariantCore', () {
    late ModVariantCore core;
    late Directory tempDir;
    late Directory gameCoreDir;

    setUp(() {
      core = ModVariantCore();
      // Create unique temporary directories for each test
      tempDir = Directory.systemTemp.createTempSync('mod_variant_test_');
      gameCoreDir = Directory.systemTemp.createTempSync('game_core_test_');
    });

    tearDown(() {
      // Clean up temporary directories after each test
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (gameCoreDir.existsSync()) {
        gameCoreDir.deleteSync(recursive: true);
      }
    });

    // Helper to create a test ModVariant
    ModVariant createTestModVariant({
      required Directory modFolder,
      required bool isModInfoEnabled,
      String modId = 'test_mod',
      String version = '1.0.0',
    }) {
      final modInfo = ModInfo(
        id: modId,
        name: 'Test Mod',
        version: Version.parse(version),
      );

      return ModVariant(
        modInfo: modInfo,
        versionCheckerInfo: null,
        modFolder: modFolder,
        hasNonBrickedModInfo: isModInfoEnabled,
        gameCoreFolder: gameCoreDir,
      );
    }

    group('brickModInfoFile', () {
      test('should rename mod_info.json to mod_info.json.disabled', () {
        // Arrange
        final modFolder = tempDir;
        final modInfoFile = modFolder.resolve(Constants.unbrickedModInfoFileName).toFile();
        modInfoFile.writeAsStringSync('{"id": "test_mod"}');
        final smolId = 'test_mod';

        // Act
        core.brickModInfoFile(modFolder, smolId);

        // Assert
        expect(modInfoFile.existsSync(), isFalse,
          reason: 'Original mod_info.json should no longer exist');

        final disabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        expect(disabledFile.existsSync(), isTrue,
          reason: 'mod_info.json.disabled should exist');
        expect(disabledFile.readAsStringSync(), equals('{"id": "test_mod"}'),
          reason: 'Content should be preserved');
      });

      test('should throw exception when mod_info.json does not exist', () {
        // Arrange
        final modFolder = tempDir;
        final smolId = 'test_mod';

        // Act & Assert
        expect(
          () => core.brickModInfoFile(modFolder, smolId),
          throwsException,
          reason: 'Should throw when mod_info.json is missing',
        );
      });
    });

    group('unbrickModInfoFile', () {
      test('should rename mod_info.json.disabled to mod_info.json', () async {
        // Arrange
        final modFolder = tempDir;
        final disabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        disabledFile.writeAsStringSync('{"id": "test_mod", "version": "1.0.0"}');

        final modVariant = createTestModVariant(
          modFolder: modFolder,
          isModInfoEnabled: false,
        );

        // Act
        await core.unbrickModInfoFile(modVariant);

        // Assert
        expect(disabledFile.existsSync(), isFalse,
          reason: 'mod_info.json.disabled should no longer exist');

        final enabledFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        expect(enabledFile.existsSync(), isTrue,
          reason: 'mod_info.json should exist');
        expect(enabledFile.readAsStringSync(), equals('{"id": "test_mod", "version": "1.0.0"}'),
          reason: 'Content should be preserved');
      });

      test('should handle already enabled mod gracefully', () async {
        // Arrange
        final modFolder = tempDir;
        final enabledFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        enabledFile.writeAsStringSync('{"id": "test_mod"}');

        final modVariant = createTestModVariant(
          modFolder: modFolder,
          isModInfoEnabled: true,
        );

        // Act
        await core.unbrickModInfoFile(modVariant);

        // Assert
        expect(enabledFile.existsSync(), isTrue,
          reason: 'mod_info.json should still exist');
        expect(enabledFile.readAsStringSync(), equals('{"id": "test_mod"}'),
          reason: 'Content should be unchanged');
      });

      test('should handle multiple disabled variants by enabling first writable one', () async {
        // Arrange
        final modFolder = tempDir;

        // Create multiple disabled files
        for (final disabledName in Constants.modInfoFileDisabledNames) {
          final file = modFolder.resolve(disabledName).toFile();
          file.writeAsStringSync('{"id": "test_mod", "name": "$disabledName"}');
        }

        final modVariant = createTestModVariant(
          modFolder: modFolder,
          isModInfoEnabled: false,
        );

        // Act
        await core.unbrickModInfoFile(modVariant);

        // Assert
        final enabledFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        expect(enabledFile.existsSync(), isTrue,
          reason: 'mod_info.json should be created');

        // Should have enabled the first disabled file
        final firstDisabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        expect(firstDisabledFile.existsSync(), isFalse,
          reason: 'First disabled file should be renamed');
      });
    });

    group('isModInfoBricked', () {
      test('should return true when mod_info is disabled', () {
        // Arrange
        final modVariant = createTestModVariant(
          modFolder: tempDir,
          isModInfoEnabled: false,
        );

        // Act
        final result = core.isModInfoBricked(modVariant);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when mod_info is enabled', () {
        // Arrange
        final modVariant = createTestModVariant(
          modFolder: tempDir,
          isModInfoEnabled: true,
        );

        // Act
        final result = core.isModInfoBricked(modVariant);

        // Assert
        expect(result, isFalse);
      });
    });

    group('integration tests', () {
      test('should brick and unbrick mod successfully', () async {
        // Arrange
        final modFolder = tempDir;
        final modInfoFile = modFolder.resolve(Constants.unbrickedModInfoFileName).toFile();
        modInfoFile.writeAsStringSync('{"id": "test_mod", "version": "1.0.0"}');
        final smolId = 'test_mod';

        // Act 1: Brick the mod
        core.brickModInfoFile(modFolder, smolId);

        // Assert 1: Mod should be bricked
        expect(modInfoFile.existsSync(), isFalse);
        final disabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        expect(disabledFile.existsSync(), isTrue);

        // Act 2: Unbrick the mod
        final modVariant = ModVariant(
          smolId: smolId,
          modFolder: modFolder,
          isModInfoEnabled: false,
        );
        await core.unbrickModInfoFile(modVariant);

        // Assert 2: Mod should be unbricked
        expect(disabledFile.existsSync(), isFalse);
        final enabledFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        expect(enabledFile.existsSync(), isTrue);
        expect(enabledFile.readAsStringSync(), equals('{"id": "test_mod", "version": "1.0.0"}'));
      });
    });
  });
}
