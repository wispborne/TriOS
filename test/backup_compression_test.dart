@Tags(['local-only'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/utils/backup_compression.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

void main() {
  // The normal SevenZip constructor looks for assets only a packaged app has,
  // so point it at the binary in the repo instead.
  final sevenZip = SevenZip.fromPath(
    "${Directory.current.path}/assets/windows/7zip/7z.exe".toFile(),
  );

  test("zips a backup, drops the plain file, and keeps the contents", () async {
    configureLogging(LoggingSettings());
    final tempDir = await Directory.systemTemp.createTemp("trios_backup_test");
    addTearDown(() => tempDir.delete(recursive: true));

    const contents = '{"hello": "world"}';
    final plainBackup = File("${tempDir.path}/settings.json_backup.bak");
    await plainBackup.writeAsString(contents);

    await compressBackupFile(plainBackup, sevenZip: sevenZip);

    final archive = File("${tempDir.path}/settings.json_backup.7z");
    expect(await archive.exists(), isTrue, reason: "archive should be created");
    expect(
      await plainBackup.exists(),
      isFalse,
      reason: "plain backup should be deleted once it's zipped",
    );

    final extractedDir = Directory("${tempDir.path}/extracted");
    await sevenZip.extractAll(archive, extractedDir);
    final extracted = File("${extractedDir.path}/settings.json_backup.bak");
    expect(await extracted.readAsString(), contents);
  });
}
