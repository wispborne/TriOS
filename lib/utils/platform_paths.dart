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
  }
      .toDirectory()
      .normalize;
}

File getJavaExecutable(Directory jrePath, {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => jrePath.resolve("bin/java.exe"),
    TargetPlatform.linux => jrePath.resolve("bin/java"), // not sure about this
    TargetPlatform.macOS => jrePath.resolve("bin/java"), // not sure about this
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }
      .toFile()
      .normalize;
}

File getLogPath(Directory gamePath, {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows =>
      generateGameCorePath(gamePath)!.resolve("starsector.log"),
    TargetPlatform.linux => gamePath.resolve("starsector.log"),
    TargetPlatform.macOS => gamePath.resolve("logs/starsector.log"),
    _ => throw UnsupportedError("Platform not supported: $platform"),
  }
      .toFile()
      .normalize;
}

FileSystemEntity getVanillaGameExecutable(Directory gamePath,
    {TargetPlatform? platform}) {
  return switch (platform ?? currentPlatform) {
    TargetPlatform.windows => gamePath.resolve("starsector.exe"),
    TargetPlatform.linux => gamePath.resolve("starsector.sh"),
    TargetPlatform.macOS => gamePath, // game path IS the .app
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }
      .toFile()
      .normalize;
}

bool validateGameFolderPath(String newGameDir) {
  try {
    if (newGameDir.isEmpty) return false;
    if (Platform.isMacOS) {
      return newGameDir
          .toDirectory()
          .resolve("Contents/MacOS/starsector_mac.sh")
          .existsSync();
    }
    return getVanillaGameExecutable(newGameDir.toDirectory()).existsSync();
  } catch (e) {
    Fimber.w("Error validating game folder path", ex: e);
    return false;
  }
}
