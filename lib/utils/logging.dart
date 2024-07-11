import 'dart:io';

// import 'package:fimber/fimber.dart' as f;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:platform_info/platform_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/pretty_printer_custom.dart';

const logFileName = "latest.log";
const logFolderName = "logs";
final logFilePath = p.join(logFolderName, logFileName);

var _consoleLogger = Logger();
var _fileLogger = Logger();
bool _allowSentryReporting = false;
const useFimber = false;

/// Fine to call multiple times.
configureLogging(
    {bool printPlatformInfo = false, bool allowSentryReporting = false}) {
  _allowSentryReporting = allowSentryReporting;
  Fimber.i(
      "Crash reporting is ${allowSentryReporting ? "enabled" : "disabled"}.");

  if (!useFimber) {
    const stackTraceBeginIndex = 4;
    const methodCount = 7;
    var consolePrinter = PrettyPrinterCustom(
      stackTraceBeginIndex: 4,
      methodCount: 7,
      // Anything other than 0 halves the speed of logging.
      // errorMethodCount: 5,
      // lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
      // noBoxingByDefault: true,
      stackTraceMaxLines: 20,
    );

    // Handle errors in Flutter.
    FlutterError.onError = (FlutterErrorDetails details) {
      Fimber.e("Error :  ${details.exception}",
          ex: details.exception, stacktrace: details.stack);
      // if (details.stack != null) {
      //   Fimber.e();
      // }
    };

    _consoleLogger = Logger(
      level: kDebugMode ? Level.debug : Level.warning,
      // filter: DevelopmentFilter(), // No console logs in release mode.
      printer: consolePrinter,
      output: ConsoleOutput(),
    );

    if (!logFolderName.toDirectory().existsSync()) {
      // TODO check for MacOS permissions here.
      logFolderName.toDirectory().createSync(recursive: true);
    }

    _fileLogger = Logger(
      level: kDebugMode ? Level.debug : Level.debug,
      filter: ProductionFilter(),
      printer: PrettyPrinterCustom(
        stackTraceBeginIndex: stackTraceBeginIndex,
        methodCount: methodCount,
        colors: false,
        printEmojis: true,
        printTime: true,
        stackTraceMaxLines: 20,
      ),
      output: AdvancedFileOutput(path: logFolderName, maxFileSizeKB: 25000),
    );

    // Clean up old log files.
    logFolderName
        .toDirectory()
        .listSync()
        .where((file) =>
            file is File &&
            file.extension == ".log" &&
            file.nameWithExtension != logFileName)
        .forEach((FileSystemEntity file) => file.deleteSync());
  } else {
    // const logLevels = kDebugMode ? ["V", "D", "I", "W", "E"] : ["I", "W", "E"];
    const logLevels = kDebugMode ? ["D", "I", "W", "E"] : ["I", "W", "E"];
    // f.Fimber.plantTree(
    //     f.DebugTree.elapsed(logLevels: logLevels, useColors: true));
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
      // f.Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.t(message, error: ex, stackTrace: stacktrace);
      _fileLogger.t(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void i(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      // f.Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.i(message, error: ex, stackTrace: stacktrace);
      _fileLogger.i(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void d(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      // f.Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.d(message, error: ex, stackTrace: stacktrace);
      _fileLogger.d(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void w(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      // f.Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.w(message, error: ex, stackTrace: stacktrace);
      _fileLogger.w(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void e(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      // f.Fimber.e(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.e(message, error: ex, stackTrace: stacktrace);
      _fileLogger.e(message, error: ex, stackTrace: stacktrace);
    }

    if (_allowSentryReporting) {
      if (message.contains(" overflowed by ")) {
        // Don't report overflow errors.
        return;
      }

      Sentry.captureException(ex, stackTrace: stacktrace);
    }
  }
}
