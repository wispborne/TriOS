import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/download_confirm.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_header.dart';
import 'package:trios/catalog/forum_post_dialog/html_to_widgets.dart';
import 'package:trios/catalog/mod_browser_page_controller.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_data.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/downloader.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

/// Persists across dialog instances within the app session.
bool _isFullScreen = false;

/// Entry point for the in-app Forum Post Dialog. Renders [details.contentHtml]
/// as native Flutter widgets; never launches a browser for the post body.
/// Outbound links and iframe placeholders route through [linkLoader].
void showForumPostDialog(
  BuildContext context, {
  required ForumModDetails details,
  ForumModIndex? index,
  required void Function(String href) linkLoader,
  bool canUseEmbeddedBrowser = true,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _ForumPostDialog(
      details: details,
      index: index,
      linkLoader: linkLoader,
      canUseEmbeddedBrowser: canUseEmbeddedBrowser,
    ),
  );
}

class _ForumPostDialog extends ConsumerStatefulWidget {
  final ForumModDetails details;
  final ForumModIndex? index;
  final void Function(String href) linkLoader;
  final bool canUseEmbeddedBrowser;

  const _ForumPostDialog({
    required this.details,
    required this.index,
    required this.linkLoader,
    required this.canUseEmbeddedBrowser,
  });

  @override
  ConsumerState<_ForumPostDialog> createState() => _ForumPostDialogState();
}

class _ForumPostDialogState extends ConsumerState<_ForumPostDialog> {
  final _hoveredUrl = ValueNotifier<String?>(null);

  Future<void> _onLinkTap(String url) async {
    // Show a spinner while we check whether the link is a downloadable file.
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
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
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss spinner
      if (isDownload) {
        _confirmAndDownload(result.url, url);
        return;
      }
    } catch (e) {
      Fimber.d('Error checking if link is downloadable: $e');
      if (mounted) Navigator.of(context).pop(); // dismiss spinner
    }
    widget.linkLoader(url);
  }

  void _confirmAndDownload(String url, String label) {
    final modName = widget.details.title.isNotEmpty
        ? widget.details.title
        : label;
    confirmAndDownloadModViaManager(
      context,
      ref,
      modName: modName,
      downloadUrl: url,
      skipDialog: true,
      sourceHint: DownloadSourceHint(
        catalogName: modName,
        forumThreadId: widget.index?.topicId.toString(),
      ),
    );
  }

  /// The per-mod download rows the topic offers. Prefers the LLM-structured
  /// links (trios installs, real labels, confidence); falls back to the links
  /// scraped from the post HTML when the topic has no LLM data.
  List<DownloadGroup> _downloadGroups() {
    final controller = ref.read(catalogPageControllerProvider.notifier);
    return buildDownloadGroups(
      index: widget.index,
      scrapedLinks: widget.details.links,
      isInstalled: (name) => controller.statusForModName(name) != null,
    );
  }

  @override
  void dispose() {
    _hoveredUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ForumPostHeader(
                      data: ModSummaryData.fromDetails(
                        widget.details,
                        widget.index,
                        null,
                      ),
                      showSummary: ref.watch(
                        appSettings.select(
                          (s) => s.catalogShowDialogHeaderSummary,
                        ),
                      ),
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
                      onOpenInSystemBrowser: () {
                        final url = widget.index?.topicUrl;
                        if (url != null && url.isNotEmpty) {
                          url.openAsUriInBrowser();
                        }
                      },
                      onOpenInEmbeddedBrowser: widget.canUseEmbeddedBrowser
                          ? () {
                              final url = widget.index?.topicUrl;
                              if (url != null && url.isNotEmpty) {
                                widget.linkLoader(url);
                              }
                            }
                          : null,
                      onToggleFullScreen: () {
                        setState(() => _isFullScreen = !_isFullScreen);
                      },
                      isFullScreen: _isFullScreen,
                      onClose: () => Navigator.of(context).pop(),
                      downloadGroups: _downloadGroups(),
                      onDownload: (candidate, modName) =>
                          executeDownloadCandidate(
                            context,
                            ref,
                            candidate,
                            modName: modName,
                            // Use the download row's own mod name (not the
                            // thread title) so an add-on links to itself, not
                            // the thread's main mod.
                            sourceHint: DownloadSourceHint(
                              catalogName: modName,
                              forumThreadId: widget.index?.topicId.toString(),
                            ),
                            linkLoader: widget.linkLoader,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: htmlToWidgets(
                          widget.details.contentHtml,
                          context,
                          onLinkTap: _onLinkTap,
                          onLinkHover: (url) => _hoveredUrl.value = url,
                          baseUrl: widget.index?.topicUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Browser-style URL status bar.
            ValueListenableBuilder<String?>(
              valueListenable: _hoveredUrl,
              builder: (context, url, _) {
                if (url == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
