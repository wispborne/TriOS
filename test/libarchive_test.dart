import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

void main() {
  final currentDir = Directory.current;
  final assetsPath = Directory("${currentDir.path}/assets");

  // Time taken: 0:00:00.332460
  test("LibArchive read test", () {
    configureLogging();

    final time = DateTime.now();
    final libArchive = LibArchive.fromPath(assetsPath);
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip".toFile();
    final archiveEntries = libArchive.listEntriesInArchive(archivePath);
    print("Time taken: ${DateTime.now().difference(time)}");

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
      print(element.file);
    }
  });

  test("LibArchive write test", () async {
    configureLogging();

    final libArchive = LibArchive.fromPath(assetsPath);
    var archivePath = "F:/Downloads/MoreMilitaryMissions-0.4.1.7z";
    final archiveEntries = await libArchive.extractEntriesInArchive(
        File(archivePath), "F:/Downloads/extractTest");

    print("Extracting archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
    }
  });
}
