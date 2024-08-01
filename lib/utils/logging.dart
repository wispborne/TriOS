import 'dart:io';

// import 'package:fimber/fimber.dart' as f;
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
// import 'package:platform_info/platform_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/pretty_printer_custom.dart';

import '../trios/constants.dart';
import '../trios/settings/settings.dart';

const logFileName = "latest.log";
const logFolderName = "logs";
final logFilePath = p.join(logFolderName, logFileName);

var _consoleLogger = Logger();
var _fileLogger = Logger();
bool _allowSentryReporting = false;
const useFimber = false;
bool didLoggingInitializeSuccessfully = false;

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
      stackTraceBeginIndex: 0,
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
      level: kDebugMode ? Level.debug : Level.error,
      // filter: DevelopmentFilter(), // No console logs in release mode.
      printer: consolePrinter,
      output: ConsoleOutput(),
    );

    if (!logFolderName.toDirectory().existsSync()) {
      // TODO check for MacOS permissions here.
      logFolderName.toDirectory().createSync(recursive: true);
    }

    _fileLogger = Logger(
      level: kDebugMode ? Level.info : Level.debug,
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
    Fimber.i("Platform: ${Platform.operatingSystemVersion}");
  }

  didLoggingInitializeSuccessfully = true;
}

class Fimber {
  static void v(String message, {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message);
      return;
    }

    if (useFimber) {
      // f.Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.t(message, error: ex, stackTrace: stacktrace);
      _fileLogger.t(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void i(String message, {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message);
      return;
    }

    if (useFimber) {
      // f.Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.i(message, error: ex, stackTrace: stacktrace);
      _fileLogger.i(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void d(String message, {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message);
      return;
    }

    if (useFimber) {
      // f.Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.d(message, error: ex, stackTrace: stacktrace);
      _fileLogger.d(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void w(String message, {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message);
      return;
    }

    if (useFimber) {
      // f.Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.w(message, error: ex, stackTrace: stacktrace);
      _fileLogger.w(message, error: ex, stackTrace: stacktrace);
    }
  }

  static void e(String message, {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message);
      return;
    }

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

SentryFlutterOptions configureSentry(
    SentryFlutterOptions options, Settings? settings) {
  options.dsn =
      'https://490328260deec1632d3833a7b5439dd5@o4507579573600256.ingest.us.sentry.io/4507579574648832';

  options
    ..debug = kDebugMode
    ..sendDefaultPii = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableAppLifecycleBreadcrumbs = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableAutoPerformanceTracing = false
    ..enableUserInteractionTracing = false
    ..enableWindowMetricBreadcrumbs = false;

  options.beforeSend = (event, hint) {
    return event
        .copyWith(
      serverName: "",
      release: Constants.version,
      dist: Constants.version,
      platform: Platform.operatingSystemVersion,
      user: event.user
          ?.copyWith(id: settings?.userId.toString(), ipAddress: "127.0.0.1"),
      contexts: event.contexts.copyWith(
        device: event.contexts.device?.copyWith(
          name: "redacted",
        ),
        culture: event.contexts.culture?.copyWith(
          timezone: "redacted",
          locale: "redacted",
        ),
      ),
    )
        .let((event) {
      try {
        return scrubSensitiveData(event, hint: hint);
      } catch (e) {
        // Can't very well log it to Sentry if it's broken.
        Fimber.i("Error scrubbing sensitive data.", ex: e);
        return event;
      }
    });
  };

  return options;
}

/// ChatGPT generated.
SentryEvent scrubSensitiveData(SentryEvent event, {Hint? hint}) {
  // Function to scrub usernames from the path
  String scrubPath(String path) {
    // Scrub Windows usernames
    path = path.replaceAll(RegExp(r'\\Users\\[^\\]+'), r'\Users\redacted');

    // Scrub macOS and Linux usernames
    path = path.replaceAll(RegExp(r'/Users/[^/]+'), '/Users/<REDACTED>');
    path = path.replaceAll(RegExp(r'/home/[^/]+'), '/home/<REDACTED>');

    return path;
  }

  // Scrub sensitive data from the exception values
  final exceptions = event.exceptions?.map((exception) {
    if (exception.stackTrace != null) {
      final frames = exception.stackTrace!.frames.map((frame) {
        if (frame.fileName != null) {
          frame = frame.copyWith(fileName: scrubPath(frame.fileName!));
        }
        return frame;
      }).toList();
      exception =
          exception.copyWith(stackTrace: SentryStackTrace(frames: frames));
    }
    if (exception.value != null) {
      exception = exception.copyWith(value: scrubPath(exception.value!));
    }
    return exception;
  }).toList();

  return event.copyWith(
    exceptions: exceptions,
  );
}
