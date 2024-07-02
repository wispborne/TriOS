import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/dashboard/dashboard.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/trios/toasts/download_toast_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/self_update_toast.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_app_icon.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'jre_manager/jre_manager.dart';
import 'launcher/launcher.dart';
import 'mod_manager/smol3.dart';
import 'models/download_progress.dart';
import 'trios/app_state.dart';
import 'trios/drag_drop_handler.dart';

Object? loggingError;

void main() async {
  try {
    print("Initializing TriOS logging framework...");
    configureLogging();
    Fimber.i("${Constants.appTitle} logging started.");
    Fimber.i(
        "Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}.");
    FlutterError.onError = (details) {
      Fimber.e("${details.exceptionAsString()}\n${details.stack}",
          ex: details.exception, stacktrace: details.stack);
    };
  } catch (ex) {
    print("Error initializing logging. $ex");
    loggingError = ex;
  }
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
  } catch (ex) {
    Fimber.e("Error initializing!", ex: ex);
  }
  try {
    // SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  } catch (e) {
    Fimber.e(
        "Error initializing shared prefs.\nDelete `%APPDATA%/org.wisp/TriOS/shared_preferences.json\n(or look here for MacOS/Linux: https://pub.dev/packages/shared_preferences#storage-location-by-platform).",
        ex: e);
  }

  runApp(const ProviderScope(observers: [], child: TriOSApp()));
  setWindowTitle(Constants.appTitle);
  const minSize = Size(900, 600);

  try {
// Restore window position and size
    final settings = readAppSettings();
    Rect windowFrame = Rect.fromLTWH(
        settings?.windowXPos ?? 0,
        settings?.windowYPos ?? 0,
        settings?.windowWidth ?? 800,
        settings?.windowHeight ?? 600);
    setWindowFrame(windowFrame);
    if (settings?.isMaximized ?? false) {
      windowManager.maximize();
    }

    windowManager.waitUntilReadyToShow(
        WindowOptions(size: windowFrame.size, minimumSize: minSize), () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    Fimber.e("Error restoring window position and size.", ex: e);
  }
// Clean up old files.
  final filePatternsToClean = [
    logFileName,
    ScriptGenerator.SELF_UPDATE_FILE_NAME
  ];
  try {
    Directory.current.list().listen((file) {
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
}

class TriOSApp extends ConsumerStatefulWidget {
  const TriOSApp({super.key});

  @override
  TriOSAppState createState() => TriOSAppState();
}

class TriOSAppState extends ConsumerState<TriOSApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    AppState.theme.addListener(() {
      setState(() {});
    });

    windowManager.addListener(this);
// loadDefaultLog(ref);
  }

  @override
  Widget build(BuildContext context) {
// Let's only manage one theme.
    var material3 = true; //AppState.theme.isMaterial3();

// final starsectorSwatch = StarsectorTriOSTheme();
// var swatch = switch (DateTime.now().month) {
//   DateTime.october => HalloweenTriOSTheme(),
//   DateTime.december => XmasTriOSTheme(),
//   _ => starsectorSwatch
// };
    final currentTheme = AppState.theme.currentThemeData();

    return MaterialApp(
      title: Constants.appTitle,
      theme: currentTheme,
      themeMode: AppState.theme.currentThemeBrightness(),
      debugShowCheckedModeBanner: false,
      darkTheme: currentTheme,
      home: const ToastificationConfigProvider(
          config: ToastificationConfig(
            alignment: Alignment.bottomRight,
            animationDuration: Duration(milliseconds: 200),
            itemWidth: 500,
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
// Could avoid saving on every event but it's probably fine.
    if (eventName != "blur" &&
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

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final tabToolMap = {
    0: TriOSTools.dashboard,
    1: TriOSTools.modManager,
    2: TriOSTools.vramEstimator,
    3: TriOSTools.chipper,
    4: TriOSTools.jreManager,
    5: null,
  };

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: tabToolMap.length,
      vsync: this,
      animationDuration: const Duration(milliseconds: 0),
    );
    tabController.addListener(() {
      if (tabToolMap[tabController.index] != null) {
        ref.read(appSettings.notifier).update((state) =>
            state.copyWith(defaultTool: tabToolMap[tabController.index]!));
      }
    });

    var defaultTool = TriOSTools.dashboard;
    try {
      defaultTool = ref.read(
          appSettings.select((value) => value.defaultTool ?? defaultTool));
    } catch (e) {
      Fimber.i("No default tool found in settings: $e");
    }
// Set the current tab to the index of the previously selected tool.
    tabController.index = tabToolMap.keys
        .firstWhere((k) => tabToolMap[k] == defaultTool, orElse: () => 0);

    try {
// Check for updates on launch and show toast if available.
      SelfUpdater.getLatestRelease().then((latestRelease) {
        try {
          if (latestRelease != null) {
            final hasNewVersion = SelfUpdater.hasNewVersion(latestRelease);
            if (hasNewVersion) {
              Fimber.i("New version available: ${latestRelease.tagName}");
              final updateInfo = SelfUpdateInfo(
                  version: latestRelease.tagName,
                  url: latestRelease.assets.first.browserDownloadUrl,
                  releaseNote: latestRelease.body);
              Fimber.i("Update info: $updateInfo");

              toastification.showCustom(
                  context: context,
                  builder: (context, item) =>
                      SelfUpdateToast(latestRelease, item));

              if (ref.read(appSettings
                  .select((value) => value.shouldAutoUpdateOnLaunch))) {
                SelfUpdater.update(latestRelease,
                    downloadProgress: (bytesReceived, contentLength) {
                  ref.read(AppState.selfUpdateDownloadProgress.notifier).update(
                      (_) => DownloadProgress(bytesReceived, contentLength,
                          isIndeterminate: false));
                });
              }
            }
          }
        } catch (e, s) {
          Fimber.e("Error checking for updates: $e", ex: e, stacktrace: s);
        }
      });
    } catch (e, st) {
      Fimber.e("Error checking for updates: $e", ex: e, stacktrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabChildren = [
      const Padding(
        padding: EdgeInsets.all(4),
        child: Dashboard(),
      ),
      const Smol3(),
      const Padding(padding: EdgeInsets.all(8), child: VramEstimatorPage()),
      const Padding(padding: EdgeInsets.all(8), child: ChipperApp()),
      Platform.isWindows
          ? const Padding(padding: EdgeInsets.all(0), child: JreManager())
          : const Center(
              child: Text("Only supported on Windows for now, sorry.")),
      const Padding(
        padding: EdgeInsets.all(4),
        child: SettingsPage(),
      ),
    ];

    var isRulesHotReloadEnabled =
        ref.watch(appSettings.select((value) => value.isRulesHotReloadEnabled));

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const DownloadToastDisplayer(),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Tooltip(
                  message: Constants.appSubtitle,
                  child: const Stack(children: [
// if (ref.watch(AppState.isWindowFocused))
                    Opacity(
                      opacity: 0.8,
                      child: Blur(
                        blurX: 10, // 8 for animation
                        blurY: 10, // 8 for animation
                        child: TriOSAppIcon(),
                      ),
                    ),
// .animate(onComplete: (c) => c.repeat(reverse: true))
// .fadeIn(duration: const Duration(seconds: 5))
// .then()
// .fadeOut(
//   duration: const Duration(seconds: 5),
// ),
                    TriOSAppIcon(),
                  ]),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Constants.appName,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text("v${Constants.version}",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12))
                      ])),
              const Launcher(),
              SizedBox(
                width: 500,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: TabBar(
                    isScrollable: true,
                    // Makes tabs fit to content width instead of all same.
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      // TODO IF YOU CHANGE THESE, UPDATE tabToolMap!
                      const Tab(
                          text: "Dashboard",
                          icon: Tooltip(
                              message: "Dashboard",
                              child: Icon(Icons.dashboard))),
                      Tab(
                          text: "Mods",
                          icon: Tooltip(
                            message: "Mods",
                            child: Transform.rotate(
                                angle: 0.7,
                                child: const SvgImageIcon(
                                  "assets/images/icon-onslaught.svg",
                                  height: 23,
                                )),
                          )),
                      const Tab(
                          text: "VRAM",
                          icon: Tooltip(
                              message: "VRAM Estimator",
                              child: SvgImageIcon(
                                  "assets/images/icon-weight.svg"))),
                      const Tab(
                          text: chipperTitle,
                          icon: Tooltip(
                            message: "$chipperTitle Log Viewer",
                            child: ImageIcon(
                                AssetImage("assets/images/chipper/icon.png")),
                          ),
                          iconMargin: EdgeInsets.zero),
                      ConditionalWrap(
                          condition: !Platform.isWindows,
                          wrapper: (child) => Disable(
                              isEnabled: Platform.isWindows, child: child),
                          child: const Tab(
                              text: "JREs",
                              icon: Tooltip(
                                  message: "JRE Manager",
                                  child: Icon(Icons.coffee)))),
                      const Tab(
                          text: "Settings",
                          icon: Tooltip(
                              message: "Settings", child: Icon(Icons.settings)),
                          iconMargin: EdgeInsets.zero),
                    ],
                    controller: tabController,
                  ),
                ),
              ),
              // Spacer(),
              // const Text("|"),
              const Spacer(),
              Tooltip(
                message: "View Changelog",
                child: IconButton(
                  icon: const SvgImageIcon("assets/images/icon-log.svg"),
                  onPressed: () => showTriOSChangelogDialog(context,
                      showUnreleasedVersions: false),
                ),
              ),
              Tooltip(
                message: "Open log file",
                child: IconButton(
                  icon: const SvgImageIcon("assets/images/icon-debug.svg"),
                  onPressed: () {
                    OpenFilex.open(logFilePath);
                  },
                ),
              ),
              Tooltip(
                message:
                    "When enabled, modifying a mod's rules.csv will\nreload in-game rules as long as dev mode is enabled."
                    "\n\nrules.csv hot reload is ${isRulesHotReloadEnabled ? "enabled" : "disabled"}."
                    "\nClick to ${isRulesHotReloadEnabled ? "disable" : "enable"}.",
                textAlign: TextAlign.center,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(ThemeManager.cornerRadius),
                  onTap: () => ref.read(appSettings.notifier).update((state) =>
                      state.copyWith(
                          isRulesHotReloadEnabled: !isRulesHotReloadEnabled)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: RulesHotReload(isEnabled: isRulesHotReloadEnabled),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: DragDropHandler(
          child: Column(
            children: [
              if (loggingError != null)
                Text(loggingError.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: vanillaErrorColor,
                        )),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: TabBarView(
                      controller: tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: tabChildren,
                    )),
              ),
            ],
          ),
          onDroppedLog: (_) =>
              tabController.animateTo(TriOSTools.chipper.index),
        ));
  }
}
