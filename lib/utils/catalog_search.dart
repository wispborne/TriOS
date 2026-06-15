import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/models/version.dart';
import 'package:trios/thirdparty/dartx/map.dart';

// ===== Version Comparison (ported from Starmodder3) =====

final _groupingRegex = RegExp(r'(\d+|[a-zA-Z]+|[-\.]+)');
final _sepRegex = RegExp(r'[\s\-\u2013_]+');
final _isLetterRegex = RegExp(r'[a-zA-Z]');

const _suffixOrder = [
  'dev',
  'prerelease',
  'preview',
  'pre',
  'alpha',
  'beta',
  'rc',
];
final _suffixRank = {
  for (var i = 0; i < _suffixOrder.length; i++) _suffixOrder[i]: i,
};

List<String> _tokenize(String s) {
  return _groupingRegex.allMatches(s).map((m) => m.group(0)!).toList();
}

String _normalizeSeparators(String s) {
  return s.replaceAll(_sepRegex, '.');
}

(List<String>, List<String>) _normalizeAndSplitTokens(
  List<String> aTokens,
  List<String> bTokens,
) {
  final aResult = <String>[];
  final bResult = <String>[];
  final len = aTokens.length > bTokens.length ? aTokens.length : bTokens.length;

  for (var i = 0; i < len; i++) {
    var aPart = i < aTokens.length ? aTokens[i] : '';
    var bPart = i < bTokens.length ? bTokens[i] : '';

    final aIsNumber = RegExp(r'^\d+$').hasMatch(aPart);
    final bIsNumber = RegExp(r'^\d+$').hasMatch(bPart);
    final aIsLetter = _isLetterRegex.hasMatch(aPart);
    final bIsLetter = _isLetterRegex.hasMatch(bPart);

    if (aIsLetter && bIsNumber) {
      aResult.add('0');
    } else if (bIsLetter && aIsNumber) {
      bResult.add('0');
    } else if (aPart.isEmpty && bIsNumber) {
      aPart = '0';
    } else if (bPart.isEmpty && aIsNumber) {
      bPart = '0';
    } else if (aPart.isEmpty && bPart == '.') {
      aPart = '.';
    } else if (bPart.isEmpty && aPart == '.') {
      bPart = '.';
    } else if (aPart.isEmpty && bIsLetter) {
      // noop
    } else if (bPart.isEmpty && aIsLetter) {
      // noop
    } else if (aPart.isEmpty && bPart.isNotEmpty) {
      aPart = bPart;
    } else if (bPart.isEmpty && aPart.isNotEmpty) {
      bPart = aPart;
    }

    aResult.add(aPart);
    bResult.add(bPart);
  }

  return (aResult, bResult);
}

/// Compares two Starsector-style version strings.
/// Returns negative if [a] < [b], positive if [a] > [b], zero if equal.
int compareVersions(String? a, String? b) {
  if (a == b) return 0;
  if (a == null || a.isEmpty) return -1;
  if (b == null || b.isEmpty) return 1;

  final aOriginal = a;
  final bOriginal = b;
  final aPartsOriginal = _tokenize(a);
  final bPartsOriginal = _tokenize(b);

  a = _normalizeSeparators(a);
  b = _normalizeSeparators(b);

  final aTokens = _tokenize(a);
  final bTokens = _tokenize(b);
  final (aParts, bParts) = _normalizeAndSplitTokens(aTokens, bTokens);

  final len = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < len; i++) {
    final aPart = i < aParts.length ? aParts[i] : '';
    final bPart = i < bParts.length ? bParts[i] : '';

    final aIsNumber = RegExp(r'^\d+$').hasMatch(aPart);
    final bIsNumber = RegExp(r'^\d+$').hasMatch(bPart);

    if (aIsNumber && bIsNumber) {
      final aNum = int.parse(aPart);
      final bNum = int.parse(bPart);
      if (aNum != bNum) return aNum > bNum ? 1 : -1;
    } else if (aIsNumber && !bIsNumber) {
      return 1;
    } else if (!aIsNumber && bIsNumber) {
      return -1;
    } else {
      final aLow = aPart.toLowerCase();
      final bLow = bPart.toLowerCase();
      final ai = _suffixRank[aLow];
      final bi = _suffixRank[bLow];

      if (ai != null && bi != null) {
        if (ai != bi) return ai > bi ? 1 : -1;
      } else if (ai != null) {
        return -1;
      } else if (bi != null) {
        return 1;
      }

      if (aPart != bPart) {
        return aPart.compareTo(bPart) < 0 ? -1 : 1;
      }
    }
  }

  final lenCmp = aPartsOriginal.length - bPartsOriginal.length;
  if (lenCmp != 0) return lenCmp > 0 ? 1 : -1;

  return aOriginal.compareTo(bOriginal);
}

