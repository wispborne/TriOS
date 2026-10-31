import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/details_dialog/addons_tab.dart';
import 'package:trios/catalog/details_dialog/compatibility_panel.dart';
import 'package:trios/catalog/details_dialog/description_tab.dart';
import 'package:trios/catalog/details_dialog/details_header.dart';
import 'package:trios/catalog/details_dialog/details_panel.dart';
import 'package:trios/catalog/details_dialog/gallery_tab.dart';
import 'package:trios/catalog/details_dialog/get_it_panel.dart';
import 'package:trios/catalog/details_dialog/links_panel.dart';
import 'package:trios/catalog/details_dialog/related_mods.dart';
import 'package:trios/catalog/details_dialog/related_mods_panel.dart';
import 'package:trios/catalog/details_dialog/same_name_panel.dart';
import 'package:trios/catalog/details_dialog/updates_tab.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/dialog_pager.dart';

/// Kept across dialogs for the rest of the app session.
bool _isFullScreen = false;

/// Opens the details dialog on [mod].
///
/// Previous / Next step through [mods], the grid's current list. The dialog
/// keeps its own copy, so the grid changing behind it doesn't move it.
void showCatalogDetailsDialog(
  BuildContext context, {
  required CatalogMod mod,
  required List<CatalogMod> mods,
  required void Function(String url) linkLoader,
  bool canUseEmbeddedBrowser = true,
}) {
  final items = List<CatalogMod>.of(mods);
  var startIndex = items.indexWhere((m) => isSameCatalogMod(m, mod));
  if (startIndex < 0) {
    items
      ..clear()
      ..add(mod);
    startIndex = 0;
  }
  showDialog(
    context: context,
    builder: (_) => CatalogDetailsDialog(
      mods: items,
      startIndex: startIndex,
      linkLoader: linkLoader,
      canUseEmbeddedBrowser: canUseEmbeddedBrowser,
    ),
  );
}

/// True when [a] and [b] are the same catalog entry: the same catalog id, or
/// the same name when there's no id.
bool isSameCatalogMod(CatalogMod a, CatalogMod b) {
  if (identical(a, b)) return true;
  final id = a.entry.id;
  if (id != null && id.isNotEmpty) return id == b.entry.id;
  return a.entry.name == b.entry.name;
}

/// The catalog details dialog. Open it with [showCatalogDetailsDialog].
class CatalogDetailsDialog extends StatefulWidget {
  /// The grid's mods, in order. Must not be empty.
  final List<CatalogMod> mods;
  final int startIndex;
  final void Function(String url) linkLoader;
  final bool canUseEmbeddedBrowser;

  const CatalogDetailsDialog({
    super.key,
    required this.mods,
    required this.startIndex,
    required this.linkLoader,
    this.canUseEmbeddedBrowser = true,
  });

  @override
  State<CatalogDetailsDialog> createState() => _CatalogDetailsDialogState();
}

class _CatalogDetailsDialogState extends State<CatalogDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final width = _isFullScreen
        ? windowSize.width
        : (windowSize.width - 48).clamp(400.0, 1200.0);
    final height = _isFullScreen ? windowSize.height : windowSize.height * 0.9;

    return Dialog(
      insetPadding: _isFullScreen ? EdgeInsets.zero : const .all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 8),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: DialogPager<CatalogMod>(
          items: widget.mods,
          startIndex: widget.startIndex,
          itemBuilder: (context, gridMod, pagerControls) => _DetailsBody(
            gridMod: gridMod,
            pagerControls: pagerControls,
            linkLoader: widget.linkLoader,
            canUseEmbeddedBrowser: widget.canUseEmbeddedBrowser,
            isFullScreen: _isFullScreen,
            onToggleFullScreen: () =>
                setState(() => _isFullScreen = !_isFullScreen),
          ),
        ),
      ),
    );
  }
}

/// The dialog's tabs, in display order.
enum DetailsTab {
  description('Description'),
  gallery('Gallery'),
  updates('Updates'),
  addons('Add-ons');

  final String label;

  const DetailsTab(this.label);
}

