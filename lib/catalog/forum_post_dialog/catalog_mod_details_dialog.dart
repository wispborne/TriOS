import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_header.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_data.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';

/// The details dialog used when a mod has no cached forum post HTML. Shares the
/// same shell, header, and grouped download rows as the forum-post dialog, but
/// builds its body from the catalog mod: image, description/summary, and the
/// AI paragraph summary when the AI-summary setting allows it.
void showCatalogModDetailsDialog(
  BuildContext context, {
  required CatalogMod mod,
  ForumModIndex? index,
  required void Function(String href) linkLoader,
  bool canUseEmbeddedBrowser = true,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _CatalogModDetailsDialog(
      mod: mod,
      index: index,
      linkLoader: linkLoader,
      canUseEmbeddedBrowser: canUseEmbeddedBrowser,
    ),
  );
}

class _CatalogModDetailsDialog extends ConsumerStatefulWidget {
  final CatalogMod mod;
  final ForumModIndex? index;
  final void Function(String href) linkLoader;
  final bool canUseEmbeddedBrowser;

  const _CatalogModDetailsDialog({
    required this.mod,
    required this.index,
    required this.linkLoader,
    required this.canUseEmbeddedBrowser,
  });

  @override
  ConsumerState<_CatalogModDetailsDialog> createState() =>
      _CatalogModDetailsDialogState();
}

class _CatalogModDetailsDialogState
    extends ConsumerState<_CatalogModDetailsDialog> {
  bool _isFullScreen = false;

  List<DownloadGroup> _downloadGroups() {
    final controller = ref.read(catalogPageControllerProvider.notifier);
    return buildDownloadGroups(
      index: widget.index,
      catalogMod: widget.mod,
      isInstalled: (name) => controller.statusForModName(name) != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;

    final double maxWidth;
    final double maxHeight;
    final EdgeInsets insetPadding;
    if (_isFullScreen) {
      maxWidth = windowSize.width;
      maxHeight = windowSize.height;
      insetPadding = EdgeInsets.zero;
    } else {
      maxWidth = windowSize.width.clamp(0.0, 900.0);
      maxHeight = windowSize.height * 0.9;
      insetPadding = const EdgeInsets.all(24);
    }

    final website = widget.mod.getBestWebsiteUrl();
    final showHeaderSummary = ref.watch(
      appSettings.select((s) => s.catalogShowDialogHeaderSummary),
    );

    final header = ForumPostHeader(
      data: ModSummaryData.fromCatalog(widget.mod, widget.index),
      showSummary: showHeaderSummary,
      onToggleSummary: () {
        ref
            .read(appSettings.notifier)
            .update(
              (s) => s.copyWith(
                catalogShowDialogHeaderSummary:
                    !s.catalogShowDialogHeaderSummary,
              ),
            );
      },
      onOpenInSystemBrowser: (website != null && website.isNotEmpty)
          ? () => website.openAsUriInBrowser()
          : null,
      onOpenInEmbeddedBrowser:
          (widget.canUseEmbeddedBrowser &&
              website != null &&
              website.isNotEmpty)
          ? () => widget.linkLoader(website)
          : null,
      onToggleFullScreen: () {
        setState(() => _isFullScreen = !_isFullScreen);
      },
      isFullScreen: _isFullScreen,
      onClose: () => Navigator.of(context).pop(),
      downloadGroups: _downloadGroups(),
      onDownload: (candidate, modName) => executeDownloadCandidate(
        context,
        ref,
        candidate,
        modName: modName,
        // The download row's own mod name is the catalog identity; the thread
        // id (when known) is a fallback clue.
        sourceHint: DownloadSourceHint(
          catalogName: modName,
          forumThreadId: widget.index?.topicId.toString(),
        ),
        linkLoader: widget.linkLoader,
      ),
    );

    return Dialog(
      insetPadding: insetPadding,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 8.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: 400,
        ),
        child: Column(
          mainAxisSize: _isFullScreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The summary block can be tall, so let it scroll rather than
            // overflow. When the header shows the summary it already covers
            // the image and description, so the body (which would duplicate
            // it) is dropped; when hidden, the header stays pinned and the
            // body scrolls instead.
            if (showHeaderSummary)
              Flexible(child: SingleChildScrollView(child: header))
            else ...[
              header,
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _Body(mod: widget.mod, index: widget.index),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final CatalogMod mod;
  final ForumModIndex? index;

  const _Body({required this.mod, this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiMode = ref.watch(effectiveCatalogAiSummaryModeProvider);

    final authorText = mod.description ?? mod.summary;
    final aiParagraph = index?.llm?.mainMod?.extras?.summary?.paragraph;
    final showAi =
        aiParagraph != null &&
        aiParagraph.isNotEmpty &&
        switch (aiMode) {
          AiSummaryMode.always => true,
          AiSummaryMode.whenNoAuthorText => authorText == null,
          AiSummaryMode.never => false,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ModImage(
              mod: mod,
              size: 300,
              fallbackImageUrl: index?.llm?.mainMod?.imageUrl,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (authorText != null && authorText.isNotEmpty)
          SelectableText(authorText, style: theme.textTheme.bodyMedium)
        else if (!showAi)
          Text(
            'No description...yet!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        if (showAi) ...[
          const SizedBox(height: 16),
          SelectableText(aiParagraph, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Summary generated by AI. See the ${Constants.appName} About page '
            'for AI Disclosure.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }
}
