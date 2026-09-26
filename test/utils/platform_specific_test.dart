@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/platform_specific.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trios_delete_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('isCloudReparseTagWindows', () {
    test('matches all 16 cloud sync tags', () {
      for (var i = 0; i < 16; i++) {
        expect(isCloudReparseTagWindows(0x9000001A | (i << 12)), isTrue);
      }
    });

    test('does not match junctions or symbolic links', () {
      const ioReparseTagMountPoint = 0xA0000003;
      const ioReparseTagSymlink = 0xA000000C;
      expect(isCloudReparseTagWindows(ioReparseTagMountPoint), isFalse);
      expect(isCloudReparseTagWindows(ioReparseTagSymlink), isFalse);
      expect(isCloudReparseTagWindows(0), isFalse);
    });
  });

  group('deleteRecursivelyWindows', () {
    test('deletes a normal folder with nested files', () {
      final modFolder = Directory(p.join(tempDir.path, 'Some Mod-1.0'));
      File(p.join(modFolder.path, 'mod_info.json')).createSync(recursive: true);
      File(p.join(modFolder.path, 'data', 'config', 'settings.json'))
          .createSync(recursive: true);

      deleteRecursivelyWindows(modFolder.path);

      expect(modFolder.existsSync(), isFalse);
      expect(tempDir.existsSync(), isTrue);
    });

    test('deletes read-only files', () {
      final modFolder = Directory(p.join(tempDir.path, 'Some Mod-1.0'));
      final file = File(p.join(modFolder.path, 'mod_info.json'))
        ..createSync(recursive: true);
      Process.runSync('attrib', ['+R', file.path]);

      deleteRecursivelyWindows(modFolder.path);

      expect(modFolder.existsSync(), isFalse);
    });

    test('deletes files with paths longer than 260 characters', () {
      final modFolder = Directory(p.join(tempDir.path, 'Some Mod-1.0'));
      var deepFolder = modFolder.path;
      while (deepFolder.length < 300) {
        deepFolder = p.join(deepFolder, 'a_long_folder_name_to_pad_the_path');
      }
      File(p.join(deepFolder, 'file.txt')).createSync(recursive: true);

      deleteRecursivelyWindows(modFolder.path);

      expect(modFolder.existsSync(), isFalse);
    });

    test('removes a link inside the folder without touching its target', () {
      final target = Directory(p.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(p.join(target.path, 'keep_me.txt'))..createSync();
      final modFolder = Directory(p.join(tempDir.path, 'Some Mod-1.0'))
        ..createSync();
      Link(p.join(modFolder.path, 'linked')).createSync(target.path);

      deleteRecursivelyWindows(modFolder.path);

      expect(modFolder.existsSync(), isFalse);
      expect(targetFile.existsSync(), isTrue);
    });

    test('removes a folder link without touching its target', () {
      final target = Directory(p.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(p.join(target.path, 'keep_me.txt'))..createSync();
      final link = Link(p.join(tempDir.path, 'Some Mod-1.0'))
        ..createSync(target.path);

      deleteRecursivelyWindows(link.path);

      expect(link.existsSync(), isFalse);
      expect(targetFile.existsSync(), isTrue);
    });

    test('does nothing if the path does not exist', () {
      deleteRecursivelyWindows(p.join(tempDir.path, 'missing'));
    });
  });
}
