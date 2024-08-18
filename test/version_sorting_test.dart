// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  test('problem comparisons', () {
    final correctPairs = [
      ['1.9.0', '1.9.g'],
      ['1.9.g', '1.9.1'],
      ['0.5.1', '0.5.3rc1'],
      ['1.0', '1.00'],
      ['1.6.1-0.96a', '1.6.1c'],
      ['2.5 Gramada', '2.5.2'],
      ['1.1.0', '1.1.b'],
      ['1.12.SSS', '1.12.1'],
    ];

    for (final pair in correctPairs) {
      final a = pair[0];
      final b = pair[1];
      final result = compareVersions(a, b);
      expect(result, -1);
    }
  });

  test('sort versions', () {
    const iterations = 50;

    for (int i = 0; i < iterations; i++) {
      final sorted = _expectedList.toList()
        ..shuffle()
        ..sort((a, b) => compareVersions(a, b));
      expect(sorted, _expectedList);
    }
  });
}

(List<String>, List<String>) normalizePair(
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
  if (a == b) {
    print('$a is the same as $b');
    return 0;
  }

  final regex = RegExp(r'(\d+|[a-zA-Z]+|[-\.]+)');

  final aOriginal = a;
  final bOriginal = b;
  final aPartsOriginal = regex.allMatches(a).map((m) => m.group(0)!).toList();
  final bPartsOriginal = regex.allMatches(b).map((m) => m.group(0)!).toList();

  // Remove all whitespace, hyphens, emdashes, and underscores
  a = a.replaceAll(RegExp(r'[\s\-–_]+'), '.');
  b = b.replaceAll(RegExp(r'[\s\-–_]+'), '.');

  // Normalize the versions
  final (aParts, bParts) = normalizePair(a, b, regex);
  // final aParts = regex.allMatches(a).map((m) => m.group(0)!).toList();
  // final bParts = regex.allMatches(b).map((m) => m.group(0)!).toList();

  final suffixOrder = ['alpha', 'beta', 'rc']; // Define the order of suffixes

  for (int i = 0; i < max(aParts.length, bParts.length); i++) {
    var aPart = aParts.getOrNull(i) ?? '';
    var bPart = bParts.getOrNull(i) ?? '';

    final aIsNumber = int.tryParse(aPart) != null;
    final bIsNumber = int.tryParse(bPart) != null;
    final aIsLetter = aPart.contains(RegExp(r'[a-zA-Z]'));
    final bIsLetter = bPart.contains(RegExp(r'[a-zA-Z]'));

    if (aIsNumber && bIsNumber) {
      final aNum = int.parse(aPart);
      final bNum = int.parse(bPart);

      if (aNum != bNum) {
        if (aNum > bNum) {
          print(
              '$aOriginal ($a) is newer than $bOriginal ($b) because $aNum > $bNum');
          return 1;
        } else {
          print(
              '$bOriginal ($b) is newer than $aOriginal ($a) because $bNum > $aNum');
          return -1;
        }
      }
    } else if (aIsNumber && !bIsNumber) {
      print(
          '$aOriginal ($a) is lower than $bOriginal ($b) because numbers come before letters or other characters');
      return 1; // Numbers come before letters or other characters
    } else if (!aIsNumber && bIsNumber) {
      print(
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
            print(
                '$bOriginal ($b) is newer than $aOriginal ($a) because $bPart has a higher suffix precedence than $aPart');
            return 1;
          } else {
            print(
                '$aOriginal ($a) is newer than $bOriginal ($b) because $aPart has a higher suffix precedence than $bPart');
            return -1;
          }
        }
      } else if (aContainsSuffix) {
        print(
            '$aOriginal ($a) is lower than $bOriginal ($b) because $aPart should come before the non-suffix part');
        return -1; // Suffix should come before non-suffix part
      } else if (bContainsSuffix) {
        print(
            '$aOriginal ($a) is newer than $bOriginal ($b) because $bPart should come before the non-suffix part');
        return 1; // Suffix should come before non-suffix part
      } else {
        if (aPart.isEmpty && bPart.isNotEmpty) {
          print(
              '$bOriginal ($b) is newer than $aOriginal ($a) because $a is empty and $b is not');
          return -1;
        }
        if (aPart.isNotEmpty && bPart.isEmpty) {
          print(
              '$aOriginal ($a) is newer than $bOriginal ($b) because $b is empty and $a is not');
          return 1;
        }

        final cmp = aPart.compareTo(bPart);
        if (cmp != 0) {
          if (cmp > 0) {
            print(
                '$aOriginal ($a) is newer than $bOriginal ($b) because $aPart > $bPart lexically');
            return 1;
          } else {
            print(
                '$bOriginal ($b) is newer than $aOriginal ($a) because $bPart > $aPart lexically');
            return -1;
          }
        }
      }
    }
  }

  final partsLengthComparison =
      aPartsOriginal.length.compareTo(bPartsOriginal.length);
  if (partsLengthComparison > 0) {
    print(
        '$aOriginal ($a) is newer than $bOriginal ($b) because $a has more parts');
    return 1;
  } else if (partsLengthComparison < 0) {
    print(
        '$bOriginal ($b) is newer than $aOriginal ($a) because $b has more parts');
    return -1;
  }

  final rawStringComparison = aOriginal.compareTo(bOriginal);
  if (rawStringComparison > 0) {
    print(
        '$aOriginal ($a) is newer than $bOriginal ($b) because $a is longer than $b');
    return 1;
  } else if (rawStringComparison < 0) {
    print(
        '$bOriginal ($b) is newer than $aOriginal ($a) because $b is longer than $a');
    return -1;
  }

  print('$aOriginal ($a) is the same as $bOriginal ($b)');
  return 0;
}

