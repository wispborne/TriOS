import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/foundation.dart';

const logFileName = "TriOS_log.";

configureLogging() {
  const logLevels = kDebugMode ? ["V", "D", "I", "W", "E"] : ["I", "W", "E"];
  Fimber.plantTree(DebugTree.elapsed(logLevels: logLevels, useColors: true));
  Fimber.plantTree(SizeRollingFileTree(DataSize.mega(10), filenamePrefix: logFileName, filenamePostfix: ".log"));
}
