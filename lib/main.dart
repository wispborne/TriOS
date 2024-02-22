import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:trios/pages/settings/settings_page.dart';
import 'package:trios/pages/vram_estimator/vram_estimator.dart';
import 'package:trios/self_updater/script_generator.dart';
import 'package:trios/self_updater/self_updater.dart';
import 'package:trios/settings/settingsSaver.dart';
import 'package:trios/utils/extensions.dart';
import 'package:window_size/window_size.dart';

import 'main.mapper.g.dart' show initializeJsonMapper;

const version = "0.0.4";
const appTitle = "TriOS v$version";
String appSubtitle =
    ["Corporate Toolkit", "by Wisp", "Hegemony Tolerated", "TriTachyon Approved", "Powered by Moloch"].random();

configureLogging() {
  const logLevels = kDebugMode ? ["V", "D", "I", "W", "E"] : ["I", "W", "E"];
  Fimber.plantTree(DebugTree.elapsed(logLevels: logLevels, useColors: true));
  Fimber.plantTree(SizeRollingFileTree(DataSize.mega(10), filenamePrefix: "TriOS_log.", filenamePostfix: ".log"));
}

void main() async {
  configureLogging();
  Fimber.i("$appTitle logging started.");
  Fimber.i("Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}.");
  initializeJsonMapper();

  runApp(ProviderScope(observers: [SettingSaver()], child: const TriOSApp()));
  setWindowTitle(appTitle);

  // Clean up old self-update script file.
  Directory.current.list().listen((file) {
    if (file is File && file.path.toLowerCase().contains(ScriptGenerator.SELF_UPDATE_FILE_NAME.toLowerCase())) {
      file.delete();
    }
  });

  // On release builds, check for updates on launch and install if available.
  if (!kDebugMode) {
    try {
      var latestRelease = await SelfUpdater.getLatestRelease();

      if (latestRelease != null) {
        final hasNewVersion = SelfUpdater.hasNewVersion(latestRelease);
        if (hasNewVersion) {
          Fimber.i("New version available: ${latestRelease.tagName}");
          final updateInfo = SelfUpdateInfo(
              version: latestRelease.tagName,
              url: latestRelease.assets.first.browserDownloadUrl,
              releaseNote: latestRelease.body);
          Fimber.i("Update info: $updateInfo");
          SelfUpdater.update(latestRelease);
        }
      }
    } catch (e, s) {
      Fimber.e("Error checking for updates: $e", ex: e, stacktrace: s);
    }
  }
}

class TriOSApp extends ConsumerStatefulWidget {
  const TriOSApp({super.key});

  @override
  TriOSAppState createState() => TriOSAppState();
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class TriOSAppState extends ConsumerState<TriOSApp> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        // dark: Themes.starsectorLauncher,
        initial: AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp.router(
              title: appTitle,
              theme: theme,
              debugShowCheckedModeBanner: false,
              darkTheme: darkTheme,
              routerConfig: _router,
            ));
  }

  final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: pageHome,
        builder: (context, state) => const AppShell(child: VramEstimatorPage()),
      ),
      GoRoute(
        path: pageVramEstimator,
        builder: (context, state) => const AppShell(child: VramEstimatorPage()),
      ),
      GoRoute(
        path: pageSettings,
        builder: (context, state) => const AppShell(child: SettingsPage()),
      ),
    ],
  );
}

const String pageHome = "/";
const String pageVramEstimator = "/vram_estimator";
const String pageSettings = "/settings";

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget? child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Directory? modsFolder;
  List<File> modRulesCsvs = [];

  // @override
  // void initState() {
  //   super.initState();
  //
  //   SharedPreferences.getInstance().then((prefs) {
  //     _prefs = prefs;
  //     setState(() {
  //       gamePath =
  //           Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
  //       if (!gamePath!.existsSync()) {
  //         gamePath = Directory(defaultGamePath()!.path);
  //       }
  //     });
  //     _updatePaths();
  //   });
  // }
  //
  // _do() async {
  //   _prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     gamePath =
  //         // Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
  //         Directory(defaultGamePath()!.path);
  //   });
  //   _updatePaths();
  // }
  //
  // _updatePaths() {
  //   setState(() {
  //     gameFiles = gameFilesPath(gamePath!)!;
  //     vanillaRulesCsv = getVanillaRulesCsvInGameFiles(gameFiles!);
  //     modsFolder = modFolderPath(gamePath!)!;
  //     modRulesCsvs = getAllRulesCsvsInModsFolder(modsFolder!);
  //   });
  // }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SvgPicture.asset(("assets/images/telos_faction_crest.svg"),
                    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                    width: 48,
                    height: 48),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appTitle, style: Theme.of(context).textTheme.titleLarge),
                Text(appSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))
              ]),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(tabs: [
                    Tab(text: "VRAM Estimator"),
                    Tab(text: "Settings"),
                  ]),
                ),
              )
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
        body: const Padding(
            padding: EdgeInsets.all(16.0),
            // child: widget.child,
            child: TabBarView(
              children: [
                VramEstimatorPage(),
                SettingsPage(),
              ],
            )),
      ),
    );
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
