import 'dart:convert';
import 'dart:io';

// import 'package:fimber/fimber.dart' as f;
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

// import 'package:platform_info/platform_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/utils/pretty_printer_custom.dart';
import 'package:uuid/uuid.dart';

import '../trios/constants.dart';
import '../trios/settings/settings.dart';

part 'logging.mapper.dart';

const logFileName = "TriOS-log.log";
String? logFolderName;
String? logFilePath;

Logger _consoleLogger = Logger();
Logger? _fileLogger;
AdvancedFileOutput? _advancedFileOutput;
const useFimber = false;
bool didLoggingInitializeSuccessfully = false;
LoggingSettings _loggingSettings = LoggingSettings();

LoggingSettings get currentSettings => _loggingSettings;

@MappableClass()
class LoggingSettings with LoggingSettingsMappable {
  final bool printPlatformInfo;
  final bool allowSentryReporting;
  final bool consoleOnly;
  final bool shouldDebugRiverpod;
  final Level consoleLoggingLevel;
  final Level fileLoggingLevel;

  LoggingSettings({
    this.printPlatformInfo = false,
    this.allowSentryReporting = false,
    this.consoleOnly = false,
    this.shouldDebugRiverpod = false,
    this.consoleLoggingLevel = kDebugMode ? Level.debug : Level.error,
    this.fileLoggingLevel = Level.info,
  });
}

Future<void> modifyLoggingSettings(
  LoggingSettings Function(LoggingSettings prevSettings) modifier,
) {
  _loggingSettings = modifier(_loggingSettings ?? LoggingSettings());
  return configureLogging(_loggingSettings!);
}

