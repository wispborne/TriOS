import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/onboarding/onboarding_page.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/widgets/restartable_app.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app_shell.dart';
import 'trios/app_state.dart';

Object? loggingError;
WebViewEnvironment? webViewEnvironment;
List<Future<void> Function(BuildContext)> onAppLoadedActions = [];

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {
    print("Error initializing Flutter widgets.");
  }
  Constants.configDataFolderPath = await getApplicationSupportDirectory();
  try {
    print("Initializing TriOS logging framework...");
    configureLogging();
    Fimber.i("${Constants.appTitle} logging started.");
    Fimber.i(
        "Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}.");
  } catch (ex) {
    print("Error initializing logging. $ex");
    loggingError = ex;
  }
  try {
    await windowManager.ensureInitialized();
  } catch (ex) {
    Fimber.e("Error initializing!", ex: ex);
  }

  AppSettingsManager settingsManager = AppSettingsManager();

  bool allowCrashReporting = false;
  Settings? settings;

  // Read existing app settings
  try {
    settingsManager.loadSync();
    settings = settingsManager.state;
  } catch (e) {
    Fimber.e("Error reading app settings.", ex: e);
    onAppLoadedActions.add((context) async {
      await showAlertDialog(
        context,
        title: "TriOS Settings Reset",
        content: "Your ${Constants.appName} settings have been reset."
            "\nThis may be due to an update or a broken settings file."
            "\n\nPlease check your settings. Your mods have not been affected."
            "\n\n\nError: \n$e",
      );
    });
  }

  if (settings?.allowCrashReporting == null) {
    onAppLoadedActions.add((context) async {
      showDialog(
        context: context,
        builder: (context) => const OnboardingCarousel(),
        barrierDismissible: false,
      );
    });
  }

  // Set up Sentry
  try {
    if (settings != null && settings.userId.isNullOrEmpty()) {
      final userId = const Uuid().v8();
      settingsManager
          .writeSettingsToDiskSync(settings.copyWith(userId: userId));
    }
    allowCrashReporting = settings?.allowCrashReporting ?? false;
    configureLogging(allowSentryReporting: allowCrashReporting);
  } catch (e) {
    Fimber.w("Error reading crash reporting setting.", ex: e);
  }

  // Don't use Sentry in debug mode, ever.
  // There's a max error limit and UI rendering errors send a million errors.
  if (allowCrashReporting && kDebugMode == false) {
    try {
      await SentryFlutter.init(
        (options) {
          options = configureSentry(options, settings);
        },
        appRunner: () {
          Fimber.i("Sentry initialized.");
          _runTriOS();
        },
      );
    } catch (e) {
      Fimber.e("Error initializing Sentry.", ex: e);
      _runTriOS();
    }
  } else {
    _runTriOS();
  }

  // WebView check
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    if (availableVersion == null) {
      Fimber.e(
          'Failed to find an installed WebView2 Runtime or non-stable Microsoft Edge installation.');
    }

    // TODO webview fallback?
    // webViewEnvironment = await WebViewEnvironment.create(
    //     settings:
    //         WebViewEnvironmentSettings(userDataFolder: 'YOUR_CUSTOM_PATH'));
  }

  try {
    setWindowTitle(Constants.appTitle);
  } catch (e) {
    Fimber.e("Error setting window title.", ex: e);
  }
  const minSize = Size(1050, 700);

  try {
// Restore window position and size
//     final settings = readAppSettings();
    Rect windowFrame = Rect.fromLTWH(
      settings?.windowXPos ?? 0,
      settings?.windowYPos ?? 0,
      settings?.windowWidth ?? 1050,
      settings?.windowHeight ?? 800,
    );
    setWindowFrame(windowFrame);
    if (settings?.isMaximized ?? false) {
      windowManager.maximize();
    }

    windowManager.waitUntilReadyToShow(
        WindowOptions(size: windowFrame.size, minimumSize: minSize), () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // If the window is off screen, move it to the first display.
    final bounds = await windowManager.getBounds();
    final displays = await ScreenRetriever.instance.getAllDisplays();
    final isOnScreen = displays.any((display) =>
        display.size.contains(bounds.topLeft) ||
        display.size.contains(bounds.bottomRight) ||
        display.size.contains(bounds.bottomLeft) ||
        display.size.contains(bounds.topRight));

    if (!isOnScreen && displays.isNotEmpty) {
      final primaryDisplay = displays.firstOrNull!;
      final newBounds = Rect.fromLTWH(
          primaryDisplay.visiblePosition?.dx ?? 0,
          primaryDisplay.visiblePosition?.dy ?? 0,
          windowFrame.width,
          windowFrame.height);
      Fimber.i("Window is off screen, moving to first display."
          "\nOld bounds: $bounds"
          "\nNew bounds: $newBounds");
      await windowManager.setBounds(newBounds);
    }
  } catch (e) {
    Fimber.e("Error restoring window position and size.", ex: e);
  }

// Clean up old files.
  final filePatternsToClean = [
    logFileName,
    ScriptGenerator.SELF_UPDATE_FILE_NAME
  ];
  try {
    currentDirectory.list().listen((file) {
      if (file is File) {
        for (var pattern in filePatternsToClean) {
          if (file.path.toLowerCase().contains(pattern.toLowerCase())) {
            try {
              file.delete();
            } catch (e) {
              Fimber.e("Error deleting file: $file", ex: e);
            }
          }
        }
      }
    });
  } catch (e) {
    Fimber.e("Error cleaning up old files.", ex: e);
  }

  runZonedGuarded(() {
    SelfUpdater.cleanUpOldUpdateFiles();
  }, (error, stackTrace) {
    Fimber.w("Error cleaning up old self-update files.", ex: error);
  });
}

