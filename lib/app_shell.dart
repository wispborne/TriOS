import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show WebViewEnvironment, WebViewEnvironmentSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/catalog/mod_browser_page.dart';
import 'package:trios/chipper/chipper_app.dart';
import 'package:trios/dashboard/dashboard.dart';
import 'package:trios/faction_viewer/faction_viewer_page.dart';
import 'package:trios/hullmod_viewer/hullmods_page.dart';
import 'package:trios/mod_manager/mods_grid_page.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/portraits/portraits_page.dart';
import 'package:trios/ship_viewer/ships_page.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/toolbar/app_sidebar.dart';
import 'package:trios/toolbar/compact_top_bar.dart';
import 'package:trios/toolbar/full_top_bar.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/navigation_request.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/settings/settings_page.dart';
import 'package:trios/trios/activity_panel/activity_panel.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/toasts/toast_manager.dart';
import 'package:trios/trios/toasts/widgets/self_update_toast.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/weapon_viewer/weapons_page.dart';
import 'package:trios/widgets/lazy_indexed_stack.dart';

import 'main.dart';
import 'mod_profiles/mod_profiles_page.dart';
import 'tips/tips_page.dart';
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
  bool _isResizeHandleHovered = false;
  final rightToolbarScrollController = ScrollController();

  final tabToolMap = {
    0: TriOSTools.dashboard,
    1: TriOSTools.modManager,
    2: TriOSTools.modProfiles,
    3: TriOSTools.vramEstimator,
    4: TriOSTools.chipper,
    5: TriOSTools.portraits,
    6: TriOSTools.ships,
    7: TriOSTools.weapons,
    8: TriOSTools.hullmods,
    9: TriOSTools.factions,
    10: TriOSTools.settings,
    11: TriOSTools.catalog,
    12: TriOSTools.tips,
  };

  late final toolToIndexMap = tabToolMap.map((k, v) => MapEntry(v, k));

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
                  userDataFolder: userDataFolder,
                ),
              )
              .then((newWebViewEnvironment) {
                ref.read(webViewEnvironment.notifier).state =
                    newWebViewEnvironment;
                Fimber.i(
                  "WebView2 environment initialized. Data folder: $userDataFolder",
                );
              })
              .onError((error, stackTrace) {
                Fimber.w(
                  "Error creating WebView2 environment: $error",
                  ex: error,
                  stacktrace: stackTrace,
                );
              });
        }
      });
    }

    var defaultTool = TriOSTools.dashboard;
    try {
      defaultTool = ref.read(
        appSettings.select((value) => value.defaultTool ?? defaultTool),
      );
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
    // Self-update is disabled on macOS due to Gatekeeper/code signing issues.
    if (!Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ref.watch(AppState.selfUpdate.notifier).getLatestRelease().then((
            latestRelease,
          ) {
            try {
              if (latestRelease != null) {
                final hasNewVersion = SelfUpdater.hasNewVersion(latestRelease);
                if (hasNewVersion) {
                  Fimber.i("New version available: ${latestRelease.tagName}");
                  final updateInfo = SelfUpdateInfo(
                    version: latestRelease.tagName,
                    url: latestRelease.assets.first.browserDownloadUrl,
                    releaseNote: latestRelease.body,
                  );
                  Fimber.i("Update info: $updateInfo");

                  toastification.showCustom(
                    context: ref.read(AppState.appContext),
                    builder: (context, item) =>
                        SelfUpdateToast(latestRelease, item),
                  );

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
    }

    // Execute all actions that were added while the app was loading
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var action in onAppLoadedActions) {
        try {
          await action(context);
        } catch (e, stackTrace) {
          Fimber.e(
            "Error executing onAppLoadedActions: $e",
            ex: e,
            stacktrace: stackTrace,
          );
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

    // Eagerly initialize mod records (and its dependency, the catalog) so data
    // is available for the mod-info dialog even before the Catalog page is opened.
    ref.watch(modRecordsStore);

    ref.listen(appSettings.select((s) => s.windowScaleFactor), (_, newValue) {
      ScaledWidgetsFlutterBinding.instance.scaleFactor = (_) => newValue;
      Fimber.i("Scale factor changed to $newValue");
    });

    ref.listen<NavigationRequest?>(AppState.navigationRequest, (
      previous,
      next,
    ) {
      if (next != null) {
        _changeTab(next.destination);
        ref.read(AppState.navigationRequest.notifier).state = null;
        if (next.highlightKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(AppState.activeHighlightKey.notifier).state =
                next.highlightKey;
          });
        }
      }
    });

    final savedScaleFactor = ref.read(appSettings).windowScaleFactor;
    ScaledWidgetsFlutterBinding.instance.scaleFactor = (_) => savedScaleFactor;
    Fimber.i("Scale factor set to $savedScaleFactor");

    final tabChildren = [
      const Padding(padding: EdgeInsets.all(4), child: Dashboard()),
      const ModsGridPage(),
      ModProfilePage(pagePadding: 8),
      const VramEstimatorPage(),
      const ChipperApp(pagePadding: 8),
      const PortraitsPage(),
      const ShipsPage(),
      const WeaponsPage(),
      const HullmodsPage(),
      const FactionViewerPage(),
      const SettingsPage(pagePadding: 8.0),
      const CatalogPage(pagePadding: .all(8)),
      const TipsPage(),
    ];

    final useTopToolbar = ref.watch(
      appSettings.select((value) => value.useTopToolbar),
    );

    final body = _buildBody(context, tabChildren);

    if (useTopToolbar) {
      return _buildTopToolbarLayout(context, body);
    } else {
      return _buildSidebarLayout(context, body);
    }
  }

  Widget _buildBody(BuildContext context, List<Widget> tabChildren) {
    return DragDropHandler(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            if (loggingError != null)
              Text(
                loggingError.toString(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TriOSThemeConstants.vanillaErrorColor,
                ),
              ),
            Expanded(
              child: () {
                final isOpen = ref.watch(
                  appSettings.select((s) => s.isActivityPanelOpen),
                );
                final isPinned =
                    ref.watch(appSettings.select((s) => s.activityPanelMode)) ==
                    ActivityPanelMode.pinned;

                return Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          LazyIndexedStack(
                            index: toolToIndexMap[_currentPage] ?? 0,
                            children: tabChildren,
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: ToastDisplayer(),
                            ),
                          ),
                          if (!isPinned) ...[
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !isOpen,
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(appSettings.notifier)
                                      .update(
                                        (s) => s.copyWith(
                                          isActivityPanelOpen: false,
                                        ),
                                      ),
                                  behavior: HitTestBehavior.opaque,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 4,
                              bottom: 8,
                              child: IgnorePointer(
                                ignoring: !isOpen,
                                child: AnimatedOpacity(
                                  opacity: isOpen ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 60),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildResizeHandle(context),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(-2, 2),
                                            ),
                                          ],
                                        ),
                                        child: const ActivityPanel(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isOpen && isPinned) ...[
                      _buildResizeHandle(context),
                      const ActivityPanel(),
                    ],
                  ],
                );
              }(),
            ),
          ],
        ),
      ),
      onDroppedLog: (_) => _changeTab(TriOSTools.chipper),
    );
  }

  /// Sidebar layout (new UI, default).
  Widget _buildSidebarLayout(BuildContext context, Widget body) {
    final isSidebarCollapsed = ref.watch(
      appSettings.select((value) => value.isSidebarCollapsed),
    );

    return Row(
      children: [
        AppSidebar(
          currentPage: _currentPage,
          onTabChanged: _changeTab,
          isCollapsed: isSidebarCollapsed,
          showBorder: !context.theme.rainbowAccent,
          onToggleCollapsed: () => ref
              .read(appSettings.notifier)
              .update(
                (s) => s.copyWith(isSidebarCollapsed: !isSidebarCollapsed),
              ),
        ),
        Expanded(
          child: Scaffold(
            appBar: CompactTopBar(
              scrollController: rightToolbarScrollController,
            ),
            body: body,
          ),
        ),
      ],
    );
  }

  /// Top toolbar layout (old UI).
  Widget _buildTopToolbarLayout(BuildContext context, Widget body) {
    return Scaffold(
      appBar: FullTopBar(
        currentPage: _currentPage,
        onTabChanged: _changeTab,
        scrollController: rightToolbarScrollController,
      ),
      body: body,
    );
  }

  Widget _buildResizeHandle(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isResizeHandleHovered = true),
      onExit: (_) => setState(() => _isResizeHandleHovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final currentWidth = ref.read(appSettings).activityPanelWidth;
          final newWidth = (currentWidth - details.delta.dx).clamp(
            minActivityPanelWidth,
            maxActivityPanelWidth,
          );
          ref
              .read(appSettings.notifier)
              .update((s) => s.copyWith(activityPanelWidth: newWidth));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: _isResizeHandleHovered ? 48 : 40,
              decoration: BoxDecoration(
                color: _isResizeHandleHovered
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
