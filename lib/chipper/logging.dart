import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart';

void initLogging({bool printPlatformInfo = false}) {
  Fimber.clearAll();
  if (kDebugMode) {
    Fimber.plantTree(DebugTree.elapsed(logLevels: ["D", "I", "W", "E"], useColors: true));
  } else {
    Fimber.plantTree(DebugTree.elapsed(logLevels: ["I", "W", "E"], useColors: true));
  }

  if (printPlatformInfo) {
    Fimber.i("Logging started.");
    Fimber.i("Platform: ${Platform.I.operatingSystem.name} ${Platform.I.version}.");
  }
}
