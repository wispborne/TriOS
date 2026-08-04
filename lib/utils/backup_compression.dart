import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/utils/logging.dart';

/// One handler shared by every backup. Building it runs `chmod` on macOS and
/// Linux, so don't make a new one each time.
SevenZip? _sharedSevenZip;

/// Zips [plainBackup] into a `.7z` beside it, then deletes the plain file.
///
/// TriOS never reads its own backups — they exist so a person can restore a
/// file by hand — so there's no reason to leave them uncompressed.
///
/// If anything goes wrong, the plain file is left exactly where it is. Losing a
/// backup to save disk space would be a bad trade.
///
/// Pass [sevenZip] to use a specific handler; tests need this because the
/// normal one looks for assets that only a packaged app has.
Future<void> compressBackupFile(File plainBackup, {SevenZip? sevenZip}) async {
  final archiveFile = File(p.setExtension(plainBackup.path, '.7z'));

  try {
    // `7z a` adds to an existing archive instead of replacing it.
    if (await archiveFile.exists()) {
      await archiveFile.delete();
    }

    final handler = sevenZip ?? (_sharedSevenZip ??= SevenZip());
    await handler.createArchive(archiveFile, [plainBackup]);

    if (await archiveFile.exists()) {
      await plainBackup.delete();
      Fimber.i("Compressed backup to ${archiveFile.path}");
    }
  } catch (e, stackTrace) {
    Fimber.w(
      "Could not compress backup '${plainBackup.path}', leaving it as-is.",
      ex: e,
      stacktrace: stackTrace,
    );
  }
}
