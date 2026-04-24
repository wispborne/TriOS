import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/forum_post_dialog/forum_post_header.dart';
import 'package:trios/catalog/forum_post_dialog/html_to_widgets.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/trios/download_manager/download_manager.dart';

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
}) {
  showDialog(
    context: context,
    builder: (ctx) => _ForumPostDialog(
      details: details,
      index: index,
      linkLoader: linkLoader,
    ),
  );
}

class _ForumPostDialog extends ConsumerStatefulWidget {
  final ForumModDetails details;
  final ForumModIndex? index;
  final void Function(String href) linkLoader;

  const _ForumPostDialog({
    required this.details,
    required this.index,
    required this.linkLoader,
  });

  @override
  ConsumerState<_ForumPostDialog> createState() => _ForumPostDialogState();
}

class _ForumPostDialogState extends ConsumerState<_ForumPostDialog> {
  final _hoveredUrl = ValueNotifier<String?>(null);

  void _confirmAndDownload(String url, String label) {
    final modName = widget.details.title.isNotEmpty
        ? widget.details.title
        : label;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(modName),
        content: Text("Do you want to download '$modName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(downloadManager.notifier)
                  .downloadAndInstallMod(
                    modName,
                    url,
                    activateVariantOnComplete: false,
                  );
            },
            child: const Text('Download'),
          ),
        ],
      ),
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
            ForumPostHeader(
              details: widget.details,
              index: widget.index,
              onOpenInBrowser: () {
                final url = widget.index?.topicUrl;
                if (url != null && url.isNotEmpty) widget.linkLoader(url);
              },
              onToggleFullScreen: () {
                setState(() => _isFullScreen = !_isFullScreen);
              },
              isFullScreen: _isFullScreen,
              onClose: () => Navigator.of(context).pop(),
              onLinkTap: widget.linkLoader,
              onDownloadLink: _confirmAndDownload,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: htmlToWidgets(
                    widget.details.contentHtml,
                    context,
                    onLinkTap: widget.linkLoader,
                    onLinkHover: (url) => _hoveredUrl.value = url,
                    baseUrl: widget.index?.topicUrl,
                  ),
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
