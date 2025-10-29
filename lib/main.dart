import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/onboarding/onboarding_page.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/post_update_toast.dart';
import 'package:trios/widgets/restartable_app.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app_shell.dart';
import 'trios/app_state.dart';

Object? loggingError;
StateProvider<WebViewEnvironment?> webViewEnvironment =
    StateProvider<WebViewEnvironment?>((ref) => null);

List<Future<void> Function(BuildContext)> onAppLoadedActions = [];

Future<Rect> _convertLogicalToPhysicalPixels(Rect r) async {
  final p = await ScreenRetriever.instance.getPrimaryDisplay();
  final d = (await ScreenRetriever.instance.getAllDisplays()).firstWhere(
    (d) => (((d.visiblePosition ?? Offset.zero) & (d.visibleSize ?? d.size))
        .contains(r.center)),
    orElse: () => p,
  );
  final s = (d.scaleFactor ?? 1).toDouble();
  return Rect.fromLTWH(r.left * s, r.top * s, r.width * s, r.height * s);
}

Future<void> _ensureWindowIsVisible() async {
  Rect vis(Display d) {
    final o = d.visiblePosition ?? Offset.zero, s = d.visibleSize ?? d.size;
    return Rect.fromLTWH(o.dx, o.dy, s.width, s.height);
  }

  final display = await ScreenRetriever.instance.getAllDisplays();
  if (display.isEmpty) return;

  final bounds = await windowManager.getBounds();
  if (display.any((d) {
    final r = vis(d);
    return r.overlaps(bounds) || r.contains(bounds.center);
  })) {
    return;
  }

  final t = await ScreenRetriever.instance.getPrimaryDisplay();
  final r = vis(t), s = (t.scaleFactor ?? 1).toDouble();
  await windowManager.setBounds(
    Rect.fromLTWH(
      r.left * s,
      r.top * s,
      math.min(bounds.width, r.width) * s,
      math.min(bounds.height, r.height) * s,
    ),
  );
}

final shouldDebugRiverpod = false;

