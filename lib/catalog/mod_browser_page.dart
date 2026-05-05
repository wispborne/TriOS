import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/catalog_card_click_action.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/catalog/scraped_mod_card.dart';
import 'package:trios/catalog/side_rail/side_rail.dart';
import 'package:trios/catalog/side_rail/side_rail_panel.dart';
import 'package:trios/catalog/widgets/catalog_filters_panel.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/drag_drop_handler.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

import '../main.dart';
import '../trios/download_manager/downloader.dart';
import '../widgets/moving_tooltip.dart';
import 'catalog_data_sources_dialog.dart';
import 'forum_data_manager.dart';

class CatalogPage extends ConsumerStatefulWidget {
  final EdgeInsets pagePadding;

  const CatalogPage({super.key, required this.pagePadding});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

enum WebViewStatus {
  loading,
  optInRequired,
  webview2Required,
  linuxNotSupported,
  unknownError,
  loaded,
}

class _CatalogPageState extends ConsumerState<CatalogPage>
    with AutomaticKeepAliveClientMixin<CatalogPage> {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  final urlController = TextEditingController();
  static const String _kBrowserPanelId = 'browser';
  static const double _kDefaultPanelWidth = 500;

  /// Null = no panel open. When the browser panel is open, equals [_kBrowserPanelId].
  String? _openPanelId;
  double _panelWidth = _kDefaultPanelWidth;
  bool _hydratedPanelState = false;
  final GlobalKey webViewKey = GlobalKey();
  final List<ContentBlocker> contentBlockers = [];
  var contentBlockerEnabled = true;
  InAppWebViewController? webViewController;
  InAppWebViewSettings? webSettings;
  double? webLoadingProgress;
  String? selectedModName;
  WebViewStatus _webViewStatus = WebViewStatus.loading;
  String? currentUrl;

  @override
  void initState() {
    super.initState();

    if (currentPlatform == TargetPlatform.linux) {
      _webViewStatus = WebViewStatus.linuxNotSupported;
      return;
    }

    final shouldAutoLoad = ref.read(appSettings).shouldLoadWebView;
    if (shouldAutoLoad && !didPreviousSessionCrash) {
      _initWebViewForPlatform();
    } else {
      _webViewStatus = WebViewStatus.optInRequired;
    }
  }

  void _initWebViewForPlatform() {
    if (currentPlatform == TargetPlatform.windows) {
      try {
        WebViewEnvironment.getAvailableVersion().then((availableVersion) {
          Fimber.i("Available WebView2 version: $availableVersion");
          if (availableVersion != null) {
            _enableWebView();
          } else {
            setState(() {
              _webViewStatus = WebViewStatus.webview2Required;
            });
          }
        });
      } catch (ex, st) {
        Fimber.w("Failed to get webview2 version", ex: ex, stacktrace: st);
        setState(() {
          _webViewStatus = WebViewStatus.unknownError;
        });
      }
    } else if (currentPlatform == TargetPlatform.macOS) {
      _enableWebView();
    }
  }

  void _loadWebViewOnce() {
    _initWebViewForPlatform();
  }

  void _loadWebViewAlways() {
    ref
        .read(appSettings.notifier)
        .update((state) => state.copyWith(shouldLoadWebView: true));
    _initWebViewForPlatform();
  }

  void _enableWebView() {
    setState(() {
      _webViewStatus = WebViewStatus.loaded;

      webSettings = InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
        algorithmicDarkeningAllowed: true,
      );
    });
  }

