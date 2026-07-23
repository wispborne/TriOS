import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_confirm.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/widgets/snackbar.dart';

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
    DownloadCandidateKind.triosDeepLink => Icons.rocket_launch,
    DownloadCandidateKind.versionChecker => Icons.download,
    DownloadCandidateKind.catalogDirect => Icons.download,
    DownloadCandidateKind.forumDirect => Icons.download,
    DownloadCandidateKind.forumMirror => Icons.cloud_download,
    DownloadCandidateKind.website => Icons.open_in_browser,
  };
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