void main() async {
  double scaleFactorCallback(Size deviceSize) {
    return 1;
  }

  try {
    ScaledWidgetsFlutterBinding.ensureInitialized(
      scaleFactor: scaleFactorCallback,
    );
  } catch (e) {
    print("Error initializing Flutter widgets.");
  }

  // REMOVED because it was causing a bunch of instances to appear for some people when they updated.
  // Windows: If another instance is already running, bring it to the foreground instead of opening a new instance.
  // (allow one debug + one release to be able to compare)
  // await WindowsSingleInstance.ensureSingleInstance(
  //   args,
  //   "wisp_trios${kDebugMode ? "_dev" : ""}${Constants.version}",
  //   onSecondWindow: (args) {
  //     print(args);
  //   },
  // );

  Constants.configDataFolderPath = await getApplicationSupportDirectory();
  try {
    print("Initializing TriOS logging framework...");
    configureLogging(
      LoggingSettings(
        printPlatformInfo: true,
        shouldDebugRiverpod: shouldDebugRiverpod,
      ),
    );
    Fimber.i("${Constants.appTitle} logging started.");
    Fimber.i(
      "Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}.",
    );
  } catch (ex) {
    print("Error initializing logging. $ex");
    loggingError = ex;
  }

  try {
    final locale = PlatformDispatcher.instance.locale;
    Intl.defaultLocale = locale.toLanguageTag();
    await initializeDateFormatting(Intl.defaultLocale ?? "en_US", null);
  } catch (ex) {
    Fimber.w("Error initializing date formatting.", ex: ex);
  }

  try {
    await windowManager.ensureInitialized();
  } catch (ex) {
    Fimber.e("Error initializing!", ex: ex);
  }

  final SettingsFileManager fileManager = SettingsFileManager();

  bool allowCrashReporting = false;
  Settings? settings;

  // Read existing app settings
  try {
    settings = fileManager.loadSync();
  } catch (e) {
    Fimber.e("Error reading app settings.", ex: e);
    onAppLoadedActions.add((context) async {
      await showAlertDialog(
        context,
        title: "TriOS Settings Reset",
        content:
            "Your ${Constants.appName} settings have been reset."
            "\nThis may be due to an update or a broken settings file."
            "\n\nPlease check your settings. Your mods have not been affected."
            "\n\n\nError: \n$e",
      );
    });
  }

  // Show onboarding if crash reporting is not set.
  if (settings?.allowCrashReporting == null) {
    onAppLoadedActions.add((context) async {
      showDialog(
        context: context,
        builder: (context) => const OnboardingCarousel(),
        barrierDismissible: false,
      );
    });
  }

  // Show changelog notification if post-update.
  try {
    if (settings?.showChangelogNextLaunch == true) {
      onAppLoadedActions.add((context) async {
        toastification.showCustom(
          context: context,
          autoCloseDuration: Duration(milliseconds: 8000),
          builder: (context, item) => PostUpdateToast(item: item),
        );
      });
    }
  } catch (e) {
    Fimber.w("Error checking for changelog notification.", ex: e);
  }
  if (settings != null) {
    try {
      fileManager.writeSync(settings.copyWith(showChangelogNextLaunch: false));
    } catch (e) {
      Fimber.w("Error writing changelog notification setting.", ex: e);
    }
  }

  // Set up Sentry
  try {
    allowCrashReporting = settings?.allowCrashReporting ?? false;
    modifyLoggingSettings((s) => s.copyWith(allowSentryReporting: allowCrashReporting));
  } catch (e) {
    Fimber.w("Error reading crash reporting setting.", ex: e);
  }

  // Actually it's fine, just don't fuck up.
  // Don't use Sentry in debug mode, ever.
  // There's a max error limit and UI rendering errors send a million errors.
  // if (allowCrashReporting && kDebugMode == false) {
  if (allowCrashReporting) {
    try {
      await SentryFlutter.init(
        (options) {
          options = configureSentry(options, settings);
        },
        appRunner: () {
          Fimber.i("Sentry initialized.");
          _runTriOS(settings, withSentry: true);
        },
      );
    } catch (e) {
      Fimber.e("Error initializing Sentry.", ex: e);
      _runTriOS(settings, withSentry: false);
    }
  } else {
    _runTriOS(settings, withSentry: false);
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
    setWindowFrame(await _convertLogicalToPhysicalPixels(windowFrame));

    // If the window is off screen, move it to the first display.
    await _ensureWindowIsVisible();

    windowManager.waitUntilReadyToShow(
      WindowOptions(size: windowFrame.size, minimumSize: minSize),
      () async {
        await windowManager.show();
        await windowManager.focus();
        if (settings?.isMaximized ?? false) {
          windowManager.maximize();
        }
      },
    );
  } catch (e) {
    Fimber.e("Error restoring window position and size.", ex: e);
  }

  // Clean up old files.
  final filePatternsToClean = [
    logFileName,
    ScriptGenerator.SELF_UPDATE_FILE_NAME,
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

  runZonedGuarded(
    () {
      SelfUpdater.cleanUpOldUpdateFiles();
    },
    (error, stackTrace) {
      Fimber.w("Error cleaning up old self-update files.", ex: error);
    },
  );
}

// ignore: missing_provider_scope
void _runTriOS(Settings? appSettings, {required bool withSentry}) => runApp(
  RestartableApp(
    child: ConditionalWrap(
      condition: withSentry,
      wrapper: (appWidget) => SentryWidget(child: appWidget),
      child: ProviderScope(
        observers: shouldDebugRiverpod ? [RiverpodDebugObserver()] : [],
        child: ExcludeSemantics(
          excluding:
              Platform.isLinux &&
              appSettings?.enableAccessibilitySemanticsOnLinux != true,
          child: TriOSApp(),
        ),
      ),
    ),
  ),
);

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
        appSettings.select((value) => value.allowCrashReporting ?? false),
      )) {
        try {
          final mods = variants.orEmpty().toList();
          final variantInfo = mods
              .flatMap((mod) => mod.modVariants)
              .map(
                (v) =>
                    "${v.isEnabled(mods) ? "E" : "X"} ${v.modInfo.id} ${v.modInfo.version}",
              )
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
        child: AppShell(child: VramEstimatorPage()),
      ),
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
        if (isMaximized) {
          // If maximizing/maximized, we want to keep the non-maximized size the same
          // so that un-maximizing it doesn't result in a screen-sized window.
          return state.copyWith(isMaximized: isMaximized);
        } else {
          return state.copyWith(
            windowXPos: windowFrame.left,
            windowYPos: windowFrame.top,
            windowWidth: windowFrame.width,
            windowHeight: windowFrame.height,
            isMaximized: isMaximized,
          );
        }
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
