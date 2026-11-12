import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/download_confirm.dart';
import 'package:trios/catalog/forum_post_dialog/html_to_widgets.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/summary_resolver.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/downloader.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/picture_viewer.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

/// The texts the dialog shows about a mod, apart from its posts. Picked the
/// way Starmodder picks them.
class AboutTexts {
  /// The short summary under the mod's name: the author's own words, or the
  /// AI sentence when the AI summary setting puts it first or there are no
  /// own words.
  final String? headerText;

  /// True when [headerText] is the AI sentence.
  final bool headerIsAi;

  /// The AI paragraph for the "About this mod" card. Null when AI summaries
  /// are turned off.
  final String? aiParagraph;

  const AboutTexts({
    this.headerText,
    this.headerIsAi = false,
    this.aiParagraph,
  });
}

/// Works out [AboutTexts] for [mod].
///
/// The header follows the AI summary setting, like the catalog card. The AI
/// paragraph shows whenever AI summaries aren't turned off, even next to the
/// author's own summary, the way Starmodder's mod page shows it. Neither
/// shows while AI features are off.
AboutTexts aboutTextsFor(CatalogMod mod, WidgetRef ref) {
  final aiMode = ref.watch(effectiveCatalogAiSummaryModeProvider);
  final header = resolveSummaryText(
    mod,
    aiMode: aiMode,
    aiLength: AiTextLength.sentence,
    authorOrder: AuthorTextOrder.shortFirst,
  );
  return AboutTexts(
    headerText: header?.text,
    headerIsAi: header?.source == ModSummarySource.ai,
    aiParagraph: aiMode == AiSummaryMode.never
        ? null
        : trimmedOrNull(mod.aiParagraph),
  );
}

/// The Description tab: the AI summary, then the forum post, then the
/// Discord post, each in its own card. Each part shows only when
/// there is one.
class DescriptionTab extends ConsumerWidget {
  final CatalogMod mod;

  /// The cached forum post. Null when TriOS doesn't have it.
  final ForumModDetails? forumDetails;

  /// The mod's Discord post as cleaned HTML. Null when there isn't one.
  final String? discordPostHtml;

  /// Called for a clicked link in a post.
  final void Function(String url) onLinkTap;

  /// Called with the link under the mouse, or null when it leaves.
  final void Function(String? url) onLinkHover;

