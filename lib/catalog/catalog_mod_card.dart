import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/forum_post_dialog/catalog_mod_details_dialog.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_dialog.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/mod_image_source.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/summary_resolver.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/mod_manager/mod_info_dialog.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/mod_download/mod_download_button.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/stroke_text.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/trios_app_icon.dart';

class CatalogModCard extends ConsumerStatefulWidget {
  final CatalogMod gathered;
  final void Function(String) linkLoader;
  final bool isSelected;
  final VersionCheckComparison? versionCheckComparison;

  /// Whether the app's built-in browser panel is usable on this platform.
  /// Gates the "Open in the built-in browser" actions.
  final bool canUseEmbeddedBrowser;

  const CatalogModCard({
    super.key,
    required this.gathered,
    required this.linkLoader,
    this.isSelected = false,
    this.versionCheckComparison,
    this.canUseEmbeddedBrowser = true,
  });

  @override
  ConsumerState<CatalogModCard> createState() => _CatalogModCardState();
}

class _CatalogModCardState extends ConsumerState<CatalogModCard> {
  CatalogMod get _catalogMod => widget.gathered;

  ModRepoEntry get _entry => _catalogMod.entry;

  VersionCheckerInfo? get _remoteVersion =>
      widget.versionCheckComparison?.remoteVersionCheck?.remoteVersion;