final _expectedList = [
  "0.0.1",
  "0.0.3",
  "0.0.4a",
  "0.0.4b",
  "0.0.4e",
  "0.0.4f",
  "0.1",
  "0.1.0",
  "0.1.1",
  "0.1.4",
  "0.1.5",
  "0.1.98.1a",
  "0.1b",
  "0.2.0",
  "0.2.9k",
  "0.3.1",
  "0.3.5",
  "0.3.5h",
  "0.3.5i",
  "0.3.7b",
  "0.3a",
  "0.4.0",
  "0.4.1",
  "0.4.1c",
  "0.4.2",
  "0.4.2a",
  "0.4.2c",
  "0.4.3",
  "0.5.0-RC1",
  "0.5.0",
  "0.5.0a",
  "0.5.0d",
  "0.5.0f",
  "0.5.0g",
  "0.5.1",
  "0.5.1a",
  "0.5.3rc1",
  "0.5.3rc1-wisp",
  "0.6.0d",
  "0.6.1c",
  "0.6.2d",
  "0.6.4.1",
  "0.6.5",
  "0.6.5d",
  "0.6.7",
  "0.6.8",
  "0.6.10",
  "0.7.2",
  "0.7.4a",
  "0.7.4d",
  "0.7.5a",
  "0.7.5b",
  "0.7.5c",
  "0.7.5c-rewritten-001",
  "0.9.6-rc1-Wisp-005",
  "0.10.1",
  "0.11.1",
  "0.11.1x",
  "0.11.2",
  "0.11.2b",
  "0.11.2c",
  "0.13.0",
  "0.13.2",
  "0.13.2a",
  "0.14.1b",
  "0.14.2",
  "0.16.1",
  "0.17rc1",
  "0.96a",
  "0.99-RC5",
  "0.99F",
  "versions are for suckers",
  "1.0.0Beta6",
  "1.0.0rc2",
  "1.0",
  "1.00",
  "1.0.0",
  "1.0.0b",
  "1.0.1",
  "1.0.3",
  "1.0.4",
  "1.0.5",
  "1.0.7",
  "1.01",
  "1.1.0",
  "1.1.b",
  "1.1.1",
  "1.1.1h",
  "1.1.2",
  "1.1.3",
  "1.2.0",
  "1.2.1",
  "1.2.2",
  "1.2.3",
  "1.2.4",
  "1.2.5",
  "1.2.6",
  "1.2.7",
  "1.2.10",
  "1.2.12",
  "1.2b",
  "1.2e",
  "1.3",
  "1.3.0",
  "1.3.2",
  "1.3.3",
  "1.3c",
  "1.4",
  "1.4.3",
  "1.4.5",
  "1.4.6",
  "1.4b",
  "1.5",
  "1.5.3",
  "1.5.5",
  "1.5.6",
  "1.5.7",
  "1.6.0",
  "1.6.1",
  "1.6.1-0.96a",
  "1.6.1c",
  "1.6.2",
  "1.6.3",
  "1.6.3a",
  "1.6.5",
  "1.6b",
  "1.6c",
  "1.7.0",
  "1.7.1",
  "1.7.2",
  "1.7.3",
  "1.7.4",
  "1.7.5",
  "1.8.0",
  "1.8.1",
  "1.8.2",
  "1.8.3",
  "1.8.4",
  "1.8.5",
  "1.09",
  "1.9",
  "1.9.0",
  "1.9.gg",
  "1.9.ggg",
  "1.9.gggg",
  "1.9.ggggggg",
  "1.9.2",
  "1.9.3",
  "1.9.5",
  "1.10.2",
  "1.11",
  "1.12.0",
  "1.12.SSS",
  "1.12.1",
  "1.12.4",
  "1.13.0",
  "1.13.SSS",
  "1.13.2",
  "1.14.0",
  "1.14.1",
  "1.15.1",
  "1.17.1",
  "1.18.3ad",
  "1.18.3ae",
  "1.18.3aj",
  "1.41rc2",
  "002",
  "2.0.0",
  "2.0.c",
  "2.0.e",
  "2.0.3",
  "2.0.4",
  "2.0.8-Part1",
  "2.0.9",
  "2.1.0",
  "2.1.8",
  "2.2",
  "2.2.0",
  "2.2.1",
  "2.3.0",
  "2.3.1",
  "2.3.2",
  "2.4.0",
  "2.4.2",
  "2.4.6",
  "2.5 Gramada",
  "2.5.2",
  "2.6.2c",
  "2.6.2e",
  "2.6.4",
  "2.7.0rc3",
  "2.8",
  "2.8b",
  "2.64",
  "3.0",
  "3.0.5",
  "3.0.6.1",
  "3.0.9",
  "3.1.3",
  "3.2.c UNOFFICIAL",
  "3.2.1",
  "3.3.c-wisp001",
  "3.3.5",
  "3.3.6",
  "3.3.7",
  "4.0.0",
  "4.0.2",
  "4.1.0",
  "4.3.2",
  "4.4.0",
  "4.4.1",
  "5.1.0",
  "5.1.1",
  "5.2.0",
  "5.3.3",
  "5.4.0",
  "5.4.1",
  "6.2.1",
  "6.2.3",
  "8.4.5",
  "2021.4.10",
  "2023.5.05",
];
