import 'package:trios/catalog/models/forum_link.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';

/// Where a download candidate came from, in priority order (lower index wins).
/// `trios` deep links outrank everything (they install dependencies too),
/// except when the link names an older version than the mod's version checker
/// — see [resolveDownloadCandidates]. The version checker comes next: it's the
/// mod author's own "latest build" link, so it beats the catalog and forum
/// links, which are snapshots that go stale. The catalog's own direct link
/// stays above forum links so today's one-click mods are unchanged.
enum DownloadCandidateKind {
  triosDeepLink,
  versionChecker,
  catalogDirect,
  forumDirect,
  forumMirror,
  website,
}

/// A single way to download a mod, gathered from the catalog and the
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
/// over the catalog mod, its forum LLM data (null when the topic has none), and
/// the installed mod's version checker result ([remoteVersion], null when the
/// mod isn't installed or has no version checker).
///
/// Sorted: trios deep links > version checker > catalog direct > forum direct
/// (high > medium > low > unknown) > forum mirror (same) > website. Manual-step
/// links keep their place in the ordering but never become the primary (see
/// [primaryCandidate]).
///
/// One exception to that order: a trios link that names an older version than
/// the version checker reports is a stale link, so the version checker's
/// download goes ahead of it.
List<DownloadCandidate> resolveDownloadCandidates(
  CatalogMod mod,
  ForumLlmMod? llmMainMod, {
  VersionCheckerInfo? remoteVersion,
}) {
  final candidates = <DownloadCandidate>[
    // Forum links (may include a trios deep link).
    for (final download in llmMainMod?.downloads ?? const <ForumLlmDownload>[])
      _forumCandidate(download),
  ];

  // The mod's own version checker download, when it has one.
  final versionCheckerUrl = remoteVersion?.directDownloadURL;
  if (versionCheckerUrl != null && versionCheckerUrl.isNotEmpty) {
    final fixedUrl = versionCheckerUrl.fixModDownloadUrl();
    final version = remoteVersion?.modVersion?.toString();
    candidates.add(
      DownloadCandidate(
        url: fixedUrl,
        label: version == null || version.isEmpty
            ? 'Version checker'
            : 'Version checker ($version)',
        kind: DownloadCandidateKind.versionChecker,
        sourceHost: _hostOf(fixedUrl),
      ),
    );
  }

  // The catalog's existing direct download link.
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

  // Only trios links can sort above the version checker, so if every one of
  // them is stale, the version checker's download becomes the primary.
  final versionCheckerIndex = candidates.indexWhere(
    (c) => c.kind == DownloadCandidateKind.versionChecker,
  );
  if (versionCheckerIndex > 0 &&
      candidates
          .take(versionCheckerIndex)
          .every((c) => _isOutdatedTrilink(c, remoteVersion?.modVersion))) {
    candidates.insert(0, candidates.removeAt(versionCheckerIndex));
  }

  return candidates;
}

/// True when a trios link names a version older than [remoteVersion].
///
/// A link pointing at a `.version` file is never outdated — it reads the mod's
/// current version when clicked. A link with no version in it can't be judged,
/// so it isn't treated as outdated either.
bool _isOutdatedTrilink(
  DownloadCandidate candidate,
  VersionObject? remoteVersion,
) {
  if (candidate.kind != DownloadCandidateKind.triosDeepLink) return false;
  if (remoteVersion == null) return false;

  final deepLink = trilinkToDeepLinkUri(candidate.url);
  if (deepLink == null) return false;
  final mainMod = parseDeepLink(deepLink)?.mainMod;
  if (mainMod == null) return false;
  if (mainMod.source == DeepLinkModSource.versionFile) return false;

  final linkVersion = mainMod.modVersion;
  if (linkVersion == null) return false;
  return Version.parse(linkVersion, sanitizeInput: false).compareTo(
        Version.parse(remoteVersion.toString(), sanitizeInput: false),
      ) <
      0;
}

/// The download candidates for one forum mod (no catalog links),
/// sorted by priority. Used by the forum post dialog, which lists links per
/// [ForumLlmMod] rather than per catalog mod.
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
    DownloadCandidateKind.triosDeepLink => 'Install with ${Constants.appName}',
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

