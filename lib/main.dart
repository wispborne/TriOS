import 'dart:io';

import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/pages/vram_estimator/vram_estimator.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/trios/MyTheme.dart';
import 'package:trios/trios/self_updater/script_generator.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settingsSaver.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/TriOSAppIcon.dart';
import 'package:trios/widgets/trios_toast.dart';
import 'package:window_size/window_size.dart';

import 'app_state.dart';
import 'main.mapper.g.dart' show initializeJsonMapper;

const version = "0.0.12";
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
  initializeJsonMapper();
  sharedPrefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(observers: [SettingSaver()], child: const TriOSApp()));
  setWindowTitle(appTitle);

  // Clean up old files.
  final filePatternsToClean = [logFileName, ScriptGenerator.SELF_UPDATE_FILE_NAME];
  Directory.current.list().listen((file) {
    if (file is File) {
      for (var pattern in filePatternsToClean) {
        if (file.path.toLowerCase().contains(pattern.toLowerCase())) {
          file.delete();
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class TriOSAppState extends ConsumerState<TriOSApp> {
  @override
  void initState() {
    super.initState();
    AppState.theme.addListener(() {
      setState(() {});
    });
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
        child: MaterialApp.router(
          title: appTitle,
          theme: lightTheme,
          themeMode: AppState.theme.currentTheme(),
          debugShowCheckedModeBanner: false,
          darkTheme: darkTheme,
          routerConfig: _router,
        ));
  }

  // Router config
  final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: pageHome,
              pageBuilder: (context, state) => const NoTransitionPage(
                    child: VramEstimatorPage(),
                  )),
          GoRoute(
            path: pageVramEstimator,
            pageBuilder: (context, state) => const NoTransitionPage(child: VramEstimatorPage()),
          ),
          GoRoute(
            path: pageChipper,
            pageBuilder: (context, state) => const NoTransitionPage(child: ChipperApp()),
          ),
          GoRoute(
            path: pageSettings,
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
          ),
        ]),
      ], builder: (context, state, navigationShell) => AppShell(child: navigationShell)),
    ],
  );
}

const String pageHome = "/";
const String pageVramEstimator = "/vram_estimator";
const String pageChipper = "/chipper";
const String pageSettings = "/settings";

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();

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

            if (ref.read(appSettings).shouldAutoUpdateOnLaunch) {
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
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: TriOSAppIcon(),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appTitle, style: Theme.of(context).textTheme.titleLarge),
                Text(appSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(mainAxisSize: MainAxisSize.max, children: [
                    InkWell(
                        child: const Column(children: [Text("VRAM Estimator"), Icon(Icons.scale)]),
                        onTap: () {
                          context.go(pageVramEstimator);
                        }),
                    InkWell(
                        child: const Column(
                            children: [Text("Chipper"), ImageIcon(AssetImage("assets/images/chipper/icon.png"))]),
                        onTap: () {
                          context.go(pageChipper);
                        }),
                    InkWell(
                        child: const Column(children: [Text("Settings"), Icon(Icons.settings)]),
                        onTap: () {
                          context.go(pageSettings);
                        }),
                  ]),
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
                message: "Hot reloading rules.csv.\nWatching ${ref.read(modRulesCsvs)?.length ?? 0} mods for changes.",
                textAlign: TextAlign.center,
                child: const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: RulesHotReload(),
                ),
              ),
              // ElevatedButton(
              //     onPressed: () {
              //       context.go(pageVramEstimator);
              //     },
              //     child: const Text("VRAM Estimator")),
              // ElevatedButton(
              //     onPressed: () {
              //       context.go(pageSettings);
              //     },
              //     child: const Text("Settings")),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.child,
        ));
  }
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       title: Row(
//         children: [
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
//             Text(widget.subtitle,
//                 style: Theme.of(context).textTheme.bodyMedium)
//           ]),
//           ElevatedButton(
//               onPressed: () {
//                 context.go("/$pageVramEstimator");
//               },
//               child: Text("VRAM Estimator")),
//           ElevatedButton(
//               onPressed: () {
//                 context.go("/$pageSettings");
//               },
//               child: Text("Settings")),
//         ],
//       ),
//     ),
//     body: Padding(
//       padding: EdgeInsets.all(16.0),
//       child: widget.child,
//     ),
//   );
// }
}
