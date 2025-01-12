import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

void main() {
  final currentDir = Directory.current;
  final assetsPath = Directory("${currentDir.path}/assets");
  final sevenZipPath = '${assetsPath.path}/windows/7zip/7z.exe'.toFile();

  // Time taken: 0:00:00.161736
  test("7zip read test", () async {
    configureLogging();
    final time = DateTime.now();

    final sevenZ = SevenZip.fromPath(sevenZipPath);
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip".toFile();
    final archiveEntries = await sevenZ.listFiles(archivePath);
    print("Time taken: ${DateTime.now().difference(time)}");

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
    }
  });

  test("7zip read game test", () async {
    configureLogging();
    final sevenZ = SevenZip();
    var archivePath = "F:/Downloads/starsector_install-0.97a-RC11.exe".toFile();
    final archiveEntries = await sevenZ.listFiles(archivePath);

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
      // print(element.file);
    }
  });

  test("7zip write test", () async {
    configureLogging();
    final sevenZ = SevenZip();
    var archivePath = "F:/Downloads/MoreMilitaryMissions-0.4.1.7z";
    final archiveEntries = await sevenZ.extractAll(
        archivePath.toFile(), "F:/Downloads/extractTest".toDirectory());

    print("Extracting archive file: $archivePath");
    // for (var element in archiveEntries) {
    //   print(element);
    // }
  });
}