void _runTriOS() => runApp(const ProviderScope(
    observers: [], child: RestartableApp(child: TriOSApp())));

class TriOSApp extends ConsumerStatefulWidget {
  const TriOSApp({super.key});

  @override
  TriOSAppState createState() => TriOSAppState();
}

class TriOSAppState extends ConsumerState<TriOSApp> with WindowListener {
  @override
  void initState() {
    super.initState();

    ref.listenManual(AppState.mods, (_, variants) {
      if (ref.read(
          appSettings.select((value) => value.allowCrashReporting ?? false))) {
        try {
          final mods = variants.orEmpty().toList();
          final variantInfo = mods
              .flatMap((mod) => mod.modVariants)
              .map((v) =>
                  "${v.isEnabled(mods) ? "E" : "X"} ${v.modInfo.id} ${v.modInfo.version}")
              .sorted();

          Sentry.configureScope((scope) {
            scope.setContexts("mods", variantInfo);
          });
        } catch (e) {
          Fimber.e("Error setting Sentry scope.", ex: e);
        }
      }
    });

    windowManager.addListener(this);
// loadDefaultLog(ref);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(AppState.themeData).valueOrNull;

    if (currentTheme == null) {
      return const SizedBox();
    }

    return MaterialApp(
      title: Constants.appTitle,
      theme: currentTheme.themeData,
      themeMode: currentTheme.themeData.brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      darkTheme: currentTheme.themeData,
      home: const ToastificationConfigProvider(
          config: ToastificationConfig(
            alignment: Alignment.bottomRight,
            animationDuration: Duration(milliseconds: 200),
            itemWidth: 450,
          ),
          child: AppShell(child: VramEstimatorPage())),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _saveWindowPosition() async {
    final windowFrame = await windowManager.getBounds();
    final isMaximized = await windowManager.isMaximized();

// Don't save window size is minimized, we want to restore to the previous size.
    if (!await windowManager.isMinimized()) {
      ref.read(appSettings.notifier).update((state) {
        return state.copyWith(
          windowXPos: windowFrame.left,
          windowYPos: windowFrame.top,
          windowWidth: windowFrame.width,
          windowHeight: windowFrame.height,
          isMaximized: isMaximized,
        );
      });
    }

    // try {
    //   final config = ConfigManager("TriOS-config.json");
    //   await config.readConfig();
    //   await config.setConfig({
    //     "windowXPos": windowFrame.left,
    //     "windowYPos": windowFrame.top,
    //     "windowWidth": windowFrame.width,
    //     "windowHeight": windowFrame.height,
    //     "isMaximized": isMaximized,
    //   });
    //   Fimber.i("Saved config to ${config.file}");
    // } catch (e) {
    //   Fimber.e("Error saving window position to config file.", ex: e);
    // }
  }

  @override
  void onWindowEvent(String eventName) {
    if (Platform.isLinux && eventName == "focus") {
      // Linux doesn't have a "moved" event like Windows and MacOS.
      _saveWindowPosition();
    } else if (eventName != "blur" &&
        eventName != "focus" &&
        eventName != "move" &&
        eventName != "resize") {
      _saveWindowPosition();
    }

    if (eventName == "focus") {
      ref.read(AppState.isWindowFocused.notifier).update((state) => true);
    } else if (eventName == "blur") {
      ref.read(AppState.isWindowFocused.notifier).update((state) => false);
    }
  }
}