  Color _statusBarColor(ThemeData theme) {
    final mod = _catalogMod.installedMod;
    if (mod == null) return Colors.transparent;

    if (widget.versionCheckComparison?.hasUpdate == true) {
      return theme.colorScheme.primary;
    }
    if (mod.isEnabledInGame) {
      return theme.statusColors.success.withValues(alpha: 0.7);
    }
    return theme.statusColors.neutral.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final mod = _entry;
    final downloadCandidates = resolveDownloadCandidates(
      mod,
      _catalogMod.llmMod,
      remoteVersion: _remoteVersion,
    );

    final theme = Theme.of(context);
    return Builder(
      builder: (context) {
        final websiteUrl = mod.getBestWebsiteUrl();
        final topicId = extractForumTopicId(mod.urls?[ModUrlType.Forum]);
        final forumDetails = topicId == null
            ? null
            : ref.watch(forumDetailsForTopic(topicId));
        final hasForumDetails =
            forumDetails != null && !forumDetails.isPlaceholderDetail;
        final forumIndex = topicId != null
            ? ref.watch(forumDataByTopicId)[topicId]
            : null;
        final enrichedMod = hasForumDetails
            ? gatherCatalogMod(
                mod: _entry,
                forumIndex: forumIndex,
                forumDetails: forumDetails,
                installedMod: _catalogMod.installedMod,
              )
            : _catalogMod;
        final hasDetailsToShow =
            hasForumDetails ||
            enrichedMod.topicUrl != null ||
            (mod.description?.isNotEmpty ?? false) ||
            (mod.summary?.isNotEmpty ?? false) ||
            (mod.images?.isNotEmpty ?? false) ||
            downloadCandidates.isNotEmpty;

        return ContextMenuRegion(
          contextMenu: ContextMenu(
            entries: [
              if (false)
                MenuItem(
                  label: 'View Mod Details...',
                  icon: Icons.info_outline,
                  onSelected: () => showModInfoDialog(
                    context,
                    mod: _catalogMod.installedMod,
                    catalogMod: mod,
                    versionCheckComparison: widget.versionCheckComparison,
                  ),
                ),
              if (downloadCandidates.isNotEmpty) ...[
                const MenuHeader(text: 'Downloads'),
                for (final candidate in downloadCandidates)
                  MenuItem(
                    label: candidate.sourceHost?.isNotEmpty == true
                        ? '${candidate.label}  ·  ${candidate.sourceHost}'
                        : candidate.label,
                    leading: MovingTooltipWidget.text(
                      message: candidate.url,
                      child: downloadCandidateIconWidget(candidate),
                    ),
                    onSelected: () => executeDownloadCandidate(
                      context,
                      ref,
                      candidate,
                      modName: mod.name,
                      sourceHint: DownloadSourceHint.fromModRepoEntry(mod),
                      linkLoader: widget.linkLoader,
                    ),
                  ),
                MenuItem(
                  label: 'Copy download link',
                  leading: MovingTooltipWidget.text(
                    message: 'Copy the best download link to the clipboard',
                    child: const Icon(Icons.copy, size: 16),
                  ),
                  onSelected: () {
                    final url =
                        (primaryCandidate(downloadCandidates) ??
                                downloadCandidates.first)
                            .url;
                    Clipboard.setData(ClipboardData(text: url));
                    showSnackBar(
                      context: context,
                      type: SnackBarType.info,
                      content: const Text('Download link copied to clipboard'),
                    );
                  },
                ),
                const MenuDivider(),
              ],
              if (websiteUrl != null && websiteUrl.isNotEmpty) ...[
                const MenuHeader(text: 'Open'),
                MenuItem(
                  label: 'Open in your web browser',
                  leading: const Icon(Icons.public, size: 16),
                  onSelected: () => websiteUrl.openAsUriInBrowser(),
                ),
                if (widget.canUseEmbeddedBrowser)
                  MenuItem(
                    label: 'Open in the built-in browser',
                    leading: const Icon(Icons.web, size: 16),
                    onSelected: () => widget.linkLoader(websiteUrl),
                  ),
                const MenuDivider(),
              ],
              if (_catalogMod.installedMod != null) ...[
                const MenuHeader(text: 'Installed Mod'),
                if (_catalogMod.installedMod!.isEnabledInGame)
                  MenuItem(
                    label: 'Disable',
                    leading: const Icon(Icons.visibility_off, size: 16),
                    onSelected: () => _setModEnabled(false),
                  )
                else
                  MenuItem(
                    label: 'Enable',
                    leading: const Icon(Icons.visibility, size: 16),
                    onSelected: () => _setModEnabled(true),
                  ),
                const MenuDivider(),
              ],
              if (_linkEntries(context).isNotEmpty) ...[
                const MenuHeader(text: 'Links'),
                ..._linkEntries(context),
                const MenuDivider(),
              ],
              MenuItem(
                label: 'Debug Info',
                leading: const Icon(Icons.bug_report, size: 16),
                onSelected: () => _showDebugDialog(context, mod),
              ),
            ],
          ),
          child: MovingTooltipWidget.framed(
            tooltipWidget: hasDetailsToShow
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: ModSummaryWidget(
                      data: enrichedMod,
                      config: ModSummaryConfig.tooltip,
                    ),
                  )
                : null,
            child: Card(
              margin: const EdgeInsets.all(0),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                ),
              ),
              child: ConditionalWrap(
                condition: hasDetailsToShow,
                wrapper: (child) => InkWell(
                  onTap: () => _openDetailsDialog(context, forumDetails),
                  child: child,
                ),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? theme.cardColor.lighter(5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 60.0,
                                  minWidth: 60.0,
                                  maxHeight: 60.0,
                                ),
                                child: ModImage(mod: enrichedMod, size: 60),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 4,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          mod.name.isNotEmpty
                                              ? mod.name
                                              : '???',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.0,
                                            // fontFamily:
                                            //     TriOSThemeConstants.orbitron,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (enrichedMod.authors.isNotEmpty)
                                    Text(
                                      enrichedMod.authors,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    ),
                                  if (enrichedMod.isPartOfThread)
                                    MovingTooltipWidget.text(
                                      message:
                                          'Part of the "${enrichedMod.partOfThreadTitle}" '
                                          'forum thread.\nClick the card to see '
                                          'the whole thread.',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 3,
                                        children: [
                                          Icon(
                                            Icons.layers,
                                            size: 11,
                                            color: theme
                                                .textTheme
                                                .labelSmall
                                                ?.color
                                                ?.withValues(alpha: 0.6),
                                          ),
                                          Flexible(
                                            child: Text(
                                              'part of ${enrichedMod.partOfThreadTitle}',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: buildDescription(
                                        theme,
                                        context,
                                        mod,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    // Only the footer sits at the button's
                                    // height, so just it clears the corner;
                                    // the name/author/description above use
                                    // the card's full width.
                                    padding: const EdgeInsets.only(right: 80.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (enrichedMod.views != null ||
                                            enrichedMod.replies != null)
                                          _ForumStatsFromGathered(
                                            gathered: enrichedMod,
                                          ),
                                        Tags(mod: mod),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mod.gameVersionReq?.isNotEmpty == true)
                      Positioned(
                        left: 8,
                        top: 4,
                        child: _CatalogModGameVersionReq(mod: mod),
                      ),
                    if (_catalogMod.installedMod != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: MovingTooltipWidget.text(
                          message: _catalogMod.installedMod!.isEnabledInGame
                              ? 'Enabled'
                              : 'Installed, disabled',
                          child: Container(
                            width: 4,
                            color: _statusBarColor(theme),
                          ),
                        ),
                      ),
                    // Overlaid in the bottom-right corner so the text content
                    // above it can span the card's full width.
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: CatalogDownloadButton(
                        mod: mod,
                        installedMod: _catalogMod.installedMod,
                        versionCheckComparison: widget.versionCheckComparison,
                        linkLoader: widget.linkLoader,
                        llmMainMod: _catalogMod.llmMod,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDescription(
    ThemeData theme,
    BuildContext context,
    ModRepoEntry mod,
  ) {
    final aiSummaryMode = ref.watch(effectiveCatalogAiSummaryModeProvider);
    final resolved = resolveSummaryText(
      _catalogMod,
      aiMode: aiSummaryMode,
      authorOrder: AuthorTextOrder.shortFirst,
      aiLength: AiTextLength.sentence,
    );
    final shownText = resolved?.text;
    final showingAiSentence = resolved?.source == ModSummarySource.ai;

    final hasNoDescription = shownText == null;
    final description = shownText ?? 'No description...yet!';
    final trimmedDescription = description
        .split('\n')
        .where((line) => line.isNotEmpty)
        .take(2)
        .join('\n');
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(150),
      fontStyle: hasNoDescription ? FontStyle.italic : null,
    );

    if (showingAiSentence) {
      // A subtle inline icon marks the text as AI-written. It flows with the
      // text so the 2-line ellipsis still applies. The card's hover tooltip
      // (built from the same data) carries the full AI paragraph, so the text
      // itself no longer needs its own tooltip.
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            TextSpan(text: trimmedDescription),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Text(
      trimmedDescription,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    // return ConditionalWrap(
    //   condition: description.isNotEmpty == true,
    //   wrapper: (child) => MovingTooltipWidget.framed(
    //     tooltipWidget: SizedBox(
    //       width: 400,
    //       child: Text(
    //         description,
    //         // overflow: .ellipsis,
    //         style: theme.textTheme.bodyMedium,
    //       ),
    //     ),
    //     child: child,
    //     // child: Material(
    //     //   color: Colors.transparent,
    //     //   child: InkWell(
    //     //     borderRadius: BorderRadius.circular(4),
    //     //     hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
    //     //     onTap: () => _showDescriptionDialog(context, mod.name, description),
    //     //     child: child,
    //     //   ),
    //     // ),
    //   ),
    //   child: Text(
    //     description
    //         .split('\n')
    //         .where((line) => line.isNotEmpty)
    //         .take(2)
    //         .join('\n'),
    //     maxLines: 2,
    //     overflow: TextOverflow.ellipsis,
    //     style: theme.textTheme.labelSmall?.copyWith(
    //       color: theme.colorScheme.onSurface.withAlpha(150),
    //       fontStyle: hasNoDescription ? FontStyle.italic : null,
    //     ),
    //   ),
    // );
  }

  /// Open the mod's details dialog: the cached forum post when available,
  /// otherwise the fallback dialog built from catalog data.
  void _openDetailsDialog(BuildContext context, ForumModDetails? forumDetails) {
    if (forumDetails != null && !forumDetails.isPlaceholderDetail) {
      final topicId = extractForumTopicId(_entry.urls?[ModUrlType.Forum]);
      final forumIndex = topicId != null
          ? ref.read(forumDataByTopicId)[topicId]
          : null;
      showForumPostDialog(
        context,
        details: forumDetails,
        index: forumIndex,
        mod: _entry,
        linkLoader: widget.linkLoader,
        canUseEmbeddedBrowser: widget.canUseEmbeddedBrowser,
      );
    } else {
      showCatalogModDetailsDialog(
        context,
        gathered: _catalogMod,
        linkLoader: widget.linkLoader,
        canUseEmbeddedBrowser: widget.canUseEmbeddedBrowser,
      );
    }
  }

  /// Enable or disable the installed mod. Moved off the primary card button
  /// so the button stays a pure Install/Update/Installed status.
  void _setModEnabled(bool enabled) {
    final mod = _catalogMod.installedMod;
    if (mod == null) return;
    if (enabled) {
      final variant = mod.findHighestVersion;
      if (variant == null) return;
      ref.read(modManager.notifier).changeActiveModVariant(mod, variant);
    } else {
      ref.read(modManager.notifier).changeActiveModVariant(mod, null);
    }
  }

  /// Context-menu link entries (Forum / Discord / NexusMods) for this mod.
  /// Empty when the mod has no such links.
  List<MenuItem> _linkEntries(BuildContext context) {
    final urls = _entry.urls;
    final forumUrl = urls?[ModUrlType.Forum];
    final discordUrl = urls?[ModUrlType.Discord];
    final nexusUrl = urls?[ModUrlType.NexusMods];
    return [
      if (forumUrl != null && forumUrl.isNotEmpty)
        MenuItem(
          label: 'Open forum page',
          leading: const Icon(Icons.public, size: 16),
          onSelected: () {
            forumUrl.openAsUriInBrowser();
          },
        ),
      if (discordUrl != null && discordUrl.isNotEmpty) ...[
        MenuItem(
          label: 'Open in Discord',
          leading: const Icon(Icons.discord, size: 16),
          onSelected: () {
            discordUrl
                .replaceAll('https://', 'discord://')
                .replaceAll('http://', 'discord://')
                .openAsUriInBrowser();
          },
        ),
        MenuItem(
          label: 'Copy Discord link',
          leading: const Icon(Icons.copy, size: 16),
          onSelected: () {
            Clipboard.setData(ClipboardData(text: discordUrl));
            showSnackBar(
              context: context,
              type: SnackBarType.info,
              content: const Text('Discord link copied to clipboard'),
            );
          },
        ),
      ],
      if (nexusUrl != null && nexusUrl.isNotEmpty)
        MenuItem(
          label: 'Open NexusMods page',
          leading: const Icon(Icons.extension, size: 16),
          onSelected: () {
            nexusUrl.openAsUriInBrowser();
          },
        ),
    ];
  }

  void _showDebugDialog(BuildContext context, ModRepoEntry mod) {
    final downloadCandidates = resolveDownloadCandidates(
      mod,
      _catalogMod.llmMod,
      remoteVersion: _remoteVersion,
    );

    final sections = <String, String?>{
      'Catalog mod': mod.toString(),
      'LLM mod (this card)': _catalogMod.llmMod?.toString(),
      'Resolved download candidates': downloadCandidates.isEmpty
          ? null
          : downloadCandidates.join('\n\n'),
    };

    final buffer = StringBuffer();
    for (final entry in sections.entries) {
      final value = entry.value;
      if (value == null || value.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer
        ..writeln('=== ${entry.key} ===')
        ..write(value);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(mod.name),
          content: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: context.theme.textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDescriptionDialog(
    BuildContext context,
    String modName,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(modName),
          content: SingleChildScrollView(
            child: SelectableText(
              description,
              style: context.theme.textTheme.bodyMedium,
            ),
            // If you have markdown content, you can use flutter_markdown package
            // child: MarkdownBody(data: description),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogModGameVersionReq extends ConsumerWidget {
  const _CatalogModGameVersionReq({required this.mod});

  final ModRepoEntry mod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final installedVersion = ref.watch(AppState.starsectorVersion).valueOrNull;
    // true  = made for the installed game version (positive standout)
    // false = made for a different/older game version (warning)
    // null  = installed or required version unknown (neutral)
    final match = gameVersionMatchesInstalled(
      mod.gameVersionReq,
      installedVersion,
    );

    final tooltip = StringBuffer(
      'Game version required: ${mod.gameVersionReq}',
    );
    if (installedVersion != null && installedVersion.isNotEmpty) {
      tooltip.write('\nYour game: $installedVersion');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: MovingTooltipWidget.text(
        message: tooltip.toString(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            // Only a known mismatch (false) warns; unknown (null) stays neutral.
            color: match != false
                ? theme.cardColor.withValues(alpha: 0.9)
                : theme.statusColors.warning.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.darker(15),
                    strokeAlign: BorderSide.strokeAlignOutside,
                    width: 1,
                  ),
                ),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: Transform.translate(
                    offset: const Offset(2.0, -1.0),
                    child: StrokeText(
                      'S',
                      strokeWidth: 1,
                      borderOnTop: true,
                      strokeColor: theme.colorScheme.surfaceTint.darker(70),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: "Orbitron",
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.darker(5),
                      ),
                    ),
                  ),
                ),
              ),
              TextTriOS(
                mod.gameVersionReq ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.labelLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModImage extends StatelessWidget {
  final CatalogMod mod;
  final int? size;

  const ModImage({super.key, required this.mod, this.size});

  @override
  Widget build(BuildContext context) {
    final ModImageSource? source = mod.catalogImage;

    if (source == null) return _defaultImage();

    return MovingTooltipWidget.framed(
      tooltipWidget: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: media.size.width * 0.9,
              maxHeight: media.size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: _buildImage(source, fit: BoxFit.scaleDown)),
              ],
            ),
          );
        },
      ),
      child: _buildImage(
        source,
        fit: BoxFit.scaleDown,
        cacheWidth: size == null ? null : size! * 2,
      ),
    );
  }

  Widget _buildImage(ModImageSource source, {BoxFit? fit, int? cacheWidth}) =>
      switch (source) {
        WebModImage(:final url) => Image.network(
          url,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) => _defaultImage(),
        ),
        FileModImage(:final file) => Image.file(
          file,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) => _defaultImage(),
        ),
      };

  Widget _defaultImage() {
    return Container(
      width: 192.0,
      height: 160.0,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: 64.0,
        color: Colors.grey.withValues(alpha: 0.5),
      ),
    );
  }
}

class Tags extends StatelessWidget {
  final ModRepoEntry mod;

  const Tags({super.key, required this.mod});

  @override
  Widget build(BuildContext context) {
    final tags = [
      ...?mod.categories,
      ...?mod.sources?.map((source) {
        switch (source) {
          case ModSource.Index:
            return 'Index';
          case ModSource.ModdingSubforum:
            return 'Modding Subforum';
          case ModSource.Discord:
            return 'Discord';
          case ModSource.NexusMods:
            return 'NexusMods';
        }
      }),
    ];

    if (tags.isEmpty) return const SizedBox.shrink();
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.tag,
          size: 12.0,
          color: labelStyle?.color?.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 2.0),
        Expanded(
          child: TextTriOS(
            tags.join(', '),
            maxLines: 1,
            overflow: .ellipsis,
            style: labelStyle?.copyWith(
              color: labelStyle.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CatalogDownloadState {
  updateDirectDownload,
  updateWebsite,
  installedEnabled,
  installedDisabled,
  notInstalledDirectDownload,
  notInstalledWebsite,
  noDownloadLink,
}

class CatalogDownloadButton extends ConsumerWidget {
  final ModRepoEntry mod;
  final Mod? installedMod;
  final VersionCheckComparison? versionCheckComparison;
  final void Function(String) linkLoader;
  final ForumLlmMod? llmMainMod;

  const CatalogDownloadButton({
    super.key,
    required this.mod,
    required this.installedMod,
    required this.versionCheckComparison,
    required this.linkLoader,
    this.llmMainMod,
  });

  _CatalogDownloadState _resolveState({
    required bool hasOneClick,
    required bool hasBrowserLink,
  }) {
    final hasUpdate = versionCheckComparison?.hasUpdate == true;

    if (installedMod != null && hasUpdate) {
      return hasOneClick
          ? _CatalogDownloadState.updateDirectDownload
          : _CatalogDownloadState.updateWebsite;
    }
    if (installedMod != null) {
      return installedMod!.isEnabledInGame
          ? _CatalogDownloadState.installedEnabled
          : _CatalogDownloadState.installedDisabled;
    }
    if (hasOneClick) {
      return _CatalogDownloadState.notInstalledDirectDownload;
    }
    if (hasBrowserLink) return _CatalogDownloadState.notInstalledWebsite;
    return _CatalogDownloadState.noDownloadLink;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final candidates = resolveDownloadCandidates(
      mod,
      llmMainMod,
      remoteVersion: versionCheckComparison?.remoteVersionCheck?.remoteVersion,
    );
    final primary = primaryCandidate(candidates);
    final tieSet = primaryTieSet(candidates);
    // Best browser-only link (a website or a manual-step link), used when no
    // one-click candidate exists.
    final browserLink = candidates.firstWhereOrNull((c) => !c.isOneClick);

    final state = _resolveState(
      hasOneClick: primary != null,
      hasBrowserLink: browserLink != null,
    );

    final IconData icon;
    final Color backgroundColor;
    final Color foregroundColor;
    final String label;
    final String tooltip;
    final VoidCallback? onPressed;
    final hasUpdate =
        state == _CatalogDownloadState.updateDirectDownload ||
        state == _CatalogDownloadState.updateWebsite;
    // Installed states render as an inert status marker, not a button.
    final isInstalledStatus =
        state == _CatalogDownloadState.installedEnabled ||
        state == _CatalogDownloadState.installedDisabled;

    // What this button's downloads are called, so it can spot its own download
    // no matter where it was started from.
    final target = DownloadTarget(
      modId: installedMod?.id,
      url: primary?.url,
      catalogName: mod.name,
      displayName: mod.name,
    );

    // Download states run the primary candidate (or open the chooser when
    // several candidates tie). A trios primary installs in-app with deps.
    final isTrios = primary?.kind == DownloadCandidateKind.triosDeepLink;
    final showChooser = tieSet.length > 1;
    void runPrimary() {
      executeDownloadCandidate(
        context,
        ref,
        primary!,
        modName: mod.name,
        sourceHint: DownloadSourceHint.fromModRepoEntry(mod),
        linkLoader: linkLoader,
        hasOwnBusyIndicator: true,
      );
    }

    switch (state) {
      case _CatalogDownloadState.updateDirectDownload:
        icon = Icons.arrow_upward;
        label = 'Update';
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        tooltip = isTrios
            ? 'Update available.\n\nThis mod supports Install with TriOS'
            : 'Update available';
        onPressed = runPrimary;
      case _CatalogDownloadState.updateWebsite:
        icon = Icons.arrow_upward;
        label = 'Update';
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        tooltip = 'Update available.\nOpen download page';
        onPressed = () => linkLoader(browserLink!.url);
      case _CatalogDownloadState.installedEnabled:
        icon = Icons.check;
        label = 'Installed';
        backgroundColor = theme.statusColors.success.withValues(alpha: 0.85);
        foregroundColor = theme.statusColors.onSuccess;
        tooltip = 'Installed and enabled.\nRight-click the card to disable.';
        onPressed = null;
      case _CatalogDownloadState.installedDisabled:
        icon = Icons.check;
        label = 'Installed';
        backgroundColor = theme.statusColors.neutral.withValues(alpha: 0.7);
        foregroundColor = theme.statusColors.onNeutral;
        tooltip = 'Installed but disabled.\nRight-click the card to enable.';
        onPressed = null;
      case _CatalogDownloadState.notInstalledDirectDownload:
        icon = Icons.download;
        label = 'Install';
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = isTrios
            ? 'Download ${mod.name}.\n\nThis mod supports Install with TriOS.'
            : 'Download ${mod.name}';
        onPressed = runPrimary;
      case _CatalogDownloadState.notInstalledWebsite:
        icon = Icons.open_in_browser;
        label = 'Get';
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = 'Open the download page';
        onPressed = () => linkLoader(browserLink!.url);
      case _CatalogDownloadState.noDownloadLink:
        icon = Icons.download;
        label = 'Install';
        backgroundColor = theme.colorScheme.surfaceContainer.withValues(
          alpha: 0.5,
        );
        foregroundColor = theme.disabledColor;
        tooltip = 'No download available';
        onPressed = null;
    }

    final isDownloadAction =
        state == _CatalogDownloadState.updateDirectDownload ||
        state == _CatalogDownloadState.notInstalledDirectDownload;
    final showTriosBrandIcon = isTrios && isDownloadAction;
    final useChooser = isDownloadAction && showChooser;

    // Installed: an inert status marker. Enable/disable lives in the card's
    // right-click menu, so the button never toggles the mod by surprise.
    if (isInstalledStatus) {
      return MovingTooltipWidget.text(
        message: tooltip,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // The update states show the full version-check readout on hover instead
    // of a line of text.
    final Widget? richTooltip =
        hasUpdate && installedMod != null && versionCheckComparison != null
        ? SizedBox(
            width: 400,
            child: VersionCheckTextReadout(
              versionCheckComparison!.comparisonInt,
              versionCheckComparison!.variant.versionCheckerInfo,
              versionCheckComparison!.remoteVersionCheck,
              installedMod!,
              true,
              false,
            ),
          )
        : null;
    final tooltipText = useChooser
        ? 'Several downloads available.\nClick to choose'
        : tooltip;

    Widget buildButton(VoidCallback? onTap, {required bool marksPending}) =>
        SizedBox(
          height: 30,
          child: ModDownloadButton(
            target: target,
            onPressed: onTap,
            markPendingOnPress: marksPending,
            // The disabled colors match the enabled ones so the button doesn't
            // gray out under the spinner.
            style: FilledButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: backgroundColor,
              disabledForegroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            spinnerSize: 20,
            spinnerColor: foregroundColor,
            icon: showTriosBrandIcon
                ? TriOSAppIcon(width: 14, height: 14, color: foregroundColor)
                : Icon(icon, size: 14),
            label: Padding(
              padding: const .only(right: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            tooltip: tooltipText,
            tooltipWidget: richTooltip,
          ),
        );

    if (useChooser) {
      return MenuAnchor(
        menuChildren: [
          for (final candidate in tieSet)
            DownloadCandidateMenuItem(
              candidate: candidate,
              target: target,
              onSelected: () => executeDownloadCandidate(
                context,
                ref,
                candidate,
                modName: mod.name,
                sourceHint: DownloadSourceHint.fromModRepoEntry(mod),
                linkLoader: linkLoader,
                hasOwnBusyIndicator: true,
              ),
            ),
        ],
        // Clicking only opens the menu, so it isn't a download click; the menu
        // item that starts one marks it instead.
        builder: (context, controller, _) => buildButton(
          () => controller.isOpen ? controller.close() : controller.open(),
          marksPending: false,
        ),
      );
    }

    // Website and no-link states don't start a download, so they never spin.
    return buildButton(onPressed, marksPending: isDownloadAction);
  }
}

class _ForumStatsFromGathered extends StatelessWidget {
  final CatalogMod gathered;
  static final _decimalFormat = NumberFormat.decimalPattern();
  static final _compactFormat = NumberFormat.compact();
  static final _dateFormat = DateFormat.yMMMMd();

  const _ForumStatsFromGathered({required this.gathered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.textTheme.labelSmall?.color;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: baseColor?.withValues(alpha: 0.6),
      fontSize: 11,
    );

    final date = gathered.lastPostDate;
    final isStale =
        date != null && DateTime.now().difference(date).inDays > 365;
    final activeStyle = style?.copyWith(
      color: style.color?.withValues(alpha: isStale ? 0.35 : 0.6),
    );

    Widget segment({
      required IconData icon,
      required String text,
      required String tooltip,
      TextStyle? segStyle,
    }) => MovingTooltipWidget.text(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 12, color: (segStyle ?? style)?.color),
          Text(text, style: segStyle ?? style),
        ],
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (gathered.views != null)
            segment(
              icon: Icons.visibility,
              text: _compactFormat.format(gathered.views),
              tooltip: '${_decimalFormat.format(gathered.views)} forum views',
            ),
          if (gathered.replies != null)
            segment(
              icon: Icons.forum,
              text: _compactFormat.format(gathered.replies),
              tooltip:
                  '${_decimalFormat.format(gathered.replies)} forum replies',
            ),
          if (date != null)
            segment(
              icon: Icons.schedule,
              text: _compactAge(date),
              segStyle: activeStyle,
              tooltip: 'Last forum post: ${_dateFormat.format(date)}',
            ),
        ],
      ),
    );
  }

  static String _compactAge(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo';
    return '${(diff.inDays / 365).round()}y';
  }
}
