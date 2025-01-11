import 'package:flutter_test/flutter_test.dart';
import 'package:trios/bit7z/seven_zip_cli.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

void main() {
  final sevenZipPath = '${currentDirectory.absolute.path}/windows/7zip/7z.exe'.toFile();

  test("7zip read test", () async {
    configureLogging();
    final sevenZ = SevenZipCLI.fromPath(sevenZipPath);
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip".toFile();
    final archiveEntries = await sevenZ.listFiles(archivePath);

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
      // print(element.file);
    }
  });

  test("7zip read game test", () async {
    configureLogging();
    final sevenZ = SevenZipCLI();
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
    final sevenZ = SevenZipCLI();
    var archivePath = "F:/Downloads/MoreMilitaryMissions-0.4.1.7z";
    final archiveEntries = await sevenZ.extractAll(
        archivePath.toFile(), "F:/Downloads/extractTest".toDirectory());

    print("Extracting archive file: $archivePath");
    // for (var element in archiveEntries) {
    //   print(element);
    // }
  });
}
