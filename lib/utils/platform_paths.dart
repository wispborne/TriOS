import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

File getVmparamsFile(Directory gamePath) {
  return switch (currentPlatform) {
    TargetPlatform.windows => gamePath.resolve("vmparams"),
    TargetPlatform.linux => gamePath.resolve("starsector.sh"),
    TargetPlatform.macOS => gamePath.resolve("Contents/MacOS/starsector_mac.sh"),
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }
      .toFile()
      .normalize;
}

File getJavaExecutable(Directory jrePath) {
  return switch (currentPlatform) {
    TargetPlatform.windows => jrePath.resolve("bin/java.exe"),
    TargetPlatform.linux => jrePath.resolve("bin/java"), // not sure about this
    TargetPlatform.macOS => jrePath.resolve("Contents/Home/bin/java"), // not sure about this
    _ => throw UnsupportedError("Platform not supported: $currentPlatform"),
  }
      .toFile()
      .normalize;
}
