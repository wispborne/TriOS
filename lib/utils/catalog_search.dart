import 'package:trios/catalog/models/scraped_mod.dart';

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
  final len =
      aTokens.length > bTokens.length ? aTokens.length : bTokens.length;

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

const _versionAliases = {
  '0.9.5': '0.95',
};

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
  final versionMap = <String, Set<String>>{};
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
    versionMap.entries
        .where((e) => (versionModCount[e.key] ?? 0) >= 3)
        .toList()
      ..sort((a, b) => compareVersions(b.key, a.key)),
  );

  return filtered;
}

// ===== Sort =====

/// Sort keys matching Starmodder3's sort options.
enum CatalogSortKey {
  nameAsc('Name A\u2013Z'),
  nameDesc('Name Z\u2013A'),
  dateDesc('Newest'),
  dateAsc('Oldest'),
  versionDesc('Game Version');

  final String label;
  const CatalogSortKey(this.label);
}

/// Sorts a list of scraped mods by the given sort key. Returns a new list.
List<ScrapedMod> sortScrapedMods(List<ScrapedMod> mods, CatalogSortKey sortKey) {
  final sorted = List<ScrapedMod>.from(mods);
  switch (sortKey) {
    case CatalogSortKey.nameAsc:
      sorted.sort(nameCompare);
    case CatalogSortKey.nameDesc:
      sorted.sort((a, b) => nameCompare(b, a));
    case CatalogSortKey.dateDesc:
      sorted.sort((a, b) {
        final da = a.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
        final db = b.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
        return db.compareTo(da);
      });
    case CatalogSortKey.dateAsc:
      sorted.sort((a, b) {
        final da = a.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
        final db = b.dateTimeCreated?.millisecondsSinceEpoch ?? 0;
        return da.compareTo(db);
      });
    case CatalogSortKey.versionDesc:
      sorted.sort((a, b) {
        final aVer = a.gameVersionReq ?? '';
        final bVer = b.gameVersionReq ?? '';
        if (aVer.isEmpty && bVer.isEmpty) return nameCompare(a, b);
        if (aVer.isEmpty) return 1;
        if (bVer.isEmpty) return -1;
        final cmp = compareVersions(aVer, bVer);
        if (cmp != 0) return -cmp; // newest first
        return nameCompare(a, b);
      });
  }
  return sorted;
}