  /// Dispatch a card-body click to the configured target: forum-post-dialog
  /// fallback, embedded browser panel (auto-opening if closed), or system
  /// browser. The forum-post-dialog primary path is handled by the card
  /// itself when cached detail HTML is available; this helper sees only the
  /// URL-loading fallback case.
  void _dispatchCardLink(String url) {
    final action = ref.read(appSettings).catalogCardClickAction;
    switch (action) {
      case CatalogCardClickAction.embeddedBrowser:
        if (_webViewStatus != WebViewStatus.loaded) {
          // Webview not ready; fall back to OS browser rather than losing
          // the click. Opt-in flow shows in the panel if the user opens it.
          url.openAsUriInBrowser();
          return;
        }
        if (_openPanelId != _kBrowserPanelId) {
          setState(() => _openPanelId = _kBrowserPanelId);
          ref
              .read(appSettings.notifier)
              .update((s) => s.copyWith(catalogBrowserPanelOpen: true));
        }
        webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        setState(() {});
        break;
      case CatalogCardClickAction.forumDialog:
      case CatalogCardClickAction.systemBrowser:
        // forumDialog falls through to system browser when cached HTML isn't
        // available (the card already handled the cached-HTML case).
        url.openAsUriInBrowser();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final httpClient = ref.watch(triOSHttpClient);
    final theme = Theme.of(context);

    final catalogState = ref.watch(catalogPageControllerProvider);
    final catalogController = ref.watch(catalogPageControllerProvider.notifier);
    final allMods = catalogState.allMods;
    final displayedMods = catalogState.displayedMods;
    final totalCount = allMods.length;

    // Hydrate the browser panel state from persisted settings on first build.
    if (!_hydratedPanelState) {
      _hydratedPanelState = true;
      final settings = ref.read(appSettings);
      final persistedWidth = settings.catalogBrowserPanelWidth;
      if (persistedWidth != null &&
          persistedWidth >= kSideRailPanelMinWidth &&
          persistedWidth.isFinite) {
        _panelWidth = persistedWidth;
      }
      if (settings.catalogBrowserPanelOpen) {
        _openPanelId = _kBrowserPanelId;
      }
    }

    // Forum data lookup by topic ID (still used by card builders below).
    final forumLookup = ref.watch(forumDataByTopicId);

    return Column(
      children: [
        Expanded(
          child: SideRail(
            openPanelId: _openPanelId,
            panelWidth: _panelWidth,
            onPanelToggled: (id) {
              setState(() {
                _openPanelId = _openPanelId == id ? null : id;
              });
              ref
                  .read(appSettings.notifier)
                  .update(
                    (s) => s.copyWith(
                      catalogBrowserPanelOpen: _openPanelId != null,
                    ),
                  );
            },
            onPanelResized: (w) {
              setState(() => _panelWidth = w);
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(catalogBrowserPanelWidth: w));
            },
            onPanelSnapCollapsed: () {
              setState(() => _openPanelId = null);
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(catalogBrowserPanelOpen: false));
            },
            contentBuilder: (context) {
              return Padding(
                padding: widget.pagePadding,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              MovingTooltipWidget.text(
                                message: 'Clear all filters',
                                child: IconButton(
                                  icon: const Icon(Icons.clear_all),
                                  onPressed: catalogController.clearAllFilters,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Align(
                                  alignment: .centerLeft,
                                  child: SizedBox(
                                    height: 30,
                                    width: 240,
                                    child: buildSearchBox(catalogController),
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: TriOSDropdownMenu<CatalogSortKey>(
                                  initialSelection: catalogState.selectedSort,
                                  onSelected: (value) {
                                    catalogController.setSort(
                                      value ?? CatalogSortKey.nameAsc,
                                    );
                                  },
                                  dropdownMenuEntries: CatalogSortKey.values
                                      .map(
                                        (key) => DropdownMenuEntry(
                                          value: key,
                                          label: key.label,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              buildCatalogOverflowButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        '$totalCount Mods${totalCount != displayedMods.length ? " (${displayedMods.length} shown)" : ""}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (catalogState.showFilters)
                            CatalogFiltersPanel(items: allMods)
                          else
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 4),
                              child: CollapsedFilterButton(
                                onTap: catalogController.toggleShowFilters,
                                activeFilterCount:
                                    catalogController.activeFilterCount,
                              ),
                            ),
                          Expanded(
                            child: catalogState.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                  )
                                : WispAdaptiveGridView<ScrapedMod>(
                                    items: displayedMods,
                                    minItemWidth: ref.watch(
                                      appSettings.select(
                                        (s) => s.catalogMinItemWidth,
                                      ),
                                    ),
                                    horizontalSpacing: ref.watch(
                                      appSettings.select(
                                        (s) => s.catalogCardSpacing,
                                      ),
                                    ),
                                    verticalSpacing: ref.watch(
                                      appSettings.select(
                                        (s) => s.catalogCardSpacing,
                                      ),
                                    ),
                                    padding: EdgeInsets.only(
                                      bottom: widget.pagePadding.bottom,
                                    ),
                                    itemBuilder: (context, profile, index) {
                                      final status = catalogController
                                          .statusForModName(profile.name);
                                      final forumThreadId = extractForumTopicId(
                                        profile.urls?[ModUrlType.Forum],
                                      );
                                      final forumEntry = forumThreadId != null
                                          ? forumLookup[forumThreadId]
                                          : null;

                                      return SizedBox(
                                        height: 140,
                                        child: ScrapedModCard(
                                          mod: profile,
                                          installedMod: status?.mod,
                                          versionCheckComparison:
                                              status?.versionCheck,
                                          forumModIndex: forumEntry,
                                          linkLoader: (url) {
                                            selectedModName = profile.name;
                                            _dispatchCardLink(url);
                                          },
                                          isSelected:
                                              currentUrl != null &&
                                              currentUrl ==
                                                  profile.getBestWebsiteUrl(),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            panels: [
              SideRailPanel(
                id: 'browser',
                label: 'Browser',
                icon: Icons.public,
                builder: (context) {
                  final hasHiddenDarkModeTip = ref.watch(
                    appSettings.select((s) => s.hasHiddenForumDarkModeTip),
                  );
                  return Column(
                    children: [
                      if (_webViewStatus == WebViewStatus.loaded) ...[
                        SizedBox(
                          height: 50,
                          child: Card(
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                crossAxisAlignment: .center,
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
                                              await webViewController?.goBack();
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.arrow_back),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  FutureBuilder(
                                    future:
                                        webViewController?.canGoForward() ??
                                        Future.value(false),
                                    builder: (context, snapshot) {
                                      final canGoForward = snapshot.hasData
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
                                              Icons.arrow_forward,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  FutureBuilder(
                                    future:
                                        webViewController?.getUrl() ??
                                        Future.value(null),
                                    builder: (context, snapshot) {
                                      return (webLoadingProgress != null)
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                                right: 8,
                                              ),
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Transform.flip(
                                                  // Trick to have indeterminate progress go CCW, then loading progress goes CW as normal.
                                                  flipX:
                                                      webLoadingProgress == 0,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        value:
                                                            webLoadingProgress ==
                                                                0
                                                            ? null
                                                            : webLoadingProgress,
                                                        color: theme
                                                            .iconTheme
                                                            .color,
                                                        strokeCap:
                                                            StrokeCap.round,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : Disable(
                                              isEnabled:
                                                  snapshot.hasData &&
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
                                                    Icons.refresh,
                                                  ),
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                  MovingTooltipWidget.text(
                                    message: "Open in Browser",
                                    child: IconButton(
                                      onPressed: () {
                                        webViewController?.getUrl().then(
                                          (url) => url
                                              ?.toString()
                                              .openAsUriInBrowser(),
                                        );
                                      },
                                      icon: const Icon(Icons.public),
                                    ),
                                  ),
                                  MovingTooltipWidget.text(
                                    message: "Index",
                                    child: IconButton(
                                      onPressed: () {
                                        webViewController?.loadUrl(
                                          urlRequest: URLRequest(
                                            url: WebUri(
                                              Constants.forumModIndexUrl,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.home),
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder(
                                      future: webViewController?.getUrl(),
                                      builder: (context, snapshot) {
                                        return TextField(
                                          controller: urlController,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          onSubmitted: (url) {
                                            webViewController?.loadUrl(
                                              urlRequest: URLRequest(
                                                url: WebUri(url),
                                              ),
                                            );
                                            setState(() {});
                                          },
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(8),
                                            border: InputBorder.none,
                                            hintText: 'URL',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      onPressedDarkTheme() {
                                        ref
                                            .read(appSettings.notifier)
                                            .update(
                                              (s) => s.copyWith(
                                                hasHiddenForumDarkModeTip: true,
                                              ),
                                            );
                                        showDialog(
                                          context: ref.read(
                                            AppState.appContext,
                                          )!,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Forum Dark Theme Instructions",
                                              ),
                                              content: const Text(
                                                ""
                                                "Read the whole thing first!\n"
                                                "\n1. Log in to the forum, then reopen this dialog."
                                                "\n2. Click the button below to navigate to the theme settings."
                                                "\n3. Next to 'Current Theme', click (change) and select 'Back n Black'.",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    webViewController?.loadUrl(
                                                      urlRequest: URLRequest(
                                                        url: WebUri(
                                                          "https://fractalsoftworks.com/forum/index.php?action=profile;area=theme",
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.of(context).pop();
                                                    setState(() {});
                                                  },
                                                  child: const Text(
                                                    "Forum Profile Prefs",
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("Close"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }

                                      return hasHiddenDarkModeTip != true
                                          ? OutlinedButton.icon(
                                              onPressed: onPressedDarkTheme,
                                              label: const Text(
                                                "Forum Dark Theme Instructions",
                                              ),
                                              icon: const Icon(Icons.dark_mode),
                                            )
                                          : MovingTooltipWidget.text(
                                              message:
                                                  "Forum Dark Theme Instructions",
                                              child: IconButton(
                                                onPressed: onPressedDarkTheme,
                                                icon: const Icon(
                                                  Icons.dark_mode,
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Expanded(
                        child: IgnoreDropMouseRegion(
                          child: switch (_webViewStatus) {
                            WebViewStatus.loading => Center(
                              child: const Text(
                                "Checking for webview support...",
                              ),
                            ),
                            WebViewStatus.optInRequired => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.web_asset_off,
                                      size: 64,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 16),
                                    // Text(
                                    //   "Web Browser",
                                    //   style: theme.textTheme.headlineSmall,
                                    // ),
                                    // const SizedBox(height: 8),
                                    if (!didPreviousSessionCrash)
                                      Text(
                                        "The web browser is disabled by default"
                                        "\nto prevent crash looping on some systems."
                                        "\n"
                                        "\nClick Load Once, and, if it works, click Always Load next time.",
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    if (didPreviousSessionCrash) ...[
                                      const SizedBox(height: 12),
                                      Card.outlined(
                                        color: theme.colorScheme.errorContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: theme
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                              const SizedBox(width: 16),
                                              Flexible(
                                                child: Text(
                                                  "${context.appName} quit unexpectedly.\n"
                                                  "The browser has been disabled as a precaution.",
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onErrorContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    Wrap(
                                      children: [
                                        MovingTooltipWidget.text(
                                          message:
                                              "Browser will be loaded until ${context.appName} exits.",
                                          child: OutlinedButton.icon(
                                            onPressed: _loadWebViewOnce,
                                            icon: Icon(Icons.web),
                                            label: const Text("Load Once"),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        MovingTooltipWidget.text(
                                          message:
                                              "Browser will always load (unless ${context.appName} crashes).",
                                          child: OutlinedButton.icon(
                                            onPressed: _loadWebViewAlways,
                                            icon: const Icon(Icons.web),
                                            label: const Text("Always Load"),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // const SizedBox(height: 8),
                                    // Text(
                                    //   "Clicking a mod in the list will open it in your default browser instead.",
                                    //   textAlign: TextAlign.center,
                                    //   style: theme.textTheme.bodySmall
                                    //       ?.copyWith(
                                    //         color: theme
                                    //             .colorScheme
                                    //             .onSurface
                                    //             .withOpacity(0.5),
                                    //       ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                            WebViewStatus.loaded => InAppWebView(
                              key: webViewKey,
                              webViewEnvironment: ref.watch(webViewEnvironment),
                              shouldOverrideUrlLoading:
                                  (controller, navigationAction) async {
                                    if (navigationAction.request.url != null) {
                                      final finalUrlAndHeaders =
                                          await DownloadManager.fetchFinalUrlAndHeaders(
                                            navigationAction.request.url
                                                .toString(),
                                            httpClient,
                                          );
                                      final url = finalUrlAndHeaders.url;

                                      final isDownloadFile =
                                          await DownloadManager.isDownloadableFile(
                                            url.toString(),
                                            finalUrlAndHeaders.headersMap,
                                            httpClient,
                                          );

                                      if (isDownloadFile) {
                                        ref
                                            .read(downloadManager.notifier)
                                            .downloadAndInstallMod(
                                              selectedModName ?? "Catalog Mod",
                                              url.toString(),
                                              activateVariantOnComplete: false,
                                            );

                                        return NavigationActionPolicy.CANCEL;
                                      }
                                    }

                                    return NavigationActionPolicy.ALLOW;
                                  },
                              onDownloadStartRequest: (controller, url) {},
                              initialUrlRequest: URLRequest(
                                url: WebUri(Constants.forumModIndexUrl),
                              ),
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
                                  currentUrl = url.toString();
                                });
                              },
                            ),

                            // Webview not supported
                            WebViewStatus.webview2Required => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Unable to display web browser",
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "WebView2 is required but not installed.",
                                ),
                                Linkify(
                                  text:
                                      "Please install it from https://developer.microsoft.com/en-us/microsoft-edge/webview2/",
                                  onOpen: (link) => OpenFilex.open(link.url),
                                ),
                                Text(
                                  "and then restart ${context.appName}.",
                                ),
                              ],
                            ),
                            WebViewStatus.linuxNotSupported => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Linux is not supported",
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Linkify(
                                  text:
                                      "Use a standalone browser to find mods (maybe at https://starmodder.pages.dev ?) instead.",
                                  onOpen: (link) => OpenFilex.open(link.url),
                                ),
                              ],
                            ),
                            WebViewStatus.unknownError => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Not supported",
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Linkify(
                                  text:
                                      "Use a standalone browser to find mods (maybe at https://starmodder.pages.dev ?) instead.",
                                  onOpen: (link) => OpenFilex.open(link.url),
                                ),
                              ],
                            ),
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
    urlController.dispose();
    super.dispose();
  }

  Widget buildSearchBox(CatalogPageController catalogController) {
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
                      controller.clear();
                      catalogController.updateSearchQuery('');
                    },
                  ),
          ],
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainer,
          ),
          onChanged: (value) {
            catalogController.updateSearchQuery(value);
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }

  Widget buildCatalogOverflowButton() {
    final theme = Theme.of(context);
    final currentAction = ref.watch(
      appSettings.select((s) => s.catalogCardClickAction),
    );

    return OverflowMenuButton(
      menuItems: [
        OverflowMenuItem(
          title: 'Data sources…',
          icon: Icons.storage,
          onTap: () {
            showCatalogDataSourcesDialog(context);
          },
        ).toEntry(0),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          enabled: false,
          height: 28,
          child: Text(
            'Card click opens',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        for (int i = 0; i < CatalogCardClickAction.values.length; i++)
          OverflowMenuCheckItem(
            title: CatalogCardClickAction.values[i].label,
            icon: CatalogCardClickAction.values[i].icon,
            checked: currentAction == CatalogCardClickAction.values[i],
            onTap: () {
              ref
                  .read(appSettings.notifier)
                  .update(
                    (s) => s.copyWith(
                      catalogCardClickAction: CatalogCardClickAction.values[i],
                    ),
                  );
            },
          ).toEntry(10 + i),
        const PopupMenuDivider(),
        _SliderMenuEntry(
          label: 'Grid item min. size',
          unit: 'px',
          min: 300,
          max: 600,
          divisions: 32,
          readValue: () => ref.read(appSettings).catalogMinItemWidth,
          onChanged: (value) {
            ref
                .read(appSettings.notifier)
                .update((s) => s.copyWith(catalogMinItemWidth: value));
          },
        ),
        _SliderMenuEntry(
          label: 'Space between cards',
          unit: 'px',
          min: 0,
          max: 24,
          // Steps of 4: 0, 4, 8, 12, 16, 20, 24.
          divisions: 6,
          readValue: () => ref.read(appSettings).catalogCardSpacing,
          onChanged: (value) {
            ref
                .read(appSettings.notifier)
                .update((s) => s.copyWith(catalogCardSpacing: value));
          },
        ),
      ],
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

/// Custom popup-menu entry that renders a labeled slider without closing
/// the menu on interaction.
///
/// Unlike [PopupMenuItem], this entry has no wrapping `InkWell`, so tapping
/// and dragging the slider do not pop the menu route. Internal state keeps
/// the slider responsive during drags while [onChanged] writes settings.
class _SliderMenuEntry extends PopupMenuEntry<Never> {
  final String label;
  final String unit;
  final double min;
  final double max;
  final int? divisions;
  final double Function() readValue;
  final void Function(double value) onChanged;

  const _SliderMenuEntry({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.readValue,
    required this.onChanged,
    this.divisions,
  });

  @override
  double get height => 64;

  @override
  bool represents(Never? value) => false;

  @override
  State<_SliderMenuEntry> createState() => _SliderMenuEntryState();
}

class _SliderMenuEntryState extends State<_SliderMenuEntry> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.readValue().clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: labelStyle),
              Text('${_value.round()} ${widget.unit}', style: labelStyle),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _value,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
