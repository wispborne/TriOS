import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/utils/logging.dart';

void main() {
  test("LibArchive read test", () {
    configureLogging();
    final libArchive = LibArchive();
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip";
    final archiveEntries = libArchive.getEntriesInArchive(archivePath);

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
      print(element.file);
    }
  });

  test("LibArchive write test", () async {
    configureLogging();
    final libArchive = LibArchive();
    var archivePath = "F:/Downloads/MoreMilitaryMissions-0.4.1.7z";
    final archiveEntries = await libArchive.extractEntriesInArchive(File(archivePath), "F:/Downloads/extractTest");

    print("Extracting archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
    }
  });
}
