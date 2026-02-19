import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

part 'version.mapper.dart';

@MappableClass()
class Version with VersionMappable implements Comparable<Version> {
  final String? raw;
  final String major;
  final String minor;
  final String patch;
  final String? build;

  const Version({
    this.raw,
    this.major = "0",
    this.minor = "0",
    this.patch = "0",
    this.build,
  });

  @override
  String toString() => raw ?? [major, minor, patch, build].nonNulls.join('.');

  /// Ignores the `raw` field even if it exists.
  String toStringFromParts() => [major, minor, patch, build].nonNulls.join('.');

  @override
  int compareTo(Version? other) {
    if (other == null) return -1;

    final a = raw ?? toString();
    final b = other.raw ?? other.toString();
    return compareVersions(a, b);
  }

  bool operator >(Version other) => compareTo(other) > 0;

  bool operator <(Version other) => compareTo(other) < 0;

  bool operator >=(Version other) => compareTo(other) >= 0;

  bool operator <=(Version other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  /// Compares two versions without using the "raw" version string.
  /// Use for comparing game versions.
  bool equalsSymbolic(Version other) {
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        build == other.build;
  }

  @override
  int get hashCode => toString().hashCode;

  /// - `sanitizeInput` should be true for `mod_info.json`, false for `.version`. Whether to remove all but numbers and symbols.
  static Version parse(String versionString, {bool sanitizeInput = true}) {
    // Remove non-version characters
    final sanitizedString = sanitizeInput
        ? versionString.replaceAll(RegExp(r"[^0-9.-]"), "")
        : versionString;

    // Split into version and release candidate
    final parts = sanitizedString.split("-").take(2);

    // Split the version number by '.'
    final versionParts = parts.first.split('.');

    return Version(
      raw: versionString,
      major: versionParts.isNotEmpty ? versionParts[0] : "0",
      minor: versionParts.length > 1 ? versionParts[1] : "0",
      patch: versionParts.length > 2 ? versionParts[2] : "0",
      build: versionParts.length > 3 ? versionParts[3] : null,
    );
  }

  static Version zero() => Version.parse("0.0.0", sanitizeInput: true);

  // Precompiled regex and suffix order
  static final RegExp _groupingRegex = RegExp(r'(\d+|[a-zA-Z]+|[-\.]+)');
  static final RegExp _sep = RegExp(r'[\s\-–_]+');
  static final isLetterRegex = RegExp(r'[a-zA-Z]');
  static final List<String> _suffixOrder = [
    'dev',
    'prerelease',
    'preview',
    'pre',
    'alpha',
    'beta',
    'rc',
  ];

  // Precomputed rank map for faster lookups
  static final Map<String, int> _suffixRank = {
    for (int i = 0; i < _suffixOrder.length; i++) _suffixOrder[i]: i,
  };

  // Small, bounded LRU caches (very conservative sizes)
  static const int _maxCacheEntries = 512;
  static final _normalizedCache = <String, String>{};
  static final _tokensCache = <String, List<String>>{};

  static String _normalizeSeparatorsCached(String s) {
    final cached = _normalizedCache[s];
    if (cached != null) return cached;
    final normalized = s.replaceAll(_sep, '.');
    // Simple LRU eviction: remove first key when size exceeded
    if (_normalizedCache.length >= _maxCacheEntries) {
      _normalizedCache.remove(_normalizedCache.keys.first);
    }
    _normalizedCache[s] = normalized;
    return normalized;
  }

  static List<String> _tokenizeCached(String s) {
    final cached = _tokensCache[s];
    if (cached != null) return cached;
    final tokens = _groupingRegex
        .allMatches(s)
        .map((m) => m.group(0)!)
        .toList();
    if (_tokensCache.length >= _maxCacheEntries) {
      _tokensCache.remove(_tokensCache.keys.first);
    }
    _tokensCache[s] = tokens;
    return tokens;
  }

  (List<String>, List<String>) _normalizeAndSplitStringsToCompare(
    String a,
    String b,
  ) {
    // Use cached tokenization for both strings
    final aParts = _tokenizeCached(a);
    final bParts = _tokenizeCached(b);

    List<String> aResult = [];
    List<String> bResult = [];

    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      var aPart = aParts.getOrNull(i) ?? '';
      var bPart = bParts.getOrNull(i) ?? '';

      final aIsNumber = int.tryParse(aPart) != null;
      final bIsNumber = int.tryParse(bPart) != null;
      final aIsLetter = aPart.contains(isLetterRegex);
      final bIsLetter = bPart.contains(isLetterRegex);

      // If one side is [0] and the other is [g], return [0] and [0,g].
      // This is to handle cases like [1.9.0] and [1.9.g] where [0] should be considered less than [g].
      if (aIsLetter && bIsNumber) {
        aResult.add('0');
      } else if (bIsLetter && aIsNumber) {
        bResult.add('0');
      }
      // If one side is a number and the other is blank, add a zero to the blank side
      else if (aPart.isEmpty && bIsNumber) {
        aPart = '0';
      } else if (bPart.isEmpty && aIsNumber) {
        bPart = '0';
      }
      // If one side is a period and the other is blank, add a period to the blank side
      else if (aPart.isEmpty && bPart == '.') {
        aPart = '.';
      } else if (bPart.isEmpty && aPart == '.') {
        bPart = '.';
      } else if (aPart.isEmpty && bIsLetter) {
        // noop if one side is a letter and other is empty string, skip the rest of the else cases
      } else if (bPart.isEmpty && aIsLetter) {
        // noop if one side is a letter and other is empty string, skip the rest of the else cases
      }
      // Anything not a period, number, or letter is considered a separator (e.g. hyphen, emdash, etc.)
      else if (aPart.isEmpty && bPart.isNotEmpty) {
        aPart = bPart;
      } else if (bPart.isEmpty && aPart.isNotEmpty) {
        bPart = aPart;
      }

      aResult.add(aPart);
      bResult.add(bPart);
    }

    return (aResult, bResult);
  }

