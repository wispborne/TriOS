import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_confirm.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/trios_app_icon.dart';

/// Runs a download [candidate] the same way everywhere it's offered (card
/// button, card menu, forum dialog):
/// - a trios deep link goes through the in-app install flow (dependencies and
///   already-installed checks included);
/// - a website or manual-step link opens in the browser via [linkLoader];
/// - anything else downloads through the download manager.
///
/// Set [hasOwnBusyIndicator] when the caller shows its own busy state (e.g.
/// the catalog card button's spinner) to skip the acknowledgment snackbar.
void executeDownloadCandidate(
  BuildContext context,
  WidgetRef ref,
  DownloadCandidate candidate, {
  required String modName,
  required DownloadSourceHint? sourceHint,
  required void Function(String) linkLoader,
  bool hasOwnBusyIndicator = false,
}) {
  if (candidate.kind == DownloadCandidateKind.triosDeepLink) {
    final deepLink = trilinkToDeepLinkUri(candidate.url);
    if (deepLink != null) {
      // The install flow does async work (loading mods, resolving the link)
      // before its confirmation dialog appears. Acknowledge the click right
      // away so it doesn't feel unresponsive.
      if (!hasOwnBusyIndicator) {
        showSnackBar(
          context: context,
          type: SnackBarType.info,
          content: Text('Preparing to install $modName…'),
        );
      }
      ref
          .read(deepLinkHandlerProvider.notifier)
          .handleUriString(deepLink, sourceHint: sourceHint);
      return;
    }
    // Not a valid trilink after all — fall back to opening it.
    linkLoader(candidate.url);
    return;
  }

  if (candidate.requiresManualStep ||
      candidate.kind == DownloadCandidateKind.website) {
    linkLoader(candidate.url);
    return;
  }

  confirmAndDownloadModViaManager(
    context,
    ref,
    modName: modName,
    downloadUrl: candidate.url,
    skipDialog: true,
    sourceHint: sourceHint,
  );
}

/// The icon shown for a candidate in menus and lists.
IconData downloadCandidateIcon(DownloadCandidate candidate) {
  if (candidate.requiresManualStep) return Icons.open_in_new;
  return switch (candidate.kind) {
    DownloadCandidateKind.triosDeepLink => Icons.download,
    DownloadCandidateKind.versionChecker => Icons.download,
    DownloadCandidateKind.catalogDirect => Icons.download,
    DownloadCandidateKind.forumDirect => Icons.download,
    DownloadCandidateKind.forumMirror => Icons.cloud_download,
    DownloadCandidateKind.website => Icons.open_in_browser,
  };
}

/// Widget version of [downloadCandidateIcon] — returns the TriOS logo for
/// deep-link candidates, a plain [Icon] for everything else.
Widget downloadCandidateIconWidget(
  DownloadCandidate candidate, {
  double size = 16,
  Color? color,
}) {
  if (!candidate.requiresManualStep &&
      candidate.kind == DownloadCandidateKind.triosDeepLink) {
    return TriOSAppIcon(width: size, height: size, color: color);
  }
  return Icon(downloadCandidateIcon(candidate), size: size, color: color);
}

/// A short one-line description of where a candidate comes from, e.g.
/// "Dropbox · opens in browser" — for tooltips and list subtitles.
String downloadCandidateSubtitle(DownloadCandidate candidate) {
  final parts = <String>[
    if (candidate.sourceHost?.isNotEmpty == true) candidate.sourceHost!,
    if (candidate.requiresManualStep) 'opens in browser',
  ];
  return parts.join(' · ');
}

/// One row in a download chooser menu: the candidate's icon, its label and
/// where it comes from, and its full URL on hover.
///
/// Picking a row tells [target]'s button to start showing progress — but only
/// for a candidate that really downloads something. A website or manual-step
/// link just opens a browser tab, so it would leave the button spinning at
/// nothing.
class DownloadCandidateMenuItem extends ConsumerWidget {
  final DownloadCandidate candidate;

  /// The button this menu belongs to.
  final DownloadTarget target;

  /// Runs the candidate.
  final VoidCallback onSelected;

  const DownloadCandidateMenuItem({
    super.key,
    required this.candidate,
    required this.target,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitle = downloadCandidateSubtitle(candidate);
    return MenuItemButton(
      leadingIcon: downloadCandidateIconWidget(candidate),
      onPressed: () {
        if (candidate.isOneClick) {
          ref.read(pendingDownloadClicks.notifier).markClicked(target);
        }
        onSelected();
      },
      child: MovingTooltipWidget.text(
        message: candidate.url,
        child: Padding(
          padding: const .symmetric(vertical: 4.0),
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
