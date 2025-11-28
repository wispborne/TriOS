import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

Directory getJreDir(Directory gamePath, {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => gamePath.resolve("jre"),
    TargetPlatform.linux => gamePath.resolve("jre_linux"),
    TargetPlatform.macOS => gamePath.resolve("Contents/Home"),
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }.toDirectory().normalize;
}

File getJavaExecutable(Directory jrePath, {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => jrePath.resolve("bin/java.exe"),
    TargetPlatform.linux => jrePath.resolve("bin/java"),
    TargetPlatform.macOS => jrePath.resolve("bin/java"),
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }.toFile().normalize;
}

File getLogPath(Directory gamePath, {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => generateGameCorePath(
      gamePath,
    )!.resolve("starsector.log"),
    TargetPlatform.linux => gamePath.resolve("starsector.log"),
    TargetPlatform.macOS => gamePath.resolve("logs/starsector.log"),
    _ => throw UnsupportedError("Platform not supported: $platform"),
  }.toFile().normalize;
}

/// WARNING: This can be set by the user and stored in settings.
/// Use the custom exe path if available.
FileSystemEntity getDefaultGameExecutable(
  Directory gamePath, {
  TargetPlatform? platform,
}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => gamePath.resolve("starsector.exe"),
    TargetPlatform.linux => gamePath.resolve("starsector.sh"),
    TargetPlatform.macOS => gamePath, // game path IS the .app
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }.toFile().normalize;
}

/// Returns true if the default game executable is a directory, not a file.
/// This means MacOS.
bool isGameExecutableADirectory() {
  return switch (currentPlatform) {
    TargetPlatform.windows => false,
    TargetPlatform.linux => false,
    TargetPlatform.macOS => true,
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  };
}

/// WARNING: This checks to see if things are set up according to DEFAULTS.
/// It does not check for custom exe paths, and will fail on Arch Linux because
/// its script doesn't end in .sh.
bool validateGameRootFolderPath(String newGameDir) {
  try {
    if (newGameDir.isEmpty) return false;
    if (Platform.isMacOS) {
      return newGameDir
          .toDirectory()
          .resolve("Contents/MacOS/starsector_mac.sh")
          .existsSync();
    }
    return getDefaultGameExecutable(newGameDir.toDirectory()).existsSync();
  } catch (e) {
    Fimber.w("Error validating game folder path", ex: e);
    return false;
  }
}