  const DescriptionTab({
    super.key,
    required this.mod,
    required this.forumDetails,
    required this.discordPostHtml,
    required this.onLinkTap,
    required this.onLinkHover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final about = aboutTextsFor(mod, ref);
    final aiParagraph = about.aiParagraph;
    final aiFeaturesOn = ref.watch(
      appSettings.select((s) => s.enableAiFeatures),
    );
    // The mod has an AI paragraph, but the user hid AI summaries.
    final aiParagraphHidden =
        aiParagraph == null &&
        aiFeaturesOn &&
        trimmedOrNull(mod.aiParagraph) != null;
    final forumHtml = forumDetails?.contentHtml;
    final topicUrl = mod.topicUrl;
    final textStyle = theme.textTheme.bodyMedium;
    final mutedSmallStyle = theme.textTheme.labelSmall?.copyWith(
      color: detailsMutedColor(theme),
    );
    final smallButtonStyle = TextButton.styleFrom(
      foregroundColor: detailsMutedColor(theme),
      textStyle: theme.textTheme.labelMedium,
      visualDensity: VisualDensity.compact,
      padding: const .symmetric(horizontal: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    void setAiSummaryMode(AiSummaryMode mode) => ref
        .read(appSettings.notifier)
        .update((s) => s.copyWith(catalogAiSummaryMode: mode));

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        if (aiParagraph != null)
          ContentSection(
            icon: Icons.auto_awesome,
            title: 'About this mod',
            child: Column(
              crossAxisAlignment: .start,
              spacing: 8,
              children: [
                SelectableText(aiParagraph, style: textStyle),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        'Summary generated by AI. See the ${Constants.appName} '
                        'About page for AI Disclosure.',
                        style: mutedSmallStyle?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message:
                          'Stop showing AI summaries in the catalog. '
                          'You can turn them back on here or in the '
                          "catalog's menu.",
                      child: TextButton(
                        style: smallButtonStyle,
                        onPressed: () => setAiSummaryMode(AiSummaryMode.never),
                        child: const Text('Hide AI summaries'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (aiParagraphHidden)
          Align(
            alignment: Alignment.centerLeft,
            child: MovingTooltipWidget.text(
              message: 'Show AI summaries in the catalog again.',
              child: TextButton.icon(
                style: smallButtonStyle,
                onPressed: () =>
                    setAiSummaryMode(AiSummaryMode.whenNoAuthorText),
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Show AI summary'),
              ),
            ),
          ),
        if (forumHtml != null && forumHtml.isNotEmpty)
          ContentSection(
            icon: Icons.public,
            title: 'Forum post',
            child: _Post(
              html: forumHtml,
              baseUrl: topicUrl,
              onLinkTap: onLinkTap,
              onLinkHover: onLinkHover,
            ),
          ),
        if (discordPostHtml case final html? when html.isNotEmpty)
          ContentSection(
            icon: Icons.discord,
            title: 'Discord post',
            child: _Post(
              html: html,
              baseUrl: null,
              onLinkTap: onLinkTap,
              onLinkHover: onLinkHover,
            ),
          ),
      ],
    );
  }
}

/// A post drawn by the forum renderer. Clicking a picture opens the picture
/// viewer on the post's pictures.
class _Post extends StatelessWidget {
  final String html;
  final String? baseUrl;
  final void Function(String url) onLinkTap;
  final void Function(String? url) onLinkHover;

  const _Post({
    required this.html,
    required this.baseUrl,
    required this.onLinkTap,
    required this.onLinkHover,
  });

  void _openPicture(BuildContext context, String url) {
    final urls = postPictureUrls(html, baseUrl: baseUrl);
    final index = urls.indexOf(url);
    showPictureViewer(
      context,
      pictures: [
        for (final u in index >= 0 ? urls : [url]) ViewerPicture(url: u),
      ],
      startIndex: index >= 0 ? index : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: htmlToWidgets(
        html,
        context,
        onLinkTap: onLinkTap,
        onLinkHover: onLinkHover,
        baseUrl: baseUrl,
        onImageTap: (url) => _openPicture(context, url),
      ),
    );
  }
}

/// Handles a link clicked in a post. A link to a mod file downloads it.
/// Anything else goes to [linkLoader].
///
/// Shows a spinner while it checks whether the link is a file.
Future<void> openPostLink(
  BuildContext context,
  WidgetRef ref,
  String url, {
  required String modName,
  required String? forumThreadId,
  required void Function(String url) linkLoader,
}) async {
  if (!context.mounted) return;
  final navigator = Navigator.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: ThemedCircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    ),
  );

  try {
    final httpClient = ref.read(triOSHttpClient);
    final result = await DownloadManager.fetchFinalUrlAndHeaders(
      url,
      httpClient,
    );
    final isDownload = await DownloadManager.isDownloadableFile(
      result.url,
      result.headersMap,
      httpClient,
    );
    navigator.pop(); // dismiss spinner
    if (isDownload && context.mounted) {
      confirmAndDownloadModViaManager(
        context,
        ref,
        modName: modName,
        downloadUrl: result.url,
        skipDialog: true,
        sourceHint: DownloadSourceHint(
          catalogName: modName,
          forumThreadId: forumThreadId,
        ),
      );
      return;
    }
  } catch (e) {
    Fimber.d('Error checking if link is downloadable: $e');
    navigator.pop(); // dismiss spinner
  }
  linkLoader(url);
}

/// The browser-style bar at the bottom of the dialog that shows the link under
/// the mouse.
class LinkStatusBar extends StatelessWidget {
  final ValueListenable<String?> hoveredUrl;

  const LinkStatusBar({super.key, required this.hoveredUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: hoveredUrl,
      builder: (context, url, _) {
        if (url == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const .all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Text(
            url,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.hintColor,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
