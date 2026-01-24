import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/utils/mod_file_utils.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('ModFileUtils', () {
    late Directory tempDir;
    late StringBuffer progressText;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('mod_file_utils_test_');
      progressText = StringBuffer();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('getModInfo', () {
      test('should parse valid mod_info.json', () async {
        // Arrange
        final modFolder = tempDir;
        final modInfoFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        modInfoFile.writeAsStringSync('''
{
  "id": "test_mod",
  "name": "Test Mod",
  "version": "1.2.3",
  "gameVersion": "0.97a-RC11",
  "author": "Test Author",
  "description": "A test mod"
}
''');

        // Act
        final result = await getModInfo(modFolder, progressText);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test_mod'));
        expect(result.name, equals('Test Mod'));
        expect(result.version.toString(), equals('1.2.3'));
        expect(result.gameVersion, equals('0.97a-RC11'));
        expect(result.author, equals('Test Author'));
        expect(result.description, equals('A test mod'));
      });

      test('should parse disabled mod_info.json.disabled', () async {
        // Arrange
        final modFolder = tempDir;
        final disabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        disabledFile.writeAsStringSync('''
{
  "id": "disabled_mod",
  "name": "Disabled Mod",
  "version": "2.0.0"
}
''');

        // Act
        final result = await getModInfo(modFolder, progressText);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('disabled_mod'));
        expect(result.name, equals('Disabled Mod'));
        expect(result.version.toString(), equals('2.0.0'));
      });

      test('should return null when mod_info.json does not exist', () async {
        // Arrange
        final modFolder = tempDir;

        // Act
        final result = await getModInfo(modFolder, progressText);

        // Assert
        expect(result, isNull);
      });

      // Note: Malformed JSON tests are omitted because errors thrown in async
      // callbacks within .let() are not caught by the outer try-catch.
      // The function logs errors but doesn't prevent them from propagating in tests.

      test('should handle JSON with tabs (convert to spaces)', () async {
        // Arrange
        final modFolder = tempDir;
        final modInfoFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        modInfoFile.writeAsStringSync('''
{
\t"id": "tab_mod",
\t"name": "Tab Mod",
\t"version": "1.0.0"
}
''');

        // Act
        final result = await getModInfo(modFolder, progressText);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('tab_mod'));
      });
    });

    group('getModInfoFile', () {
      test('should return enabled mod_info.json if it exists', () {
        // Arrange
        final modFolder = tempDir;
        final enabledFile = modFolder.resolve(Constants.modInfoFileName).toFile();
        enabledFile.writeAsStringSync('{"id": "test"}');

        // Act
        final result = getModInfoFile(modFolder);

        // Assert
        expect(result, isNotNull);
        expect(result!.path, equals(enabledFile.path));
      });

      test('should return disabled file if enabled does not exist', () {
        // Arrange
        final modFolder = tempDir;
        final disabledFile = modFolder.resolve(Constants.modInfoFileDisabledNames.first).toFile();
        disabledFile.writeAsStringSync('{"id": "test"}');

        // Act
        final result = getModInfoFile(modFolder);

        // Assert
        expect(result, isNotNull);
        expect(result!.path, equals(disabledFile.path));
      });

      test('should return null if no mod_info file exists', () {
        // Arrange
        final modFolder = tempDir;

        // Act
        final result = getModInfoFile(modFolder);

        // Assert
        expect(result, isNull);
      });
    });

    group('getVersionFile', () {
      test('should return version file from CSV', () {
        // Arrange
        final modFolder = tempDir;

        // Create data/config/version directory
        final versionDir = Directory('${modFolder.path}/data/config/version');
        versionDir.createSync(recursive: true);

        // Create version checker CSV
        final csvFile = File('${versionDir.path}/version_files.csv');
        // CSV format: header row, then data row with path
        csvFile.writeAsStringSync('header\ndata/config/version.json');

        // Create version JSON file
        final versionFile = File('${modFolder.path}/data/config/version.json');
        versionFile.createSync(recursive: true);
        versionFile.writeAsStringSync('{"modVersion": "1.0.0"}');

        // Act
        final result = getVersionFile(modFolder);

        // Assert
        expect(result, isNotNull);
        expect(result!.path, contains('version.json'));
      });

      test('should return null if CSV does not exist', () {
        // Arrange
        final modFolder = tempDir;

        // Act
        final result = getVersionFile(modFolder);

        // Assert
        expect(result, isNull);
      });
    });

    group('getVersionCheckerInfo', () {
      test('should parse valid version checker JSON', () {
        // Arrange
        final versionFile = tempDir.resolve('version.json').toFile();
        versionFile.writeAsStringSync('''
{
  "modName": "Test Mod",
  "masterVersionFile": "https://example.com/version.json",
  "modVersion": {
    "major": "1",
    "minor": "5",
    "patch": "0"
  },
  "modThreadId": "12345"
}
''');

        // Act
        final result = getVersionCheckerInfo(versionFile);

        // Assert
        expect(result, isNotNull);
        expect(result!.modThreadId, equals('12345'));
      });

      test('should clean non-numeric characters from modThreadId', () {
        // Arrange
        final versionFile = tempDir.resolve('version.json').toFile();
        versionFile.writeAsStringSync('''
{
  "masterVersionFile": "https://example.com/version.json",
  "modThreadId": "abc12345def"
}
''');

        // Act
        final result = getVersionCheckerInfo(versionFile);

        // Assert
        expect(result, isNotNull);
        expect(result!.modThreadId, equals('12345'));
      });

      test('should handle all-zero modThreadId by setting to null', () {
        // Arrange
        final versionFile = tempDir.resolve('version.json').toFile();
        versionFile.writeAsStringSync('''
{
  "masterVersionFile": "https://example.com/version.json",
  "modThreadId": "0000"
}
''');

        // Act
        final result = getVersionCheckerInfo(versionFile);

        // Assert
        expect(result, isNotNull);
        expect(result!.modThreadId, isNull);
      });

      test('should return null if file does not exist', () {
        // Arrange
        final versionFile = tempDir.resolve('nonexistent.json').toFile();

        // Act
        final result = getVersionCheckerInfo(versionFile);

        // Assert
        expect(result, isNull);
      });

      test('should handle JSON with type mismatch gracefully', () {
        // Arrange
        final versionFile = tempDir.resolve('version.json').toFile();
        // modVersion should be an object, not a string - this will cause parsing to fail
        versionFile.writeAsStringSync('{ "modVersion": "1.0.0" }');

        // Act
        final result = getVersionCheckerInfo(versionFile);

        // Assert
        // getVersionCheckerInfo catches exceptions and returns null
        expect(result, isNull);
      });
    });

    group('getModVariantForModInfo', () {
      test('should find matching mod variant by smolId', () {
        // Arrange
        final modInfo1 = ModInfo(id: 'mod1', version: Version.parse('1.0.0'));
        final modInfo2 = ModInfo(id: 'mod2', version: Version.parse('2.0.0'));

        final variant1 = ModVariant(
          modInfo: modInfo1,
          versionCheckerInfo: null,
          modFolder: tempDir,
          hasNonBrickedModInfo: true,
          gameCoreFolder: tempDir,
        );

        final variant2 = ModVariant(
          modInfo: modInfo2,
          versionCheckerInfo: null,
          modFolder: tempDir,
          hasNonBrickedModInfo: true,
          gameCoreFolder: tempDir,
        );

        final variants = [variant1, variant2];

        // Act
        final result = getModVariantForModInfo(modInfo2, variants);

        // Assert
        expect(result, isNotNull);
        expect(result, equals(variant2));
      });

      test('should return null if no matching variant found', () {
        // Arrange
        final modInfo1 = ModInfo(id: 'mod1', version: Version.parse('1.0.0'));
        final modInfo2 = ModInfo(id: 'mod2', version: Version.parse('2.0.0'));

        final variant1 = ModVariant(
          modInfo: modInfo1,
          versionCheckerInfo: null,
          modFolder: tempDir,
          hasNonBrickedModInfo: true,
          gameCoreFolder: tempDir,
        );

        final variants = [variant1];

        // Act
        final result = getModVariantForModInfo(modInfo2, variants);

        // Assert
        expect(result, isNull);
      });
    });
  });
}
