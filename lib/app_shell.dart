import 'dart:io';

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
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/dropdown_with_icon.dart';
import 'package:trios/widgets/lazy_indexed_stack.dart';
import 'package:trios/widgets/restartable_app.dart';
import 'package:trios/widgets/self_update_toast.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/tab_button.dart';
import 'package:trios/widgets/trios_app_icon.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  late TriOSTools _currentPage;

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

  void _changeTab(TriOSTools tab) {
    setState(() {
      _currentPage = tab;
    });

    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(defaultTool: _currentPage));
  }

  @override
  void initState() {
    super.initState();

    var defaultTool = TriOSTools.dashboard;
    try {
      defaultTool = ref.read(
          appSettings.select((value) => value.defaultTool ?? defaultTool));
    } catch (e) {
      Fimber.i("No default tool found in settings: $e");
    }
// Set the current tab to the index of the previously selected tool.
    try {
      _changeTab(defaultTool);
    } catch (e) {
      Fimber.e("Error setting default tool: $e");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
// Check for updates on launch and show toast if available.
        ref
            .watch(AppState.selfUpdate.notifier)
            .getLatestRelease()
            .then((latestRelease) {
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
    });

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
    final theme = Theme.of(context);

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
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 0, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Tooltip(
                            message: "Dashboard",
                            child: TabButton(
                              text: "Dash",
                              icon: const Icon(Icons.dashboard),
                              isSelected: _currentPage == TriOSTools.dashboard,
                              onPressed: () => _changeTab(TriOSTools.dashboard),
                            )),
                      ],
                    ),
                    TabButton(
                      text: "Mods",
                      icon: Transform.rotate(
                          angle: 0.7,
                          child: const SvgImageIcon(
                            "assets/images/icon-onslaught.svg",
                            height: 23,
                          )),
                      isSelected: _currentPage == TriOSTools.modManager,
                      onPressed: () => _changeTab(TriOSTools.modManager),
                    ),
                    TabButton(
                      text: "Profiles",
                      icon: const Tooltip(
                        message: "Mod Profiles (unfinished)",
                        child: SvgImageIcon(
                          "assets/images/icon-view-carousel.svg",
                          height: 23,
                        ),
                      ),
                      isSelected: _currentPage == TriOSTools.modProfiles,
                      onPressed: () => _changeTab(TriOSTools.modProfiles),
                    ),
                    TabButton(
                      text: "Logs",
                      icon: const Tooltip(
                        message: "$chipperTitle Log Viewer",
                        child: ImageIcon(
                          AssetImage("assets/images/chipper/icon.png"),
                          size: 22,
                        ),
                      ),
                      isSelected: _currentPage == TriOSTools.chipper,
                      onPressed: () => _changeTab(TriOSTools.chipper),
                    ),
                    const SizedBox(width: 4),
                    AnimatedPopupMenuButton<TriOSTools>(
                      icon: SvgImageIcon("assets/images/icon-toolbox.svg",
                          color: theme.iconTheme.color),
                      onSelected: (TriOSTools value) => _changeTab(value),
                      menuItems: const [
                        PopupMenuItem(
                            value: TriOSTools.vramEstimator,
                            child: Row(
                              children: [
                                SvgImageIcon("assets/images/icon-weight.svg"),
                                SizedBox(width: 8),
                                // Space between icon and text
                                Text("VRAM"),
                              ],
                            )),
                        PopupMenuItem(
                            value: TriOSTools.portraits,
                            child: Row(
                              children: [
                                SvgImageIcon(
                                    "assets/images/icon-account-box-outline.svg"),
                                SizedBox(width: 8),
                                // Space between icon and text
                                Text("Portraits"),
                              ],
                            )),
                        // PopupMenuItem(
                        //     text: "Portraits",
                        //     icon: const SvgImageIcon(
                        //         "assets/images/icon-account-box-outline.svg"),
                        //     page: TriOSTools.portraits),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 1,
                height: 24,
                child: Container(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) {
                var gameFolderPath =
                    ref.watch(AppState.gameFolder).valueOrNull?.path;
                return gameFolderPath == null
                    ? Container()
                    : Tooltip(
                        message: "Open Starsector folder",
                        child: IconButton(
                          icon: const SvgImageIcon(
                              "assets/images/icon-folder-game.svg"),
                          color: Theme.of(context).iconTheme.color,
                          onPressed: () {
                            OpenFilex.open(gameFolderPath);
                          },
                        ),
                      );
              }),
              if (logFilePath != null)
                Tooltip(
                  message: "${Constants.appName} log file",
                  child: IconButton(
                    icon:
                        const SvgImageIcon("assets/images/icon-file-debug.svg"),
                    color: Theme.of(context).iconTheme.color,
                    onPressed: () {
                      try {
                        launchUrlString(logFilePath!.toFile().normalize.path);
                      } catch (e, st) {
                        Fimber.e("Error opening log file: $e",
                            ex: e, stacktrace: st);
                      }
                    },
                  ),
                ),
              Tooltip(
                  message: "Settings",
                  child: IconButton(
                      // text: "Settings",
                      onPressed: () {
                        _changeTab(TriOSTools.settings);
                      },
                      color: _currentPage == TriOSTools.settings
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                      isSelected: _currentPage == TriOSTools.settings,
                      icon: const Icon(Icons.settings))),
              const SizedBox(
                width: 4,
              ),
              SizedBox(
                width: 1,
                height: 36,
                child: Container(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              const Spacer(),
              FilePermissionShield(ref: ref),
              const AdminPermissionShield(),
              const Spacer(),
              Tooltip(
                message: "${Constants.appName} Changelog",
                child: IconButton(
                  icon: const SvgImageIcon(
                      "assets/images/icon-bullhorn-variant.svg"),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () => showTriOSChangelogDialog(context,
                      showUnreleasedVersions: false),
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
                          LazyIndexedStack(
                            index: tabToolMap.values
                                .toList()
                                .indexOf(_currentPage),
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
          onDroppedLog: (_) => _changeTab(TriOSTools.chipper),
        ));
  }
}

class MenuOption {
  final String text;
  final Widget icon;
  final TriOSTools page;

  MenuOption({required this.text, required this.icon, required this.page});
}

class FilePermissionShield extends StatelessWidget {
  const FilePermissionShield({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final paths = [
      (
        description: 'vmparams file',
        isWritable:
            ref.watch(AppState.isVmParamsFileWritable).valueOrNull ?? false,
        path: ref.watch(AppState.vmParamsFile).valueOrNull?.path,
      ),
      if ((ref.watch(appSettings.select((s) => s.useJre23)) ?? false))
        (
          description: 'JRE 23 vmparams file',
          isWritable:
              ref.watch(AppState.isJre23VmparamsFileWritable).valueOrNull ??
                  false,
          path: ref.watch(AppState.jre23VmparamsFile).valueOrNull?.path,
        ),
    ];

    // Check if any paths are non-writable
    final hasNonWritablePaths = paths.any((path) => path.isWritable == false);

    // If all paths are writable, return an empty widget
    if (!hasNonWritablePaths) {
      return const SizedBox();
    }

    return Tooltip(
      message: "Admin permissions needed for some files."
          "\n${paths.joinToString(
        separator: "\n",
        transform: (path) =>
            "${path.isWritable ? "✅" : "❌"} ${path.description} is ${path.isWritable ? 'writable' : 'not writable'}."
            "\n    (${path.path ?? 'unknown path'}).",
      )}",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgImageIcon(
            "assets/images/icon-admin-shield.svg",
            color: ThemeManager.vanillaWarningColor,
          ),
          Text(
            "Check Permissions",
            style: TextStyle(
              color: ThemeManager.vanillaWarningColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPermissionShield extends StatelessWidget {
  const AdminPermissionShield({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool test = false;
    // Check if the app is running on Windows and as administrator
    if ((!Platform.isWindows || !windowsIsAdmin()) && !test) {
      return const SizedBox(); // Don't show anything if not on Windows or not Admin
    }

    return Tooltip(
      message:
          "Running as Administrator.\nDrag'n'drop will not work due to Windows limitations.",
      child: SvgImageIcon(
        "assets/images/icon-admin-shield-half.svg",
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
