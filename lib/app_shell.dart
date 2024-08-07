import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/dashboard/dashboard.dart';
import 'package:trios/portraits/portraits_viewer.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/trios/toasts/toast_manager.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/restartable_app.dart';
import 'package:trios/widgets/self_update_toast.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_app_icon.dart';

import 'about/about_page.dart';
import 'launcher/launcher.dart';
import 'main.dart';
import 'mod_manager/smol3.dart';
import 'mod_profiles/mod_profiles_page.dart';
import 'trios/app_state.dart';
import 'trios/drag_drop_handler.dart';

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
    2: TriOSTools.modProfiles,
    3: TriOSTools.vramEstimator,
    4: TriOSTools.chipper,
    // 5: TriOSTools.jreManager,
    5: TriOSTools.portraits,
    6: TriOSTools.settings,
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
    try {
      tabController.index = tabToolMap.keys
          .firstWhere((k) => tabToolMap[k] == defaultTool, orElse: () => 0);
    } catch (e) {
      Fimber.e("Error setting default tool: $e");
    }

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
                ref
                    .read(AppState.selfUpdate.notifier)
                    .updateSelf(latestRelease);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appSettings.select((s) => s.allowCrashReporting)) == null) {
        // show dialog asking for crash reporting permission
        _askUserForReportingPermission();
      }
    });
  }

  void _askUserForReportingPermission() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Crash Reporting"),
          content: Linkify(
            text:
                "${Constants.appName} can send crash/error reports to help me find and fix issues."
                "\n\nNothing identifiable or personal is ever sent."
                "\n\nInfo includes: app version, mod list, basic PC info (resolution, OS), randomly generated user id, and the crash details."
                "\nNot sent: IP address, language/region/zip, PC name, any file paths, etc."
                "\nExample of a report: https://i.imgur.com/k9E6zxO.png."
                "\n\nWould you like to enable crash reporting?",
            onOpen: (link) {
              OpenFilex.open(link.url);
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(appSettings.notifier).update(
                    (state) => state.copyWith(allowCrashReporting: true));
                RestartableApp.restartApp(context);
              },
              icon: const Icon(Icons.track_changes),
              label: const Text("Allow Reporting"),
            ),
            TextButton.icon(
              onPressed: () {
                ref.read(appSettings.notifier).update(
                    (state) => state.copyWith(allowCrashReporting: false));
                RestartableApp.restartApp(context);
              },
              icon:
                  const SvgImageIcon("assets/images/icon-incognito-circle.svg"),
              label: const Text("Keep Reporting Disabled"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabChildren = [
      const Padding(
        padding: EdgeInsets.all(4),
        child: Dashboard(),
      ),
      const Smol3(),
      const Padding(padding: EdgeInsets.all(8), child: ModProfilePage()),
      const Padding(padding: EdgeInsets.all(8), child: VramEstimatorPage()),
      const Padding(padding: EdgeInsets.all(8), child: ChipperApp()),
      // Platform.isWindows
      //     ? const Padding(padding: EdgeInsets.all(0), child: JreManager())
      //     : const Center(
      //         child: Text("Only supported on Windows for now, sorry.")),
      const Padding(padding: EdgeInsets.all(8), child: ImageGridScreen()),
      const Padding(
        padding: EdgeInsets.all(8),
        child: SettingsPage(),
      ),
    ];
    final scrollController = ScrollController();

    var isRulesHotReloadEnabled =
        ref.watch(appSettings.select((value) => value.isRulesHotReloadEnabled));

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    thickness: 10,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: scrollController,
                      child: SizedBox(
                        // width: 540,
                        child: TabBar(
                          controller: tabController,
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
                            Tab(
                                text: "Profiles",
                                icon: Tooltip(
                                  message: "Mod Profiles",
                                  child: Transform.rotate(
                                      angle: -0.7,
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
                                text: "Logs",
                                icon: Tooltip(
                                  message: "$chipperTitle Log Viewer",
                                  child: ImageIcon(AssetImage(
                                      "assets/images/chipper/icon.png")),
                                ),
                                iconMargin: EdgeInsets.zero),
                            // ConditionalWrap(
                            //     condition: !Platform.isWindows,
                            //     wrapper: (child) => Disable(
                            //         isEnabled: Platform.isWindows,
                            //         child: child),
                            //     child: const Tab(
                            //         text: "JREs",
                            //         icon: Tooltip(
                            //             message: "JRE Manager",
                            //             child: Icon(Icons.coffee)))),
                            const Tab(
                              text: "Portraits",
                              icon: Tooltip(
                                  message: "Replace Portraits",
                                  child: SvgImageIcon(
                                      "assets/images/icon-account-box-outline.svg")),
                            ),
                            const Tab(
                                text: "Settings",
                                icon: Tooltip(
                                    message: "Settings",
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 2),
                                      child: Icon(Icons.settings),
                                    )),
                                iconMargin: EdgeInsets.zero),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Spacer(),
              FilePermissionShield(ref: ref),
              // const Spacer(),
              Builder(builder: (context) {
                var gameFolderPath =
                    ref.watch(AppState.gameFolder).valueOrNull?.path;
                return gameFolderPath == null
                    ? Container()
                    : Tooltip(
                        message: "Open Starsector folder",
                        child: IconButton(
                          icon: const Icon(Icons.folder_open),
                          color: Theme.of(context).iconTheme.color,
                          onPressed: () {
                            OpenFilex.open(gameFolderPath);
                          },
                        ),
                      );
              }),
              Tooltip(
                message: "View Changelog",
                child: IconButton(
                  icon: const SvgImageIcon("assets/images/icon-log.svg"),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () => showTriOSChangelogDialog(context,
                      showUnreleasedVersions: false),
                ),
              ),
              Tooltip(
                message: "Open log file",
                child: IconButton(
                  icon: const SvgImageIcon("assets/images/icon-debug.svg"),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () {
                    OpenFilex.open(logFilePath);
                  },
                ),
              ),
              Tooltip(
                message: "About",
                child: IconButton(
                  icon: const SvgImageIcon("assets/images/icon-info.svg"),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationIcon: const TriOSAppIcon(),
                      applicationName: Constants.appTitle,
                      applicationVersion: "A Starsector toolkit\nby Wisp",
                      children: [const AboutPage()],
                    );
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
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                if (loggingError != null)
                  Text(loggingError.toString(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ThemeManager.vanillaErrorColor,
                          )),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Stack(
                        children: [
                          TabBarView(
                            controller: tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: tabChildren,
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: ToastDisplayer(),
                            ),
                          )
                        ],
                      )),
                ),
              ],
            ),
          ),
          onDroppedLog: (_) =>
              tabController.animateTo(TriOSTools.chipper.index),
        ));
  }
}

