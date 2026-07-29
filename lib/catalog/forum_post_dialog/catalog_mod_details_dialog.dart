import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_header.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/summary_resolver.dart';
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
  required CatalogMod gathered,
  required void Function(String href) linkLoader,
  bool canUseEmbeddedBrowser = true,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _CatalogModDetailsDialog(
      gathered: gathered,
      linkLoader: linkLoader,
      canUseEmbeddedBrowser: canUseEmbeddedBrowser,
    ),
  );
}

class _CatalogModDetailsDialog extends ConsumerStatefulWidget {
  final CatalogMod gathered;
  final void Function(String href) linkLoader;
  final bool canUseEmbeddedBrowser;

  const _CatalogModDetailsDialog({
    required this.gathered,
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
      catalogMod: widget.gathered.entry,
      isInstalled: (name) => controller.statusForModName(name) != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.gathered;
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

    final website = mod.entry.getBestWebsiteUrl();
    final showHeaderSummary = ref.watch(
      appSettings.select((s) => s.catalogShowDialogHeaderSummary),
    );

    final header = ForumPostHeader(
      data: mod,
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
        sourceHint: DownloadSourceHint(catalogName: modName),
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
            if (showHeaderSummary)
              Flexible(child: SingleChildScrollView(child: header))
            else ...[
              header,
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _Body(gathered: mod),
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
  final CatalogMod gathered;

  const _Body({required this.gathered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiMode = ref.watch(effectiveCatalogAiSummaryModeProvider);

    final authorResolved = resolveAuthorText(
      gathered,
      authorOrder: AuthorTextOrder.longFirst,
    );
    final authorText = authorResolved?.text;
    final showAi = shouldShowAiWithAuthorText(
      gathered,
      aiMode: aiMode,
      hasAuthorText: authorText != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ModImage(mod: gathered, size: 300),
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
          SelectableText(
            gathered.aiParagraph!,
            style: theme.textTheme.bodyMedium,
          ),
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
