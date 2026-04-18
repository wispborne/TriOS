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
  ///
  /// Walks the content character-by-character with a global `inQuotes` state
  /// that persists across physical newlines, so that:
  ///
  /// - A `#` outside of a quoted field comments out the rest of the logical
  ///   row (end of row = next unquoted `\n`).
  /// - A commented row whose quoted fields contain literal newlines is
  ///   dropped in its entirety — the embedded newlines do not terminate
  ///   the commented row, so continuation lines are not misread as new rows.
  /// - A `#` inside a quoted field is treated as data, not a comment.
  /// - Escaped `""` inside a quoted field is preserved.
  ///
  /// Each entry in the returned `lineNumberMap` is the 1-indexed source line
  /// where the corresponding emitted logical row began.
  static ({String cleanContent, List<int> lineNumberMap})
  stripCsvCommentsAndTrackLines(String content) {
    final outRows = <String>[];
    final lineMap = <int>[];
    final currentRow = StringBuffer();

    bool inQuotes = false;
    bool inComment = false;
    int sourceLine = 1;
    int? rowStartLine;

    void flushRow() {
      if (!inComment) {
        final rowStr = currentRow.toString();
        if (rowStr.trim().isNotEmpty) {
          outRows.add(rowStr);
          lineMap.add(rowStartLine ?? sourceLine);
        }
      }
      currentRow.clear();
      inComment = false;
      rowStartLine = null;
    }

    void markRowStart() {
      rowStartLine ??= sourceLine;
    }

    for (int i = 0; i < content.length; i++) {
      final c = content[i];

      // Skip \r in CRLF sequences — treat \n as the sole line terminator.
      if (c == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
        continue;
      }

      if (inQuotes) {
        if (c == '"') {
          // Escaped "" inside a quoted field.
          if (i + 1 < content.length && content[i + 1] == '"') {
            if (!inComment) {
              markRowStart();
              currentRow.write('""');
            }
            i += 1;
            continue;
          }
          inQuotes = false;
          if (!inComment) {
            markRowStart();
            currentRow.write('"');
          }
          continue;
        }
        if (c == '\n') {
          // Literal newline inside a quoted field — preserve and keep row open.
          sourceLine++;
          if (!inComment) {
            markRowStart();
            currentRow.write('\n');
          }
          continue;
        }
        if (!inComment) {
          markRowStart();
          currentRow.write(c);
        }
        continue;
      }

      // Not in quotes.
      if (c == '\n') {
        flushRow();
        sourceLine++;
        continue;
      }
      if (inComment) {
        // Still need to track quote state so a commented row's multi-line
        // quoted field doesn't terminate the row prematurely.
        if (c == '"') inQuotes = true;
        continue;
      }
      if (c == '"') {
        inQuotes = true;
        markRowStart();
        currentRow.write('"');
        continue;
      }
      if (c == '#') {
        inComment = true;
        continue;
      }
      // Ordinary character outside quotes and outside comments.
      if (c != ' ' && c != '\t') {
        markRowStart();
      }
      currentRow.write(c);
    }

    // Flush the final row (no trailing newline in the input).
    flushRow();

    return (cleanContent: outRows.join('\n'), lineNumberMap: lineMap);
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
