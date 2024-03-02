import 'dart:io';

import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/widgets/TriOSAppIcon.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_toast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app_state.dart';
import 'chipper/views/chipper_dropper.dart';
import 'jre_manager/jre_manager.dart';
import 'main.mapper.g.dart' show initializeJsonMapper;

const version = "0.0.18";
const appName = "TriOS";
const appTitle = "$appName v$version";
String appSubtitle = [
  "Corporate Toolkit",
  "by Wisp",
  "Hegemony Tolerated",
  "TriTachyon Approved",
  "Powered by Moloch",
  "Prerelease"
].random();

void main() async {
  configureLogging();
  Fimber.i("$appTitle logging started.");
  Fimber.i("Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}.");
  FlutterError.onError = (details) {
    Fimber.e("${details.exceptionAsString()}\n${details.stack}", ex: details.exception, stacktrace: details.stack);
  };
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  initializeJsonMapper();
  sharedPrefs = await SharedPreferences.getInstance();

  runApp(const ProviderScope(observers: [], child: TriOSApp()));
  setWindowTitle(appTitle);

  // Restore window position and size
  final settings = readAppSettings();
  if (settings != null && settings.windowWidth != null && settings.windowHeight != null) {
    setWindowFrame(Rect.fromLTWH(
        settings.windowXPos ?? 0, settings.windowYPos ?? 0, settings.windowWidth ?? 800, settings.windowHeight ?? 600));
    if (settings.isMaximized ?? false) {
      windowManager.maximize();
    }
  }

  // Clean up old files.
  final filePatternsToClean = [logFileName, ScriptGenerator.SELF_UPDATE_FILE_NAME];
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
    var material3 = AppState.theme.isMaterial3();

    final starsectorSwatch = StarsectorSwatch();
    var swatch = switch (DateTime.now().month) {
      DateTime.october => HalloweenSwatch(),
      DateTime.december => XmasSwatch(),
      _ => starsectorSwatch
    };

    final seedColor = swatch.primary;

    // Dark theme
    var darkThemeBase = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark), useMaterial3: material3);
    final darkTheme = darkThemeBase.copyWith(
        colorScheme: darkThemeBase.colorScheme.copyWith(
          primary: swatch.primary,
          secondary: swatch.secondary,
          tertiary: swatch.tertiary,
        ),
        scaffoldBackgroundColor: swatch.background,
        dialogBackgroundColor: swatch.background,
        cardColor: swatch.card,
        appBarTheme: darkThemeBase.appBarTheme.copyWith(backgroundColor: swatch.card),
        floatingActionButtonTheme: darkThemeBase.floatingActionButtonTheme
            .copyWith(backgroundColor: swatch.primary, foregroundColor: darkThemeBase.colorScheme.surface),
        textTheme:
            darkThemeBase.textTheme.copyWith(bodyMedium: darkThemeBase.textTheme.bodyMedium?.copyWith(fontSize: 16)));

    // Light theme
    var lightThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
      useMaterial3: material3,
    );
    final lightTheme = lightThemeBase.copyWith(
        colorScheme: lightThemeBase.colorScheme.copyWith(
            primary: starsectorSwatch.primary,
            secondary: starsectorSwatch.secondary,
            tertiary: starsectorSwatch.tertiary),
        textTheme:
            lightThemeBase.textTheme.copyWith(bodyMedium: lightThemeBase.textTheme.bodyMedium?.copyWith(fontSize: 16)),
        snackBarTheme: const SnackBarThemeData());

    return ToastificationConfigProvider(
        config: const ToastificationConfig(
          alignment: Alignment.bottomRight,
        ),
        child: MaterialApp(
          title: appTitle,
          theme: lightTheme,
          themeMode: AppState.theme.currentTheme(),
          debugShowCheckedModeBanner: false,
          darkTheme: darkTheme,
          home: const AppShell(child: VramEstimatorPage()),
        ));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _saveWindowPosition() async {
    final windowFrame = await windowManager.getBounds();
    final isMaximized = await windowManager.isMaximized();
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

  @override
  void onWindowEvent(String eventName) {
    // Could avoid saving on every event but it's probably fine.
    _saveWindowPosition();
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
  late TabController tabController;

  final tabToolMap = {
    0: TriOSTools.vramEstimator,
    1: TriOSTools.chipper,
    2: TriOSTools.jreManager,
    3: null,
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
        ref.read(appSettings.notifier).update((state) => state.copyWith(defaultTool: tabToolMap[tabController.index]!));
      }
    });

    final defaultTool = ref.read(appSettings.select((value) => value.defaultTool));
    if (defaultTool != null) {
      // Using index is a bit of a hack but if I change the tab order then people will simply fix it with a click.
      tabController.index = tabToolMap.keys.firstWhere((k) => tabToolMap[k] == defaultTool, orElse: () => 0);
    }

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

            toastification.showCustom(context: context, builder: (context, item) => TriOSToast(latestRelease, item));

            if (ref.read(appSettings.select((value) => value.shouldAutoUpdateOnLaunch))) {
              SelfUpdater.update(latestRelease, downloadProgress: (bytesReceived, contentLength) {
                final progress = bytesReceived / contentLength;
                ref.read(selfUpdateDownloadProgress.notifier).update((_) => progress);
              });
            }
          }
        }
      } catch (e, s) {
        Fimber.e("Error checking for updates: $e", ex: e, stacktrace: s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabChildren = [
      VramEstimatorPage(),
      ChipperApp(),
      JreManager(),
      SettingsPage(),
    ];

    var isRulesHotReloadEnabled = ref.watch(appSettings.select((value) => value.isRulesHotReloadEnabled));
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Stack(children: [
                  const Blur(child: TriOSAppIcon(), blurX: 8, blurY: 8)
                      .animate(onComplete: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: const Duration(seconds: 5))
                      .then()
                      .fadeOut(duration: const Duration(seconds: 5)),
                  const TriOSAppIcon(),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appTitle, style: Theme.of(context).textTheme.titleLarge),
                Text(appSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(tabs: const [
                    // TODO IF YOU CHANGE THESE, UPDATE tabToolMap!
                    Tab(text: "VRAM Estimator", icon: SvgImageIcon("assets/images/weight.svg")),
                    Tab(
                        text: chipperTitle,
                        icon: ImageIcon(AssetImage("assets/images/chipper/icon.png")),
                        iconMargin: EdgeInsets.zero),
                    Tab(text: "JRE Manager", icon: SvgImageIcon("assets/images/weight.svg")),
                    Tab(text: "Settings", icon: Icon(Icons.settings), iconMargin: EdgeInsets.zero),
                  ], controller: tabController),
                ),
              ),
              IconButton(
                tooltip: AppState.theme.currentTheme() == ThemeMode.dark
                    ? "THE SUN THE SUN THE SUN\nTHE SUN THE SUN THE SUN\nTHE SUN THE SUN THE SUN"
                    : "Dark theme",
                onPressed: () => AppState.theme.switchThemes(context),
                icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night),
              ),
              IconButton(
                  tooltip: "Switch density",
                  onPressed: () => AppState.theme.switchMaterial(),
                  icon: Icon(AppState.theme.isMaterial3() ? Icons.view_compact : Icons.view_cozy)),
              Tooltip(
                message:
                    "When enabled, modifying a mod\'s rules.csv will\nreload in-game rules as long as dev mode is enabled."
                    "\n\nrules.csv hot reload is ${isRulesHotReloadEnabled ? "enabled" : "disabled"}."
                    "\nClick to ${isRulesHotReloadEnabled ? "disable" : "enable"}.",
                textAlign: TextAlign.center,
                child: InkWell(
                  borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                  onTap: () => ref
                      .read(appSettings.notifier)
                      .update((state) => state.copyWith(isRulesHotReloadEnabled: !isRulesHotReloadEnabled)),
                  child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: RulesHotReload(isEnabled: isRulesHotReloadEnabled)),
                ),
              ),
            ],
          ),
        ),
        body: ChipperDropper(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBarView(
                controller: tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: tabChildren,
              )),
          onDropped: (_) => tabController.animateTo(1),
        ));
  }
}