class FilePermissionShield extends StatelessWidget {
  const FilePermissionShield({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isVmParamsFileWritable =
        ref.watch(AppState.isVmParamsFileWritable).valueOrNull;
    final isJre23VmparamsFileWritable =
        (ref.watch(appSettings.select((s) => s.useJre23)) ?? false)
            ? (ref.watch(AppState.isJre23VmparamsFileWritable).valueOrNull ??
                false)
            : null;

    if (isVmParamsFileWritable != false &&
        isJre23VmparamsFileWritable != false) {
      return const SizedBox();
    }

    final warnings = <String>[];
    if (isVmParamsFileWritable == false) {
      warnings.add(
          "vmparams file is not writable (${ref.watch(AppState.vmParamsFile).valueOrNull?.path}).");
    }
    if (isJre23VmparamsFileWritable == false) {
      warnings.add(
          "JRE 23 vmparams file is not writable (${ref.watch(AppState.jre23VmparamsFile).valueOrNull?.path}).");
    }

    return Tooltip(
      message:
          "Admin permissions needed.${warnings.isNotEmpty ? "\n${warnings.join(", ")}" : ""}",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgImageIcon(
            "assets/images/icon-admin-shield.svg",
            color: ThemeManager.vanillaWarningColor,
          ),
          Text("Check Permissions",
              style: TextStyle(
                  color: ThemeManager.vanillaWarningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