/// Fine to call multiple times.
Future<void> configureLogging(LoggingSettings settings) async {
  Fimber.i(
    "Crash reporting is ${settings.allowSentryReporting ? "enabled" : "disabled"}.",
  );
  try {
    WidgetsFlutterBinding.ensureInitialized();
    logFolderName = (Constants.configDataFolderPath).absolute.path;
    logFilePath = p.join(logFolderName!, logFileName);
  } catch (e) {
    Fimber.e("Error getting log folder name.", ex: e);
  }

  if (!useFimber) {
    const stackTraceBeginIndex = 4;
    const methodCount = 7;
    var consolePrinter = PrettyPrinterCustom(
      stackTraceBeginIndex: 0,
      methodCount: 20,
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
      Fimber.e(
        "Error :  ${details.exception}",
        ex: details.exception,
        stacktrace: details.stack,
      );
      // if (details.stack != null) {
      //   Fimber.e();
      // }
    };

    _consoleLogger = Logger(
      level: settings.consoleLoggingLevel,
      // filter: DevelopmentFilter(), // No console logs in release mode.
      printer: consolePrinter,
      output: ConsoleOutput(),
    );

    if (settings.consoleOnly) {
      _fileLogger = null;
    } else {
      try {
        if (logFolderName?.toDirectory().existsSync() != true) {
          // TODO check for MacOS permissions here.
          logFolderName?.toDirectory().createSync(recursive: true);
        }

        // Only set up file logging once, otherwise it messes up sink handling.
        if (_advancedFileOutput == null) {
          // Closes file handles to the log file if they exist.
          await _advancedFileOutput?.destroy();

          _advancedFileOutput = AdvancedFileOutput(
            path: logFolderName!,
            maxFileSizeKB: 25000,
            writeImmediately: [Level.error, Level.fatal],
            latestFileName: logFileName,
          );

          _fileLogger = Logger(
            level: settings.fileLoggingLevel,
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
                .where(
                  (file) =>
                      file is File &&
                      file.extension == ".log" &&
                      file.nameWithExtension != logFileName,
                )
                .forEach(
                  (FileSystemEntity file) =>
                      file.moveToTrash(deleteIfFailed: true),
                );
          } catch (e) {
            Fimber.e("Error cleaning up old log files.", ex: e);
          }
        }
      } catch (e) {
        Fimber.e(
          "Error setting up file logging. Falling back to console only.",
          ex: e,
        );
        configureLogging((_loggingSettings).copyWith(consoleOnly: true));
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

  didLoggingInitializeSuccessfully = true;

  if (settings.printPlatformInfo) {
    printLoggingStartedInfo();
  }
}

void printLoggingStartedInfo() {
  final b = StringBuffer("Logging started.\n");

  for (var info in [
    () =>
        "Platform: ${Platform.operatingSystem} - ${Platform.operatingSystemVersion}",
    () => "Dart version: ${Platform.version}",
    () => "Processors: ${Platform.numberOfProcessors}",
    () => "Executable: ${Platform.executable}",
    () => "Release mode: $kReleaseMode",
    // () {
    //   final env = Platform.environment;
    //   return "Env vars:\n${env.entries.map((e) => "${e.key}: ${e.value}").join('\n')}";
    // },
    () => "Startup timestamp: ${DateTime.now().millisecondsSinceEpoch}",
    () => "Memory (RSS): ${ProcessInfo.currentRss.bytesAsReadableMB()}",
  ]) {
    try {
      b.writeln(info());
    } catch (e) {
      stdout.writeln("Error: $e");
    }
  }

  Fimber.i(b.toString().trim());
}

class Fimber {
  /// Logs a verbose message.
  /// [message] is a function that returns the message to log.
  /// Verbose logging is expected to be super spammy, so don't build the message unless we're actually going to log it.
  static void v(
    String Function() message, {
    Object? ex,
    StackTrace? stacktrace,
  }) {
    if (!didLoggingInitializeSuccessfully) {
      print(message());
      return;
    }

    final msg = message();

    if (useFimber) {
      // f.Fimber.v(() =>message, ex: ex, stacktrace: stacktrace);
    } else {
      _consoleLogger.t(msg, error: ex, stackTrace: stacktrace);
      _fileLogger?.t(msg, error: ex, stackTrace: stacktrace);
    }

    // noop if Sentry disabled
    // Sentry.logger.trace(msg);
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

    // noop if Sentry disabled
    // Sentry.logger.debug(message);
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

    // noop if Sentry disabled
    Sentry.logger.info(message);
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

    // noop if Sentry disabled
    Sentry.logger.warn(message);
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

    if (_loggingSettings.allowSentryReporting) {
      Sentry.captureException(
        ex,
        stackTrace: stacktrace,
        withScope: (scope) {
          scope.setContexts("extra-data", {"message": _scrubPath(message)});
        },
      );
    }

    // noop if Sentry disabled
    Sentry.logger.error(message);
  }
}

class RiverpodDebugObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {}

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {}

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (_loggingSettings.shouldDebugRiverpod) {
      Fimber.d(
        "Provider: $provider, prev: ${previousValue.toString().take(200)}, new: ${newValue.toString().take(200)}, container: ${container.toString().take(200)}",
      );
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {}
}

/////////////////
// Sentry Section

final lastErrorMessagesAndTimestamps = <String, DateTime>{};
// If tag key is present, the event won't be rate limited, regardless of the tag's value.
final reportBugMagicString = "User clicked Report Bug";

SentryFlutterOptions configureSentry(
  SentryFlutterOptions options,
  Settings? settings,
) {
  final userId = getSentryUserId(settings);

  // I'm lazy, please don't steal.
  final dsn = utf8.decode(
    base64Decode(
      'aHR0cHM6Ly80OTAzMjgyNjBkZWVjMTYzMmQzODMzYTdiNTQzOWRkNUBvNDUwNzU3OTU3MzYwMDI1Ni5pbmdlc3QudXMuc2VudHJ5LmlvLzQ1MDc1Nzk1NzQ2NDg4MzI=',
    ),
  );
  options
    ..dsn = dsn
    ..debug = kDebugMode
    ..sendDefaultPii = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableAppLifecycleBreadcrumbs = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableAutoPerformanceTracing = false
    ..enableUserInteractionTracing = false
    ..enableWindowMetricBreadcrumbs = false
    ..release = Constants.version
    ..dist = Constants.version
    ..attachScreenshot = true
    ..privacy.maskAllImages = false
    ..privacy.maskAllText = false
    ..privacy.maskAssetImages = false
    ..enableLogs = true
    ..feedback.nameLabel = "Username (not required)"
    ..feedback.namePlaceholder = [
      "@JohnStarsector",
      "@JaneStarsector",
      "@LowHegemon",
      "@MyLittleStarfarer",
      "@NotAnAICore",
      "@DefinitelyAnAICore",
      "@AlphariusHumani",
      "@GensNobody",
      "@No1SebeFan",
      "@RealGileadPrince",
      "@TeaAndCotton",
      "@CareBaird",
      "@FinlayTipLine",
      "@CaptainRoger",
    ].random()
    ..feedback.emailLabel = "Email (definitely not required!)"
    // "\n  by entering an email, you agree to receive marketing messages from the TriTachyon Corporation"
    ..feedback.emailPlaceholder = "you@email.com"
    ..feedback.isEmailRequired = false
    ..feedback.messageLabel = "Description"
    ..feedback.isRequiredLabel = "(required)"
    ..feedback.showCaptureScreenshot = false
    ..feedback.messagePlaceholder =
        "Please describe the issue you are experiencing with ${Constants.appName}."
        "\n"
        "\n${Constants.appName} is not affiliated with Fractal Softworks and cannot help with issues with the game, payments, license keys, or mods.";

  options.beforeCaptureScreenshot = (event, hint, shouldDebounce) async {
    // Only allow screenshots for the report bug flow.
    return event.message?.formatted == reportBugMagicString;
  };

  options.beforeSend = (event, hint) {
    final message =
        event.message?.formatted ?? event.exceptions?.firstOrNull?.value;
    const debounceMins = 10;

    if (message != null) {
      // Don't report overflow errors.
      if (message.contains(" overflowed by ")) {
        return null;
      }

      if (event.exceptions?.firstOrNull is NetworkImageLoadException) {
        return null;
      }

      // Don't report the same error message more than once every debounceMins minutes.
      if (event.message?.formatted != reportBugMagicString &&
          lastErrorMessagesAndTimestamps.containsKey(message)) {
        final lastTime = lastErrorMessagesAndTimestamps[message];
        if (lastTime != null &&
            DateTime.now().difference(lastTime).inMinutes < debounceMins) {
          Fimber.d(
            "Suppressing error message already sent in the last $debounceMins mins: $message",
          );
          return null;
        }
      }

      lastErrorMessagesAndTimestamps[message] = DateTime.now();
      // Remove old error messages.
      lastErrorMessagesAndTimestamps.removeWhere(
        (key, value) =>
            DateTime.now().difference(value).inMinutes > (debounceMins + 1),
      );
    }

    // Strip out PII as much as possible.
    return (event
          ..serverName = ""
          ..release = Constants.version
          ..dist = Constants.version
          ..platform = Platform.operatingSystemVersion
          ..user = (event.user
            ?..id = userId
            ..ipAddress = "127.0.0.1"
            ..geo = null)
          ..contexts = (event.contexts
            ..device = (event.contexts.device?..name = "redacted")
            ..culture = (event.contexts.culture
              ?..timezone = "redacted"
              ..locale = "redacted")))
        .let((event) {
          try {
            return _scrubSensitiveDataFromSentryEvent(event, hint: hint);
          } catch (e) {
            // Can't very well log it to Sentry if it's broken.
            Fimber.i("Error scrubbing sensitive data.", ex: e);
            return event;
          }
        });
  };

  // Remove username from log paths.
  options.beforeSendLog = (SentryLog? log) {
    if (log == null) {
      return null;
    }

    log.body = _scrubPath(log.body);
    return log;
  };

  return options;
}

String getSentryUserId(Settings? settings) {
  final userIdFile = Constants.configDataFolderPath
      .resolve("user_id_sentry.txt")
      .toFile();
  var userId = "";

  // Read user id from file.
  try {
    if (userIdFile.existsSync()) {
      userId = userIdFile.readAsStringSync().trim();
    }
  } catch (e) {
    Fimber.e("Error reading user ID from file.", ex: e);
  }

  // If user id is empty or too long, generate a new one.
  if (userId.isEmpty || userId.length > 100) {
    try {
      // Generate a new user id.
      userId = const Uuid().v8();

      userIdFile.writeAsStringSync(userId);
    } catch (e) {
      Fimber.w("Error setting user ID.", ex: e);
    }
  }

  return userId;
}

/// ChatGPT generated.
SentryEvent _scrubSensitiveDataFromSentryEvent(
  SentryEvent event, {
  Hint? hint,
}) {
  // Scrub sensitive data from the exception values
  final exceptions = event.exceptions?.map((exception) {
    if (exception.stackTrace != null) {
      final frames = exception.stackTrace!.frames.map((frame) {
        if (frame.fileName != null) {
          frame.fileName = _scrubPath(frame.fileName!);
        }
        return frame;
      }).toList();
      exception.stackTrace = SentryStackTrace(frames: frames);
    }
    if (exception.value != null) {
      exception.value = _scrubPath(exception.value!);
    }
    return exception;
  }).toList();

  return event..exceptions = exceptions;
}

// Function to scrub usernames from the path
String _scrubPath(String path) {
  // Scrub Windows usernames
  path = path.replaceAll(RegExp(r'\\Users\\[^\\]+'), r'\Users\redacted');

  // Scrub macOS and Linux usernames
  path = path.replaceAll(RegExp(r'/Users/[^/]+'), '/Users/<REDACTED>');
  path = path.replaceAll(RegExp(r'/home/[^/]+'), '/home/<REDACTED>');

  return path;
}