/// One mod's required mod (e.g. "LazyLib") and whether it's already installed.
class DependencyStatus {
  final String name;
  final bool installed;

  const DependencyStatus({required this.name, required this.installed});
}

/// One row in the details dialog's Downloads section: a mod (the topic's main
/// mod, an add-on, a separate mod, or the unnamed scraped fallback) with its
/// own download candidates and — for the main mod — its dependencies.
class DownloadGroup {
  /// The mod's name, or null for the unnamed scraped fallback (a topic with
  /// no LLM data, where links come straight from the post).
  final String? modName;
  final LlmModRole role;
  final List<DownloadCandidate> candidates;

  /// True when the best download is a TriOS deep link, which installs the
  /// mod's dependencies for you.
  final bool installsDependencies;

  /// The main mod's dependencies. Empty for non-main rows.
  final List<DependencyStatus> dependencies;

  const DownloadGroup({
    required this.modName,
    required this.role,
    required this.candidates,
    required this.installsDependencies,
    this.dependencies = const [],
  });
}

/// Builds the per-mod download rows for the details dialog.
///
/// When the topic has LLM data, each [ForumLlmMod] becomes a row (ordered
/// main → add-on → separate → unknown). Otherwise a single unnamed row is
/// built from the scraped post links ([scrapedLinks]) or, when the dialog has
/// no forum post at all, from the catalog mod itself ([catalogMod]).
///
/// [isInstalled] answers whether a dependency mod name is already installed.
List<DownloadGroup> buildDownloadGroups({
  ForumModIndex? index,
  List<ForumLink>? scrapedLinks,
  CatalogMod? catalogMod,
  required bool Function(String name) isInstalled,
}) {
  final mods = index?.llm?.mods ?? const <ForumLlmMod>[];
  if (mods.isNotEmpty) {
    final ordered = [...mods]
      ..sort((a, b) => a.role.index.compareTo(b.role.index));
    // Skip mods the thread only mentions but has no download for; a group with
    // no candidates would crash the download button (candidates.first).
    return [
      for (final mod in ordered)
        if (mod.downloads.isNotEmpty) _groupForLlmMod(mod, isInstalled),
    ];
  }

  // No LLM data: a single unnamed group from the scraped links or mod.
  final candidates = <DownloadCandidate>[];
  if (scrapedLinks != null) {
    for (final link in scrapedLinks) {
      if (!link.isDownloadable) continue;
      candidates.add(
        DownloadCandidate(
          url: link.url,
          label: _scrapedLinkLabel(link),
          kind: DownloadCandidateKind.forumDirect,
          sourceHost: _hostOf(link.url),
        ),
      );
    }
  } else if (catalogMod != null) {
    candidates.addAll(resolveDownloadCandidates(catalogMod, null));
  }

  if (candidates.isEmpty) return const [];
  return [
    DownloadGroup(
      modName: null,
      role: LlmModRole.unknown,
      candidates: candidates,
      installsDependencies:
          primaryCandidate(candidates)?.kind ==
          DownloadCandidateKind.triosDeepLink,
    ),
  ];
}

DownloadGroup _groupForLlmMod(
  ForumLlmMod mod,
  bool Function(String name) isInstalled,
) {
  final candidates = forumDownloadCandidates(mod);
  final installsDeps =
      primaryCandidate(candidates)?.kind ==
      DownloadCandidateKind.triosDeepLink;
  // Only the main mod lists its dependencies; add-on/separate rows stay compact.
  final dependencies = mod.role == LlmModRole.main
      ? [
          for (final name in mod.requires ?? const <String>[])
            if (name.trim().isNotEmpty)
              DependencyStatus(name: name, installed: isInstalled(name)),
        ]
      : const <DependencyStatus>[];
  return DownloadGroup(
    modName: mod.name,
    role: mod.role,
    candidates: candidates,
    installsDependencies: installsDeps,
    dependencies: dependencies,
  );
}

String _scrapedLinkLabel(ForumLink link) {
  if (link.text.isNotEmpty) return link.text;
  final segs = Uri.tryParse(link.url)?.pathSegments;
  if (segs != null && segs.isNotEmpty && segs.last.isNotEmpty) {
    return segs.last;
  }
  return link.url;
}
