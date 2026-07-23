import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_dialog.dart';
import 'package:trios/catalog/forum_post_dialog/catalog_mod_details_dialog.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_data.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/dashboard/version_check_text_readout.dart';
import 'package:trios/mod_manager/mod_info_dialog.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/stroke_text.dart';
import 'package:trios/widgets/text_trios.dart';

class CatalogModCard extends ConsumerStatefulWidget {
  final CatalogMod mod;
  final void Function(String) linkLoader;
  final bool isSelected;
  final Mod? installedMod;
  final VersionCheckComparison? versionCheckComparison;
  final ForumModIndex? forumModIndex;

  /// Whether the app's built-in browser panel is usable on this platform.
  /// Gates the "Open in the built-in browser" actions.
  final bool canUseEmbeddedBrowser;

  const CatalogModCard({
    super.key,
    required this.mod,
    required this.linkLoader,
    this.isSelected = false,
    this.installedMod,
    this.versionCheckComparison,
    this.forumModIndex,
    this.canUseEmbeddedBrowser = true,
  });

  @override
  ConsumerState<CatalogModCard> createState() => _CatalogModCardState();
}

class _CatalogModCardState extends ConsumerState<CatalogModCard> {
  /// The LLM mod this card represents. For a synthesized "part of a thread"
  /// entry, that's the specific bundled mod (matched by name); otherwise it's
  /// the thread's main mod. Drives which downloads the install button offers.
  ForumLlmMod? get _targetLlmMod {
    final llm = widget.forumModIndex?.llm;
    if (llm == null) return null;
    if (widget.mod.isPartOfThread) {
      final key = widget.mod.name.toLowerCase().trim();
      return llm.mods.firstWhereOrNull(
            (m) => m.name.toLowerCase().trim() == key,
          ) ??
          llm.mainMod;
    }
    return llm.mainMod;
  }

  /// The installed mod's version checker result, when it has one. Its download
  /// link is the mod author's own, so it outranks the catalog and forum links.
  VersionCheckerInfo? get _remoteVersion =>
      widget.versionCheckComparison?.remoteVersionCheck?.remoteVersion;

