import 'dart:math';

import 'package:collection/collection.dart';
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
  String toString() =>
      raw ?? [major, minor, patch, build].nonNulls.join(".");

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

  @override
  int get hashCode => toString().hashCode;

  /// - `sanitizeInput` should be true for `mod_info.json`, false for `.version`. Whether to remove all but numbers and symbols.
  static Version parse(String versionString, {required bool sanitizeInput}) {
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

  (List<String>, List<String>) _normalizeAndSplitStringsToCompare(
      String a, String b, RegExp groupingRegex) {
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
    final suffixOrder = [
      'dev',
      'prerelease',
      'pre',
      'alpha',
      'beta',
      'rc'
    ]; // Define the order of suffixes

    if (a == b) {
      Fimber.v(() => '$a is the same as $b');
      return 0;
    }

    final regex = RegExp(r'(\d+|[a-zA-Z]+|[-\.]+)');
    final aOriginal = a;
    final bOriginal = b;
    final aPartsOriginal = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final bPartsOriginal = regex.allMatches(b).map((m) => m.group(0)!).toList();

    // Normalize version strings
    a = a.replaceAll(RegExp(r'[\s\-–_]+'), '.');
    b = b.replaceAll(RegExp(r'[\s\-–_]+'), '.');

    // Normalize and split the strings for comparison
    final (aParts, bParts) = _normalizeAndSplitStringsToCompare(a, b, regex);

    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      var aPart = aParts.getOrNull(i) ?? '';
      var bPart = bParts.getOrNull(i) ?? '';

      final aIsNumber = int.tryParse(aPart) != null;
      final bIsNumber = int.tryParse(bPart) != null;

      if (aIsNumber && bIsNumber) {
        final aNum = int.parse(aPart);
        final bNum = int.parse(bPart);

        if (aNum != bNum) {
          if (aNum > bNum) {
            Fimber.v(() =>
                '$aOriginal ($a) is newer than $bOriginal ($b) because $aNum > $bNum');
            return 1;
          } else {
            Fimber.v(() =>
                '$bOriginal ($b) is newer than $aOriginal ($a) because $bNum > $aNum');
            return -1;
          }
        }
      } else if (aIsNumber && !bIsNumber) {
        Fimber.v(() =>
            '$aOriginal ($a) is lower than $bOriginal ($b) because numbers come before letters or other characters');
        return 1; // Numbers come before letters or other characters
      } else if (!aIsNumber && bIsNumber) {
        Fimber.v(() =>
            '$aOriginal ($a) is newer than $bOriginal ($b) because letters or other characters come after numbers');
        return -1; // Letters or other characters come after numbers
      } else {
        final aLower = aPart.toLowerCase();
        final bLower = bPart.toLowerCase();

        final aContainsSuffix = suffixOrder.contains(aLower);
        final bContainsSuffix = suffixOrder.contains(bLower);

        if (aContainsSuffix && bContainsSuffix) {
          final aIndex = suffixOrder.indexOf(aLower);
          final bIndex = suffixOrder.indexOf(bLower);

          if (aIndex != bIndex) {
            if (aIndex > bIndex) {
              Fimber.v(() =>
                  '$bOriginal ($b) is newer than $aOriginal ($a) because $bPart has a higher suffix precedence than $aPart');
              return 1;
            } else {
              Fimber.v(() =>
                  '$aOriginal ($a) is newer than $bOriginal ($b) because $aPart has a higher suffix precedence than $bPart');
              return -1;
            }
          }
        } else if (aContainsSuffix) {
          Fimber.v(() =>
              '$aOriginal ($a) is lower than $bOriginal ($b) because $aPart should come before the non-suffix part');
          return -1; // Suffix should come before non-suffix part
        } else if (bContainsSuffix) {
          Fimber.v(() =>
              '$aOriginal ($a) is newer than $bOriginal ($b) because $bPart should come before the non-suffix part');
          return 1; // Suffix should come before non-suffix part
        } else {
          if (aPart.isEmpty && bPart.isNotEmpty) {
            Fimber.v(() =>
                '$bOriginal ($b) is newer than $aOriginal ($a) because $a is empty and $b is not');
            return -1;
          }
          if (aPart.isNotEmpty && bPart.isEmpty) {
            Fimber.v(() =>
                '$aOriginal ($a) is newer than $bOriginal ($b) because $b is empty and $a is not');
            return 1;
          }

          final cmp = aPart.compareTo(bPart);
          if (cmp != 0) {
            if (cmp > 0) {
              Fimber.v(() =>
                  '$aOriginal ($a) is newer than $bOriginal ($b) because $aPart > $bPart lexically');
              return 1;
            } else {
              Fimber.v(() =>
                  '$bOriginal ($b) is newer than $aOriginal ($a) because $bPart > $aPart lexically');
              return -1;
            }
          }
        }
      }
    }

    // Final length-based comparison
    final partsLengthComparison =
        aPartsOriginal.length.compareTo(bPartsOriginal.length);
    if (partsLengthComparison > 0) {
      Fimber.v(() =>
          '$aOriginal ($a) is newer than $bOriginal ($b) because $a has more parts');
      return 1;
    } else if (partsLengthComparison < 0) {
      Fimber.v(() =>
          '$bOriginal ($b) is newer than $aOriginal ($a) because $b has more parts');
      return -1;
    }

    final rawStringComparison = aOriginal.compareTo(bOriginal);
    if (rawStringComparison > 0) {
      Fimber.v(() =>
          '$aOriginal ($a) is newer than $bOriginal ($b) because $a is longer than $b');
      return 1;
    } else if (rawStringComparison < 0) {
      Fimber.v(() =>
          '$bOriginal ($b) is newer than $aOriginal ($a) because $b is longer than $a');
      return -1;
    }

    Fimber.v(() => '$aOriginal ($a) is the same as $bOriginal ($b)');
    return 0;
  }
}