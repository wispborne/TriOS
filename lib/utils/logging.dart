import 'dart:convert';
import 'dart:io';

// import 'package:fimber/fimber.dart' as f;
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

// import 'package:platform_info/platform_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/utils/pretty_printer_custom.dart';

import '../trios/constants.dart';
import '../trios/settings/settings.dart';

const logFileName = "TriOS-log.log";
String? logFolderName;
String? logFilePath;

Logger _consoleLogger = Logger();
Logger? _fileLogger;
AdvancedFileOutput? _advancedFileOutput;
bool _allowSentryReporting = false;
const useFimber = false;
bool didLoggingInitializeSuccessfully = false;

/// Fine to call multiple times.
configureLogging({
  bool printPlatformInfo = false,
  bool allowSentryReporting = false,
  bool consoleOnly = false,
}) async {
  _allowSentryReporting = allowSentryReporting;
  Fimber.i(
      "Crash reporting is ${allowSentryReporting ? "enabled" : "disabled"}.");
  try {
    WidgetsFlutterBinding.ensureInitialized();
    logFolderName = (await configDataFolderPath).absolute.path;
    logFilePath = p.join(logFolderName!, logFileName);
  } catch (e) {
    Fimber.e("Error getting log folder name.", ex: e);
  }

  if (!useFimber) {
    const stackTraceBeginIndex = 4;
    const methodCount = 7;
    var consolePrinter = PrettyPrinterCustom(
      stackTraceBeginIndex: 3,
      methodCount: 9,
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

    if (consoleOnly) {
      _fileLogger = null;
    } else {
      try {
        if (logFolderName?.toDirectory().existsSync() != true) {
          // TODO check for MacOS permissions here.
          logFolderName?.toDirectory().createSync(recursive: true);
        }

        // Closes file handles to the log file if they exist.
        await _advancedFileOutput?.destroy();

        _advancedFileOutput = AdvancedFileOutput(
          path: logFolderName!,
          maxFileSizeKB: 25000,
          writeImmediately: [Level.error, Level.fatal],
          latestFileName: logFileName,
        );

        _fileLogger = Logger(
          level: kDebugMode ? Level.debug : Level.info,
          filter: ProductionFilter(),
          printer: PrettyPrinterCustom(
            stackTraceBeginIndex: stackTraceBeginIndex,
            methodCount: methodCount,
            colors: false,
            printEmojis: true,
            printTime: true,
            stackTraceMaxLines: 20,
          ),
          output: _advancedFileOutput,
        );

        // Clean up old log files.
        try {
          logFolderName
              ?.toDirectory()
              .listSync()
              .where((file) =>
                  file is File &&
                  file.extension == ".log" &&
                  file.nameWithExtension != logFileName)
              .forEach((FileSystemEntity file) =>
                  file.moveToTrash(deleteIfFailed: true));
        } catch (e) {
          Fimber.e("Error cleaning up old log files.", ex: e);
        }
      } catch (e) {
        Fimber.e("Error setting up file logging. Falling back to console only.",
            ex: e);
        configureLogging(
            printPlatformInfo: printPlatformInfo,
            allowSentryReporting: allowSentryReporting,
            consoleOnly: true);
        return;
      }
    }
  } else {
    // const logLevels = kDebugMode ? ["V", "D", "I", "W", "E"] : ["I", "W", "E"];
    // const logLevels = kDebugMode ? ["D", "I", "W", "E"] : ["I", "W", "E"];
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
  /// Logs a verbose message.
  /// [message] is a function that returns the message to log.
  /// Verbose logging is expected to be super spammy, so don't build the message unless we're actually going to log it.
  static void v(String Function() message,
      {Object? ex, StackTrace? stacktrace}) {
    if (!didLoggingInitializeSuccessfully) {
      print(message());
      return;
    }

    if (useFimber) {
      // f.Fimber.v(() =>message, ex: ex, stacktrace: stacktrace);
    } else {
      final msg = message();
      _consoleLogger.t(msg, error: ex, stackTrace: stacktrace);
      _fileLogger?.t(msg, error: ex, stackTrace: stacktrace);
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
      _fileLogger?.i(message, error: ex, stackTrace: stacktrace);
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
      _fileLogger?.d(message, error: ex, stackTrace: stacktrace);
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
      _fileLogger?.w(message, error: ex, stackTrace: stacktrace);
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
      _fileLogger?.e(message, error: ex, stackTrace: stacktrace);
    }

    if (_allowSentryReporting) {
      Sentry.captureException(ex, stackTrace: stacktrace);
    }
  }
}

final lastErrorMessagesAndTimestamps = <String, DateTime>{};

SentryFlutterOptions configureSentry(
    SentryFlutterOptions options, Settings? settings) {
  // I'm lazy, please don't steal.
  options.dsn = utf8.decode(base64Decode(
      'aHR0cHM6Ly80OTAzMjgyNjBkZWVjMTYzMmQzODMzYTdiNTQzOWRkNUBvNDUwNzU3OTU3MzYwMDI1Ni5pbmdlc3QudXMuc2VudHJ5LmlvLzQ1MDc1Nzk1NzQ2NDg4MzI='));

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
    final message =
        event.message?.formatted ?? event.exceptions?.firstOrNull?.value;
    const debounceMins = 10;

    if (message != null) {
      // Don't report overflow errors.
      if (message.contains(" overflowed by ")) {
        return null;
      }

      // Don't report the same error message more than once every debounceMins minutes.
      if (lastErrorMessagesAndTimestamps.containsKey(message)) {
        final lastTime = lastErrorMessagesAndTimestamps[message];
        if (lastTime != null &&
            DateTime.now().difference(lastTime).inMinutes < debounceMins) {
          Fimber.d(
              "Suppressing error message already sent in the last $debounceMins mins: $message");
          return null;
        }
      }

      lastErrorMessagesAndTimestamps[message] = DateTime.now();
      // Remove old error messages.
      lastErrorMessagesAndTimestamps.removeWhere((key, value) =>
          DateTime.now().difference(value).inMinutes > (debounceMins + 1));
    }

    // Strip out PII as much as possible.
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
