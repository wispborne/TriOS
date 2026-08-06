import 'package:trios/utils/extensions.dart';

/// Lenient reads for values out of a parsed Starsector JSON file.
///
/// The game reads numbers and booleans through org.json's `opt`/`get` methods,
/// which accept a quoted string wherever a number or boolean is expected —
/// `"angle": "90"` and `"utility": "true"` both work in game. The parser keeps
/// those values as strings because it can't know what type the reader wants,
/// so any code reading a number or boolean out of game JSON should go through
/// these instead of casting.

/// The value as a double: numbers pass through, numeric strings are parsed
/// (including Java-style `"1.5f"`), anything else is null.
double? doubleFromGameJson(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return value.toDoubleOrNullAllowingJavaSuffix();
  return null;
}

/// The value as a bool: bools pass through, `"true"`/`"false"` strings are
/// parsed (any casing), anything else is null.
bool? boolFromGameJson(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return null;
}
