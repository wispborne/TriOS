import 'package:collection/collection.dart';
import 'package:trios/catalog/models/forum_link.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/utils/extensions.dart';

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
  ModRepoEntry mod,
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
/// own download candidates and — for the row the dialog is about — its
/// dependencies.
class DownloadGroup {
  /// The mod's name, cleaned for display by [cleanModDisplayName]. Null for
  /// the unnamed scraped fallback (a topic with no LLM data, where links come
  /// straight from the post).
  final String? modName;

  /// The name exactly as the source wrote it. Downloads and mod records use
  /// this one: a record is matching data, so it keeps the source's wording.
  final String? rawModName;
  final LlmModRole role;
  final List<DownloadCandidate> candidates;

  /// True when the best download is a TriOS deep link, which installs the
  /// mod's dependencies for you.
  final bool installsDependencies;

  /// The dependencies of the mod the dialog is about. Empty for every other
  /// row, and never lists a mod that has its own row in the same section.
  final List<DependencyStatus> dependencies;

  /// True for the mod the dialog is about. That row leads the list and hides
  /// its name, because the dialog's title says it already.
  final bool isDialogMod;

  /// True when the mod the dialog is about names this one in its `requires`.
  final bool requiredByDialogMod;

  const DownloadGroup({
    required this.modName,
    required this.role,
    required this.candidates,
    required this.installsDependencies,
    this.rawModName,
    this.dependencies = const [],
    this.isDialogMod = false,
    this.requiredByDialogMod = false,
  });
}

/// Strips the decoration mod authors put around a name in a forum title, so
/// `[0.98a] Red - the Oculian Armada (0.10.2-RC4) Mod` reads as
/// `Red - the Oculian Armada`. Removes a bracketed group at either end, a
/// parenthesised group at the end, a trailing version number, and a trailing
/// bare "Mod".
///
/// Runs until the name stops changing, because the parts nest: "Mod" has to go
/// before the `(0.10.2-RC4)` behind it is at the end. Display only — the raw
/// name still goes to downloads and mod records.
String cleanModDisplayName(String name) {
  var result = name.trim();
  for (var pass = 0; pass < 6; pass++) {
    final before = result;
    for (final pattern in _nameDecoration) {
      result = result.replaceAll(pattern, '').trim();
    }
    // A name split by the removal, e.g. "Foo - (1.2)" -> "Foo -".
    while (result.endsWith('-') || result.endsWith(':')) {
      result = result.substring(0, result.length - 1).trim();
    }
    if (result == before) break;
  }
  // Nothing but decoration: the raw name is more use than an empty row.
  return result.isEmpty ? name.trim() : result;
}

final _nameDecoration = [
  RegExp(r'^\[[^\]]*\]'),
  RegExp(r'\[[^\]]*\]$'),
  RegExp(r'\([^)]*\)$'),
  RegExp(r'\s+v?\.?\s*\d[\w.\-]*$', caseSensitive: false),
  RegExp(r'\s+mod$', caseSensitive: false),
];

/// True when two mod names point at the same mod. Compares the cleaned names
/// first, then falls back to letters and numbers only — the same pair of steps
/// the catalog uses to match an entry to an installed mod.
///
/// Both sides come from scraped forum text, so neither is trustworthy enough
/// for a plain string comparison.
bool modNamesMatch(String a, String b) {
  final cleanA = cleanModDisplayName(a);
  final cleanB = cleanModDisplayName(b);
  if (cleanA.toLowerCase() == cleanB.toLowerCase()) return true;
  final fuzzyA = cleanA.alphanumericLower();
  return fuzzyA.isNotEmpty && fuzzyA == cleanB.alphanumericLower();
}

