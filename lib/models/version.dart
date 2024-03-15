import 'package:collection/collection.dart';

// All Gemini created, not verified yet.
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
  String toString() => raw ?? [major, minor, patch, build].whereNotNull().join(".");

  @override
  int compareTo(Version? other) {
    if (other == null) return -1;

    var result = _compareRecognizingNumbers(major, other.major);
    if (result != 0) return result;

    result = _compareRecognizingNumbers(minor, other.minor);
    if (result != 0) return result;

    result = _compareRecognizingNumbers(patch, other.patch);
    if (result != 0) return result;

    result = _compareRecognizingNumbers(build ?? "0", other.build ?? "");
    return result;
  }

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode => raw.hashCode;

  static Version parse(String versionString) {
    // Remove non-version characters
    final sanitizedString = versionString.replaceAll(RegExp(r"[^0-9.-]"), "");

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

  // Helper for comparing number-like strings
  int _compareRecognizingNumbers(String str1, String str2) {
    final chunks1 = _splitIntoAlphaAndNumeric(str1);
    final chunks2 = _splitIntoAlphaAndNumeric(str2);

    for (var i = 0; i < chunks1.length || i < chunks2.length; i++) {
      final chunk1 = _getSafeChunk(chunks1, i);
      final chunk2 = _getSafeChunk(chunks2, i);

      final result = _compareChunks(chunk1, chunk2);
      if (result != 0) return result;
    }

    return 0;
  }

  // Helper to split strings into letter and number components
  List<String> _splitIntoAlphaAndNumeric(String str) {
    final letterDigitSplitterRegex = RegExp(r"(?<=\D)(?=\d)|(?<=\d)(?=\D)");
    return letterDigitSplitterRegex.allMatches(str).map((m) => str.substring(m.start, m.end)).toList()
      ..add(str.substring(str.length)); // Add the last part manually
  }

  String _getSafeChunk(List<String> chunks, int index) => index < chunks.length ? chunks[index] : "0";

  int _compareChunks(String chunk1, String chunk2) {
    final int1 = int.tryParse(chunk1);
    final int2 = int.tryParse(chunk2);

    if (int1 != null && int2 != null) {
      return int1.compareTo(int2);
    } else {
      return chunk1.compareTo(chunk2);
    }
  }
}
