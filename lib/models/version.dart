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

    // var result = (major.compareRecognizingNumbers(other.major));
    // if (result != 0) return result;
    //
    // result = (minor.compareRecognizingNumbers(other.minor));
    // if (result != 0) return result;
    //
    // result = (patch.compareRecognizingNumbers(other.patch));
    // if (result != 0) return result;
    //
    // result = ((build ?? "0").compareRecognizingNumbers(other.build ?? ""));
    // return result;
  }

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
  static final RegExp _regex = RegExp(r'(\d+|[a-zA-Z]+|[-\.]+)');
  static final RegExp _sep = RegExp(r'[\s\-–_]+');
  static final List<String> _suffixOrder = [
    'dev',
    'prerelease',
    'pre',
    'alpha',
    'beta',
    'rc',
  ];

  (List<String>, List<String>) _normalizeAndSplitStringsToCompare(
    String a,
    String b,
    RegExp groupingRegex,
  ) {
    final aParts = groupingRegex.allMatches(a).map((m) => m.group(0)!).toList();
    final bParts = groupingRegex.allMatches(b).map((m) => m.group(0)!).toList();

    List<String> aResult = [];
    List<String> bResult = [];

    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      var aPart = aParts.getOrNull(i) ?? '';
      var bPart = bParts.getOrNull(i) ?? '';

      final aIsNumber = int.tryParse(aPart) != null;
      final bIsNumber = int.tryParse(bPart) != null;
      final aIsLetter = aPart.contains(RegExp(r'[a-zA-Z]'));
      final bIsLetter = bPart.contains(RegExp(r'[a-zA-Z]'));

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
    final aPartsOriginal = _regex
        .allMatches(a)
        .map((m) => m.group(0)!)
        .toList();
    final bPartsOriginal = _regex
        .allMatches(b)
        .map((m) => m.group(0)!)
        .toList();

    a = a.replaceAll(_sep, '.');
    b = b.replaceAll(_sep, '.');

    final (aParts, bParts) = _normalizeAndSplitStringsToCompare(a, b, _regex);

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
        final aContains = _suffixOrder.contains(aLow);
        final bContains = _suffixOrder.contains(bLow);
        if (aContains && bContains) {
          final ai = _suffixOrder.indexOf(aLow);
          final bi = _suffixOrder.indexOf(bLow);
          if (ai != bi) return ai > bi ? 1 : -1;
        } else if (aContains) {
          return -1;
        } else if (bContains) {
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