/// Builds the per-mod download rows for the details dialog.
///
/// When the topic has LLM data, each [ForumLlmMod] becomes a row. [dialogMod]
/// is the mod the dialog is about — a thread's add-on gets its own catalog
/// card, so it is often not the thread's main mod. That row comes first, then
/// the mods it requires, then the rest by role.
///
/// Without a [dialogMod] match the main mod leads instead, and keeps its name
/// on the row: hiding a name is only safe when we know it matches the title.
///
/// With no LLM data a single unnamed row is built from the scraped post links
/// ([scrapedLinks]) or, when the dialog has no forum post at all, from the
/// catalog mod itself ([catalogMod]).
///
/// [isInstalled] answers whether a dependency mod name is already installed.
List<DownloadGroup> buildDownloadGroups({
  ForumModIndex? index,
  List<ForumLink>? scrapedLinks,
  ModRepoEntry? catalogMod,
  ForumLlmMod? dialogMod,
  required bool Function(String name) isInstalled,
}) {
  final mods = index?.llm?.mods ?? const <ForumLlmMod>[];
  if (mods.isNotEmpty) {
    // Skip mods the thread only mentions but has no download for; a group with
    // no candidates would crash the download button (candidates.first).
    final rows = mods.where((mod) => mod.downloads.isNotEmpty).toList()
      ..sort((a, b) => a.role.index.compareTo(b.role.index));
    final self = _matchIn(rows, dialogMod);
    // No match: the main mod leads and shows its name, as before.
    final dependencyOwner =
        self ?? rows.where((mod) => mod.role == LlmModRole.main).firstOrNull;
    final requiredBySelf = _requiredRows(rows, self);
    final rowNames = rows.map((mod) => mod.name).toList();

    return [
      for (final mod in _orderRows(rows, self, requiredBySelf))
        _groupForLlmMod(
          mod,
          isInstalled,
          isDialogMod: mod == self,
          requiredByDialogMod: requiredBySelf.contains(mod),
          dependencies: mod == dependencyOwner
              ? _dependenciesFor(mod, rowNames, isInstalled)
              : const [],
        ),
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

/// The row in [rows] that is [mod], or null when the thread doesn't list it.
ForumLlmMod? _matchIn(List<ForumLlmMod> rows, ForumLlmMod? mod) {
  if (mod == null) return null;
  return rows.where((row) => row == mod).firstOrNull;
}

/// The rows [self] names in its `requires`.
Set<ForumLlmMod> _requiredRows(List<ForumLlmMod> rows, ForumLlmMod? self) {
  final required = self?.requires ?? const <String>[];
  if (required.isEmpty) return const {};
  return {
    for (final row in rows)
      if (required.any((name) => modNamesMatch(name, row.name))) row,
  };
}

/// The dialog's own mod first, then what it requires, then the rest — which
/// arrive already sorted by role.
List<ForumLlmMod> _orderRows(
  List<ForumLlmMod> rows,
  ForumLlmMod? self,
  Set<ForumLlmMod> requiredBySelf,
) {
  if (self == null) return rows;
  return [
    self,
    for (final row in rows)
      if (row != self && requiredBySelf.contains(row)) row,
    for (final row in rows)
      if (row != self && !requiredBySelf.contains(row)) row,
  ];
}

/// A mod's dependencies, minus any that has its own row in the same section —
/// that row already says "required", and naming it twice reads as two mods.
List<DependencyStatus> _dependenciesFor(
  ForumLlmMod mod,
  List<String> rowNames,
  bool Function(String name) isInstalled,
) {
  final dependencies = <DependencyStatus>[];
  for (final name in mod.requires ?? const <String>[]) {
    if (name.trim().isEmpty) continue;
    if (rowNames.any((rowName) => modNamesMatch(name, rowName))) continue;
    // Scraped names carry version decoration ("GraphicsLib 1.0.4"), which no
    // installed mod is called, so clean before asking.
    final cleaned = cleanModDisplayName(name);
    dependencies.add(
      DependencyStatus(name: cleaned, installed: isInstalled(cleaned)),
    );
  }
  return dependencies;
}

DownloadGroup _groupForLlmMod(
  ForumLlmMod mod,
  bool Function(String name) isInstalled, {
  required bool isDialogMod,
  required bool requiredByDialogMod,
  required List<DependencyStatus> dependencies,
}) {
  final candidates = forumDownloadCandidates(mod);
  final installsDeps =
      primaryCandidate(candidates)?.kind ==
      DownloadCandidateKind.triosDeepLink;
  return DownloadGroup(
    modName: cleanModDisplayName(mod.name),
    rawModName: mod.name,
    role: mod.role,
    candidates: candidates,
    installsDependencies: installsDeps,
    dependencies: dependencies,
    isDialogMod: isDialogMod,
    requiredByDialogMod: requiredByDialogMod,
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