// ===== Version Normalization =====

const _versionAliases = {'0.9.5': '0.95'};

/// Normalizes a raw game version string to a base version for grouping.
/// e.g. "0.97a-RC11" → "0.97", "0.9.5a" → "0.95"
String normalizeBaseVersion(String? rawVersion) {
  if (rawVersion == null || rawVersion.isEmpty) return '';
  // Strip all non-version characters (keep digits, dots, hyphens)
  var s = rawVersion.replaceAll(RegExp(r'[^0-9.\-]'), '');
  // Split by hyphen, take first part (drops RC suffix)
  s = s.split('-').first;
  // Split by dot, filter empty, rejoin
  final parts = s.split('.').where((p) => p.isNotEmpty).toList();
  var base = parts.join('.');
  // Apply hardcoded equivalences
  if (_versionAliases.containsKey(base)) base = _versionAliases[base]!;
  return base;
}

// ===== URL Extraction =====

final _forumTopicIdRegex = RegExp(r'topic=(\d+)');
final _nexusModIdRegex = RegExp(r'/mods/(\d+)');

/// Extracts the numeric topic ID from a forum URL like
/// `https://fractalsoftworks.com/forum/index.php?topic=25658.0`.
int? extractForumTopicId(String? url) {
  if (url == null) return null;
  final match = _forumTopicIdRegex.firstMatch(url);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Like [extractForumTopicId] but returns the raw string ID (no parse).
String? extractForumThreadId(String? url) {
  if (url == null) return null;
  return _forumTopicIdRegex.firstMatch(url)?.group(1);
}

/// Extracts the numeric mod ID from a NexusMods URL like
/// `https://www.nexusmods.com/starsector/mods/123`.
String? extractNexusModId(String? url) {
  if (url == null) return null;
  return _nexusModIdRegex.firstMatch(url)?.group(1);
}

// ===== Name Comparison =====

final _nonAlphanumericStart = RegExp(r'^[^a-zA-Z0-9]');

/// Compares mod names alphabetically, placing names starting with
/// non-alphanumeric characters (brackets, symbols) at the end.
int nameCompare(ScrapedMod a, ScrapedMod b) {
  final aName = a.name;
  final bName = b.name;
  final aIsBracket = _nonAlphanumericStart.hasMatch(aName);
  final bIsBracket = _nonAlphanumericStart.hasMatch(bName);
  if (aIsBracket != bIsBracket) return aIsBracket ? 1 : -1;
  return aName.compareTo(bName);
}

// ===== Filter Population Helpers =====

/// Extracts unique non-empty categories from mods, sorted alphabetically.
List<String> extractCategories(List<ScrapedMod> mods) {
  final categories = <String>{};
  for (final mod in mods) {
    if (mod.categories != null) {
      for (final cat in mod.categories!) {
        if (cat.trim().isNotEmpty) categories.add(cat);
      }
    }
  }
  return categories.toList()..sort();
}

/// Extracts normalized version groups from mods.
/// Returns a map of base version → set of raw version strings,
/// filtered to groups with 3+ mods, sorted newest-first.
Map<String, Set<String>> extractVersionGroups(List<ScrapedMod> mods) {
  var versionMap = <String, Set<String>>{};
  final versionModCount = <String, int>{};

  for (final mod in mods) {
    if (mod.gameVersionReq != null && mod.gameVersionReq!.isNotEmpty) {
      final base = normalizeBaseVersion(mod.gameVersionReq);
      if (base.isNotEmpty) {
        versionMap.putIfAbsent(base, () => {}).add(mod.gameVersionReq!);
        versionModCount[base] = (versionModCount[base] ?? 0) + 1;
      }
    }
  }

  // Filter to 3+ mods and sort newest-first
  final filtered = Map.fromEntries(
    versionMap.entries.where((e) => (versionModCount[e.key] ?? 0) >= 3).toList()
      ..sort((a, b) => compareVersions(b.key, a.key)),
  );

  return filtered;
}

// ===== Sort =====

/// Sort keys for the catalog page.
enum CatalogSortKey {
  name('Name'),
  date('Date Added'),
  version('Game Version'),
  mostViewed('Forum Views'),
  mostReplies('Forum Replies'),
  lastActivity('Last Forum Activity');

  final String label;

  const CatalogSortKey(this.label);

  /// Whether ascending is the natural/default direction for this sort key.
  bool get defaultAscending => switch (this) {
    CatalogSortKey.name => true,
    _ => false,
  };
}

/// Looks up the [ForumModIndex] for a [ScrapedMod] using the forum URL.
ForumModIndex? _forumFor(ScrapedMod mod, Map<int, ForumModIndex> forumLookup) {
  final id = extractForumTopicId(mod.urls?[ModUrlType.Forum]);
  return id != null ? forumLookup[id] : null;
}

/// Sorts a list of scraped mods by the given sort key. Returns a new list.
/// [forumLookup] is needed for [CatalogSortKey.mostViewed] and
/// [CatalogSortKey.lastActivity]; mods without forum data sort last.
List<ScrapedMod> sortScrapedMods(
  List<ScrapedMod> mods,
  CatalogSortKey sortKey, {
  bool ascending = true,
  Map<int, ForumModIndex> forumLookup = const {},
}) {
  final sorted = List<ScrapedMod>.from(mods);
  final flip = ascending ? 1 : -1;
  switch (sortKey) {
    case CatalogSortKey.name:
      sorted.sort((a, b) => nameCompare(a, b) * flip);
    case CatalogSortKey.date:
      sorted.sort((a, b) {
        final da =
            (a.dateTimeCreated ?? _forumFor(a, forumLookup)?.createdDate);
        final db =
            (b.dateTimeCreated ?? _forumFor(b, forumLookup)?.createdDate);
        if (da == null && db == null) return nameCompare(a, b);
        if (da == null) return 1;
        if (db == null) return -1;
        final cmp = da.compareTo(db) * flip;
        return cmp != 0 ? cmp : nameCompare(a, b);
      });
    case CatalogSortKey.version:
      sorted.sort((a, b) {
        final aVer = a.gameVersionReq ?? '';
        final bVer = b.gameVersionReq ?? '';
        if (aVer.isEmpty && bVer.isEmpty) return nameCompare(a, b);
        if (aVer.isEmpty) return 1;
        if (bVer.isEmpty) return -1;
        final cmp = compareVersions(aVer, bVer) * flip;
        return cmp != 0 ? cmp : nameCompare(a, b);
      });
    case CatalogSortKey.mostViewed:
      sorted.sort((a, b) {
        final af = _forumFor(a, forumLookup);
        final bf = _forumFor(b, forumLookup);
        if (af == null && bf == null) return nameCompare(a, b);
        if (af == null) return 1;
        if (bf == null) return -1;
        final cmp = af.views.compareTo(bf.views) * flip;
        return cmp != 0 ? cmp : nameCompare(a, b);
      });
    case CatalogSortKey.mostReplies:
      sorted.sort((a, b) {
        final af = _forumFor(a, forumLookup);
        final bf = _forumFor(b, forumLookup);
        if (af == null && bf == null) return nameCompare(a, b);
        if (af == null) return 1;
        if (bf == null) return -1;
        final cmp = af.replies.compareTo(bf.replies) * flip;
        return cmp != 0 ? cmp : nameCompare(a, b);
      });
    case CatalogSortKey.lastActivity:
      sorted.sort((a, b) {
        final af = _forumFor(a, forumLookup)?.lastPostDate;
        final bf = _forumFor(b, forumLookup)?.lastPostDate;
        if (af == null && bf == null) return nameCompare(a, b);
        if (af == null) return 1;
        if (bf == null) return -1;
        final cmp = af.compareTo(bf) * flip;
        return cmp != 0 ? cmp : nameCompare(a, b);
      });
  }
  return sorted;
}
