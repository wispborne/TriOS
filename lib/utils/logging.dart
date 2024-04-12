import 'package:fimber/fimber.dart' as f;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:platform_info/platform_info.dart';

const logFileName = "TriOS_log.";

var _logger = Logger();
const useFimber = false;

configureLogging({bool printPlatformInfo = false}) {
  if (!useFimber) {
    _logger = Logger(
      level: kDebugMode ? Level.debug : Level.info,
      printer: PrettyPrinter(
        methodCount: 0, // Anything other than 0 halves the speed of logging.
        // errorMethodCount: 5,
        // lineLength: 50,
        colors: true,
        printEmojis: true,
        printTime: true,
        // noBoxingByDefault: true,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        AdvancedFileOutput(path: "logs", maxFileSizeKB: 25000),
      ]),
    );
  } else {
    // const logLevels = kDebugMode ? ["V", "D", "I", "W", "E"] : ["I", "W", "E"];
    const logLevels = kDebugMode ? ["D", "I", "W", "E"] : ["I", "W", "E"];
    f.Fimber.plantTree(
        f.DebugTree.elapsed(logLevels: logLevels, useColors: true));
    // f.Fimber.plantTree(f.SizeRollingFileTree(DataSize.mega(10),
    //     filenamePrefix: logFileName, filenamePostfix: ".log"));
  }

  if (printPlatformInfo) {
    Fimber.i("Logging started.");
    Fimber.i(
        "Platform: ${Platform.I.operatingSystem.name} ${Platform.I.version}.");
  }
}

class Fimber {
  static void v(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      _logger.t(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void i(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      _logger.i(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void d(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      _logger.d(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void w(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      _logger.w(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void e(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.e(message, ex: ex, stacktrace: stacktrace);
    } else {
      _logger.e(message, error: ex, stackTrace: stacktrace);
    }
  }
}
