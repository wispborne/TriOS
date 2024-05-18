import 'dart:io';

import 'package:fimber/fimber.dart' as f;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:platform_info/platform_info.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/pretty_printer_custom.dart';

const logFileName = "TriOS_log.";

var _consoleLogger = Logger();
var _fileLogger = Logger();
const useFimber = false;

configureLogging({bool printPlatformInfo = false}) {
  if (!useFimber) {
    const logFolderName = "logs";
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
    FlutterError.onError = (FlutterErrorDetails details) {
      print("Error :  ${details.exception}");
      print(Trace.from(details.stack!).terse);
    };


    _consoleLogger = Logger(
      level: kDebugMode ? Level.debug : Level.warning,
      filter: DevelopmentFilter(), // No console logs in release mode.
      printer: consolePrinter,
      output: ConsoleOutput(),
    );
    _fileLogger = Logger(
      level: kDebugMode ? Level.debug : Level.debug,
      filter: ProductionFilter(),
      printer: PrettyPrinterCustom(
        stackTraceBeginIndex: 1,
        methodCount: 3,
        colors: false,
        printEmojis: true,
        printTime: true,
        stackTraceMaxLines: 20,
      ),
      output: AdvancedFileOutput(path: logFolderName, maxFileSizeKB: 25000),
    );

    logFolderName
        .toDirectory()
        .listSync()
        .where((file) =>
            file is File &&
            file.extension == ".log" &&
            file.nameWithExtension != "latest.log")
        .forEach((FileSystemEntity file) => file.deleteSync());
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
      _consoleLogger.t(message, error: ex, stackTrace: stacktrace);
      _fileLogger.t(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void i(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.i(message, error: ex, stackTrace: stacktrace);
      _fileLogger.i(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void d(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.d(message, error: ex, stackTrace: stacktrace);
      _fileLogger.d(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void w(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.w(message, error: ex, stackTrace: stacktrace);
      _fileLogger.w(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void e(String message, {Object? ex, StackTrace? stacktrace}) {
    if (useFimber) {
      f.Fimber.e(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.e(message, error: ex, stackTrace: stacktrace);
      _fileLogger.e(message, error: ex, stackTrace: stacktrace);
    }
  }
}
