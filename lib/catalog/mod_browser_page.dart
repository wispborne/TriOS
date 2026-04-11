import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/catalog/scraped_mod_card.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/drag_drop_handler.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/popup_style_menu_anchor.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/tristate_icon_button.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

import '../main.dart';
import '../trios/download_manager/downloader.dart';
import '../widgets/moving_tooltip.dart';
import '../widgets/multi_split_mixin_view.dart';
import 'catalog_data_sources_dialog.dart';
import 'forum_data_manager.dart';
import 'mod_browser_manager.dart';

class CatalogPage extends ConsumerStatefulWidget {
  final double pagePadding;

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
    with AutomaticKeepAliveClientMixin<CatalogPage>, MultiSplitViewMixin {
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
  bool? filterInstalled;
  bool? filterHasUpdate;
  bool? filterWip;
  bool? filterArchived;
  String selectedCategory = '';
  String selectedVersion = '';
  CatalogSortKey selectedSort = CatalogSortKey.mostViewed;
  bool _hasAppliedInitialDefaults = false;
  List<String> _categoryOptions = [];
  Map<String, Set<String>> _versionGroupOptions = {};
  WebViewStatus _webViewStatus = WebViewStatus.loading;
  Map<String, _CatalogEntryStatus> _catalogStatusMap = {};
  String? currentUrl;

  @override
  List<Area> get areas => splitPane
      ? [Area(id: 'left', size: 500), Area(id: 'right')]
      : [Area(id: 'left')];

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final httpClient = ref.watch(triOSHttpClient);
    final allMods = ref.watch(browseModsNotifierProvider).value;
    displayedMods ??= allMods?.items;
    final theme = Theme.of(context);
    final weaponCount = allMods?.items.length;

    // Rebuild dropdown options when mod data is available.
    if (allMods?.items != null) {
      _categoryOptions = extractCategories(allMods!.items);
      final prevVersionOptions = _versionGroupOptions;
      _versionGroupOptions = extractVersionGroups(allMods.items);

      // Default to the highest (newest) version on first load.
      if (selectedVersion.isEmpty &&
          prevVersionOptions.isEmpty &&
          _versionGroupOptions.isNotEmpty) {
        selectedVersion = _versionGroupOptions.keys.first;
      }

      // Apply default filters/sort on initial data load.
      if (!_hasAppliedInitialDefaults && allMods.items.isNotEmpty) {
        _hasAppliedInitialDefaults = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateFilter();
          setState(() {});
        });
      }
    }

    // Forum data lookup by topic ID.
    final forumLookup = ref.watch(forumDataByTopicId);

    // Build catalog status map from mod records.
    final modRecords = ref.watch(modRecordsStore).valueOrNull;
    final installedMods = ref.watch(AppState.mods);
    final versionCheckState = ref
        .watch(AppState.versionCheckResults)
        .valueOrNull;
    _catalogStatusMap = _buildCatalogStatusMap(
      modRecords,
      installedMods,
      versionCheckState,
    );

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.pagePadding,
              right: widget.pagePadding,
              top: widget.pagePadding,
            ),
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                dividerThickness: 16,
                dividerPainter: DividerPainters.dashed(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  highlightedColor: theme.colorScheme.onSurface,
                  highlightedThickness: 2,
                  gap: 1,
                  animationDuration: const Duration(milliseconds: 100),
                ),
              ),
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
                            height: 80,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        // Text(
                                        //   "Filters  ",
                                        //   style: theme.textTheme.labelLarge,
                                        // ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            buildTristateTooltipIconButton(
                                              icon: const Icon(
                                                Icons.download_for_offline,
                                              ),
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
                                              },
                                            ),
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
                                              },
                                            ),
                                            buildTristateTooltipIconButton(
                                              icon: const SvgImageIcon(
                                                'assets/images/icon-podium-gold.svg',
                                                width: 24,
                                                height: 24,
                                              ),
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
                                              },
                                            ),
                                            buildTristateTooltipIconButton(
                                              icon: const SvgImageIcon(
                                                'assets/images/icon-podium-silver.svg',
                                                width: 24,
                                                height: 24,
                                              ),
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
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            buildTristateTooltipIconButton(
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                              ),
                                              filter: filterInstalled,
                                              trueTooltip:
                                                  'Showing only installed mods',
                                              falseTooltip:
                                                  'Hiding installed mods',
                                              nullTooltip:
                                                  'Showing all mods incl. installed',
                                              onChanged: (value) {
                                                filterInstalled = value;
                                                updateFilter();
                                                setState(() {});
                                              },
                                            ),
                                            buildTristateTooltipIconButton(
                                              icon: const Icon(Icons.download),
                                              filter: filterHasUpdate,
                                              trueTooltip:
                                                  'Showing only mods with updates',
                                              falseTooltip:
                                                  'Hiding mods with updates',
                                              nullTooltip:
                                                  'Showing all mods incl. with updates',
                                              onChanged: (value) {
                                                filterHasUpdate = value;
                                                updateFilter();
                                                setState(() {});
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            buildTristateTooltipIconButton(
                                              icon: const Icon(
                                                Icons.construction,
                                              ),
                                              filter: filterWip,
                                              trueTooltip:
                                                  'Showing only work-in-progress mods',
                                              falseTooltip:
                                                  'Hiding work-in-progress mods',
                                              nullTooltip:
                                                  'Showing all mods incl. WIP',
                                              onChanged: (value) {
                                                filterWip = value;
                                                updateFilter();
                                                setState(() {});
                                              },
                                            ),
                                            buildTristateTooltipIconButton(
                                              icon: const Icon(Icons.archive),
                                              filter: filterArchived,
                                              trueTooltip:
                                                  'Showing only archived mods',
                                              falseTooltip:
                                                  'Hiding archived mods',
                                              nullTooltip:
                                                  'Showing all mods incl. archived',
                                              onChanged: (value) {
                                                filterArchived = value;
                                                updateFilter();
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Align(
                                            alignment: .centerRight,
                                            child: SizedBox(
                                              height: 30,
                                              width: 200,
                                              child: buildSearchBox(),
                                            ),
                                          ),
                                        ),
                                        buildCatalogOverflowButton(),
                                      ],
                                    ),
                                    // Category, Version, Sort dropdowns
                                    Row(
                                      spacing: 8,
                                      children: [
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 180,
                                            ),
                                            child: TriOSDropdownMenu<String>(
                                              initialSelection:
                                                  selectedCategory,
                                              onSelected: (value) {
                                                setState(() {
                                                  selectedCategory =
                                                      value ?? '';
                                                  updateFilter();
                                                });
                                              },
                                              dropdownMenuEntries: [
                                                const DropdownMenuEntry(
                                                  value: '',
                                                  label: 'All Categories',
                                                ),
                                                ..._categoryOptions.map(
                                                  (cat) => DropdownMenuEntry(
                                                    value: cat,
                                                    label: cat,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 150,
                                            ),
                                            child: TriOSDropdownMenu<String>(
                                              initialSelection: selectedVersion,
                                              onSelected: (value) {
                                                setState(() {
                                                  selectedVersion = value ?? '';
                                                  updateFilter();
                                                });
                                              },
                                              dropdownMenuEntries: [
                                                DropdownMenuEntry(
                                                  value: '',
                                                  label: 'All Versions',
                                                ),
                                                ..._versionGroupOptions.keys
                                                    .map(
                                                      (ver) =>
                                                          DropdownMenuEntry(
                                                            value: ver,
                                                            label: ver,
                                                          ),
                                                    ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 200,
                                            ),
                                            child:
                                                TriOSDropdownMenu<
                                                  CatalogSortKey
                                                >(
                                                  initialSelection:
                                                      selectedSort,
                                                  onSelected: (value) {
                                                    setState(() {
                                                      selectedSort =
                                                          value ??
                                                          CatalogSortKey
                                                              .nameAsc;
                                                      updateFilter();
                                                    });
                                                  },
                                                  dropdownMenuEntries:
                                                      CatalogSortKey.values
                                                          .map(
                                                            (key) =>
                                                                DropdownMenuEntry(
                                                                  value: key,
                                                                  label:
                                                                      key.label,
                                                                ),
                                                          )
                                                          .toList(),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0.8,
                            child: Text(
                              '${weaponCount ?? "..."} Mods${allMods?.items.length != displayedMods?.length ? " (${displayedMods?.length} shown)" : ""}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          Expanded(
                            child: ref.watch(isLoadingCatalog)
                                ? Center(
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
                                    items: displayedMods ?? [],
                                    minItemWidth: 390,
                                    horizontalSpacing: 4,
                                    verticalSpacing: 4,
                                    padding: EdgeInsets.only(
                                      bottom: widget.pagePadding,
                                    ),
                                    itemBuilder: (context, profile, index) {
                                      final statusKey = profile.name
                                          .toLowerCase()
                                          .trim();
                                      final status =
                                          _catalogStatusMap[statusKey];

                                      final forumThreadId =
                                          extractForumTopicId(
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
                                            if (_webViewStatus ==
                                                WebViewStatus.loaded) {
                                              webViewController?.loadUrl(
                                                urlRequest: URLRequest(
                                                  url: WebUri(url),
                                                ),
                                              );
                                            } else {
                                              url.openAsUriInBrowser();
                                            }
                                            setState(() {});
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
                      );
                    case 'right':
                      final hasHiddenDarkModeTip = ref.watch(
                        appSettings.select((s) => s.hasHiddenForumDarkModeTip),
                      );
                      return Column(
                        children: [
                          if (_webViewStatus == WebViewStatus.loaded) ...[
                            SizedBox(
                              height: 50,
                              child: Card(
                                margin: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                  ),
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
                                                  Icons.arrow_back,
                                                ),
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8,
                                                        right: 8,
                                                      ),
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: Transform.flip(
                                                      // Trick to have indeterminate progress go CCW, then loading progress goes CW as normal.
                                                      flipX:
                                                          webLoadingProgress ==
                                                          0,
                                                      child: CircularProgressIndicator(
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
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
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
                                                contentPadding: EdgeInsets.all(
                                                  8,
                                                ),
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
                                                    hasHiddenForumDarkModeTip:
                                                        true,
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
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {});
                                                      },
                                                      child: const Text(
                                                        "Forum Profile Prefs",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: const Text(
                                                        "Close",
                                                      ),
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
                                                  icon: const Icon(
                                                    Icons.dark_mode,
                                                  ),
                                                )
                                              : MovingTooltipWidget.text(
                                                  message:
                                                      "Forum Dark Theme Instructions",
                                                  child: IconButton(
                                                    onPressed:
                                                        onPressedDarkTheme,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.web_asset_off,
                                          size: 64,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.4),
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
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                        if (didPreviousSessionCrash) ...[
                                          const SizedBox(height: 12),
                                          Card.outlined(
                                            color: theme
                                                .colorScheme
                                                .errorContainer,
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
                                                      "${Constants.appName} quit unexpectedly.\n"
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
                                                  "Browser will be loaded until ${Constants.appName} exits.",
                                              child: OutlinedButton.icon(
                                                onPressed: _loadWebViewOnce,
                                                icon: Icon(Icons.web),
                                                label: const Text("Load Once"),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            MovingTooltipWidget.text(
                                              message:
                                                  "Browser will always load (unless ${Constants.appName} crashes).",
                                              child: OutlinedButton.icon(
                                                onPressed: _loadWebViewAlways,
                                                icon: const Icon(Icons.web),
                                                label: const Text(
                                                  "Always Load",
                                                ),
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
                                  webViewEnvironment: ref.watch(
                                    webViewEnvironment,
                                  ),
                                  shouldOverrideUrlLoading:
                                      (controller, navigationAction) async {
                                        if (navigationAction.request.url !=
                                            null) {
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
                                                  selectedModName ??
                                                      "Catalog Mod",
                                                  url.toString(),
                                                  activateVariantOnComplete:
                                                      false,
                                                );

                                            return NavigationActionPolicy
                                                .CANCEL;
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
                                      onOpen: (link) =>
                                          OpenFilex.open(link.url),
                                    ),
                                    const Text(
                                      "and then restart ${Constants.appName}.",
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
                                      onOpen: (link) =>
                                          OpenFilex.open(link.url),
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
                                      onOpen: (link) =>
                                          OpenFilex.open(link.url),
                                    ),
                                  ],
                                ),
                              },
                            ),
                          ),
                        ],
                      );
                    default:
                      return Container();
                  }
                },
              ),
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

    // Category filter
    if (selectedCategory.isNotEmpty) {
      displayedMods = displayedMods
          ?.where((mod) => (mod.categories ?? []).contains(selectedCategory))
          .toList();
    }

    // Version filter
    if (selectedVersion.isNotEmpty) {
      final rawVersions = _versionGroupOptions[selectedVersion];
      if (rawVersions != null) {
        displayedMods = displayedMods
            ?.where(
              (mod) =>
                  mod.gameVersionReq != null &&
                  rawVersions.contains(mod.gameVersionReq),
            )
            .toList();
      } else {
        displayedMods = [];
      }
    }

    if (filterHasDownloadLink == true) {
      displayedMods = displayedMods
          ?.where(
            (mod) => mod.urls?.containsKey(ModUrlType.DirectDownload) == true,
          )
          .toList();
    } else if (filterHasDownloadLink == false) {
      displayedMods = displayedMods
          ?.where(
            (mod) => mod.urls?.containsKey(ModUrlType.DirectDownload) != true,
          )
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
            (mod) => mod.sources?.contains(ModSource.ModdingSubforum) == true,
          )
          .toList();
    } else if (filterForumModding == false) {
      displayedMods = displayedMods
          ?.where(
            (mod) => mod.sources?.contains(ModSource.ModdingSubforum) != true,
          )
          .toList();
    }

    if (filterInstalled == true) {
      displayedMods = displayedMods
          ?.where(
            (mod) =>
                _catalogStatusMap.containsKey(mod.name.toLowerCase().trim()),
          )
          .toList();
    } else if (filterInstalled == false) {
      displayedMods = displayedMods
          ?.where(
            (mod) =>
                !_catalogStatusMap.containsKey(mod.name.toLowerCase().trim()),
          )
          .toList();
    }

    if (filterHasUpdate == true) {
      displayedMods = displayedMods?.where((mod) {
        final status = _catalogStatusMap[mod.name.toLowerCase().trim()];
        return status?.versionCheck?.hasUpdate == true;
      }).toList();
    } else if (filterHasUpdate == false) {
      displayedMods = displayedMods?.where((mod) {
        final status = _catalogStatusMap[mod.name.toLowerCase().trim()];
        return status?.versionCheck?.hasUpdate != true;
      }).toList();
    }

    // Forum-data-backed filters (WIP, Archived) — single pass and lookup.
    if (filterWip != null || filterArchived != null) {
      final lookup = ref.read(forumDataByTopicId);
      displayedMods = displayedMods?.where((mod) {
        final topicId = extractForumTopicId(mod.urls?[ModUrlType.Forum]);
        final forum = topicId != null ? lookup[topicId] : null;
        if (filterWip != null) {
          final isWip = forum?.isWip ?? false;
          if ((filterWip == true) != isWip) return false;
        }
        if (filterArchived != null) {
          final isArchived = forum?.isArchivedModIndex ?? false;
          if ((filterArchived == true) != isArchived) return false;
        }
        return true;
      }).toList();
    }

    // Sort (always applied last)
    if (displayedMods != null) {
      displayedMods = sortScrapedMods(
        displayedMods!,
        selectedSort,
        forumLookup: ref.read(forumDataByTopicId),
      );
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
        falseIcon: Transform.flip(flipY: true, child: icon),
        nullIcon: Opacity(opacity: 0.5, child: icon),
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
                  ),
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

  Widget buildCatalogOverflowButton() {
    return MovingTooltipWidget.text(
      message: 'More options',
      child: PopupStyleMenuAnchor(
        builder: (context, menuController, child) {
          return IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '',
            onPressed: () {
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
          );
        },
        menuChildren: [
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(
              const Icon(Icons.storage),
            ),
            onPressed: () {
              showCatalogDataSourcesDialog(context);
            },
            child: const Text('Data sources…'),
          ),
        ],
      ),
    );
  }

  Map<String, _CatalogEntryStatus> _buildCatalogStatusMap(
    ModRecords? records,
    List<Mod> installedMods,
    VersionCheckerState? versionCheckState,
  ) {
    if (records == null) return {};
    final modsByModId = {for (final mod in installedMods) mod.id: mod};
    final map = <String, _CatalogEntryStatus>{};

    for (final record in records.records.values) {
      final catalogName = record.catalog?.name;
      if (catalogName == null) continue;

      final isInstalled = record.installed != null;
      if (!isInstalled) continue;

      final modId = record.modId;
      if (modId == null) continue;

      final mod = modsByModId[modId];
      if (mod == null) continue;

      final versionCheck = mod.updateCheck(versionCheckState);
      map[catalogName.toLowerCase().trim()] = _CatalogEntryStatus(
        mod: mod,
        versionCheck: versionCheck,
      );
    }

    return map;
  }
}

class _CatalogEntryStatus {
  final Mod mod;
  final VersionCheckComparison? versionCheck;

  const _CatalogEntryStatus({required this.mod, this.versionCheck});
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

