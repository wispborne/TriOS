import 'dart:io';

import 'package:trios/compression/seven_zip/seven_zip.dart';

/// The 7-Zip binary checked into `assets/`, for the machine running the tests.
///
/// The normal [SevenZip] constructor looks for assets the way a packaged app
/// would, which doesn't work from a test, so this points at the copy in the
/// repo. Returns null when there is no binary for this platform, so a test can
/// skip instead of failing for a reason that has nothing to do with the code.
SevenZip? sevenZipFromRepo() {
  final repoRoot = Directory.current.path;

  String? relativePath;
  if (Platform.isWindows) {
    relativePath = 'assets/windows/7zip/7z.exe';
  } else if (Platform.isMacOS) {
    relativePath = 'assets/macos/7zip/7zz';
  } else if (Platform.isLinux) {
    final architecture = Process.runSync('uname', [
      '-m',
    ]).stdout.toString().trim();
    relativePath = switch (architecture) {
      'x86_64' => 'assets/linux/7zip/x64/7zzs',
      'aarch64' || 'arm64' => 'assets/linux/7zip/arm64/7zzs',
      _ => null,
    };
  }

  if (relativePath == null) return null;

  final binary = File('$repoRoot/$relativePath');
  if (!binary.existsSync()) return null;

  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', binary.path]);
  }

  return SevenZip.fromPath(binary);
}
