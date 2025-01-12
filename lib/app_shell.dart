import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:open_filex/open_filex.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/dashboard/dashboard.dart';
import 'package:trios/modBrowser/mod_browser_page.dart';
import 'package:trios/mod_manager/mods_grid_page.dart';
import 'package:trios/models/version.dart';
import 'package:trios/portraits/portraits_viewer.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/trios/toasts/toast_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/vram_estimator/vram_estimator.dart';
import 'package:trios/weaponViewer/weaponPage.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/changelog_viewer.dart';
import 'package:trios/widgets/dropdown_with_icon.dart';
import 'package:trios/widgets/lazy_indexed_stack.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/self_update_toast.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/tab_button.dart';
import 'package:trios/widgets/trios_app_icon.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'about/about_page.dart';
import 'jre_manager/jre_manager_logic.dart';
import 'launcher/launcher.dart';
import 'main.dart';
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
  bool isNewGrid = true;
  final rightToolbarScrollController = ScrollController();

  final tabToolMap = {
    0: TriOSTools.dashboard,
    1: TriOSTools.modManager,
    2: TriOSTools.modProfiles,
    3: TriOSTools.vramEstimator,
    4: TriOSTools.chipper,
    // 5: TriOSTools.jreManager,
    5: TriOSTools.portraits,
    6: TriOSTools.weapons,
    7: TriOSTools.settings,
    8: TriOSTools.modBrowser,
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

    // WebView check
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      WebViewEnvironment.getAvailableVersion().then((availableVersion) {
        if (availableVersion != null) {
          var userDataFolder = Constants.configDataFolderPath.path;
          WebViewEnvironment.create(
                  settings: WebViewEnvironmentSettings(
                      userDataFolder: userDataFolder))
              .then((newWebViewEnvironment) {
            ref.read(webViewEnvironment.notifier).state = newWebViewEnvironment;
            Fimber.i(
                "WebView2 environment initialized. Data folder: $userDataFolder");
          }).onError((error, stackTrace) {
            Fimber.e("Error creating WebView2 environment: $error",
                ex: error, stacktrace: stackTrace);
          });
        }
      });
    }

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

    // Check for updates on launch and show toast if available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
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
                    context: ref.read(AppState.appContext),
                    builder: (context, item) =>
                        SelfUpdateToast(latestRelease, item));

                // if (ref.read(appSettings
                //     .select((value) => value.shouldAutoUpdateOnLaunch))) {
                //   ref
                //       .read(AppState.selfUpdate.notifier)
                //       .updateSelf(latestRelease);
                // }
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

    // Execute all actions that were added while the app was loading
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var action in onAppLoadedActions) {
        try {
          await action(context);
        } catch (e, stackTrace) {
          Fimber.e("Error executing onAppLoadedActions: $e",
              ex: e, stacktrace: stackTrace);
        }
      }

      onAppLoadedActions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set global Context, needs to be done next frame to avoid rebuilding and exploding everything
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(AppState.appContext) == null ||
          ref.read(AppState.appContext)?.mounted == false) {
        ref.read(AppState.appContext.notifier).state = context;
      }
    });

    final tabChildren = [
      const Padding(
        padding: EdgeInsets.all(4),
        child: Dashboard(),
      ),
      const ModsGridPage(),
      const Padding(padding: EdgeInsets.all(8), child: ModProfilePage()),
      const Padding(padding: EdgeInsets.all(8), child: VramEstimatorPage()),
      const Padding(padding: EdgeInsets.all(8), child: ChipperApp()),
      const Padding(padding: EdgeInsets.all(8), child: ImageGridScreen()),
      const WeaponPage(),
      const Padding(
        padding: EdgeInsets.all(8),
        child: SettingsPage(),
      ),
      const ModBrowserPage(),
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
                child: MovingTooltipWidget.text(
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
                        MovingTooltipWidget.text(
                            message: "Dashboard",
                            child: TabButton(
                              text: "Dash",
                              icon: const Icon(Icons.dashboard),
                              isSelected: _currentPage == TriOSTools.dashboard,
                              onPressed: () => _changeTab(TriOSTools.dashboard),
                            )),
                      ],
                    ),
                    MovingTooltipWidget.text(
                      message: "Mod Manager",
                      child: TabButton(
                        text: "Mods",
                        icon: Transform.rotate(
                            angle: 0.7,
                            child: SizedBox(
                              height: 23,
                              width: 23,
                              child: ScalableImageWidget.fromSISource(
                                si: ScalableImageSource.fromSI(DefaultAssetBundle.of(context), "assets/images/icon-onslaught.si", currentColor: Colors.red),
                                // height: 23,
                              ),
                            )),
                        isSelected: _currentPage == TriOSTools.modManager,
                        onPressed: () => _changeTab(TriOSTools.modManager),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: "Mod Profiles",
                      child: TabButton(
                        text: "Profiles",
                        icon: SvgImageIcon(
                          "assets/images/icon-view-carousel.svg",
                          height: 23,
                        ),
                        isSelected: _currentPage == TriOSTools.modProfiles,
                        onPressed: () => _changeTab(TriOSTools.modProfiles),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: "Browse online mods",
                      child: TabButton(
                        text: "Catalog",
                        icon: Icon(Icons.cloud_download),
                        isSelected: _currentPage == TriOSTools.modBrowser,
                        onPressed: () => _changeTab(TriOSTools.modBrowser),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: "$chipperTitle Log Viewer",
                      child: TabButton(
                        text: "Logs",
                        icon: ImageIcon(
                          AssetImage("assets/images/chipper/icon.png"),
                          size: 22,
                        ),
                        isSelected: _currentPage == TriOSTools.chipper,
                        onPressed: () => _changeTab(TriOSTools.chipper),
                      ),
                    ),
                    const SizedBox(width: 4),
                    MovingTooltipWidget.text(
                      message: "More tools",
                      child: AnimatedPopupMenuButton<TriOSTools>(
                        icon: SvgImageIcon("assets/images/icon-toolbox.svg",
                            color: theme.iconTheme.color),
                        onSelected: (TriOSTools value) => _changeTab(value),
                        menuItems: [
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
                              child: MovingTooltipWidget.text(
                                message: "Warning: spoilers!",
                                warningLevel: TooltipWarningLevel.warning,
                                child: Row(
                                  children: [
                                    SvgImageIcon(
                                        "assets/images/icon-account-box-outline.svg"),
                                    SizedBox(width: 8),
                                    // Space between icon and text
                                    Text("Portraits"),
                                  ],
                                ),
                              )),
                          PopupMenuItem(
                              value: TriOSTools.weapons,
                              child: MovingTooltipWidget.text(
                                message: "Warning: spoilers!",
                                warningLevel: TooltipWarningLevel.warning,
                                child: Row(
                                  children: [
                                    SvgImageIcon(
                                        "assets/images/icon-target.svg"),
                                    SizedBox(width: 8),
                                    // Space between icon and text
                                    Text("Weapons"),
                                  ],
                                ),
                              )),
                          // PopupMenuItem(
                          //     text: "Portraits",
                          //     icon: const SvgImageIcon(
                          //         "assets/images/icon-account-box-outline.svg"),
                          //     page: TriOSTools.portraits),
                        ],
                      ),
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
                    : MovingTooltipWidget.text(
                        message: "Open Starsector folder",
                        child: IconButton(
                          icon: const SvgImageIcon(
                              "assets/images/icon-folder-game.svg"),
                          color: Theme.of(context).iconTheme.color,
                          onPressed: () async {
                            if (Platform.isMacOS) {
                              // Hack for mac to reveal the Contents folder
                              // otherwise it runs the game.
                              try {
                                final process = await Process.start(
                                    'open', ["-R", "$gameFolderPath/Contents"]);
                                final result = await process.exitCode;
                                if (result != 0) {
                                  Fimber.e(
                                      "Error opening game folder: $result");
                                }
                              } catch (e, st) {
                                Fimber.e("Error opening game folder: $e",
                                    ex: e, stacktrace: st);
                              }
                            } else {
                              // Everybody else just opens the folder
                              OpenFilex.open(gameFolderPath);
                            }
                          },
                        ),
                      );
              }),
              if (logFilePath != null)
                MovingTooltipWidget.text(
                  message: "Open ${Constants.appName} log file folder",
                  child: IconButton(
                    icon:
                        const SvgImageIcon("assets/images/icon-file-debug.svg"),
                    color: Theme.of(context).iconTheme.color,
                    onPressed: () {
                      try {
                        logFilePath!
                            .toFile()
                            .normalize
                            .parent
                            .path
                            .openAsUriInBrowser();
                      } catch (e, st) {
                        Fimber.e("Error opening log file: $e",
                            ex: e, stacktrace: st);
                      }
                    },
                  ),
                ),
              MovingTooltipWidget.text(
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
              Expanded(
                child: Scrollbar(
                  controller: rightToolbarScrollController,
                  scrollbarOrientation: ScrollbarOrientation.top,
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: rightToolbarScrollController,
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilePermissionShield(),
                        const AdminPermissionShield(),
                        // const Spacer(),
                        MovingTooltipWidget.text(
                          message: "${Constants.appName} Changelog",
                          child: IconButton(
                            icon: const SvgImageIcon(
                                "assets/images/icon-bullhorn-variant.svg"),
                            color: Theme.of(context).iconTheme.color,
                            onPressed: () => showTriOSChangelogDialog(context,
                                lastestVersionToShow: Version.parse(Constants.version, sanitizeInput: false)),
                          ),
                        ),
                        MovingTooltipWidget.text(
                          message: "About",
                          child: IconButton(
                            icon: const SvgImageIcon(
                                "assets/images/icon-info.svg"),
                            color: Theme.of(context).iconTheme.color,
                            onPressed: () {
                              showAboutDialog(
                                context: context,
                                applicationIcon: const TriOSAppIcon(),
                                applicationName: Constants.appTitle,
                                applicationVersion:
                                    "A Starsector toolkit\nby Wisp",
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 700,
                                    ),
                                    child: const AboutPage(),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                        MovingTooltipWidget.text(
                          message: "Show donation popup",
                          child: IconButton(
                            icon: const SvgImageIcon(
                                "assets/images/icon-donate.svg"),
                            color: Theme.of(context).iconTheme.color,
                            onPressed: () {
                              // donate options
                              // Constants.patreonUrl.openAsUriInBrowser();
                              // Constants.kofiUrl.openAsUriInBrowser();
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Donations"),
                                      content: DonateView(),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Close")),
                                      ],
                                    );
                                  });
                            },
                          ),
                        ),
                        MovingTooltipWidget.text(
                          message:
                              "When enabled, modifying a mod's rules.csv will\nreload in-game rules as long as dev mode is enabled."
                              "\n\nrules.csv hot reload is ${isRulesHotReloadEnabled ? "enabled" : "disabled"}."
                              "\nClick to ${isRulesHotReloadEnabled ? "disable" : "enable"}.",
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                                ThemeManager.cornerRadius),
                            onTap: () => ref.read(appSettings.notifier).update(
                                (state) => state.copyWith(
                                    isRulesHotReloadEnabled:
                                        !isRulesHotReloadEnabled)),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: RulesHotReload(
                                  isEnabled: isRulesHotReloadEnabled),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class DonateView extends StatelessWidget {
  const DonateView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
              "TriOS, like SMOL before it, is a hobby that I do because I enjoy it, and because I enjoy giving to Starsector."
              "\nThey're the result of many hundreds of hours of coding, and I hope they have been useful (and even enjoyable) for you."
              "\n"
              "\nIf you feel like donating, thank you. If you can't donate but wish you were rich enough to just give money away, thank you anyway :)"
              "\nTake care of yourself,"
              "\n- Wisp",
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                ListTile(
                  title: const Text("Patreon"),
                  leading: SvgImageIcon(
                    "assets/images/icon-patreon.svg",
                    height: 20,
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    Constants.patreonUrl.openAsUriInBrowser();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("Ko-Fi"),
                  leading: Icon(Icons.coffee, size: 20),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    Constants.kofiUrl.openAsUriInBrowser();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuOption {
  final String text;
  final Widget icon;
  final TriOSTools page;

  MenuOption({required this.text, required this.icon, required this.page});
}

class FilePermissionShield extends ConsumerStatefulWidget {
  const FilePermissionShield({
    super.key,
  });

  @override
  ConsumerState<FilePermissionShield> createState() =>
      _FilePermissionShieldState();
}

class _FilePermissionShieldState extends ConsumerState<FilePermissionShield> {
  bool isStandardVmparamsWritable = false;
  bool areAllCustomJresWritable = false;
  List<String> customVmParamsFilesThatCannotBeWritten = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    // copied from RamChanger
    ref.listen(jreManagerProvider, (prev, next) async {
      final newState = next.valueOrNull;
      if (newState != null && prev?.valueOrNull != newState) {
        await refresh(newState);
      }
    });

    final usesCustomJre =
        ref.watch(jreManagerProvider).valueOrNull?.activeJre?.isCustomJre ??
            false;

    if (!_initialized) {
      return const SizedBox();
    }

    final paths = [
      (
        description: 'vmparams file',
        isWritable: isStandardVmparamsWritable ?? false,
        path: ref.watch(AppState.vmParamsFile).valueOrNull?.path,
      ),
      if (usesCustomJre)
        (
          description: 'JRE 23 vmparams file',
          isWritable: areAllCustomJresWritable ?? false,
          path: customVmParamsFilesThatCannotBeWritten
        ),
    ];

    // Check if any paths are non-writable
    final nonWritablePaths = paths.where((path) => path.isWritable == false);

    // If all paths are writable, return an empty widget
    if (nonWritablePaths.isEmpty) {
      return const SizedBox();
    }

    final isAlreadyAdmin = windowsIsAdmin();

    return MovingTooltipWidget.framed(
      tooltipWidget: RichText(
          text: TextSpan(
        children: [
          TextSpan(
            text: isAlreadyAdmin
                ? "Unable to find or modify file(s)."
                : "Right-click TriOS.exe and select 'Run as Administrator'.",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
              text: isAlreadyAdmin
                  ? "\nEnsure that they exist and are not read-only.\n"
                  : "\nTriOS may not be able to modify game files, otherwise.\n"),
          TextSpan(
              text: "\n${nonWritablePaths.joinToString(
            separator: "\n",
            transform: (path) => "❌ Unable to edit ${path.description}."
                "\n    (${path.path ?? 'unknown path'}).",
          )}")
        ],
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgImageIcon(
            "assets/images/icon-admin-shield.svg",
            color: ThemeManager.vanillaWarningColor,
          ),
          Text(
            isAlreadyAdmin ? "Warning" : "Must Run as Admin",
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

  Future<void> refresh(JreManagerState newState) async {
    customVmParamsFilesThatCannotBeWritten.clear();
    isStandardVmparamsWritable =
        await newState.standardActiveJre?.canWriteToVmParamsFile() ?? true;
    areAllCustomJresWritable = true;
    for (final customJre in newState.customInstalledJres) {
      if (!await customJre.canWriteToVmParamsFile()) {
        areAllCustomJresWritable = false;
        customVmParamsFilesThatCannotBeWritten
            .add(customJre.vmParamsFileRelativePath);
        break;
      }
    }
    setState(() {
      _initialized = true;
    });
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

    return MovingTooltipWidget.text(
      message:
          "Running as Administrator.\nDrag'n'drop will not work due to Windows security limits.",
      child: SvgImageIcon(
        "assets/images/icon-admin-shield-half.svg",
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
