import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/scraped_mod.dart';

/// Where a download candidate came from, in priority order (lower index wins).
/// `trios` deep links always outrank everything; the scraped catalog's own
/// direct link stays above forum links so today's one-click mods are unchanged.
enum DownloadCandidateKind {
  triosDeepLink,
  catalogDirect,
  forumDirect,
  forumMirror,
  website,
}

/// A single way to download a mod, gathered from the scraped catalog and the
/// forum LLM data. The card button, context menu, and forum dialog all share
/// this list.
class DownloadCandidate {
  /// The URL to act on: a forum link's [ForumLlmDownload.resolvedDirectUrl]
  /// when present, otherwise its `url`.
  final String url;

  /// Human label, e.g. "Patch (0.3.1 → 0.3.1b)" or "Direct download".
  final String label;
  final DownloadCandidateKind kind;

  /// Only set for forum links; null for the catalog direct link and website.
  final LlmDownloadConfidence? confidence;

  /// Host to show in menus, e.g. "Dropbox" or "github.com".
  final String? sourceHost;
  final String? fileName;

  /// True when the link can't be downloaded directly (opens the browser).
  final bool requiresManualStep;

  const DownloadCandidate({
    required this.url,
    required this.label,
    required this.kind,
    this.confidence,
    this.sourceHost,
    this.fileName,
    this.requiresManualStep = false,
  });

  /// A candidate the download button can act on with one click: a deep link or
  /// a direct download, but not a website or a link needing a manual step.
  bool get isOneClick =>
      kind != DownloadCandidateKind.website && !requiresManualStep;

  @override
  String toString() =>
      'DownloadCandidate(${kind.name}, ${confidence?.name}, '
      'manual: $requiresManualStep, $label -> $url)';
}

/// Builds the prioritized list of download candidates for a mod. Pure function
/// over the scraped mod plus its forum LLM data (null when the topic has none).
///
/// Sorted: trios deep links > catalog direct > forum direct (high > medium >
/// low > unknown) > forum mirror (same) > website. Manual-step links keep their
/// place in the ordering but never become the primary (see [primaryCandidate]).
List<DownloadCandidate> resolveDownloadCandidates(
  ScrapedMod mod,
  ForumLlmMod? llmMainMod,
) {
  final candidates = <DownloadCandidate>[
    // Forum links (may include a trios deep link).
    for (final download in llmMainMod?.downloads ?? const <ForumLlmDownload>[])
      _forumCandidate(download),
  ];

  // The scraped catalog's existing direct download link.
  final catalogDirect = mod.urls?[ModUrlType.DirectDownload];
  if (catalogDirect != null && catalogDirect.isNotEmpty) {
    candidates.add(
      DownloadCandidate(
        url: catalogDirect,
        label: 'Direct download',
        kind: DownloadCandidateKind.catalogDirect,
        sourceHost: _hostOf(catalogDirect),
      ),
    );
  }

  // Website fallback (forum/NexusMods page).
  final website = mod.getBestWebsiteUrl();
  if (website != null && website.isNotEmpty) {
    candidates.add(
      DownloadCandidate(
        url: website,
        label: 'Website',
        kind: DownloadCandidateKind.website,
        sourceHost: _hostOf(website),
      ),
    );
  }

  candidates.sort(_byPriority);
  return candidates;
}

/// The download candidates for one forum mod (no scraped-catalog links),
/// sorted by priority. Used by the forum post dialog, which lists links per
/// [ForumLlmMod] rather than per scraped mod.
List<DownloadCandidate> forumDownloadCandidates(ForumLlmMod mod) {
  return mod.downloads.map(_forumCandidate).toList()..sort(_byPriority);
}

DownloadCandidate _forumCandidate(ForumLlmDownload download) {
  final kind = switch (download.kind) {
    LlmDownloadKind.trios => DownloadCandidateKind.triosDeepLink,
    LlmDownloadKind.direct => DownloadCandidateKind.forumDirect,
    // Mirrors and anything we couldn't classify sit in the lowest one-click
    // tier, below `direct` links.
    LlmDownloadKind.mirror => DownloadCandidateKind.forumMirror,
    LlmDownloadKind.unknown => DownloadCandidateKind.forumMirror,
  };
  final url = (download.resolvedDirectUrl?.isNotEmpty == true)
      ? download.resolvedDirectUrl!
      : download.url;
  return DownloadCandidate(
    url: url,
    label: _forumLabel(download, kind),
    kind: kind,
    confidence: download.confidence,
    sourceHost: download.sourceHost ?? _hostOf(url),
    fileName: download.fileName,
    requiresManualStep: download.requiresManualStep,
  );
}

int _byPriority(DownloadCandidate a, DownloadCandidate b) {
  final byKind = a.kind.index.compareTo(b.kind.index);
  if (byKind != 0) return byKind;
  return _confidenceRank(a.confidence).compareTo(_confidenceRank(b.confidence));
}

/// The candidate the download button runs on click: the best one-click
/// candidate (deep link or direct download). Null when the only options are a
/// website or manual-step links, in which case the button opens the browser.
DownloadCandidate? primaryCandidate(List<DownloadCandidate> candidates) {
  for (final c in candidates) {
    if (c.isOneClick) return c;
  }
  return null;
}

/// The one-click candidates tied with the primary (same kind and confidence).
/// When this has more than one entry, the button shows a chooser instead of
/// guessing. Empty when there is no primary.
List<DownloadCandidate> primaryTieSet(List<DownloadCandidate> candidates) {
  final primary = primaryCandidate(candidates);
  if (primary == null) return const [];
  return candidates
      .where(
        (c) =>
            c.isOneClick &&
            c.kind == primary.kind &&
            c.confidence == primary.confidence,
      )
      .toList();
}

String _forumLabel(ForumLlmDownload download, DownloadCandidateKind kind) {
  if (download.label.isNotEmpty) return download.label;
  if (download.fileName?.isNotEmpty == true) return download.fileName!;
  return switch (kind) {
    DownloadCandidateKind.triosDeepLink => 'Install with TriOS',
    DownloadCandidateKind.forumMirror => 'Mirror',
    _ => 'Download',
  };
}

int _confidenceRank(LlmDownloadConfidence? confidence) => switch (confidence) {
  LlmDownloadConfidence.high => 0,
  LlmDownloadConfidence.medium => 1,
  LlmDownloadConfidence.low => 2,
  LlmDownloadConfidence.unknown => 3,
  null => 0,
};

String? _hostOf(String url) {
  final host = Uri.tryParse(url)?.host;
  return (host == null || host.isEmpty) ? null : host;
}