  Color _statusBarColor(ThemeData theme) {
    final mod = widget.installedMod;
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
    final mod = widget.mod;
    final downloadCandidates = resolveDownloadCandidates(
      mod,
      _targetLlmMod,
      remoteVersion: _remoteVersion,
    );

    final theme = Theme.of(context);
    return Builder(
      builder: (context) {
        final websiteUrl = mod.getBestWebsiteUrl();
        final topicId = widget.forumModIndex?.topicId;
        final forumDetails = topicId == null
            ? null
            : ref.watch(forumDetailsForTopic(topicId));
        final hasForumDetails =
            forumDetails != null && !forumDetails.isPlaceholderDetail;
        // Clicking any card opens a details dialog: the forum post when it's
        // cached, otherwise a fallback built from catalog data. Only skip when
        // there's genuinely nothing to show.
        final hasDetailsToShow =
            hasForumDetails ||
            widget.forumModIndex != null ||
            (mod.description?.isNotEmpty ?? false) ||
            (mod.summary?.isNotEmpty ?? false) ||
            (mod.images?.isNotEmpty ?? false) ||
            downloadCandidates.isNotEmpty;

        // The hover tooltip: a full mod overview. Prefer rich forum details
        // (author title, post count, avatar) when the post is cached.
        final summaryData = hasForumDetails
            ? ModSummaryData.fromDetails(
                forumDetails,
                widget.forumModIndex,
                mod,
              )
            : ModSummaryData.fromCatalog(mod, widget.forumModIndex);

        return ContextMenuRegion(
          contextMenu: ContextMenu(
            entries: [
              if (false)
                MenuItem(
                  label: 'View Mod Details...',
                  icon: Icons.info_outline,
                  onSelected: () => showModInfoDialog(
                    context,
                    mod: widget.installedMod,
                    catalogMod: mod,
                    forumModIndex: widget.forumModIndex,
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
                      child: Icon(downloadCandidateIcon(candidate), size: 16),
                    ),
                    onSelected: () => executeDownloadCandidate(
                      context,
                      ref,
                      candidate,
                      modName: mod.name,
                      sourceHint: DownloadSourceHint.fromCatalogMod(mod),
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
              if (widget.installedMod != null) ...[
                const MenuHeader(text: 'Installed Mod'),
                if (widget.installedMod!.isEnabledInGame)
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
                      data: summaryData,
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
                                child: ModImage(
                                  mod: mod,
                                  size: 60,
                                  fallbackImageUrl: _targetLlmMod?.imageUrl,
                                ),
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
                                  if (mod.authorsList?.isNotEmpty == true)
                                    Text(
                                      mod.getAuthorsDeduplicated().join(', '),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    ),
                                  if (mod.isPartOfThread)
                                    MovingTooltipWidget.text(
                                      message:
                                          'Part of the "${mod.partOfThreadTitle}" '
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
                                              'part of ${mod.partOfThreadTitle}',
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
                                        if (widget.forumModIndex != null)
                                          _ForumStats(
                                            forumModIndex:
                                                widget.forumModIndex!,
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
                    if (widget.installedMod != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: MovingTooltipWidget.text(
                          message: widget.installedMod!.isEnabledInGame
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
                        installedMod: widget.installedMod,
                        versionCheckComparison: widget.versionCheckComparison,
                        linkLoader: widget.linkLoader,
                        llmMainMod: _targetLlmMod,
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
    CatalogMod mod,
  ) {
    final authorText = mod.summary ?? mod.description;
    final aiSummary = _targetLlmMod?.extras?.summary;
    final aiSummaryMode = ref.watch(
      appSettings.select((s) => s.catalogAiSummaryMode),
    );

    final String? shownText = switch (aiSummaryMode) {
      AiSummaryMode.always => aiSummary?.sentence ?? authorText,
      AiSummaryMode.whenNoAuthorText => authorText ?? aiSummary?.sentence,
      AiSummaryMode.never => authorText,
    };
    // The hover tooltip shows the AI paragraph only when the AI sentence is
    // what's actually displayed; author text keeps its default overflow
    // tooltip.
    final bool showingAiSentence =
        shownText != null && shownText == aiSummary?.sentence;

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
      showForumPostDialog(
        context,
        details: forumDetails,
        index: widget.forumModIndex,
        linkLoader: widget.linkLoader,
        canUseEmbeddedBrowser: widget.canUseEmbeddedBrowser,
      );
    } else {
      showCatalogModDetailsDialog(
        context,
        mod: widget.mod,
        index: widget.forumModIndex,
        linkLoader: widget.linkLoader,
        canUseEmbeddedBrowser: widget.canUseEmbeddedBrowser,
      );
    }
  }

  /// Enable or disable the installed mod. Moved off the primary card button
  /// so the button stays a pure Install/Update/Installed status.
  void _setModEnabled(bool enabled) {
    final mod = widget.installedMod;
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
    final urls = widget.mod.urls;
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

  void _showDebugDialog(BuildContext context, CatalogMod mod) {
    final forumModIndex = widget.forumModIndex;
    final targetLlmMod = _targetLlmMod;
    final downloadCandidates = resolveDownloadCandidates(
      mod,
      targetLlmMod,
      remoteVersion: _remoteVersion,
    );

    // Note: the forum index's toString already contains its LLM data, so we
    // don't dump that separately. The per-card download candidate is the one
    // LLM mod (of possibly several in a thread) that drives this card.
    final sections = <String, String?>{
      'Catalog mod': mod.toString(),
      'Forum index': forumModIndex?.toString(),
      'Download candidate (this card)': targetLlmMod?.toString(),
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

  final CatalogMod mod;

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

  /// Used when the mod itself has no scraped image, e.g. an image found in the
  /// AI-extracted forum data.
  final String? fallbackImageUrl;

  const ModImage({
    super.key,
    required this.mod,
    this.size,
    this.fallbackImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final mainImage = mod.images?.values.isNotEmpty == true
        ? mod.images?.values.first
        : null;

    // Prefer the mod's own scraped image; otherwise fall back to the image
    // from the AI-extracted forum data, if any.
    final String? imageUrl = mainImage?.url ?? fallbackImageUrl;

    if (imageUrl != null) {
      final description = mainImage?.description;
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
                  Flexible(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.scaleDown,
                      errorBuilder: (context, error, stackTrace) =>
                          _defaultImage(),
                    ),
                  ),
                  if (description != null && description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        child: Image.network(
          imageUrl,
          fit: .scaleDown,
          cacheWidth: size == null ? null : size! * 2,
          errorBuilder: (context, error, stackTrace) {
            return _defaultImage();
          },
        ),
      );
    } else {
      return _defaultImage();
    }
  }

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
  final CatalogMod mod;

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

class CatalogDownloadButton extends ConsumerStatefulWidget {
  final CatalogMod mod;
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

  @override
  ConsumerState<CatalogDownloadButton> createState() =>
      _CatalogDownloadButtonState();
}

class _CatalogDownloadButtonState extends ConsumerState<CatalogDownloadButton> {
  /// True between clicking a one-click download action and a real signal
  /// taking over (deep-link dialog ready, or the download appearing in the
  /// download manager). Drives the button spinner during that gap.
  bool _clickBusy = false;
  Timer? _busyFallback;

  CatalogMod get mod => widget.mod;

  Mod? get installedMod => widget.installedMod;

  VersionCheckComparison? get versionCheckComparison =>
      widget.versionCheckComparison;

  void Function(String) get linkLoader => widget.linkLoader;

  ForumLlmMod? get llmMainMod => widget.llmMainMod;

  void _markBusy() {
    _busyFallback?.cancel();
    // Safety net: never spin forever if no completion signal arrives (e.g.
    // a de-duplicated double-click, or a download that fails to register).
    _busyFallback = Timer(const Duration(seconds: 10), _clearBusy);
    setState(() => _clickBusy = true);
  }

  void _clearBusy() {
    _busyFallback?.cancel();
    if (_clickBusy && mounted) setState(() => _clickBusy = false);
  }

  @override
  void dispose() {
    _busyFallback?.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The click-busy spinner hands off to real signals: the deep-link
    // confirmation dialog becoming ready, or the download manager picking up
    // a download for this mod (whose own in-progress state then drives the
    // spinner until install finishes).
    ref.listen(deepLinkProcessing, (previous, next) {
      if (previous == true && next == false) _clearBusy();
    });
    ref.listen(downloadManager, (previous, next) {
      final downloads = next.valueOrNull ?? const <Download>[];
      if (downloads.any((d) => d.displayName == mod.name)) _clearBusy();
    });
    final activeDownload = ref
        .watch(downloadManager)
        .valueOrNull
        ?.firstWhereOrNull((d) => d.displayName == mod.name && d.isInProgress);
    final isBusy = _clickBusy || activeDownload != null;

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

    // Download states run the primary candidate (or open the chooser when
    // several candidates tie). A trios primary installs in-app with deps.
    final isTrios = primary?.kind == DownloadCandidateKind.triosDeepLink;
    final showChooser = tieSet.length > 1;
    void runPrimary() {
      _markBusy();
      executeDownloadCandidate(
        context,
        ref,
        primary!,
        modName: mod.name,
        sourceHint: DownloadSourceHint.fromCatalogMod(mod),
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
            ? 'Update available.\nInstall with TriOS (also installs the mods it needs)'
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
        icon = isTrios ? Icons.rocket_launch : Icons.download;
        label = 'Install';
        backgroundColor = theme.statusColors.info;
        foregroundColor = theme.statusColors.onInfo;
        tooltip = isTrios
            ? 'Install ${mod.name} with TriOS\n(also installs the mods it needs)'
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

    Widget buildButton(VoidCallback? onTap) => SizedBox(
      height: 30,
      child: FilledButton.icon(
        // While busy, ignore clicks; the disabled colors match the enabled
        // ones so the button doesn't gray out under the spinner.
        onPressed: isBusy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isBusy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Icon(icon, size: 14),
        label: Padding(
          padding: const .only(right: 4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );

    final Widget buttonChild;
    if (useChooser) {
      buttonChild = MenuAnchor(
        menuChildren: [
          for (final candidate in tieSet) _downloadMenuItem(context, candidate),
        ],
        builder: (context, controller, _) => buildButton(
          () => controller.isOpen ? controller.close() : controller.open(),
        ),
      );
    } else {
      buttonChild = buildButton(onPressed);
    }

    if (hasUpdate && installedMod != null && versionCheckComparison != null) {
      final comparison = versionCheckComparison!;
      return MovingTooltipWidget.framed(
        tooltipWidget: SizedBox(
          width: 400,
          child: VersionCheckTextReadout(
            comparison.comparisonInt,
            comparison.variant.versionCheckerInfo,
            comparison.remoteVersionCheck,
            installedMod!,
            true,
            false,
          ),
        ),
        child: buttonChild,
      );
    }

    final tooltipText = useChooser
        ? 'Several downloads available.\nClick to choose'
        : tooltip;
    return MovingTooltipWidget.text(message: tooltipText, child: buttonChild);
  }

  /// One row in the tie-break chooser opened from the button.
  Widget _downloadMenuItem(BuildContext context, DownloadCandidate candidate) {
    final theme = Theme.of(context);
    final subtitle = downloadCandidateSubtitle(candidate);
    return MenuItemButton(
      leadingIcon: Icon(downloadCandidateIcon(candidate), size: 16),
      onPressed: () {
        _markBusy();
        executeDownloadCandidate(
          context,
          ref,
          candidate,
          modName: mod.name,
          sourceHint: DownloadSourceHint.fromCatalogMod(mod),
          linkLoader: linkLoader,
          hasOwnBusyIndicator: true,
        );
      },
      child: MovingTooltipWidget.text(
        message: candidate.url,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(candidate.label),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumStats extends StatelessWidget {
  final ForumModIndex forumModIndex;
  static final _decimalFormat = NumberFormat.decimalPattern();
  static final _compactFormat = NumberFormat.compact();
  static final _dateFormat = DateFormat.yMMMMd();

  const _ForumStats({required this.forumModIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.textTheme.labelSmall?.color;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: baseColor?.withValues(alpha: 0.6),
      fontSize: 11,
    );

    final date = forumModIndex.lastPostDate;
    // The age chip = last post in the thread, NOT necessarily a mod update.
    // A mod can update without the post changing, so the tooltip says "last
    // forum post". Dim when very old so abandoned threads read that way.
    final isStale =
        date != null && DateTime.now().difference(date).inDays > 365;
    final activeStyle = style?.copyWith(
      color: style.color?.withValues(alpha: isStale ? 0.35 : 0.6),
    );
    final modCount = forumModIndex.llm?.mods.length ?? 0;

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

    // Everything here is secondary info, so it stays on one line and scales
    // down slightly on narrow cards instead of wrapping or overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          segment(
            icon: Icons.visibility,
            text: _compactFormat.format(forumModIndex.views),
            tooltip:
                '${_decimalFormat.format(forumModIndex.views)} forum views',
          ),
          segment(
            icon: Icons.forum,
            text: _compactFormat.format(forumModIndex.replies),
            tooltip:
                '${_decimalFormat.format(forumModIndex.replies)} forum replies',
          ),
          if (date != null)
            segment(
              icon: Icons.schedule,
              text: _compactAge(date),
              segStyle: activeStyle,
              tooltip: 'Last forum post: ${_dateFormat.format(date)}',
            ),
          if (modCount > 1)
            segment(
              icon: Icons.layers,
              text: '+${modCount - 1}',
              tooltip:
                  'This forum thread has $modCount mods.\nClick the card to see them all.',
            ),
        ],
      ),
    );
  }

  /// Very short age for the card footer: "3h", "6d", "2mo", "3y".
  static String _compactAge(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo';
    return '${(diff.inDays / 365).round()}y';
  }
}
