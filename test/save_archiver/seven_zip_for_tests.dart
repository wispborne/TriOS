import 'dart:io';

import 'package:trios/compression/seven_zip/seven_zip.dart';

/// Uses the bundled binary directly because packaged asset lookup does not
/// work in tests. Returns null on platforms without a bundled binary.
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
