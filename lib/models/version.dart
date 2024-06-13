import 'package:collection/collection.dart';
import 'package:trios/utils/extensions.dart';

class Version implements Comparable<Version> {
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
      raw ?? [major, minor, patch, build].whereNotNull().join(".");

  @override
  int compareTo(Version? other) {
    if (other == null) return -1;

    var result = (major.compareRecognizingNumbers(other.major));
    if (result != 0) return result;

    result = (minor.compareRecognizingNumbers(other.minor));
    if (result != 0) return result;

    result = (patch.compareRecognizingNumbers(other.patch));
    if (result != 0) return result;

    result = ((build ?? "0").compareRecognizingNumbers(other.build ?? ""));
    return result;
  }

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode => raw.hashCode;

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
}
