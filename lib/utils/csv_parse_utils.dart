import 'dart:convert';

import 'package:csv/csv.dart';

class CsvJsonParsingUtils {
  /// Removes comments (`#`) outside of quotes in CSV lines.
  static String removeCsvLineComments(String line) {
    bool inQuotes = false;
    final buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') inQuotes = !inQuotes;
      if (!inQuotes && char == '#') break;
      buffer.write(char);
    }

    return buffer.toString().trimRight();
  }

  /// Removes comment lines from raw .wpn/.ship JSON-like files
  static String removeJsonComments(String raw) {
    return LineSplitter.split(
      raw,
    ).map((line) => line.split('#').first).join('\n');
  }

  /// Converts a single CSV row to a [Map<String, dynamic>] with typed values.
  static Map<String, dynamic> rowToTypedMap(
    List<dynamic> row,
    List<String> headers,
  ) {
    final result = <String, dynamic>{};

    for (int i = 0; i < headers.length; i++) {
      final key = headers[i];
      dynamic value = row.length > i ? row[i] : null;

      if (value == null || (value is String && value.trim().isEmpty)) {
        result[key] = null;
      } else if (value.toString().toUpperCase() == 'TRUE') {
        result[key] = true;
      } else if (value.toString().toUpperCase() == 'FALSE') {
        result[key] = false;
      } else {
        result[key] = num.tryParse(value.toString()) ?? value.toString();
      }
    }

    return result;
  }

  /// Attempts to parse a CSV string into a list of rows and logs errors if needed.
  static List<List<dynamic>> tryParseCsv({
    required String content,
    required String fileName,
    required List<String> errors,
    required String modName,
  }) {
    try {
      return const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(content);
    } catch (e) {
      errors.add('[$modName] Failed to parse CSV in $fileName: $e');
      return [];
    }
  }

  /// Removes comment lines, tracks original line numbers, returns clean content.
  static ({String cleanContent, List<int> lineNumberMap})
  stripCsvCommentsAndTrackLines(String content) {
    final lines = content.split('\n');
    final strippedLines = <String>[];
    final lineMap = <int>[];

    for (int i = 0; i < lines.length; i++) {
      final clean = removeCsvLineComments(lines[i]);
      if (clean.trim().isEmpty) continue;
      strippedLines.add(clean);
      lineMap.add(i + 1);
    }

    return (cleanContent: strippedLines.join('\n'), lineNumberMap: lineMap);
  }
}

extension CsvStringUtils on String {
  /// Removes `#` comments outside of quoted regions from a CSV line.
  String removeCsvLineComments() =>
      CsvJsonParsingUtils.removeCsvLineComments(this);

  /// Removes all `#` comments from a JSON-ish file (.ship/.wpn).
  String removeJsonComments() => CsvJsonParsingUtils.removeJsonComments(this);

  /// Removes comment lines from CSV, returns cleaned content + line number map.
  ({String cleanContent, List<int> lineNumberMap})
  stripCsvCommentsAndTrackLines() =>
      CsvJsonParsingUtils.stripCsvCommentsAndTrackLines(this);
}

extension CsvRowUtils on List<dynamic> {
  /// Converts a CSV row and headers into a strongly typed map.
  Map<String, dynamic> toTypedCsvMap(List<String> headers) =>
      CsvJsonParsingUtils.rowToTypedMap(this, headers);
}

extension CsvParsingUtils on String {
  /// Parses the CSV content into rows, recording errors if it fails.
  List<List<dynamic>> tryParseCsv({
    required String fileName,
    required List<String> errors,
    required String modName,
  }) {
    return CsvJsonParsingUtils.tryParseCsv(
      content: this,
      fileName: fileName,
      errors: errors,
      modName: modName,
    );
  }
}
