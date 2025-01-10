import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/modBrowser/models/scraped_mod.dart';
import 'package:trios/modBrowser/scraped_mod_card.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/drag_drop_handler.dart';
import 'package:trios/trios/providers.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/tristate_icon_button.dart';

import '../main.dart';
import '../trios/download_manager/downloader.dart';
import '../trios/settings/settings.dart';
import '../widgets/MultiSplitViewMixin.dart';
import '../widgets/moving_tooltip.dart';
import 'mod_browser_manager.dart';

class ModBrowserPage extends ConsumerStatefulWidget {
  const ModBrowserPage({super.key});

  @override
  ConsumerState<ModBrowserPage> createState() => _ModBrowserPage();
}

class _ModBrowserPage extends ConsumerState<ModBrowserPage>
    with AutomaticKeepAliveClientMixin<ModBrowserPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  final urlController = TextEditingController();
  bool splitPane = true;
  List<ScrapedMod>? displayedMods;
  final GlobalKey webViewKey = GlobalKey();
  final List<ContentBlocker> contentBlockers = [];
  var contentBlockerEnabled = true;
  InAppWebViewController? webViewController;
  InAppWebViewSettings? webSettings;
  double? webLoadingProgress;
  String? selectedModName;
  bool? filterHasDownloadLink;
  bool? filterDiscord;
  bool? filterIndex;
  bool? filterForumModding;
  bool? _webview2RequiredAndMissing;

  @override
  List<Area> get areas => splitPane
      ? [Area(id: 'left', size: 500), Area(id: 'right')]
      : [Area(id: 'left')];

  @override
  void initState() {
    super.initState();

    if (currentPlatform != TargetPlatform.windows) {
      _webview2RequiredAndMissing = false;
    } else {
      WebViewEnvironment.getAvailableVersion().then((availableVersion) {
        Fimber.i("Available WebView2 version: $availableVersion");
        if (availableVersion != null) {
          _enableWebView();
        } else {
          _webview2RequiredAndMissing = true;
        }
      });
    }
  }

  _enableWebView() {
    setState(() {
      _webview2RequiredAndMissing = false;
      webSettings = InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
        algorithmicDarkeningAllowed: true,
        forceDark: ForceDark.ON,
        forceDarkStrategy:
            ForceDarkStrategy.PREFER_WEB_THEME_OVER_USER_AGENT_DARKENING,
      );
      // downloadAdBlockList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final httpClient = ref.watch(triOSHttpClient);
    final allMods = ref.watch(browseModsNotifierProvider).value;
    displayedMods ??= allMods?.items;
    final theme = Theme.of(context);
    final weaponCount = allMods?.items.length;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 4, right: 4, bottom: 4, top: 4),
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerThickness: 16,
                  dividerPainter: DividerPainters.dashed(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    highlightedColor: theme.colorScheme.onSurface,
                    highlightedThickness: 2,
                    gap: 1,
                    animationDuration: const Duration(milliseconds: 100),
                  )),
              child: MultiSplitView(
                  controller: multiSplitController,
                  axis: Axis.horizontal,
                  builder: (context, area) {
                    switch (area.id) {
                      case 'left':
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 50,
                              child: Card(
                                margin: const EdgeInsets.only(
                                    left: 4, top: 4, bottom: 4),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, right: 4),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            if (ref.watch(isLoadingWeaponsList))
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 8),
                                                child: SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    strokeCap: StrokeCap.round,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text("Filters  ",
                                          style: theme.textTheme.labelLarge),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildTristateTooltipIconButton(
                                              icon: const Icon(
                                                  Icons.download_for_offline),
                                              filter: filterHasDownloadLink,
                                              trueTooltip:
                                                  'Showing only mods with a download link',
                                              falseTooltip:
                                                  'Hiding mods with a download link',
                                              nullTooltip:
                                                  'Showing all mods incl. with a download link',
                                              onChanged: (value) {
                                                filterHasDownloadLink = value;
                                                updateFilter();
                                                setState(() {});
                                              }),
                                          buildTristateTooltipIconButton(
                                              icon: const Icon(Icons.discord),
                                              filter: filterDiscord,
                                              trueTooltip:
                                                  'Showing only mods on Discord',
                                              falseTooltip:
                                                  'Hiding mods on Discord',
                                              nullTooltip:
                                                  'Showing all mods incl. Discord',
                                              onChanged: (value) {
                                                filterDiscord = value;
                                                updateFilter();
                                                setState(() {});
                                              }),
                                          buildTristateTooltipIconButton(
                                              icon: const SvgImageIcon(
                                                  'assets/images/icon-podium-gold.svg',
                                                  width: 24,
                                                  height: 24),
                                              filter: filterIndex,
                                              trueTooltip:
                                                  'Showing only mods on the Index',
                                              falseTooltip:
                                                  'Hiding mods on the Index',
                                              nullTooltip:
                                                  'Showing all mods incl. the Index',
                                              onChanged: (value) {
                                                filterIndex = value;
                                                updateFilter();
                                                setState(() {});
                                              }),
                                          buildTristateTooltipIconButton(
                                              icon: const SvgImageIcon(
                                                  'assets/images/icon-podium-silver.svg',
                                                  width: 24,
                                                  height: 24),
                                              filter: filterForumModding,
                                              trueTooltip:
                                                  "Showing only mods on the Forum (besides the Index)",
                                              falseTooltip:
                                                  'Hiding mods on the Forum (besides the Index)',
                                              nullTooltip:
                                                  'Showing all mods incl. Forum',
                                              onChanged: (value) {
                                                filterForumModding = value;
                                                updateFilter();
                                                setState(() {});
                                              }),
                                          // IconButton(
                                          //   icon: const Icon(Icons.refresh),
                                          //   tooltip: 'Redownload Catalog',
                                          //   onPressed: () {
                                          //     setState(() {});
                                          //
                                          //     ref.invalidate(
                                          //         browseModsNotifierProvider);
                                          //   },
                                          // ),
                                        ],
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                          height: 30,
                                          width: 200,
                                          child: buildSearchBox()),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Opacity(
                                opacity: 0.8,
                                child: Text(
                                  '${weaponCount ?? "..."} Mods${allMods?.items.length != displayedMods?.length ? " (${displayedMods?.length} shown)" : ""}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemExtent: 200,
                                itemCount: displayedMods?.length,
                                itemBuilder: (context, index) {
                                  if (displayedMods == null) {
                                    return const SizedBox();
                                  }
                                  final profile = displayedMods![index];

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, top: 4, bottom: 4),
                                    child: ScrapedModCard(
                                        mod: profile,
                                        linkLoader: (url) {
                                          selectedModName = profile.name;
                                          webViewController?.loadUrl(
                                              urlRequest:
                                                  URLRequest(url: WebUri(url)));
                                          setState(() {});
                                        }),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      case 'right':
                        final hasHiddenDarkModeTip = ref.watch(appSettings
                            .select((s) => s.hasHiddenForumDarkModeTip));
                        return Column(
                          children: [
                            SizedBox(
                              height: 50,
                              child: Card(
                                margin: const EdgeInsets.only(
                                    top: 4, bottom: 4, right: 4),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, right: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      FutureBuilder(
                                          future:
                                              webViewController?.canGoBack() ??
                                                  Future.value(false),
                                          builder: (context, snapshot) {
                                            final canGoBack = snapshot.hasData
                                                ? snapshot.data!
                                                : false;
                                            return Disable(
                                              isEnabled: canGoBack == true,
                                              child: MovingTooltipWidget.text(
                                                message: "Back",
                                                child: IconButton(
                                                    onPressed: () async {
                                                      await webViewController
                                                          ?.goBack();
                                                      setState(() {});
                                                    },
                                                    icon: const Icon(
                                                        Icons.arrow_back)),
                                              ),
                                            );
                                          }),
                                      FutureBuilder(
                                          future: webViewController
                                                  ?.canGoForward() ??
                                              Future.value(false),
                                          builder: (context, snapshot) {
                                            final canGoForward =
                                                snapshot.hasData
                                                    ? snapshot.data!
                                                    : false;
                                            return Disable(
                                              isEnabled: canGoForward == true,
                                              child: MovingTooltipWidget.text(
                                                message: "Forward",
                                                child: IconButton(
                                                    onPressed: () async {
                                                      await webViewController
                                                          ?.goForward();
                                                      setState(() {});
                                                    },
                                                    icon: const Icon(
                                                        Icons.arrow_forward)),
                                              ),
                                            );
                                          }),
                                      FutureBuilder(
                                          future: webViewController?.getUrl() ??
                                              Future.value(null),
                                          builder: (context, snapshot) {
                                            return Disable(
                                              isEnabled: snapshot.hasData &&
                                                  snapshot.data != null,
                                              child: MovingTooltipWidget.text(
                                                message: "Reload",
                                                child: IconButton(
                                                    onPressed: () async {
                                                      await webViewController
                                                          ?.reload();
                                                      setState(() {});
                                                    },
                                                    icon: const Icon(
                                                        Icons.refresh)),
                                              ),
                                            );
                                          }),
                                      MovingTooltipWidget.text(
                                        message: "Open in Browser",
                                        child: IconButton(
                                            onPressed: () {
                                              webViewController?.getUrl().then(
                                                  (url) => url
                                                      ?.toString()
                                                      .openAsUriInBrowser());
                                            },
                                            icon: const Icon(Icons.public)),
                                      ),
                                      MovingTooltipWidget.text(
                                        message: "Index",
                                        child: IconButton(
                                            onPressed: () {
                                              webViewController?.loadUrl(
                                                  urlRequest: URLRequest(
                                                      url: WebUri(Constants
                                                          .forumModIndexUrl)));
                                            },
                                            icon: const Icon(Icons.home)),
                                      ),
                                      Expanded(
                                          child: FutureBuilder(
                                              future:
                                                  webViewController?.getUrl(),
                                              builder: (context, snapshot) {
                                                return TextField(
                                                  controller: urlController,
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  maxLines: 1,
                                                  onSubmitted: (url) {
                                                    webViewController?.loadUrl(
                                                        urlRequest: URLRequest(
                                                            url: WebUri(url)));
                                                    setState(() {});
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.all(8),
                                                          border:
                                                              InputBorder.none,
                                                          hintText: 'URL'),
                                                );
                                              })),
                                      if (webLoadingProgress != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, right: 8),
                                          child: SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: webLoadingProgress,
                                              strokeCap: StrokeCap.round,
                                            ),
                                          ),
                                        ),
                                      Builder(builder: (context) {
                                        onPressedDarkTheme() {
                                          ref.read(appSettings.notifier).update(
                                              (s) => s.copyWith(
                                                  hasHiddenForumDarkModeTip:
                                                      true));
                                          showDialog(
                                              context: ref
                                                  .read(AppState.appContext)!,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Forum Dark Theme Instructions"),
                                                  content: const Text(""
                                                      "Read the whole thing first!\n"
                                                      "\n1. Log in to the forum, then reopen this dialog."
                                                      "\n2. Click the button below to navigate to the theme settings."
                                                      "\n3. Next to 'Current Theme', click (change) and select 'Back n Black'."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        webViewController?.loadUrl(
                                                            urlRequest: URLRequest(
                                                                url: WebUri(
                                                                    "https://fractalsoftworks.com/forum/index.php?action=profile;area=theme")));
                                                        Navigator.of(context)
                                                            .pop();
                                                        setState(() {});
                                                      },
                                                      child: const Text(
                                                          "Forum Profile Prefs"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child:
                                                          const Text("Close"),
                                                    ),
                                                  ],
                                                );
                                              });
                                        }

                                        return hasHiddenDarkModeTip != true
                                            ? OutlinedButton.icon(
                                                onPressed: onPressedDarkTheme,
                                                label: const Text(
                                                    "Forum Dark Theme Instructions"),
                                                icon:
                                                    const Icon(Icons.dark_mode),
                                              )
                                            : MovingTooltipWidget.text(
                                                message:
                                                    "Forum Dark Theme Instructions",
                                                child: IconButton(
                                                    onPressed:
                                                        onPressedDarkTheme,
                                                    icon: const Icon(
                                                        Icons.dark_mode)),
                                              );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: IgnoreDropMouseRegion(
                                  child: switch (_webview2RequiredAndMissing) {
                                false => InAppWebView(
                                    key: webViewKey,
                                    webViewEnvironment:
                                        ref.watch(webViewEnvironment),
                                    shouldOverrideUrlLoading:
                                        (controller, navigationAction) async {
                                      if (navigationAction.request.url !=
                                          null) {
                                        final finalUrlAndHeaders =
                                            await DownloadManager
                                                .fetchFinalUrlAndHeaders(
                                                    navigationAction.request.url
                                                        .toString(),
                                                    httpClient);
                                        final url = finalUrlAndHeaders.url;

                                        final isDownloadFile =
                                            await DownloadManager
                                                .isDownloadableFile(
                                                    url.toString(),
                                                    finalUrlAndHeaders
                                                        .headersMap,
                                                    httpClient);

                                        if (isDownloadFile) {
                                          ref
                                              .read(downloadManager.notifier)
                                              .downloadAndInstallMod(
                                                  selectedModName ??
                                                      "Catalog Mod",
                                                  url.toString(),
                                                  activateVariantOnComplete:
                                                      false);

                                          return NavigationActionPolicy.CANCEL;
                                        }
                                      }

                                      return NavigationActionPolicy.ALLOW;
                                    },
                                    onDownloadStartRequest:
                                        (controller, url) {},
                                    initialUrlRequest: URLRequest(
                                        url:
                                            WebUri(Constants.forumModIndexUrl)),
                                    initialSettings: webSettings,
                                    onWebViewCreated: (controller) {
                                      webViewController = controller;
                                    },
                                    onProgressChanged: (controller, progress) {
                                      setState(() {
                                        if (progress == 100) {
                                          webLoadingProgress = null;
                                        } else {
                                          webLoadingProgress = progress / 100;
                                        }
                                      });
                                    },
                                    onLoadStop: (controller, url) {
                                      setState(() {
                                        urlController.text = url.toString();
                                      });
                                    },
                                  ),
                                null => Center(
                                    child: const Text(
                                        "Checking for webview support...")),
                                true => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Unable to display web browser",
                                        style: theme.textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                          "WebView2 is required but not installed."),
                                      Linkify(
                                        text:
                                            "Please install it from https://developer.microsoft.com/en-us/microsoft-edge/webview2/",
                                        onOpen: (link) =>
                                            OpenFilex.open(link.url),
                                      ),
                                      const Text(
                                          "and then restart ${Constants.appName}."),
                                    ],
                                  ),
                              }),
                            ),
                          ],
                        );
                      default:
                        return Container();
                    }
                  }),
            ),
          ),
        ),
      ],
    );
    // },
    // loading: () => const Center(child: CircularProgressIndicator()),
    // error: (error, stack) => Center(
    //   child: SelectableText('Error loading weapons: $error'),
    // ),
    // );
  }

  void updateFilter() {
    final query = _searchController.value.text;
    final allMods = ref.watch(browseModsNotifierProvider).value?.items ?? [];

    if (query.isNotEmpty) {
      displayedMods = searchScrapedMods(allMods, query);
    } else {
      displayedMods = allMods;
    }

    if (filterHasDownloadLink == true) {
      displayedMods = displayedMods
          ?.where(
              (mod) => mod.urls?.containsKey(ModUrlType.DirectDownload) == true)
          .toList();
    } else if (filterHasDownloadLink == false) {
      displayedMods = displayedMods
          ?.where(
              (mod) => mod.urls?.containsKey(ModUrlType.DirectDownload) != true)
          .toList();
    }

    if (filterDiscord == true) {
      displayedMods = displayedMods
          ?.where((mod) => mod.sources?.contains(ModSource.Discord) == true)
          .toList();
    } else if (filterDiscord == false) {
      displayedMods = displayedMods
          ?.where((mod) => mod.sources?.contains(ModSource.Discord) != true)
          .toList();
    }

    if (filterIndex == true) {
      displayedMods = displayedMods
          ?.where((mod) => mod.sources?.contains(ModSource.Index) == true)
          .toList();
    } else if (filterIndex == false) {
      displayedMods = displayedMods
          ?.where((mod) => mod.sources?.contains(ModSource.Index) != true)
          .toList();
    }

    if (filterForumModding == true) {
      displayedMods = displayedMods
          ?.where(
              (mod) => mod.sources?.contains(ModSource.ModdingSubforum) == true)
          .toList();
    } else if (filterForumModding == false) {
      displayedMods = displayedMods
          ?.where(
              (mod) => mod.sources?.contains(ModSource.ModdingSubforum) != true)
          .toList();
    }
  }

  // static CacheManager? _adblockListCacheManager;

  // Only supported on Android, iOS, MacOS: https://inappwebview.dev/docs/webview/content-blockers
  // void downloadAdBlockList() async {
  //   try {
  //     _adblockListCacheManager ??= CacheManager(
  //         Config("trios_adblock_list_cache", stalePeriod: const Duration(days: 3)));
  //   } catch (ex, st) {
  //     Fimber.e('Failed to create mod catalog adblock list cache manager',
  //         ex: ex, stacktrace: st);
  //   }
  //
  //   if (_adblockListCacheManager == null) return;
  //
  //   try {
  //     final cacheManagerLocal = _adblockListCacheManager!;
  //     final adblockList = await (await cacheManagerLocal.getSingleFile(
  //             "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"))
  //         .readAsLines()
  //       ..removeWhere((line) => line.trim().startsWith("#") || line.isEmpty);
  //
  //     List<String> transformed = adblockList.map((entry) {
  //       // Extract the domain part by splitting and taking the second part
  //       String domain = entry.split(" ")[1];
  //       // Convert to the desired regex pattern format
  //       return '.*.$domain/.*';
  //     })
  //         .whereType<String>()
  //         .toList();
  //
  //     for (final adUrlFilter in transformed) {
  //       contentBlockers.add(ContentBlocker(
  //           trigger: ContentBlockerTrigger(
  //             urlFilter: adUrlFilter,
  //           ),
  //           action: ContentBlockerAction(
  //             type: ContentBlockerActionType.BLOCK,
  //           )));
  //     }
  //
  //     webViewController?.setSettings(
  //         settings: webSettings!..contentBlockers = contentBlockers);
  //   } catch (ex, st) {
  //     Fimber.w("Failed to download adblock list.", ex: ex, stacktrace: st);
  //   }
  // }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget buildTristateTooltipIconButton({
    required Widget icon,
    required bool? filter,
    required String trueTooltip,
    required String falseTooltip,
    required String nullTooltip,
    required Function(bool?) onChanged,
  }) {
    return MovingTooltipWidget.text(
      message: switch (filter) {
        true => trueTooltip,
        false => falseTooltip,
        null => nullTooltip,
      },
      child: TristateIconButton(
        value: filter,
        trueIcon: icon,
        falseIcon: Transform.flip(
          flipY: true,
          child: icon,
        ),
        nullIcon: Opacity(
          opacity: 0.5,
          child: icon,
        ),
        onChanged: (newValue) {
          onChanged(newValue);
        },
      ),
    );
  }

  Widget buildSearchBox() {
    return SearchAnchor(
      searchController: _searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          leading: const Icon(Icons.search),
          hintText: "Filter...",
          trailing: [
            controller.value.text.isEmpty
                ? Container()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        updateFilter();
                      });
                    },
                  )
          ],
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainer,
          ),
          onChanged: (value) {
            updateFilter();
            setState(() {});
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }
}

// Custom widget for asynchronously checking file existence and displaying the image
class WeaponImageCell extends StatefulWidget {
  final List<String> imagePaths;

  const WeaponImageCell({super.key, required this.imagePaths});

  @override
  State<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends State<WeaponImageCell> {
  static final Map<String, bool> _fileExistsCache = {};

  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    _findExistingImagePath();
  }

  void _findExistingImagePath() async {
    for (String path in widget.imagePaths) {
      if (_fileExistsCache.containsKey(path)) {
        if (_fileExistsCache[path] == true) {
          _existingImagePath = path;
          break;
        }
      } else {
        bool exists = await File(path).exists();
        _fileExistsCache[path] = exists;
        if (exists) {
          _existingImagePath = path;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        // Trigger a rebuild with the found image path
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_existingImagePath == null) {
      // While checking or if no image is found, show a placeholder
      return const SizedBox(
        width: 50,
        height: 50,
        child: Center(child: Icon(Icons.image_not_supported)),
      );
    } else {
      return Image.file(
        File(_existingImagePath!),
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    }
  }
}
