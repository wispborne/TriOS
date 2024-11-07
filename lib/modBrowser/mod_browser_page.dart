import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/modBrowser/models/scraped_mod.dart';
import 'package:trios/modBrowser/scraped_mod_card.dart';
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';

import '../main.dart';
import '../widgets/MultiSplitViewMixin.dart';
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
  bool splitPane = true;
  List<ScrapedMod> displayedMods = [];
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  @override
  List<Area> get areas => splitPane
      ? [Area(id: 'left', size: 500), Area(id: 'right')]
      : [Area(id: 'left')];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allMods = ref.watch(browseModsNotifierProvider).value;
    displayedMods = allMods?.items ?? [];
    final theme = Theme.of(context);
    const minHeight = 120.0;
    const cardPadding = 8.0;

    List<PlutoRow> rows = [];

    final weaponCount = allMods?.items.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Stack(
                  children: [
                    const SizedBox(width: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            '${weaponCount ?? "..."} Mods${allMods?.items.length != displayedMods.length ? " (${displayedMods.length} shown)" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 20),
                          ),
                          if (ref.watch(isLoadingWeaponsList))
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: buildSearchBox(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {});

                              ref.invalidate(browseModsNotifierProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                        return AlignedGridView.count(
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          // maxCrossAxisExtent: 800,
                          crossAxisCount: 1,
                          itemCount: displayedMods.length,
                          itemBuilder: (context, index) {
                            final profile = displayedMods[index];

                            return ScrapedModCard(
                                mod: profile,
                                linkLoader: (url) {
                                  webViewController?.loadUrl(
                                      urlRequest: URLRequest(url: WebUri(url)));
                                });
                          },
                        );
                      case 'right':
                        return InAppWebView(
                          key: webViewKey,
                          webViewEnvironment: webViewEnvironment,
                          initialUrlRequest: URLRequest(
                              url: WebUri(
                                  "https://fractalsoftworks.com/forum/index.php?topic=177.0")),
                          initialSettings: InAppWebViewSettings(),
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
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

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchAnchor(
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
                        // _notifyGridFilterChanged();
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              // _notifyGridFilterChanged();
            },
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return [];
        },
      ),
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