/// Everything the dialog shows for one mod. The pager rebuilds this with a
/// new key on each Previous / Next, which also clears the Back history.
class _DetailsBody extends ConsumerStatefulWidget {
  /// The grid mod the pager is on.
  final CatalogMod gridMod;
  final Widget pagerControls;
  final void Function(String url) linkLoader;
  final bool canUseEmbeddedBrowser;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  const _DetailsBody({
    required this.gridMod,
    required this.pagerControls,
    required this.linkLoader,
    required this.canUseEmbeddedBrowser,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  /// The mods shown before each followed link, oldest first.
  final List<CatalogMod> _history = [];
  late CatalogMod _shown = widget.gridMod;
  DetailsTab? _tab;
  final _hoveredUrl = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _hoveredUrl.dispose();
    super.dispose();
  }

  /// Shows [mod] and remembers the current one for Back.
  void _openMod(CatalogMod mod) {
    if (isSameCatalogMod(mod, _shown)) return;
    setState(() {
      _history.add(_shown);
      _shown = mod;
      _tab = null;
    });
    _hoveredUrl.value = null;
  }

  void _goBack() {
    if (_history.isEmpty) return;
    setState(() {
      _shown = _history.removeLast();
      _tab = null;
    });
    _hoveredUrl.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allMods = ref.watch(catalogModsProvider);
    final links = ref.watch(catalogLinksProvider);
    bool isInstalledByName(String name) => links.linkForName(name) != null;

    // The newest copy of the shown mod, so installing or enabling it shows up
    // while the dialog is open.
    final base = allMods.firstWhereOrNull((m) => isSameCatalogMod(m, _shown));
    final shown = base ?? _shown;

    // Add the cached forum post, the same way the card does.
    final entry = shown.entry;
    final topicId = catalogForumTopicId(entry);
    final forumIndex = topicId == null
        ? null
        : ref.watch(forumDataByTopicId)[topicId];
    final cachedDetails = topicId == null
        ? null
        : ref.watch(forumDetailsForTopic(topicId));
    final forumDetails = cachedDetails?.isPlaceholderDetail == false
        ? cachedDetails
        : null;
    final mod = forumDetails == null
        ? shown
        : gatherCatalogMod(
            mod: entry,
            forumIndex: forumIndex,
            discordThreads: discordThreadsFor(
              entry,
              ref.watch(discordThreadsById),
            ),
            forumDetails: forumDetails,
            installedMod: shown.installedMod,
            extras: shown.extras,
          );
    final forumThreadId = forumIndex?.topicId.toString();

    final downloadGroups = buildDownloadGroups(
      index: forumIndex,
      scrapedLinks: forumDetails?.links,
      dialogMod: mod.llmMod,
      isInstalled: isInstalledByName,
    );
    final ownGroup = downloadGroups.firstWhereOrNull(
      (g) => g.isDialogMod || g.modName == null,
    );
    final threadRows = threadModRows(downloadGroups);

    void onGroupDownload(DownloadCandidate candidate, String modName) =>
        executeDownloadCandidate(
          context,
          ref,
          candidate,
          modName: modName,
          // Use the row's own mod name, not the thread title, so an add-on
          // links to itself rather than the thread's main mod.
          sourceHint: DownloadSourceHint(
            catalogName: modName,
            forumThreadId: forumThreadId,
          ),
          linkLoader: widget.linkLoader,
        );

    void onPostLinkTap(String url) => openPostLink(
      context,
      ref,
      url,
      modName: mod.title,
      forumThreadId: forumThreadId,
      linkLoader: widget.linkLoader,
    );

    // Tabs, leaving out any with nothing to show.
    final discordPostHtml = mod.extras?.discordPostHtml;
    final about = aboutTextsFor(mod, ref);
    final hasDescription =
        about.aiParagraph != null ||
        (forumDetails?.contentHtml.isNotEmpty ?? false) ||
        (discordPostHtml?.isNotEmpty ?? false);
    final gallery = galleryPicturesFor(mod, forumDetails);
    final tabs = [
      if (hasDescription) DetailsTab.description,
      if (gallery.isNotEmpty) DetailsTab.gallery,
      if (UpdatesTab.hasContent(mod)) DetailsTab.updates,
      if (threadRows.isNotEmpty) DetailsTab.addons,
    ];
    final tab = tabs.contains(_tab) ? _tab : tabs.firstOrNull;

    final websiteUrl = mod.topicUrl ?? entry.getBestWebsiteUrl();
    final hasWebsite = websiteUrl != null && websiteUrl.isNotEmpty;
    final sameNameMods = mod.extras?.sameNameMods ?? const [];
    final byAuthor = moreByAuthor(mod, allMods);
    final similar = similarMods(mod, allMods);
    final firstAuthor =
        entry.getAuthorsDeduplicated().firstOrNull ?? mod.authors;

    final tabContent = switch (tab) {
      DetailsTab.description => DescriptionTab(
        mod: mod,
        forumDetails: forumDetails,
        discordPostHtml: discordPostHtml,
        onLinkTap: onPostLinkTap,
        onLinkHover: (url) => _hoveredUrl.value = url,
      ),
      DetailsTab.gallery => GalleryTab(pictures: gallery),
      DetailsTab.updates => UpdatesTab(mod: mod),
      DetailsTab.addons => AddonsTab(
        rows: threadRows,
        dialogModName: mod.title,
        onDownload: onGroupDownload,
      ),
      null => Text(
        'No description...yet!',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ),
    };

    final sidePanels = <Widget>[
      GetItPanel(
        mod: mod,
        postCandidates: ownGroup?.candidates ?? const [],
        linkLoader: widget.linkLoader,
      ),
      if (LinksPanel.hasContent(mod)) LinksPanel(mod: mod),
      if (CompatibilityPanel.hasContent(mod))
        CompatibilityPanel(
          mod: mod,
          allMods: allMods,
          downloadGroups: downloadGroups,
          isInstalledByName: isInstalledByName,
          onOpenMod: _openMod,
          onDownload: onGroupDownload,
        ),
      DetailsPanel(mod: mod),
      if (byAuthor.isNotEmpty)
        RelatedModsPanel(
          title: 'More by $firstAuthor',
          mods: byAuthor,
          onOpenMod: _openMod,
        ),
      if (similar.isNotEmpty)
        RelatedModsPanel(
          title: 'Similar mods',
          mods: similar,
          onOpenMod: _openMod,
        ),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        DetailsHeader(
          mod: mod,
          summary: about.headerText,
          summaryIsAi: about.headerIsAi,
          onBack: _history.isEmpty ? null : _goBack,
          pagerControls: widget.pagerControls,
          onOpenInEmbeddedBrowser: widget.canUseEmbeddedBrowser && hasWebsite
              ? () => widget.linkLoader(websiteUrl)
              : null,
          onOpenInSystemBrowser: hasWebsite
              ? () => websiteUrl.openAsUriInBrowser()
              : null,
          onToggleFullScreen: widget.onToggleFullScreen,
          isFullScreen: widget.isFullScreen,
          onClose: () => Navigator.of(context).pop(),
          onShowThreadMods: tabs.contains(DetailsTab.addons)
              ? () => setState(() => _tab = DetailsTab.addons)
              : null,
        ),
        Divider(height: 1, color: theme.dividerColor),
        // A fresh subtree per shown mod, so scroll positions and folded
        // sections start over.
        Expanded(
          child: KeyedSubtree(
            key: ObjectKey(_shown),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                if (sameNameMods.isNotEmpty)
                  SameNamePanel(
                    sameNameMods: sameNameMods,
                    allMods: allMods,
                    onOpenMod: _openMod,
                    linkLoader: widget.linkLoader,
                  ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: .stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .stretch,
                          children: [
                            if (tabs.length > 1)
                              _TabStrip(
                                tabs: tabs,
                                selected: tab!,
                                galleryCount: gallery.length,
                                onSelected: (t) => setState(() => _tab = t),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                key: ValueKey(tab),
                                padding: const .all(16),
                                child: tabContent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const .fromLTRB(8, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: .stretch,
                            children: sidePanels,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        LinkStatusBar(hoveredUrl: _hoveredUrl),
      ],
    );
  }
}

/// The row of tab buttons above the tab area.
class _TabStrip extends StatefulWidget {
  final List<DetailsTab> tabs;
  final DetailsTab selected;

  /// Shown beside the Gallery tab's name.
  final int galleryCount;
  final void Function(DetailsTab tab) onSelected;

  const _TabStrip({
    required this.tabs,
    required this.selected,
    required this.galleryCount,
    required this.onSelected,
  });

  @override
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> with TickerProviderStateMixin {
  late TabController _controller = _newController();

  TabController _newController() => TabController(
    length: widget.tabs.length,
    initialIndex: widget.tabs.indexOf(widget.selected),
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant _TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<DetailsTab>().equals(oldWidget.tabs, widget.tabs)) {
      _controller.dispose();
      _controller = _newController();
    } else {
      final index = widget.tabs.indexOf(widget.selected);
      if (index != _controller.index) _controller.animateTo(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TabBar(
      controller: _controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (index) => widget.onSelected(widget.tabs[index]),
      tabs: [
        for (final tab in widget.tabs)
          Tab(
            child: Row(
              mainAxisSize: .min,
              spacing: 6,
              children: [
                Text(tab.label),
                if (tab == DetailsTab.gallery)
                  Text(
                    '${widget.galleryCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