  int compareVersions(String a, String b) {
    if (a == b) {
      Fimber.v(() => '$a is the same as $b');
      return 0;
    }

    final aOriginal = a;
    final bOriginal = b;
    // Use tokenization cache for originals
    final aPartsOriginal = _tokenizeCached(a);
    final bPartsOriginal = _tokenizeCached(b);

    // Use normalization cache for separator replacement
    a = _normalizeSeparatorsCached(a);
    b = _normalizeSeparatorsCached(b);

    final (aParts, bParts) = _normalizeAndSplitStringsToCompare(a, b);

    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      final aPart = aParts.getOrNull(i) ?? '';
      final bPart = bParts.getOrNull(i) ?? '';

      final aIsNumber = int.tryParse(aPart) != null;
      final bIsNumber = int.tryParse(bPart) != null;

      if (aIsNumber && bIsNumber) {
        final aNum = int.parse(aPart);
        final bNum = int.parse(bPart);
        if (aNum != bNum) {
          Fimber.v(() => '$aOriginal ($a) vs $bOriginal ($b): $aNum vs $bNum');
          return aNum > bNum ? 1 : -1;
        }
      } else if (aIsNumber && !bIsNumber) {
        Fimber.v(() => '$aOriginal ($a) num before letter');
        return 1;
      } else if (!aIsNumber && bIsNumber) {
        Fimber.v(() => '$bOriginal ($b) num before letter');
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
          final cmp = aPart.compareTo(bPart);
          Fimber.v(() => '$aPart vs $bPart lexical $cmp');
          return cmp > 0 ? 1 : -1;
        }
      }
    }

    final lenCmp = aPartsOriginal.length.compareTo(bPartsOriginal.length);
    if (lenCmp != 0) {
      return lenCmp > 0 ? 1 : -1;
    }

    final rawCmp = aOriginal.compareTo(bOriginal);
    if (rawCmp != 0) {
      return rawCmp > 0 ? 1 : -1;
    }

    Fimber.v(() => '$aOriginal same as $bOriginal');
    return 0;
  }
}
